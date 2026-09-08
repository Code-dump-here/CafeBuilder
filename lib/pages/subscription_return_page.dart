import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/responses/payment_responses.dart';
import '../services/payment_service.dart';
import '../services/subscription_service.dart';
import '../theme/app_colors.dart';
import '../utils/money.dart';

/// Where payOS sends the payer back after a completed transaction — the
/// `MobileReturnUrl` in the API's payOS config points at `/payment/success`.
///
/// The page shows the transaction the *server* has, not a success message it
/// assumed: it reads `GET /payments/status` for [orderCode] and, when that
/// says paid, re-reads the entitlement from
/// `GET /payments/subscriptions/me/active`. A payer can land here before
/// payOS's webhook has reached the server, so a pending reading is a normal
/// state with its own message, not an error.
class SubscriptionReturnPage extends StatefulWidget {
  /// From the `orderCode` query parameter payOS appends to the return URL, or
  /// passed directly when the checkout screen routes here itself.
  final int? orderCode;

  const SubscriptionReturnPage({super.key, this.orderCode});

  @override
  State<SubscriptionReturnPage> createState() => _SubscriptionReturnPageState();
}

class _SubscriptionReturnPageState extends State<SubscriptionReturnPage> {
  PaymentStatusResponse? _status;
  SubscriptionResponse? _subscription;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      PaymentStatusResponse? status;
      if (widget.orderCode != null) {
        // Give the webhook a couple of chances to land: payOS redirects the
        // payer the moment it takes the money, which can beat its own
        // server-to-server callback by a second or two.
        status = await PaymentService.pollStatus(
          orderCode: widget.orderCode,
          intervalSeconds: 2,
          maxAttempts: 5,
          shouldContinue: () => mounted,
        );
      }

      // Refreshes the local cache too, so the gated 3D visual unlocks the
      // moment this page has an answer.
      final active = await SubscriptionService.refreshFromServer();

      if (!mounted) return;
      setState(() {
        _status = status;
        _subscription = active;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  /// Paid according to the transaction, or — when we arrived without an
  /// orderCode — simply the fact that the account now holds a live plan.
  bool get _isSuccess =>
      (_status?.isPaid ?? false) || (_subscription?.isLive ?? false);

  bool get _isPending => _status != null && !_status!.isFinal;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Kết Quả Thanh Toán',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
            color: AppColors.espresso,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.espresso))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildBadge(),
                  const SizedBox(height: 20),
                  Text(
                    _headline(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.espresso,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _blurb(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      height: 1.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 30),
                  _buildReceipt(),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                          fontSize: 12, color: Colors.red.shade700),
                    ),
                  ],
                  const SizedBox(height: 36),
                  _buildActions(),
                ],
              ),
            ),
    );
  }

  Widget _buildBadge() {
    final color = _isSuccess
        ? const Color(0xFF4CAF50)
        : _isPending
            ? Colors.amber
            : Colors.red.shade400;
    final icon = _isSuccess
        ? Icons.check_rounded
        : _isPending
            ? Icons.hourglass_top_rounded
            : Icons.close_rounded;

    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: 48),
        ),
      ),
    );
  }

  String _headline() {
    if (_isSuccess) return 'Thanh Toán Thành Công!';
    if (_isPending) return 'Đang Chờ Xác Nhận';
    return 'Chưa Ghi Nhận Thanh Toán';
  }

  String _blurb() {
    if (_isSuccess) {
      return 'Cảm ơn bạn đã đăng ký gói Subscription Pro! Quyền lợi mở khóa 3D Layout Visual đã được kích hoạt trên tài khoản của bạn.';
    }
    if (_isPending) {
      return 'payOS chưa báo kết quả về hệ thống. Nếu bạn vừa chuyển khoản xong, chờ thêm một lát rồi bấm "Kiểm tra lại".';
    }
    return _status?.message ??
        'Giao dịch chưa hoàn tất nên gói chưa được kích hoạt.';
  }

  Widget _buildReceipt() {
    final status = _status;
    final sub = _subscription;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long_outlined,
                  color: AppColors.espresso, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Thông Tin Giao Dịch',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.espresso,
                  ),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          _buildSummaryItem('Gói dịch vụ', sub?.planName ?? '—'),
          if (status != null)
            _buildSummaryItem('Mã giao dịch', '${status.orderCode}'),
          _buildSummaryItem(
            'Số tiền thanh toán',
            formatVnd(status?.amount ?? sub?.paidAmount ?? 0),
          ),
          if (sub != null) ...[
            _buildSummaryItem('Hiệu lực từ', _formatDate(sub.startDate)),
            _buildSummaryItem('Hết hạn', _formatDate(sub.endDate)),
          ],
          _buildSummaryItem(
            'Trạng thái',
            _statusLabel(),
            isSuccessStatus: _isSuccess,
          ),
        ],
      ),
    );
  }

  String _statusLabel() {
    if (_isSuccess) return 'Thành công (Đã kích hoạt)';
    if (_isPending) return 'Đang chờ payOS xác nhận';
    switch (_status?.status) {
      case 'cancelled':
        return 'Đã huỷ';
      case 'failed':
        return 'Thất bại';
      default:
        return 'Chưa kích hoạt';
    }
  }

  Widget _buildActions() {
    return Column(
      children: [
        if (_isSuccess)
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  Navigator.pushReplacementNamed(context, '/home');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.espresso,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 2,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.visibility_rounded, size: 20),
                  const SizedBox(width: 8),
                  // Nhãn dài gần bằng bề ngang nút trên máy nhỏ; Flexible cho
                  // nó xuống dòng thay vì tràn ra khỏi nút.
                  Flexible(
                    child: Text(
                      'Trải Nghiệm Ngay 3D Layout Visual',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                          fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _load,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.espresso,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 2,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.refresh_rounded, size: 20),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Kiểm tra lại',
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
          child: TextButton(
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                  context, '/home', (route) => false);
            },
            child: Text(
              'Quay Về Trang Chủ',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  static String _formatDate(DateTime value) {
    String two(int n) => n.toString().padLeft(2, '0');
    final local = value.toLocal();
    return '${two(local.day)}/${two(local.month)}/${local.year}';
  }

  Widget _buildSummaryItem(String label, String value,
      {bool isSuccessStatus = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style:
                GoogleFonts.inter(fontSize: 13, color: AppColors.placeholder),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSuccessStatus
                    ? const Color(0xFF2E7D32)
                    : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
