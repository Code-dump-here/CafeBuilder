import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_colors.dart';
import '../models/responses/api_responses.dart';
import '../widgets/confirm_dialog.dart';

/// Site surveys filed against this project's engagements.
///
/// A survey is the provider's record of the site's existing condition before
/// work starts: a free-text condition note and optionally an uploaded report.
/// The owner reads them here; they're authored on the web app.
///
/// Most recently filed first, since that's the one that describes the site now
/// and older rows are history rather than a checklist. Ordered by date rather
/// than by the version number, which is being retired backend-side.
class SurveyDetailPage extends StatelessWidget {
  final List<SurveyResponse> surveys;

  const SurveyDetailPage({super.key, required this.surveys});

  List<SurveyResponse> get _ordered {
    final sorted = [...surveys];
    sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }

  Future<void> _openReport(BuildContext context, String url) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Open survey report',
      message: 'This will open the report in another app. Continue?',
      confirmLabel: 'Open',
    );
    if (!confirmed || !context.mounted) return;

    final uri = Uri.tryParse(url);
    if (uri == null || !await canLaunchUrl(uri)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the report.')),
        );
      }
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final ordered = _ordered;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.espresso),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Site Surveys',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.espresso,
          ),
        ),
        centerTitle: true,
      ),
      body: ordered.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: ordered.length,
              itemBuilder: (context, index) =>
                  _buildSurveyCard(context, ordered[index], index == 0),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.map_outlined, size: 48, color: AppColors.placeholder),
            const SizedBox(height: 12),
            Text(
              'No site survey yet.',
              style: GoogleFonts.playfairDisplay(
                fontSize: 18,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Your provider files a survey after visiting the site. It will '
              'appear here once they do.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12,
                height: 1.5,
                color: AppColors.placeholder,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSurveyCard(
      BuildContext context, SurveyResponse survey, bool isLatest) {
    // Prefer the resolved public URL — the raw `reportUrl` is a bucket object
    // name and 404s if opened directly.
    final reportUrl = survey.openableReportUrl;
    final note = survey.conditionNote?.trim() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLatest
              ? AppColors.espresso.withValues(alpha: 0.3)
              : AppColors.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isLatest) ...[
                Text(
                  'Latest',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.espresso,
                  ),
                ),
              ],
              const Spacer(),
              Text(
                _formatDate(survey.createdAt),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.placeholder,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Site condition',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: AppColors.outline,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            note.isNotEmpty ? note : 'No condition note recorded.',
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 1.55,
              color: note.isNotEmpty
                  ? AppColors.textPrimary
                  : AppColors.placeholder,
            ),
          ),
          const SizedBox(height: 16),
          if (reportUrl != null && reportUrl.isNotEmpty)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _openReport(context, reportUrl),
                icon: const Icon(Icons.description_outlined, size: 16),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.outlineVariant),
                  foregroundColor: AppColors.espresso,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                label: Text(
                  'View report',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            )
          else
            Text(
              'No report file attached.',
              style: GoogleFonts.inter(
                  fontSize: 12, color: AppColors.placeholder),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
