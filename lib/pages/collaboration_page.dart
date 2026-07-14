import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import 'thread_detail_page.dart';
import 'meeting_notes_page.dart';
import 'file_review_detail_page.dart';

class CollaborationPage extends StatelessWidget {
  const CollaborationPage({super.key});

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
            icon: const Icon(Icons.settings_outlined, color: AppColors.espresso),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _buildHeader(),
            const SizedBox(height: 32),
            _buildDiscussionThreads(context),
            const SizedBox(height: 32),
            _buildPendingApprovals(context),
            const SizedBox(height: 32),
            _buildDecisionLog(),
            const SizedBox(height: 32),
            _buildMeetingNotes(context),
            const SizedBox(height: 32),
            _buildSharedAssets(context),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Collaboration\nWorkspace',
          style: GoogleFonts.playfairDisplay(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.espresso,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Project: Urban Roast Flagship Store • 12 Active Contributors',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildDiscussionThreads(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Discussion\nThreads',
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.espresso,
                height: 1.2,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add, size: 16),
              label: Text('New\nThread', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.espresso,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                elevation: 0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildThreadCard(
          tag: 'DESIGN',
          tagColor: const Color(0xFFD6F0D0),
          tagTextColor: const Color(0xFF4A7D43),
          timeAgo: '2h ago',
          title: 'Bar Counter Discussion',
          subtitle: 'Exploring the integration of seamless brass inlays within the main mahogany...',
          commentsCount: '14 comments',
          hasAvatars: true,
          onTap: () {
            Navigator.push(context, MaterialPageRoute(
              builder: (context) => const ThreadDetailPage(
                title: 'Bar Counter Discussion',
                tag: 'DESIGN',
                tagColor: Color(0xFFD6F0D0),
                tagTextColor: Color(0xFF4A7D43),
              ),
            ));
          }
        ),
        const SizedBox(height: 12),
        _buildThreadCard(
          tag: 'MATERIALS',
          tagColor: const Color(0xFFFFE4CC),
          tagTextColor: const Color(0xFFC46A25),
          timeAgo: '5h ago',
          title: 'Material Selection',
          subtitle: 'Reviewing the sustainable acoustic panel options for the mezzanine ceiling. Needs...',
          commentsCount: '8 comments',
          onTap: () {
            Navigator.push(context, MaterialPageRoute(
              builder: (context) => const ThreadDetailPage(
                title: 'Material Selection',
                tag: 'MATERIALS',
                tagColor: Color(0xFFFFE4CC),
                tagTextColor: Color(0xFFC46A25),
              ),
            ));
          }
        ),
        const SizedBox(height: 12),
        _buildThreadCard(
          tag: 'TECHNICAL',
          tagColor: const Color(0xFFD9ECF4),
          tagTextColor: const Color(0xFF337996),
          timeAgo: 'Yesterday',
          title: 'Facade Lighting',
          subtitle: 'Placement of recessed warm LEDs along the exterior brickwork. Wiring diagram...',
          commentsCount: '21 comments',
          onTap: () {
            Navigator.push(context, MaterialPageRoute(
              builder: (context) => const ThreadDetailPage(
                title: 'Facade Lighting',
                tag: 'TECHNICAL',
                tagColor: Color(0xFFD9ECF4),
                tagTextColor: Color(0xFF337996),
              ),
            ));
          }
        ),
      ],
    );
  }

  Widget _buildThreadCard({
    required String tag,
    required Color tagColor,
    required Color tagTextColor,
    required String timeAgo,
    required String title,
    required String subtitle,
    required String commentsCount,
    bool hasAvatars = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.outlineVariant.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.01),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: tagColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    tag,
                    style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.bold, color: tagTextColor),
                  ),
                ),
                Text(
                  timeAgo,
                  style: GoogleFonts.inter(fontSize: 10, color: AppColors.placeholder),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.playfairDisplay(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.espresso),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary, height: 1.4),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (hasAvatars) ...[
                  SizedBox(
                    width: 40,
                    height: 20,
                    child: Stack(
                      children: [
                        Positioned(
                          left: 0,
                          child: CircleAvatar(
                            radius: 10,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: const NetworkImage('https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&q=80&w=150'),
                          ),
                        ),
                        Positioned(
                          left: 12,
                          child: CircleAvatar(
                            radius: 10,
                            backgroundColor: Colors.grey[400],
                            backgroundImage: const NetworkImage('https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&q=80&w=150'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  commentsCount,
                  style: GoogleFonts.inter(fontSize: 10, color: AppColors.placeholder),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingApprovals(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pending Approvals',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.espresso,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.outlineVariant.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 180,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                  image: DecorationImage(
                    image: NetworkImage('https://images.unsplash.com/photo-1555529733-0e670560f4e1?auto=format&fit=crop&q=80&w=600'), // Dark wood texture
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            'Walnut Material\nApproval',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.espresso,
                              height: 1.2,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.access_time, size: 12, color: Color(0xFFC6463A)),
                            const SizedBox(width: 4),
                            Text(
                              'High\nPriority',
                              style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFFC6463A), fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Request from Design Team for the bespoke cabinetry in the main brewing area. Sample code: WN-2024-X.',
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary, height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(
                                builder: (context) => const FileReviewDetailPage(
                                  title: 'Walnut Material Approval',
                                  imageUrl: 'https://images.unsplash.com/photo-1555529733-0e670560f4e1?auto=format&fit=crop&q=80&w=600',
                                  status: ReviewItemStatus.needReview,
                                ),
                              ));
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.espresso,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              elevation: 0,
                            ),
                            child: Text('Approve\nSelection', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(
                                builder: (context) => const FileReviewDetailPage(
                                  title: 'Walnut Material Approval',
                                  imageUrl: 'https://images.unsplash.com/photo-1555529733-0e670560f4e1?auto=format&fit=crop&q=80&w=600',
                                  status: ReviewItemStatus.revision,
                                ),
                              ));
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.espresso,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: const BorderSide(color: AppColors.outlineVariant),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            ),
                            child: Text('Request\nChanges', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDecisionLog() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Decision Log',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.espresso,
          ),
        ),
        const SizedBox(height: 24),
        _buildLogItem(
          color: const Color(0xFF56642B),
          title: 'Confirmed Industrial Lighting',
          subtitle: 'Oct 24 • Approved by M. Roberts',
        ),
        _buildLogItem(
          color: const Color(0xFF56642B),
          title: 'Approved Layout v4.2',
          subtitle: 'Oct 23 • Final Client Sign-off',
        ),
        _buildLogItem(
          color: const Color(0xFFD2C4BA),
          title: 'Base Plumbing Sign-off',
          subtitle: 'Oct 20 • Contractor Team',
          isLast: true,
        ),
      ],
    );
  }

  Widget _buildLogItem({
    required Color color,
    required String title,
    required String subtitle,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            if (!isLast)
              Container(
                width: 1,
                height: 40,
                color: AppColors.outlineVariant.withOpacity(0.5),
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.espresso)),
              const SizedBox(height: 2),
              Text(subtitle, style: GoogleFonts.inter(fontSize: 10, color: AppColors.placeholder)),
              if (!isLast) const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMeetingNotes(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF3EFE9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Meeting Notes',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.espresso,
                ),
              ),
              const Icon(Icons.edit_note, color: AppColors.placeholder, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Site Visit Oct 22',
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.espresso),
          ),
          Text(
            'Key Summary:',
            style: GoogleFonts.inter(fontSize: 10, color: AppColors.placeholder),
          ),
          const SizedBox(height: 12),
          _buildCheckItem('Wall demolition completed.', isChecked: true),
          const SizedBox(height: 8),
          _buildCheckItem('Confirm sink placement with MEP.', isChecked: false),
          const SizedBox(height: 8),
          _buildCheckItem('Source local brick alternative.', isChecked: false),
          const SizedBox(height: 20),
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) => const MeetingNotesPage(),
                ));
              },
              child: Text(
                'View All Notes',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.espresso,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckItem(String text, {bool isChecked = false}) {
    return Row(
      children: [
        Icon(
          isChecked ? Icons.check_circle_outline : Icons.circle_outlined,
          size: 14,
          color: isChecked ? const Color(0xFF56642B) : AppColors.placeholder,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(fontSize: 11, color: AppColors.espresso),
          ),
        ),
      ],
    );
  }

  Widget _buildSharedAssets(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Shared Assets',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.espresso,
          ),
        ),
        const SizedBox(height: 16),
        _buildAssetCard(
          context,
          bgColor: const Color(0xFFFFF2F2),
          iconColor: const Color(0xFFC6463A),
          icon: Icons.picture_as_pdf_outlined,
          title: 'Schematic_v2.pdf',
          subtitle: '12.4 MB • 2H AGO',
        ),
        const SizedBox(height: 8),
        _buildAssetCard(
          context,
          bgColor: const Color(0xFFF2F9F2),
          iconColor: const Color(0xFF56642B),
          icon: Icons.image_outlined,
          title: 'Facade_Render_4K.jpg',
          subtitle: '45.0 MB • 5H AGO',
        ),
        const SizedBox(height: 8),
        _buildAssetCard(
          context,
          bgColor: const Color(0xFFF5F5F5),
          iconColor: const Color(0xFF888888),
          icon: Icons.draw_outlined,
          title: 'Electrical_Draft.dwg',
          subtitle: '8.2 MB • YESTERDAY',
        ),
      ],
    );
  }

  Widget _buildAssetCard(
    BuildContext context, {
    required Color bgColor,
    required Color iconColor,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Downloading $title...'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.espresso,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFBFAF8),
          border: Border.all(color: AppColors.outlineVariant.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(icon, size: 16, color: iconColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.espresso)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.placeholder, letterSpacing: 0.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
