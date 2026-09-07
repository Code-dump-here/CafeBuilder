import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/responses/payment_responses.dart';
import '../services/api_client.dart';
import '../services/payment_service.dart';
import '../services/subscription_service.dart';
import '../theme/app_colors.dart';
import '../utils/money.dart';
import 'subscription_cancel_page.dart';
import 'subscription_return_page.dart';

/// Buying a platform plan, through payOS.
///
/// The page used to render a mock VietQR and a hard-coded bank account with a
/// "Xác nhận đã thanh toán" button that simply flipped a local flag. That is
/// replaced by the real flow the API is built for: the server opens a payOS
/// link, payOS collects the money on its own hosted page (its QR, its bank
/// details, its transfer content — none of it ours to invent), and its webhook
/// tells the server the outcome. This screen only ever *asks* what happened,
/// through `GET /payments/status`; it can no longer grant itself the plan.
class SubscriptionCheckoutPage extends StatefulWidget {
  const SubscriptionCheckoutPage({super.key});

  @override
  State<SubscriptionCheckoutPage> createState() =>
      _SubscriptionCheckoutPageState();
}

class _SubscriptionCheckoutPageState extends State<SubscriptionCheckoutPage> {
  List<SubscriptionPlanResponse> _plans = [];
  SubscriptionPlanResponse? _selected;

  /// The live payOS link once one has been opened for this visit.
  CreatePaymentResponse? _payment;

  /// Latest reading of the transaction, while we wait for payOS to settle it.
  PaymentStatusResponse? _status;

  bool _loadingPlans = true;
  bool _creating = false;
  bool _checking = false;
  String? _error;

  /// Guards the polling loop: it must stop when the page goes away, otherwise
  /// it keeps hitting the API for a screen nobody is looking at.
  bool _polling = false;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  @override
  void dispose() {
    _polling = false;
    super.dispose();
  }

  Future<void> _loadPlans() async {
    setState(() {
      _loadingPlans = true;
      _error = null;
    });
    try {
      // Plans are sold per role and the server filters for us; asking for
      // someone else's role would offer the owner a provider plan they cannot
      // use. Fall back to 'owner' — this app is the owner app.
      final role = await ApiClient.getRole() ?? 'owner';
      final plans = await PaymentService.getPlans(targetRole: role);
      if (!mounted) return;
      setState(() {
        _plans = plans;
        // Cheapest first is the sane default: it is the monthly plan, and a
        // yearly commitment should be an explicit choice.
        _selected = plans.isEmpty
            ? null
            : (plans.toList()..sort((a, b) => a.price.compareTo(b.price))).first;
        _loadingPlans = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loadingPlans = false;
      });
    }
  }

