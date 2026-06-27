import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../theme/app_colors.dart';
import 'style_detail_page.dart';

class DiscoveryPage extends StatefulWidget {
  const DiscoveryPage({super.key});

  @override
  State<DiscoveryPage> createState() => _DiscoveryPageState();
}

class _DiscoveryPageState extends State<DiscoveryPage> {
  String _selectedCategory = 'All Styles';
  final List<String> _categories = [
    'All Styles',
    'Japandi',
    'Industrial',
    'Minimalist',
    'Modern Japanese',
    'Vintage'
  ];

  final List<InspirationItem> _items = [
    InspirationItem(
      title: 'The Serene Oak Nook',
      category: 'Japandi',
      imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuA0zfL4zRZixYzd_GZJ-DN7G41T7Fwc1-_up8vdESgUwp5LH15zA76_f2V3drY7ENi0_Gv_a7EUOnphS0EkhFPLiTtTmoRcS0qKzJ8Mkj4XNTpsL10sB0yLJkRvC-jA7kh9-W9vyU2bwTLOEPDuV5bU56WerX2pr6NKQfMZ9u2BNuwYAazaYiw2lCmsE2SGjkm2SMP0rkmOXkO0BgtwsZI8J2Wu6xma4YID2B-_eOBCN5Ct9A1hZZIaq2d96h4P4wSbIXY44HJa5wOh',
      aspectRatio: 0.8,
    ),
    InspirationItem(
      title: 'Foundry & Bean',
      category: 'Industrial',
      imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuB5vD51uWiFE5Q3DMaJIzKTwCA9Gq6e0EkIRNGQ6FFYu7PDpwZKCaV-i1_eFjClJy0sPZ2JFjS1udNliKtgC1Mms-iPF1693XMoTK4d_oUpDOhRrudW8VogA8ZKyH5EMDUjizCvY5wCh8lNy6tLUcVZ9rVt-Yj6GIgYRfGZw-P2Vx-eWjeg1ta2goPDmwfVMhem_GTtXAmAF9NB-ap0I_8ZsbmGAExKXWNAyhcQjUi3Fkcz9_MPt13fj_XIwNo4YYNURHhVubz_-q8w',
      aspectRatio: 1.0,
    ),
    InspirationItem(
      title: 'Kyoto Shadow Studio',
      category: 'Modern Japanese',
      imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuBy6gk5oyc7-nlviqJtvU7HOipIF1msCHVAbLdKy5sYwfitsvD1csZK-MxpJw2u5S_ZvtyU60nu5opd1j8edl5ra8zelid6CGyvw2R9S9437t56wAdO8OI5SJwfYicmBpkJ3x_CT0gK0ZzpTteOgZF9XtSVj26pPchZFSXfuyvsWOzGRDun660AL2E5VxKjJwzJUBmOKzW48yqX6F_VmNbu5XzzbcLc6GdmofJTQdmAdb94nIpjzoAusZwCJqtIyuLZdaBX4uA5QoN6',
      aspectRatio: 0.75,
    ),
    InspirationItem(
      title: 'Heritage Lounge',
      category: 'Vintage',
      imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuBsc5y_BikkuzEIsEksI8mRXQW18RrIf8syqCwHnnIfcMYZU4A58dAGvR0rCzw4_f8PBRJW1kZox1UlU5FglVW5m5tzmlZYjp7wG79qo6Uud4BtxCgu_IGFxIW2vygj5f-osIfjOZLBQO_ffBIF132eL_GwpXnrUTYExMj9iSbCHkRW1LhJ0CmMAwiqNHERBmqgJliqitvus06YfYxgwSPBS0Qs6gMj69AXq4NuF5zLDrUUxPAnb5yyYvcQ5zfIvF_ZxQ9kdtAI5wLt',
      aspectRatio: 1.33,
    ),
    InspirationItem(
      title: 'The Monolith Bar',
      category: 'Minimalist',
      imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuADBueeISuOAXEdbr8HlelllInAf-T7mWcLVyFtJhP7vBKsQnimgp44rHnmItL9825InSvUOkfZegid6WmYMlRYvinZDLjG1VFN46UEDd4IBS9wzuIW4xlnCg2QwCVmASZFkoVMdDGyBT5zY7YdETDjjA4gzlBz3u_dTC2QZQN0OK9pEMhYJiVApbswV62_XKfQnwm_uyAispfePtQj5e4TWmP6iKp6hTe_DcX6oKCAG6VnRXSCJIKPrriUZJQMX5SHoLID0vUpPWBz',
      aspectRatio: 1.0,
    ),
    InspirationItem(
      title: 'Mist & Wood',
      category: 'Japandi',
      imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuBlNH5NWjKZmhYw5yMgMLQEdbu8CGxJNI1GYV1Q_F431PrPYsnIJMKWx5vexV7My8Iv8etJq_t3r8iGTu3TYlYj0mPtB65-GfqbQ-WIHPKXGtYb2lHyBtRh1Emeo-bvlynsJI6Qm938DTZlehF03nRu8y-zKewlrg2uEC_4SJVv3zmjVJK5-t_DtvYoYaSDl_HkkoDchCAhfnJUQOtozlpt7SrZykdcgpJQFw0uoxTyUlKDvgQfaQNZeqy4plUPMlU8yF0xcSUO3igW',
      aspectRatio: 0.8,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopAppBar(),
          _buildHeader(),
          _buildCategoryScroll(),
          _buildMasonryGrid(),
          const SizedBox(height: 100), // Pushing content above bottom nav
        ],
      ),
    );
  }

  Widget _buildTopAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.menu, color: AppColors.primary, size: 28),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 16),
              Text(
                'Atelier Cafe',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primaryFixed, width: 2),
              image: const DecorationImage(
                image: NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuBl6TFsIkZee7xiVk-tTK6DuXY6PJRgAVcQIn7VGlqLQ52OtqPF6321PmUBiK2XtSyHByhwx9AeeQeqLqhxhvqDlsiwdAOrNwW-EihCYgN6W3iXujYvgZbBx-m8KvOfa6oYXUYkiXDQNV7Y1wXsaDk6SVIPmWAzvhafPC6z9HWaz9OstcRvnEMZgz1eoQD2JU17Oei3fHXprQc1dFa8RSTR6Uo3xcv3XaR4cWJCCkfSAsAPv1hAtyevryuyceQnbCdlspXfakQqfvYy'),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Discover Inspiration',
            style: GoogleFonts.playfairDisplay(
              fontSize: 48,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              letterSpacing: -0.02,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Curated architectural visions for the next generation of boutique café experiences.',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 32),
          // Search Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F3F2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.outlineVariant.withOpacity(0.4)),
            ),
            child: TextField(
              decoration: InputDecoration(
                icon: Icon(Icons.search, color: AppColors.outline.withOpacity(0.6)),
                hintText: 'Search styles, materials, or moods...',
                hintStyle: GoogleFonts.inter(
                  color: AppColors.outline.withOpacity(0.6),
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryScroll() {
    return Container(
      height: 44,
      margin: const EdgeInsets.only(bottom: 32),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = category),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(30),
                border: isSelected 
                  ? null 
                  : Border.all(color: AppColors.outlineVariant.withOpacity(0.4)),
              ),
              child: Text(
                category,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMasonryGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: MasonryGridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 24,
        crossAxisSpacing: 24,
        itemCount: _items.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          return _buildInspirationCard(_items[index]);
        },
      ),
    );
  }

  Widget _buildInspirationCard(InspirationItem item) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StyleDetailPage(item: item),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.03),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: item.aspectRatio,
                child: Hero(
                  tag: 'style-${item.imageUrl}',
                  child: Image.network(
                    item.imageUrl,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.category.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2.0,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.title,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Icon(Icons.bookmark_border_rounded, size: 22, color: AppColors.outline),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class InspirationItem {
  final String title;
  final String category;
  final String imageUrl;
  final double aspectRatio;

  InspirationItem({
    required this.title,
    required this.category,
    required this.imageUrl,
    required this.aspectRatio,
  });
}
