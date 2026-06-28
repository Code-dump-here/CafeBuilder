import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import 'select_project_page.dart';

class ConstructorDetailPage extends StatelessWidget {
  const ConstructorDetailPage({super.key});

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
              'Constructor Detail',
              style: GoogleFonts.playfairDisplay(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.espresso,
              ),
            ),
            Text(
              'Marketplace Feed',
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.espresso,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'A',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Atelier Build Co.',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.espresso,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.verified, size: 14, color: Color(0xFF56642B)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Premium Architectural Construction & Fit-out',
                              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                              maxLines: 2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _buildStatCard('COMPLETED\nPROJECTS', '142')),
                const SizedBox(width: 8),
                Expanded(child: _buildStatCard('AVG. TIMELINE', '12-16\nWeeks')),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildStatCard('EXPERIENCE', '15 Years')),
                const SizedBox(width: 8),
                Expanded(child: _buildStatCard('RETENTION RATE', '94%')),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SelectProjectPage(
                      designerName: 'Atelier Build Co.',
                      isConstructor: true,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.espresso,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: Text(
                'Hire Contractor',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
            ),
            const SizedBox(height: 32),
            _buildLeftAlignedTitle('Services'),
            const SizedBox(height: 16),
            _buildServiceItem(Icons.electrical_services_outlined, 'MEP', 'Mechanical, Electrical, Plumbing systems'),
            const SizedBox(height: 8),
            _buildServiceItem(Icons.foundation_outlined, 'Civil Work', 'Structural integrity and foundation'),
            const SizedBox(height: 8),
            _buildServiceItem(Icons.chair_outlined, 'Interior Fit-out', 'Custom joinery and luxury finishes'),
            const SizedBox(height: 32),
            _buildLeftAlignedTitle('Technical Ratings'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.outlineVariant.withOpacity(0.5)),
              ),
              child: Column(
                children: [
                  _buildRatingBar('Workmanship', 9.8),
                  const SizedBox(height: 20),
                  _buildRatingBar('Safety Compliance', 10.0),
                  const SizedBox(height: 20),
                  _buildRatingBar('Timeline Management', 9.5),
                  const SizedBox(height: 20),
                  _buildRatingBar('Cost Efficiency', 9.2),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildLeftAlignedTitle('Portfolio'),
                Text(
                  'View All Projects',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF56642B),
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildPortfolioCard(
              'https://images.unsplash.com/photo-1497366216548-37526070297c?auto=format&fit=crop&q=80&w=600',
              'The Oak & Bean Specialty Coffee',
              'COMPLETED 2023 • INTERIOR FIT-OUT',
            ),
            const SizedBox(height: 16),
            _buildPortfolioCard(
              'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&q=80&w=600',
              'Vista Residential Loft',
              'COMPLETED 2023 • CIVIL & FIT-OUT',
            ),
            const SizedBox(height: 32),
            _buildLeftAlignedTitle('Client Testimonials'),
            const SizedBox(height: 16),
            _buildReviewCard(
              'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?auto=format&fit=crop&q=80&w=150',
              'Julian Reed',
              'Founder, The Oak & Bean',
              '"Atelier Build Co. transformed our vision into a tangible reality with surgical precision. Their attention to joinery details and MEP integration is unparalleled in the region. They didn\'t just build a shop; they crafted an experience."',
            ),
            const SizedBox(height: 16),
            _buildReviewCard(
              'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&q=80&w=150',
              'Sarah Chen',
              'Lead Architect, Studio Chen',
              '"Working with the Atelier team was a masterclass in professional construction. They stayed within the tight 12-week schedule without compromising on the safety or finishing quality of the high-rise project."',
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildLeftAlignedTitle(String text) {
    return Text(
      text,
      style: GoogleFonts.playfairDisplay(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: AppColors.espresso,
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: AppColors.placeholder),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.espresso),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceItem(IconData icon, String title, String desc) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF56642B), size: 20),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.espresso),
              ),
              Text(
                desc,
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBar(String label, double rating) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.espresso),
            ),
            Text(
              '${rating.toStringAsFixed(1)}/10',
              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF56642B)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: rating / 10.0,
          backgroundColor: AppColors.outlineVariant,
          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF56642B)),
          minHeight: 4,
          borderRadius: BorderRadius.circular(2),
        ),
      ],
    );
  }

  Widget _buildPortfolioCard(String imageUrl, String name, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            imageUrl,
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          name,
          style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.espresso),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: AppColors.placeholder),
        ),
      ],
    );
  }

  Widget _buildReviewCard(String avatarUrl, String name, String role, String text) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: GoogleFonts.inter(fontSize: 13, fontStyle: FontStyle.italic, color: AppColors.textSecondary, height: 1.6),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage: NetworkImage(avatarUrl),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.espresso),
                  ),
                  Text(
                    role,
                    style: GoogleFonts.inter(fontSize: 10, color: AppColors.placeholder),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
