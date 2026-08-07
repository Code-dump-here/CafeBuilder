import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  static const _faqs = [
    (
      'How do I start a new project?',
      'From the Home tab, tap "Start New Project" and follow the onboarding steps to describe your space, budget, and style.',
    ),
    (
      'How do I hire a designer or contractor?',
      'Open a project from Project Management, review proposals under the project\'s open posts, and accept the one you want to work with.',
    ),
    (
      'How do I track progress on my project?',
      'Open the project and go to its Collaboration Workspace to see contract status, design deliverables, and construction progress in one place.',
    ),
    (
      'How do I message a provider?',
      'From the project detail page, use the Collab quick action to open a chat thread with the provider working on that engagement.',
    ),
    (
      'I found a bug or something isn\'t working. What do I do?',
      'Reach out using the contact details below — include what you were doing and, if possible, a screenshot.',
    ),
  ];

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
        title: Text(
          'Help',
          style: GoogleFonts.playfairDisplay(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.espresso,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'FREQUENTLY ASKED QUESTIONS',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: AppColors.outline,
            ),
          ),
          const SizedBox(height: 12),
          ..._faqs.map((faq) => _buildFaqTile(faq.$1, faq.$2)),
          const SizedBox(height: 24),
          Text(
            'CONTACT SUPPORT',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: AppColors.outline,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildContactRow(Icons.email_outlined, 'support@smartcoffeebuilder.com'),
                const SizedBox(height: 12),
                _buildContactRow(Icons.access_time_rounded, 'Mon–Fri, 9:00–18:00'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 12),
        Text(text, style: GoogleFonts.inter(fontSize: 14, color: AppColors.espresso)),
      ],
    );
  }

  Widget _buildFaqTile(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        title: Text(
          question,
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.espresso),
        ),
        iconColor: AppColors.primary,
        collapsedIconColor: AppColors.outline,
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            answer,
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
          ),
        ],
      ),
    );
  }
}