  /// Creates (or reuses) the payOS link and opens it.
  Future<void> _startPayment() async {
    final plan = _selected;
    if (plan == null || _creating) return;

    setState(() {
      _creating = true;
      _error = null;
    });
    try {
      final payment =
          await PaymentService.createSubscriptionPayment(planId: plan.id);
      if (!mounted) return;
      setState(() {
        _payment = payment;
        _creating = false;
      });
      await _openCheckoutUrl();
      _startPolling();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _creating = false;
      });
    }
  }

  Future<void> _openCheckoutUrl() async {
    final url = _payment?.checkoutUrl;
    if (url == null || url.isEmpty) return;
    // externalApplication: payOS's page has to run in a real browser to reach
    // the banking apps it hands off to.
    final opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      setState(() => _error =
          'Không mở được trang thanh toán payOS. Bạn có thể sao chép link và mở bằng trình duyệt.');
    }
  }

  /// Polls until payOS settles the transaction, then routes on the outcome.
  Future<void> _startPolling() async {
    final orderCode = _payment?.orderCode;
    if (orderCode == null || _polling) return;

    _polling = true;
    try {
      final result = await PaymentService.pollStatus(
        orderCode: orderCode,
        shouldContinue: () => _polling && mounted,
        onPoll: (s) {
          if (mounted) setState(() => _status = s);
        },
      );
      if (!mounted || !_polling) return;
      await _routeOnOutcome(result);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      _polling = false;
    }
  }

  /// One manual reading, for the "Tôi đã thanh toán" button — a payer who has
  /// just finished should not have to wait out the poll interval.
  Future<void> _checkNow() async {
    final orderCode = _payment?.orderCode;
    if (orderCode == null || _checking) return;

    setState(() => _checking = true);
    try {
      final status = await PaymentService.getStatus(orderCode: orderCode);
      if (!mounted) return;
      setState(() {
        _status = status;
        _checking = false;
      });
      if (status.isFinal) await _routeOnOutcome(status);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _checking = false;
      });
    }
  }

  Future<void> _routeOnOutcome(PaymentStatusResponse status) async {
    if (!status.isFinal || !mounted) return;
    _polling = false;

    if (status.isPaid) {
      // Read the entitlement back from the server rather than assuming it:
      // "paid" is a fact about the transaction, "subscribed" is a fact about
      // the account, and only the server joins the two.
      await SubscriptionService.refreshFromServer();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SubscriptionReturnPage(orderCode: status.orderCode),
        ),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => SubscriptionCancelPage(orderCode: status.orderCode),
      ),
    );
  }

  /// Leaving the screen with a link still pending. The server is told, so the
  /// transaction does not sit pending until payOS expires it.
  Future<void> _handleCancelPayment() async {
    _polling = false;
    final orderCode = _payment?.orderCode;

    if (orderCode == null) {
      // Nothing was ever created — just back out.
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => SubscriptionCancelPage(orderCode: orderCode),
      ),
    );
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã sao chép $label vào bộ nhớ tạm'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Thanh Toán Subscription',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
            color: AppColors.espresso,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.espresso),
          onPressed: _handleCancelPayment,
        ),
      ),
      body: _loadingPlans
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.espresso))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPlanSummary(),
                  const SizedBox(height: 24),
                  if (_payment == null) _buildPlanPicker() else _buildPending(),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    _buildError(_error!),
                  ],
                  const SizedBox(height: 24),
                  _buildActions(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  // ── Sections ───────────────────────────────────────────────────────────────

  Widget _buildPlanSummary() {
    final plan = _selected;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.espresso, Color(0xFF67492F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.espresso.withValues(alpha: 0.25),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.workspace_premium,
                    color: Color(0xFFFFD700), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GÓI NÂNG CẤP PRO VIP',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFFFD700),
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      plan?.name ?? 'Mở khóa 3D Layout Visual',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (plan?.description != null &&
                        plan!.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        plan.description!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          height: 1.4,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: Colors.white24, height: 1),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Tổng chi phí thanh toán:',
                style: GoogleFonts.inter(fontSize: 13, color: Colors.white70),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  plan == null ? '—' : formatVnd(plan.price),
                  textAlign: TextAlign.right,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFFD700),
                  ),
                ),
              ),
            ],
          ),
          if (plan != null) ...[
            const SizedBox(height: 4),
            Text(
              'Thời hạn ${plan.durationInDays} ngày',
              style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
            ),
          ],
        ],
      ),
    );
  }

  /// Which plan to buy. Rendered even for a single plan so the duration and
  /// price the payer is committing to are on screen before they pay.
  Widget _buildPlanPicker() {
    if (_plans.isEmpty) {
      return _buildCard(
        child: Text(
          'Hiện chưa có gói nào đang mở bán cho tài khoản của bạn.',
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
        ),
      );
    }

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chọn gói',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.espresso,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Thanh toán qua payOS — quét VietQR hoặc chuyển khoản ngay trên trang của payOS.',
            style: GoogleFonts.inter(
              fontSize: 12,
              height: 1.4,
              color: AppColors.placeholder,
            ),
          ),
          const SizedBox(height: 12),
          ..._plans.map((plan) {
            final isSelected = _selected?.id == plan.id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => setState(() => _selected = plan),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.espresso.withValues(alpha: 0.06)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.espresso
                          : AppColors.outlineVariant,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        size: 18,
                        color: isSelected
                            ? AppColors.espresso
                            : AppColors.placeholder,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              plan.name,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              '${plan.durationInDays} ngày',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.placeholder,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        formatVnd(plan.price),
                        textAlign: TextAlign.right,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.espresso,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  /// After the link is open: what the payer needs to reconcile the transfer,
  /// taken from the transaction the server actually created.
  Widget _buildPending() {
    final payment = _payment!;
    final status = _status;

    return _buildCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.espresso),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  status?.message ?? 'Đang chờ payOS xác nhận thanh toán…',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.espresso,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Hoàn tất thanh toán trên trang payOS vừa mở. Màn hình này tự cập nhật khi payOS báo về.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              height: 1.4,
              color: AppColors.placeholder,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: AppColors.outlineVariant.withValues(alpha: 0.4)),
            ),
            child: Column(
              children: [
                _buildDetailRow(
                  'Mã giao dịch',
                  '${payment.orderCode}',
                  isHighlight: true,
                  onCopy: () => _copyToClipboard(
                      '${payment.orderCode}', 'Mã giao dịch'),
                ),
                const Divider(height: 16),
                _buildDetailRow('Số tiền', formatVnd(payment.amount)),
                const Divider(height: 16),
                _buildDetailRow(
                  'Link hết hạn',
                  _formatTime(payment.expiresAt),
                ),
                const Divider(height: 16),
                _buildDetailRow(
                  'Link thanh toán',
                  payment.checkoutUrl,
                  onCopy: () =>
                      _copyToClipboard(payment.checkoutUrl, 'Link thanh toán'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    if (_payment == null) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed:
                  _selected == null || _creating ? null : _startPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.espresso,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 2,
              ),
              child: _creating
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.qr_code_2_rounded, size: 20),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Thanh toán qua payOS',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                                fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 12),
          _buildCancelButton('Quay lại'),
        ],
      );
    }

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _checking ? null : _checkNow,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.espresso,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 2,
            ),
            child: _checking
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_outline, size: 20),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Tôi đã thanh toán — kiểm tra',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                              fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            onPressed: _openCheckoutUrl,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.espresso,
              side: const BorderSide(color: AppColors.outlineVariant),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.open_in_new, size: 18),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Mở lại trang thanh toán',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildCancelButton('Hủy thanh toán'),
      ],
    );
  }

  Widget _buildCancelButton(String label) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: _handleCancelPayment,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red[700],
          side: BorderSide(color: Colors.red[300]!),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cancel_outlined, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style:
                    GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Small pieces ───────────────────────────────────────────────────────────

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildError(String message) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, size: 18, color: Colors.red.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 12,
                height: 1.4,
                color: Colors.red.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatTime(DateTime value) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(value.hour)}:${two(value.minute)} ${two(value.day)}/${two(value.month)}/${value.year}';
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isHighlight = false,
    VoidCallback? onCopy,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Text(
            label,
            style:
                GoogleFonts.inter(fontSize: 13, color: AppColors.placeholder),
          ),
        ),
        Expanded(
          flex: 6,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight:
                        isHighlight ? FontWeight.bold : FontWeight.w600,
                    color: isHighlight
                        ? AppColors.espresso
                        : AppColors.textPrimary,
                  ),
                ),
              ),
              if (onCopy != null) ...[
                const SizedBox(width: 6),
                InkWell(
                  onTap: onCopy,
                  borderRadius: BorderRadius.circular(4),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.copy_rounded,
                        size: 16, color: AppColors.espresso),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
