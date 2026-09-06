import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class SubscriptionReturnPage extends StatelessWidget {
  const SubscriptionReturnPage({super.key});

  @override
  Widget build(BuildContext context) {
    final nowStr = DateTime.now().toString().substring(0, 16);

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Celebratory Banner & Icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: const BoxDecoration(
                    color: Color(0xFF4CAF50),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 48),
                ),
              ),
            ),

            const SizedBox(height: 20),

            Text(
              'Thanh Toán Thành Công!',
              style: GoogleFonts.playfairDisplay(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.espresso,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Cảm ơn bạn đã đăng ký gói Subscription Pro! Quyền lợi mở khóa 3D Layout Visual đã được kích hoạt trên tài khoản của bạn.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: 30),

            // Receipt Summary Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
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
                      const Icon(Icons.receipt_long_outlined, color: AppColors.espresso, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Thông Tin Giao Dịch',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.espresso,
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1),
                  ),
                  _buildSummaryItem('Gói dịch vụ', 'Gói Pro VIP 3D Layout'),
                  _buildSummaryItem('Mã giao dịch', 'SUB3D99824'),
                  _buildSummaryItem('Số tiền thanh toán', '199.000 VNĐ'),
                  _buildSummaryItem('Thời gian kích hoạt', nowStr),
                  _buildSummaryItem('Trạng thái', 'Thành công (Đã kích hoạt)', isSuccessStatus: true),
                  _buildSummaryItem('Quyền lợi mở khóa', 'Visual 3D sắc nét & Báo cáo AI'),
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
                  // Pop back or navigate home/report
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    Navigator.pushReplacementNamed(context, '/home');
                  }
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
                    const Icon(Icons.visibility_rounded, size: 20),
                    const SizedBox(width: 8),
                    // Nhãn dài gần bằng bề ngang nút trên máy nhỏ; Flexible cho
                    // nó xuống dòng thay vì tràn ra khỏi nút.
                    Flexible(
                      child: Text(
                        'Trải Nghiệm Ngay 3D Layout Visual',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold),
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
                  Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
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
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, {bool isSuccessStatus = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.placeholder),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSuccessStatus ? const Color(0xFF2E7D32) : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
