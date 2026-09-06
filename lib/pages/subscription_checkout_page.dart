import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/subscription_service.dart';
import '../theme/app_colors.dart';

class SubscriptionCheckoutPage extends StatefulWidget {
  const SubscriptionCheckoutPage({super.key});

  @override
  State<SubscriptionCheckoutPage> createState() => _SubscriptionCheckoutPageState();
}

class _SubscriptionCheckoutPageState extends State<SubscriptionCheckoutPage> {
  final String _bankName = 'MB Bank (Nghân hàng Quân Đội)';
  final String _accountNumber = '999988886666';
  final String _accountName = 'CAFE BUILDER CO., LTD';
  final String _amount = '199.000 VNĐ';
  final String _transferCode = 'SUB3D99824';

  bool _isProcessing = false;

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

  Future<void> _handleConfirmPayment() async {
    setState(() {
      _isProcessing = true;
    });

    // Simulate quick network/payment check delay
    await Future.delayed(const Duration(milliseconds: 1200));

    await SubscriptionService.setSubscribed(true, planName: 'Gói VIP 3D Layout Visual');

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/subscription-return');
  }

  void _handleCancelPayment() {
    Navigator.pushReplacementNamed(context, '/subscription-cancel');
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Summary Card
            Container(
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
                        child: const Icon(Icons.workspace_premium, color: Color(0xFFFFD700), size: 24),
                      ),
                      const SizedBox(width: 12),
                      Column(
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
                            'Mở khóa 3D Layout Visual',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(color: Colors.white24, height: 1),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tổng chi phí thanh toán:',
                        style: GoogleFonts.inter(fontSize: 13, color: Colors.white70),
                      ),
                      Text(
                        _amount,
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFFFD700),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // QR Code Payment Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.6)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.qr_code_2_rounded, color: AppColors.espresso, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'Quét Mã VietQR Chuyển Khoản',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.espresso,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Mở ứng dụng ngân hàng bất kỳ để quét mã',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.placeholder),
                  ),
                  const SizedBox(height: 20),

                  // QR Image Container (Stylized VietQR Mockup)
                  Container(
                    width: 230,
                    height: 230,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.espresso.withValues(alpha: 0.2), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.espresso.withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Stylized QR pattern illustration
                        CustomPaint(
                          size: const Size(200, 200),
                          painter: _QrMockupPainter(),
                        ),
                        // Center bank logo badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.espresso,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: const [
                              BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                            ],
                          ),
                          child: Text(
                            'VietQR',
                            style: GoogleFonts.inter(
                              color: const Color(0xFFFFD700),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Bank Details Table
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.4)),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow('Ngân hàng', _bankName),
                        const Divider(height: 16),
                        _buildDetailRow(
                          'Số tài khoản',
                          _accountNumber,
                          onCopy: () => _copyToClipboard(_accountNumber, 'Số tài khoản'),
                        ),
                        const Divider(height: 16),
                        _buildDetailRow('Chủ tài khoản', _accountName),
                        const Divider(height: 16),
                        _buildDetailRow('Số tiền', _amount),
                        const Divider(height: 16),
                        _buildDetailRow(
                          'Nội dung CK',
                          _transferCode,
                          isHighlight: true,
                          onCopy: () => _copyToClipboard(_transferCode, 'Nội dung chuyển khoản'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _handleConfirmPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.espresso,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
                child: _isProcessing
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_outline, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Xác nhận đã thanh toán',
                            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold),
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
                onPressed: _isProcessing ? null : _handleCancelPayment,
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
                    Text(
                      'Hủy thanh toán',
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isHighlight = false, VoidCallback? onCopy}) {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.placeholder),
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
                    fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
                    color: isHighlight ? AppColors.espresso : AppColors.textPrimary,
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
                    child: Icon(Icons.copy_rounded, size: 16, color: AppColors.espresso),
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

/// Helper custom painter to render a crisp QR Code placeholder graphic.
class _QrMockupPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1B1C1C)
      ..style = PaintingStyle.fill;

    const double blockSize = 8;

    // Corner Finder Patterns
    void drawFinder(double x, double y) {
      canvas.drawRect(Rect.fromLTWH(x, y, 48, 48), paint);
      final whitePaint = Paint()..color = Colors.white;
      canvas.drawRect(Rect.fromLTWH(x + 8, y + 8, 32, 32), whitePaint);
      canvas.drawRect(Rect.fromLTWH(x + 14, y + 14, 20, 20), paint);
    }

    drawFinder(10, 10);
    drawFinder(size.width - 58, 10);
    drawFinder(10, size.height - 58);

    // Random pattern grid elements
    final gridMatrix = [
      [0, 1, 1, 0, 1, 0, 1, 1, 0, 1],
      [1, 0, 0, 1, 0, 1, 0, 0, 1, 0],
      [0, 1, 1, 0, 1, 1, 1, 0, 0, 1],
      [1, 1, 0, 1, 0, 0, 1, 1, 0, 0],
      [0, 0, 1, 0, 1, 1, 0, 1, 1, 0],
      [1, 0, 1, 1, 0, 0, 1, 0, 0, 1],
      [0, 1, 0, 0, 1, 1, 0, 1, 1, 0],
      [1, 1, 1, 0, 0, 1, 1, 0, 1, 1],
    ];

    for (int r = 0; r < gridMatrix.length; r++) {
      for (int c = 0; c < gridMatrix[r].length; c++) {
        if (gridMatrix[r][c] == 1) {
          final x = 65 + c * blockSize * 1.5;
          final y = 65 + r * blockSize * 1.5;
          if (x < size.width - 20 && y < size.height - 20) {
            canvas.drawRRect(
              RRect.fromRectAndRadius(Rect.fromLTWH(x, y, blockSize, blockSize), const Radius.circular(2)),
              paint,
            );
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
