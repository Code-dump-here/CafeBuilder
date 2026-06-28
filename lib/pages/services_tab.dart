import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import 'find_designers_page.dart';

class ServicesTab extends StatelessWidget {
  const ServicesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildTopBar(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                Text(
                  'FOR OWNERS & INVESTORS',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Create high-end experience spaces',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'At Atelier Café, we connect you with a network of top architectural and construction experts to turn your dream café into reality.',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 48),
                
                // Card 1: Hire a Designer
                _buildWhiteServiceCard(
                  imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuD2_S_NqV9F9m8m7m6m5m4m3m2m1m0m9m8m7m6m5m4m3m2m1m0m9m8m7m6m5m4m3m2m1m0m9m8m7m6m5m4m3m2m1m0m9m8m7m6m5m4m3m2m1m0m9m8m7m6m5m4m3m2m1m0m9m8m7m6',
                  icon: Icons.architecture_rounded,
                  title: 'Hire a Designer',
                  desc: 'Find interior design studios and leading architects for high-end F&B spaces.',
                  actionText: 'EXPLORE STUDIOS',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const FindDesignersPage()),
                    );
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Card 2: Hire a Contractor
                _buildWhiteServiceCard(
                  imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuD7_N_m8m7m6m5m4m3m2m1m0m9m8m7m6m5m4m3m2m1m0m9m8m7m6m5m4m3m2m1m0m9m8m7m6m5m4m3m2m1m0m9m8m7m6m5m4m3m2m1m0m9m8m7m6m5m4m3m2m1m0m9m8m7m6',
                  icon: Icons.construction_rounded,
                  title: 'Hire a Contractor',
                  desc: 'Professional construction team, ensuring progress and the most sophisticated finishing quality.',
                  actionText: 'VIEW PARTNERS',
                ),
                
                const SizedBox(height: 24),
                
                // Card 3: Start New Project
                _buildDarkProjectCard(),
                
                const SizedBox(height: 100), // Bottom nav space
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuCdRocndzSsN-UYAyAdDehJe5iER8FIYMiE35WxCJBErozOUf2B3yLChgipuBhVB2ygfuMi7dPypKlDSHVvpvWUNEwx8C9H199dSCEp1Tu738oOGnNuAe3tyDtyMBfFBo0DrDvijOS7KW3cFo5vI8z6GhSGAKWUlR0QnpCnGtGNj6-lhHHKxFyfYkRe1xA8mCEpLYpwWtG1LxWP0NA4RwzOLw-qHhhmkGrZtqHn__ZXAvz-Cz47e0qey8ZAZ_4keMq0p93ycyXaXlbg'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Design Cafe',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const Icon(Icons.notifications_none_rounded, color: AppColors.primary),
        ],
      ),
    );
  }

  Widget _buildWhiteServiceCard({
    required String imageUrl,
    required IconData icon,
    required String title,
    required String desc,
    required String actionText,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Image.network(
              imageUrl,
              height: 240,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Container(height: 240, color: Colors.grey[200]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F3F2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 20),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  desc,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Text(
                      actionText,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, size: 14, color: AppColors.primary),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ));
  }

  Widget _buildDarkProjectCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.espresso,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF56642B).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'START NOW!',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryFixed,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Start New Project',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Ready to build? Start your design brief and receive quotes from the most suitable experts in our network.',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: AppColors.primaryFixed.withOpacity(0.8),
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                    child: Text(
                      'START DESIGN PROCESS',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
            child: Image.network(
              'https://lh3.googleusercontent.com/aida-public/AB6AXuCT_N_m8m7m6m5m4m3m2m1m0m9m8m7m6m5m4m3m2m1m0m9m8m7m6m5m4m3m2m1m0m9m8m7m6m5m4m3m2m1m0m9m8m7m6m5m4m3m2m1m0m9m8m7m6m5m4m3m2m1m0',
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Container(height: 200, color: Colors.black12),
            ),
          ),
        ],
      ),
    );
  }
}
