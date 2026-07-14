import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class MeetingNotesPage extends StatelessWidget {
  const MeetingNotesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF8F6),
      appBar: AppBar(
        title: Text(
          'All Meeting Notes',
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildNoteCard(
            title: 'Site Visit Oct 22',
            subtitle: 'On-site sync with MEP contractor',
            date: 'Oct 22, 2023',
            items: [
              _CheckItem('Wall demolition completed.', true),
              _CheckItem('Confirm sink placement with MEP.', false),
              _CheckItem('Source local brick alternative.', false),
              _CheckItem('Validate load bearing capacity.', true),
            ],
          ),
          const SizedBox(height: 16),
          _buildNoteCard(
            title: 'Design Review: Phase 1',
            subtitle: 'Zoom Call with TROP Studio',
            date: 'Oct 15, 2023',
            items: [
              _CheckItem('Client approved 3D perspective v1.', true),
              _CheckItem('Update materials board with walnut.', true),
              _CheckItem('Revise lighting layout (warm up).', true),
            ],
          ),
          const SizedBox(height: 16),
          _buildNoteCard(
            title: 'Kick-off Meeting',
            subtitle: 'Initial requirements and constraints',
            date: 'Oct 01, 2023',
            items: [
              _CheckItem('Budget locked at \$120k.', true),
              _CheckItem('Timeline: 3 months to grand opening.', true),
              _CheckItem('Target audience defined.', true),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppColors.espresso,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildNoteCard({
    required String title,
    required String subtitle,
    required String date,
    required List<_CheckItem> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(date, style: GoogleFonts.inter(fontSize: 10, color: AppColors.placeholder)),
              const Icon(Icons.more_horiz, size: 16, color: AppColors.placeholder),
            ],
          ),
          const SizedBox(height: 12),
          Text(title, style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.espresso)),
          const SizedBox(height: 4),
          Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Icon(
                  item.isChecked ? Icons.check_box : Icons.check_box_outline_blank,
                  size: 16,
                  color: item.isChecked ? const Color(0xFF56642B) : AppColors.placeholder,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.text,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: item.isChecked ? AppColors.textSecondary : AppColors.espresso,
                      decoration: item.isChecked ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

class _CheckItem {
  final String text;
  final bool isChecked;
  _CheckItem(this.text, this.isChecked);
}
