import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/responses/payment_responses.dart';
import '../services/payment_service.dart';
import '../theme/app_colors.dart';
import 'subscription_checkout_page.dart';

/// Where payOS sends the payer when they abandon a transaction — the
/// `MobileCancelUrl` in the API's payOS config points at `/payment/cancel`.
///
/// Arriving here is not by itself a cancellation: payOS only redirects, the
/// transaction is still `pending` on our side until someone says otherwise. So
/// the page calls `POST /payments/cancel` for [orderCode] on arrival, which is
/// idempotent and only touches a transaction the caller owns. Without it the
/// row sits pending until the link expires, and the account's next attempt
/// silently reuses that stale link.
class SubscriptionCancelPage extends StatefulWidget {
  /// From the `orderCode` query parameter payOS appends to the cancel URL, or
  /// passed directly when the checkout screen routes here itself. Null when
  /// the user backed out before any link was created — there is nothing to
  /// cancel then.
  final int? orderCode;

  const SubscriptionCancelPage({super.key, this.orderCode});

  @override
  State<SubscriptionCancelPage> createState() => _SubscriptionCancelPageState();
}

class _SubscriptionCancelPageState extends State<SubscriptionCancelPage> {
  PaymentStatusResponse? _status;
  bool _working = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.orderCode != null) _cancelOnServer();
  }

  Future<void> _cancelOnServer() async {
    setState(() {
      _working = true;
      _error = null;
    });
    try {
      final status = await PaymentService.cancel(widget.orderCode!);
      if (!mounted) return;
      setState(() {
        _status = status;
        _working = false;
      });
    } catch (e) {
      if (!mounted) return;
      // A failure here is worth showing but not worth blocking on: the payer
      // has already left the payment, and payOS expires the link regardless.
      setState(() {
        _error = e.toString();
        _working = false;
      });
    }
  }

  /// The one case where landing on the cancel URL does not mean cancelled: the
  /// payer paid, then hit back before payOS finished redirecting.
  bool get _actuallyPaid => _status?.isPaid ?? false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Hủy Thanh Toán',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),

            // Cancel Icon Banner
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: const BoxDecoration(
                    color: Colors.amber,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.cancel_outlined,
                      color: Colors.white, size: 48),
                ),
              ),
            ),

            const SizedBox(height: 24),

            Text(
              _actuallyPaid ? 'Giao Dịch Đã Thanh Toán' : 'Giao Dịch Đã Bị Hủy',
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.espresso,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              _actuallyPaid
                  ? 'payOS báo giao dịch này đã thanh toán thành công, nên hệ thống không huỷ nữa. Mở lại báo cáo để dùng quyền lợi đã kích hoạt.'
                  : 'Bạn vừa dừng quá trình thanh toán nâng cấp Subscription. Tài khoản của bạn hiện ở trạng thái Miễn phí (ảnh 3D Layout Visualization sẽ tiếp tục được làm mờ).',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                height: 1.6,
                color: AppColors.textSecondary,
              ),
            ),

            if (widget.orderCode != null) ...[
              const SizedBox(height: 12),
              Text(
                _working
                    ? 'Đang báo huỷ giao dịch #${widget.orderCode}…'
                    : 'Mã giao dịch #${widget.orderCode}'
                        '${_status == null ? '' : ' — ${_status!.message}'}',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.placeholder,
                ),
              ),
            ],

            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style:
                    GoogleFonts.inter(fontSize: 12, color: Colors.red.shade700),
              ),
            ],

            const SizedBox(height: 32),

            // Benefits reminder box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AppColors.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.stars_rounded,
                          color: AppColors.espresso, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Quyền lợi khi đăng ký Subscription:',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.espresso,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildFeatureBullet('Xem hình ảnh 3D Layout sắc nét & chi tiết cao'),
                  _buildFeatureBullet('Mở khóa toàn bộ báo cáo phân tích AI Concept'),
                  _buildFeatureBullet('Hỗ trợ ưu tiên và cập nhật không giới hạn'),
                ],
              ),
            ),

            const SizedBox(height: 36),

            // Action Buttons
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _working
                    ? null
                    : () {
                        // A fresh editor, not `pushReplacementNamed`: coming
                        // back here from that screen should land on the cancel
                        // page it came from, not on a route that no longer
                        // exists in the stack.
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SubscriptionCheckoutPage(),
                          ),
                        );
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
                    const Icon(Icons.refresh_rounded, size: 20),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Thử Thanh Toán Lại',
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
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    Navigator.pushReplacementNamed(context, '/home');
                  }
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.espresso,
                  side: const BorderSide(color: AppColors.outlineVariant),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  'Quay Về Trang Báo Cáo',
                  style: GoogleFonts.inter(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline,
              color: Color(0xFF4CAF50), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
