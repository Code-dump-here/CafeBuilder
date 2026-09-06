import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class SubscriptionCancelPage extends StatelessWidget {
  const SubscriptionCancelPage({super.key});

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
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
                  child: const Icon(Icons.cancel_outlined, color: Colors.white, size: 48),
                ),
              ),
            ),

            const SizedBox(height: 24),

            Text(
              'Giao Dịch Đã Bị Hủy',
              style: GoogleFonts.playfairDisplay(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.espresso,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              'Bạn vừa dừng quá trình thanh toán nâng cấp Subscription. Tài khoản của bạn hiện ở trạng thái Miễn phí (ảnh 3D Layout Visualization sẽ tiếp tục được làm mờ).',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                height: 1.6,
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: 32),

            // Benefits reminder box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.stars_rounded, color: AppColors.espresso, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Quyền lợi khi đăng ký Subscription:',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.espresso,
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
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/subscription-checkout');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.espresso,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.refresh_rounded, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Thử Thanh Toán Lại',
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
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    Navigator.pushReplacementNamed(context, '/home');
                  }
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.espresso,
                  side: BorderSide(color: AppColors.outlineVariant),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  'Quay Về Trang Báo Cáo',
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
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
          const Icon(Icons.check_circle_outline, color: Color(0xFF4CAF50), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
