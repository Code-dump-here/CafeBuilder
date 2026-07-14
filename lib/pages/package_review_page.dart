import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import 'file_review_detail_page.dart';

class PackageReviewPage extends StatelessWidget {
  const PackageReviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF8F6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Center(
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: NetworkImage(
                      'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?auto=format&fit=crop&q=80&w=150'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
        title: Text(
          'Design Cafe',
          style: GoogleFonts.playfairDisplay(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.espresso,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined,
                color: AppColors.espresso),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildStatsRow(),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.espresso,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        elevation: 0,
                      ),
                      child: Text(
                        'Approve',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Item 1
                    _buildFileCard(
                      imageUrl:
                          'https://images.unsplash.com/photo-1554118811-1e0d58224f24?auto=format&fit=crop&q=80&w=600',
                      version: 'v2.0',
                      tagLabel: 'NEED REVIEW',
                      title: '3D Interior Perspective',
                      subtitle:
                          'Comprehensive visual of the main service area and lounge.',
                      buttonText: 'View',
                      onView: () {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (context) => const FileReviewDetailPage(
                            title: '3D Interior Perspective',
                            imageUrl: 'https://images.unsplash.com/photo-1554118811-1e0d58224f24?auto=format&fit=crop&q=80&w=600',
                            status: ReviewItemStatus.needReview,
                          ),
                        ));
                      },
                    ),
                    const SizedBox(height: 24),
                    // Item 2
                    _buildFileCard(
                      imageUrl:
                          'https://images.unsplash.com/photo-1503387762-592deb58ef4e?auto=format&fit=crop&q=80&w=600',
                      version: 'v1.1',
                      title: 'Lighting Layout',
                      buttonText: 'View Details',
                      onView: () {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (context) => const FileReviewDetailPage(
                            title: 'Lighting Layout',
                            imageUrl: 'https://images.unsplash.com/photo-1503387762-592deb58ef4e?auto=format&fit=crop&q=80&w=600',
                            status: ReviewItemStatus.needReview,
                          ),
                        ));
                      },
                    ),
                    const SizedBox(height: 24),
                    // Item 3
                    _buildFileCard(
                      imageUrl:
                          'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&q=80&w=600',
                      version: 'v3.0',
                      statusText: 'REVISION REQUESTED',
                      statusColor: const Color(0xFFC6463A),
                      title: 'Furniture Layout',
                      subtitle: 'Clarify clearance around the barista station.',
                      buttonText: 'Revise',
                      onView: () {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (context) => const FileReviewDetailPage(
                            title: 'Furniture Layout',
                            imageUrl: 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&q=80&w=600',
                            status: ReviewItemStatus.revision,
                          ),
                        ));
                      },
                    ),
                    const SizedBox(height: 24),
                    // Item 4
                    _buildFileCard(
                      imageUrl: 'https://images.unsplash.com/photo-1618221195710-dd6b41faaea6?auto=format&fit=crop&q=80&w=600',
                      version: 'v1.2',
                      statusText: 'APPROVED',
                      statusColor: const Color(0xFF56642B),
                      title: 'Material Board',
                      subtitle:
                          'Finalized selection of wood, paper, and metal finishes.',
                      buttonText: 'View',
                      onView: () {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (context) => const FileReviewDetailPage(
                            title: 'Material Board',
                            imageUrl: 'https://images.unsplash.com/photo-1618221195710-dd6b41faaea6?auto=format&fit=crop&q=80&w=600',
                            status: ReviewItemStatus.approved,
                          ),
                        ));
                      },
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: GoogleFonts.inter(
              fontSize: 10,
              color: AppColors.placeholder,
            ),
            children: const [
              TextSpan(text: 'Projects > '),
              TextSpan(
                text: 'Japanese Coffee Shop Design',
                style: TextStyle(
                  color: AppColors.espresso,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Japanese Coffee Shop\nDesign',
          style: GoogleFonts.playfairDisplay(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AppColors.espresso,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Text(
              'by TROP Studio',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.espresso,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Container(width: 1, height: 12, color: AppColors.outlineVariant),
            const SizedBox(width: 8),
            Text(
              '6 total files',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _buildStatBadge(
          label: '3 Approved',
          bgColor: const Color(0xFFE5EFBD),
          dotColor: const Color(0xFF56642B),
          textColor: AppColors.espresso,
        ),
        const SizedBox(width: 8),
        _buildStatBadge(
          label: '2 Need Review',
          bgColor: const Color(0xFFEFECE9),
          dotColor: AppColors.placeholder,
          textColor: AppColors.espresso,
        ),
        const SizedBox(width: 8),
        _buildStatBadge(
          label: '1 Revision',
          bgColor: const Color(0xFFFFE5E3),
          dotColor: const Color(0xFFC6463A),
          textColor: AppColors.espresso,
        ),
      ],
    );
  }

  Widget _buildStatBadge({
    required String label,
    required Color bgColor,
    required Color dotColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileCard({
    String? imageUrl,
    required String version,
    String? tagLabel,
    String? statusText,
    Color? statusColor,
    required String title,
    String? subtitle,
    required String buttonText,
    VoidCallback? onView,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image / Top Area
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: const Color(0xFFF9F6F4),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              image: imageUrl != null
                  ? DecorationImage(
                      image: NetworkImage(imageUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      version,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.espresso,
                      ),
                    ),
                  ),
                ),
                if (tagLabel != null)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        tagLabel,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.placeholder,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Content Area
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (statusText != null && statusColor != null) ...[
                  Text(
                    statusText,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  title,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.espresso,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: onView ?? () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.espresso,
                      side: const BorderSide(color: AppColors.outlineVariant),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: Text(
                      buttonText,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.outlineVariant.withOpacity(0.3)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: null, // Disabled state
            icon: const Icon(Icons.check_circle_outline, size: 18),
            label: Text(
              'Approve Package',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              disabledBackgroundColor: const Color(0xFFB1A9A2), // Greyed out brown
              disabledForegroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
