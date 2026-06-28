import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class DesignerDetailPage extends StatelessWidget {
  const DesignerDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF8F6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.espresso),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Designer Detail',
              style: GoogleFonts.playfairDisplay(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.espresso,
              ),
            ),
            Text(
              'Marketplace feed',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.placeholder,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.espresso,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'T',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'TROP Studio',
              style: GoogleFonts.playfairDisplay(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.espresso,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star, size: 14, color: Color(0xFF56642B)),
                const SizedBox(width: 4),
                Text(
                  '4.9',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.espresso),
                ),
                Text(
                  ' (86 projects)',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.placeholder),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_on_outlined, size: 14, color: AppColors.placeholder),
                const SizedBox(width: 4),
                Text(
                  'HCMC, Vietnam',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                'TROPICAL', 'MODERN', 'INDUSTRIAL', 'JAPANDI', 'MINIMALIST'
              ].map((t) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEBEBEB),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  t,
                  style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                ),
              )).toList(),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.espresso,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: Text(
                'Book Designer',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
            ),
            const SizedBox(height: 32),
            _buildLeftAlignedTitle('Specialized Excellence'),
            const SizedBox(height: 12),
            Text(
              'With a legacy of 86 successful cafe projects, TROP Studio transforms spaces into immersive brand experiences. Our expertise spans diverse topological challenges:',
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 16),
            _buildBulletPoint(Icons.park_outlined, 'Garden café integration'),
            const SizedBox(height: 8),
            _buildBulletPoint(Icons.coffee_maker_outlined, 'Specialty coffee lab design'),
            const SizedBox(height: 8),
            _buildBulletPoint(Icons.architecture_outlined, 'Rooftop café structural aesthetics'),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _buildStatCard('86', 'PROJECTS')),
                const SizedBox(width: 8),
                Expanded(child: _buildStatCard('100%', 'SUCCESS\nRATE')),
                const SizedBox(width: 8),
                Expanded(child: _buildStatCard('5Y+', 'EXPERIENCE')),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildLeftAlignedTitle('Selected Works'),
                Text(
                  'View All Portfolio',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.placeholder,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildPortfolioCard(
              'https://images.unsplash.com/photo-1540200049848-d9813ea0e120?auto=format&fit=crop&q=80&w=600',
              'TROPICAL MID-RANGE',
              'Koi Corner Café',
            ),
            const SizedBox(height: 16),
            _buildPortfolioCard(
              'https://images.unsplash.com/photo-1509042239860-f550ce710b93?auto=format&fit=crop&q=80&w=600',
              'PREMIUM ROOFTOP',
              'Aether Lounge',
            ),
            const SizedBox(height: 32),
            _buildDetailCard(
              Icons.trending_up, // Icon placeholder
              'Suitable for: Mid-range to Premium café projects',
              'This designer is suitable for café owners who want a balanced investment between visual quality, practical construction, and brand experience. We focus on ROI-driven design that doesn\'t compromise on artistic integrity.',
            ),
            const SizedBox(height: 16),
            _buildDetailCard(
              Icons.engineering_outlined, // Icon placeholder
              'Design + Supervision',
              'Provides comprehensive design documents and supports checking whether construction follows the approved design. We act as your quality guardians throughout the build process to ensure the vision becomes reality.',
            ),
            const SizedBox(height: 32),
            _buildLeftAlignedTitle('Client Feedback'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F3F1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildRatingBar('Design Quality', '4.9', 0.98),
                  const SizedBox(height: 16),
                  _buildRatingBar('Communication', '4.7', 0.94),
                  const SizedBox(height: 16),
                  _buildRatingBar('On-time Delivery', '4.6', 0.92),
                  const SizedBox(height: 16),
                  _buildRatingBar('Budget Fit', '4.5', 0.90),
                  const SizedBox(height: 16),
                  _buildRatingBar('Construction Feasibility', '4.8', 0.96),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildReviewCard(
              'MK',
              'Minh Khoa',
              'Owner of Koi Corner Cafe',
              5,
              '"TROP Studio truly understood our vision for a tranquil tropical getaway in the city. The technical precision of their garden integration was impressive."',
              ['Beautiful design', 'Matches solid concept'],
            ),
            const SizedBox(height: 16),
            _buildReviewCard(
              'AN',
              'An Nguyen',
              'Specialty Coffee Curator',
              4,
              '"Expertly handled the specialized requirements of our espresso lab. The workflow optimization integrated into the design has made daily operations much smoother."',
              ['Practical workflow', 'Highly technical'],
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildLeftAlignedTitle(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: GoogleFonts.playfairDisplay(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppColors.espresso,
        ),
      ),
    );
  }

  Widget _buildBulletPoint(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF56642B)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.espresso),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F3F1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.espresso),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: AppColors.placeholder),
          ),
        ],
      ),
    );
  }

  Widget _buildPortfolioCard(String imageUrl, String type, String name) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          Image.network(
            imageUrl,
            height: 240,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type,
                    style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: Colors.white70),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    name,
                    style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(IconData icon, String title, String desc) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFD9EAA3).withOpacity(0.4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF56642B), size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.espresso),
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBar(String label, String score, double progress) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.espresso),
          ),
        ),
        Text(
          score,
          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.espresso),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.outlineVariant,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF56642B)),
            minHeight: 4,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewCard(String initials, String name, String role, int rating, String text, List<String> tags) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFFF0E5D8),
                child: Text(
                  initials,
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.espresso),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.espresso),
                    ),
                    Text(
                      role,
                      style: GoogleFonts.inter(fontSize: 9, color: AppColors.placeholder),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(5, (index) => Icon(
                  index < rating ? Icons.star : Icons.star_border,
                  size: 12,
                  color: const Color(0xFF56642B),
                )),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            text,
            style: GoogleFonts.inter(fontSize: 13, fontStyle: FontStyle.italic, color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tags.map((t) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F9F9),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                t,
                style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w600, color: const Color(0xFF56642B)),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
}
