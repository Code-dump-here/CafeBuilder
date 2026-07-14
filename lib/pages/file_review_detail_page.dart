import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

enum ReviewItemStatus { needReview, revision, approved }

class FileReviewDetailPage extends StatelessWidget {
  final String title;
  final String imageUrl;
  final ReviewItemStatus status;

  const FileReviewDetailPage({
    super.key,
    required this.title,
    required this.imageUrl,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    String pageTitle = 'Review File';
    if (status == ReviewItemStatus.needReview) pageTitle = 'Review Revised File';
    if (status == ReviewItemStatus.approved) pageTitle = 'Approved File';
    if (status == ReviewItemStatus.revision) pageTitle = 'Revision Details';

    return Scaffold(
      backgroundColor: const Color(0xFFFBF8F6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          pageTitle,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz, color: AppColors.textPrimary),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            _buildHeaderCard(),
            const SizedBox(height: 24),
            if (status != ReviewItemStatus.approved) ...[
              _buildDesignersNote(),
              const SizedBox(height: 24),
            ],
            if (status == ReviewItemStatus.needReview) ...[
              _buildVersionComparison(),
              const SizedBox(height: 24),
            ],
            _buildTimeline(),
            const SizedBox(height: 24),
            if (status != ReviewItemStatus.approved) ...[
              _buildFeedbackDiscussion(),
              const SizedBox(height: 32),
            ],
          ],
        ),
      ),
      bottomNavigationBar: status == ReviewItemStatus.needReview
          ? _buildNeedReviewActions()
          : status == ReviewItemStatus.revision
              ? _buildRevisionActions()
              : _buildApprovedActions(),
    );
  }

  Widget _buildHeaderCard() {
    String tagText = '';
    Color tagColor = Colors.transparent;

    switch (status) {
      case ReviewItemStatus.needReview:
        tagText = 'REVISED V2';
        tagColor = const Color(0xFF56642B);
        break;
      case ReviewItemStatus.revision:
        tagText = 'V3.0 - REVISION REQUESTED';
        tagColor = const Color(0xFFC6463A);
        break;
      case ReviewItemStatus.approved:
        tagText = 'V1.2 - APPROVED';
        tagColor = const Color(0xFF56642B);
        break;
    }

    return Container(
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: tagColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                tagText,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesignersNote() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.edit_note, color: AppColors.espresso, size: 20),
              const SizedBox(width: 8),
              Text(
                "Designer's Note",
                style: GoogleFonts.playfairDisplay(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.espresso,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          IntrinsicHeight(
            child: Row(
              children: [
                Container(
                  width: 3,
                  color: AppColors.espresso.withOpacity(0.8),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "I adjusted the lighting tone to be slightly warmer to match the morning sun vibe we discussed. I also reduced the counter size by 15% to improve the flow of the customer seating area.",
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      height: 1.5,
                      color: AppColors.textSecondary,
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

  Widget _buildVersionComparison() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Version Comparison',
          style: GoogleFonts.playfairDisplay(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.espresso,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildVersionBox(
                image: 'https://images.unsplash.com/photo-1554118811-1e0d58224f24?auto=format&fit=crop&q=80&w=300',
                tag: 'v1 Original',
                subtitle: 'SUBMITTED JULY 12',
                isLatest: false,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildVersionBox(
                image: imageUrl,
                tag: 'v2 Revised',
                subtitle: 'LATEST REVISION',
                isLatest: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVersionBox({
    required String image,
    required String tag,
    required String subtitle,
    required bool isLatest,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(
              image: NetworkImage(image),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.black.withOpacity(0.2),
            ),
            padding: const EdgeInsets.all(8),
            alignment: Alignment.bottomLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                tag,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: isLatest ? FontWeight.bold : FontWeight.normal,
            color: isLatest ? AppColors.espresso : AppColors.placeholder,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeline() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Revision Timeline',
          style: GoogleFonts.playfairDisplay(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.espresso,
          ),
        ),
        const SizedBox(height: 24),
        _buildTimelineItem(
          color: AppColors.placeholder,
          title: 'v1 Submitted',
          subtitle: 'July 12, 2023 • 09:45 AM',
          isLast: status == ReviewItemStatus.approved,
        ),
        if (status == ReviewItemStatus.approved) ...[
           _buildTimelineItem(
            color: const Color(0xFF56642B),
            title: 'Approved',
            subtitle: 'July 14, 2023 • 10:00 AM',
            isLast: true,
            isFirst: false,
          ),
        ] else ...[
          _buildTimelineItem(
            color: const Color(0xFFC6463A),
            title: 'Revision Requested',
            subtitle: 'July 13, 2023 • 02:15 PM',
            feedback: '"Please warm up the lighting and shrink the main counter area."',
            isLast: status == ReviewItemStatus.revision,
          ),
          if (status == ReviewItemStatus.needReview) ...[
            _buildTimelineItem(
              color: const Color(0xFF56642B),
              title: 'v2 Uploaded',
              subtitle: 'July 14, 2023 • 11:30 AM',
              isLast: true,
            ),
          ]
        ],
      ],
    );
  }

  Widget _buildTimelineItem({
    required Color color,
    required String title,
    required String subtitle,
    String? feedback,
    bool isLast = false,
    bool isFirst = false,
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
                height: feedback != null ? 60 : 40,
                color: AppColors.outlineVariant,
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.placeholder,
                ),
              ),
              if (feedback != null) ...[
                const SizedBox(height: 8),
                Text(
                  feedback,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              if (!isLast) const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeedbackDiscussion() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Feedback\nDiscussion',
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                height: 1.2,
                color: AppColors.espresso,
              ),
            ),
            Row(
              children: [
                Text(
                  'View Full\nChat',
                  textAlign: TextAlign.right,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.espresso,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.open_in_new, size: 14, color: AppColors.espresso),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.outlineVariant.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              _buildChatBubbleLeft(),
              const SizedBox(height: 16),
              _buildChatBubbleRight(),
              const SizedBox(height: 20),
              _buildChatInput(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChatBubbleLeft() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 12,
          backgroundImage: const NetworkImage('https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&q=80&w=150'),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('TROP designer', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.espresso)),
                  const SizedBox(width: 6),
                  Text('2:00 PM', style: GoogleFonts.inter(fontSize: 9, color: AppColors.placeholder)),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F6F4),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(12), 
                    bottomLeft: Radius.circular(12), 
                    bottomRight: Radius.circular(12)
                  ),
                  border: Border.all(color: AppColors.outlineVariant.withOpacity(0.3)),
                ),
                child: Text(
                  'The lighting layout looks great, but could we add more accent lighting near the zen garden viewing area? It seems a bit dark in the 3D perspective.',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textPrimary, height: 1.4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 24), // Margin from right
      ],
    );
  }

  Widget _buildChatBubbleRight() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(width: 24), // Margin from left
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('3:15 PM', style: GoogleFonts.inter(fontSize: 9, color: AppColors.placeholder)),
                  const SizedBox(width: 6),
                  Text('Minh ( shop owner)', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.espresso)),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: AppColors.espresso,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12), 
                    bottomLeft: Radius.circular(12), 
                    bottomRight: Radius.circular(12)
                  ),
                ),
                child: Text(
                  "Absolutely, James. I'll update the lighting plan to include some discreet spotlights focusing on the garden elements. I'll have the updated version ready by tomorrow morning.",
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.white, height: 1.4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        CircleAvatar(
          radius: 12,
          backgroundImage: const NetworkImage('https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?auto=format&fit=crop&q=80&w=150'),
        ),
      ],
    );
  }

  Widget _buildChatInput() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFFFBF8F6),
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Type a quick reply...',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.placeholder),
            ),
          ),
          const Icon(Icons.send_outlined, size: 16, color: AppColors.espresso),
        ],
      ),
    );
  }

  Widget _buildNeedReviewActions() {
    return _buildActionBottomBar(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.check_circle_outline, size: 18),
            label: Text('Approve Version', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.espresso,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.refresh, size: 18),
            label: Text('Request Another Revision', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEBE6E1),
              foregroundColor: AppColors.espresso,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
          ),
        ),
      ]
    );
  }

  Widget _buildRevisionActions() {
    return _buildActionBottomBar(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.edit_note, size: 18, color: AppColors.espresso),
            label: Text('Edit Revision Request', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.espresso)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.outlineVariant),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
          ),
        ),
      ]
    );
  }

  Widget _buildApprovedActions() {
    return const SizedBox.shrink(); // No actions if it's already approved
  }

  Widget _buildActionBottomBar({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.outlineVariant.withOpacity(0.3))),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: children,
        ),
      ),
    );
  }
}
