import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import 'discovery_page.dart';

class StyleDetailPage extends StatelessWidget {
  final InspirationItem item;

  const StyleDetailPage({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCategoryBadge(),
                  const SizedBox(height: 16),
                  _buildTitle(),
                  const SizedBox(height: 24),
                  _buildDescription(),
                  const SizedBox(height: 40),
                  _buildDesignStats(),
                  const SizedBox(height: 40),
                  _buildSectionTitle('Key Materials'),
                  const SizedBox(height: 16),
                  _buildMaterialsList(),
                  const SizedBox(height: 40),
                  _buildSectionTitle('Color Palette'),
                  const SizedBox(height: 16),
                  _buildColorPalette(),
                  const SizedBox(height: 40),
                  _buildApplyButton(context),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 450,
      pinned: true,
      backgroundColor: AppColors.espresso,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CircleAvatar(
          backgroundColor: Colors.white.withOpacity(0.9),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.espresso, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.white.withOpacity(0.9),
            child: IconButton(
              icon: const Icon(Icons.bookmark_border_rounded, color: AppColors.espresso),
              onPressed: () {},
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Hero(
          tag: 'style-${item.imageUrl}',
          child: Image.network(
            item.imageUrl,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryFixed,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        item.category.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
          color: AppColors.espresso,
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      item.title,
      style: GoogleFonts.playfairDisplay(
        fontSize: 36,
        fontWeight: FontWeight.bold,
        color: AppColors.espresso,
        height: 1.2,
      ),
    );
  }

  Widget _buildDescription() {
    return Text(
      'This design philosophy focuses on the harmony between natural elements and modern structural integrity. By emphasizing "Wabi-sabi" principles, it celebrates Imperfection and the passage of time through raw textures like aged oak and cold-rolled steel. The spatial arrangement is carefully curated to maximize light flow while maintaining a sense of intimate enclosure.',
      style: GoogleFonts.inter(
        fontSize: 16,
        color: AppColors.textSecondary,
        height: 1.8,
      ),
    );
  }

  Widget _buildDesignStats() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStatItem('Complexity', 'Medium'),
        _buildStatItem('Cost Ratio', '\$\$\$'),
        _buildStatItem('Timelessness', 'High'),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: AppColors.outline,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.playfairDisplay(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.espresso,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.playfairDisplay(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: AppColors.espresso,
      ),
    );
  }

  Widget _buildMaterialsList() {
    final materials = ['Aged White Oak', 'Raw Concrete', 'Smoked Glass', 'Brushed Brass'];
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: materials.map((m) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.outlineVariant),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          m,
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
        ),
      )).toList(),
    );
  }

  Widget _buildColorPalette() {
    final colors = [
      Color(0xFFFCF9F8),
      Color(0xFFE1C1A4),
      Color(0xFFD2C4BA),
      Color(0xFF4B3621),
    ];
    return Row(
      children: colors.map((c) => Container(
        width: 60,
        height: 60,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: c,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildApplyButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.espresso,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.architecture_rounded),
            const SizedBox(width: 12),
            Text(
              'APPLY STYLE TO PROJECT',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
