import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../models/responses/api_responses.dart';
import '../services/api_client.dart';
import '../services/project_service.dart';
import '../services/review_service.dart';
import '../services/service_provider_service.dart';
import 'select_project_page.dart';

class DesignerDetailPage extends StatefulWidget {
  final int serviceProviderProfileId;

  const DesignerDetailPage({
    super.key,
    required this.serviceProviderProfileId,
  });

  @override
  State<DesignerDetailPage> createState() => _DesignerDetailPageState();
}

class _DesignerDetailPageState extends State<DesignerDetailPage> {
  ServiceProviderResponse? _provider;
  ProviderReviewSummary? _summary;
  List<ReviewResponse> _reviews = [];
  final Map<int, ProjectOwnerResponse> _reviewOwners = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        ServiceProviderService.getProvider(widget.serviceProviderProfileId),
        ReviewService.getProviderReviewSummary(widget.serviceProviderProfileId),
        ReviewService.getReviewsForProvider(widget.serviceProviderProfileId),
      ]);
      final provider = results[0] as ServiceProviderResponse;
      final summary = results[1] as ProviderReviewSummary;
      final reviews = results[2] as List<ReviewResponse>;

      final owners = <int, ProjectOwnerResponse>{};
      for (final review in reviews) {
        if (owners.containsKey(review.projectShopOwnerId)) continue;
        try {
          final project = await ProjectService.getProject(review.projectShopOwnerId);
          if (project.owner != null) {
            owners[review.projectShopOwnerId] = project.owner!;
          }
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _provider = provider;
          _summary = summary;
          _reviews = reviews;
          _reviewOwners
            ..clear()
            ..addAll(owners);
          _loading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Failed to load designer profile';
        });
      }
    }
  }

  String get _displayName => _provider?.displayName ?? 'Designer';
  String get _initial => _displayName.isNotEmpty ? _displayName[0].toUpperCase() : 'D';
  double get _avgRating => _summary?.averageRating ?? _provider?.avgRating ?? 0;
  int get _reviewCount => _summary?.reviewCount ?? _reviews.length;

  static String _initialsFrom(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return parts.first.isNotEmpty ? parts.first[0].toUpperCase() : '?';
  }

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
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
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
                      _initial,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _displayName,
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
                        _loading ? '...' : _avgRating.toStringAsFixed(1),
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.espresso),
                      ),
                      Text(
                        _loading ? '' : ' ($_reviewCount reviews)',
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.placeholder),
                      ),
                    ],
                  ),
                  if (_provider?.portfolioHeadline != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _provider!.portfolioHeadline!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (_provider != null) ...[
                        _buildTag(_provider!.providerType.toUpperCase()),
                        _buildTag(_provider!.capability.toUpperCase()),
                      ] else
                        for (final t in ['TROPICAL', 'MODERN', 'INDUSTRIAL', 'JAPANDI', 'MINIMALIST'])
                          _buildTag(t),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _loading
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SelectProjectPage(designerName: _displayName),
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
                      'Book Designer',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildLeftAlignedTitle('Specialized Excellence'),
                  const SizedBox(height: 12),
                  Text(
                    _provider?.bio ??
                        'With a legacy of successful cafe projects, this designer transforms spaces into immersive brand experiences.',
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
                      Expanded(child: _buildStatCard('${_reviewCount}', 'REVIEWS')),
                      const SizedBox(width: 8),
                      Expanded(child: _buildStatCard(_avgRating.toStringAsFixed(1), 'AVG\nRATING')),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatCard(
                          _provider?.yearsExperience != null ? '${_provider!.yearsExperience}Y+' : '—',
                          'EXPERIENCE',
                        ),
                      ),
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
                    Icons.trending_up,
                    'Suitable for: Mid-range to Premium café projects',
                    'This designer is suitable for café owners who want a balanced investment between visual quality, practical construction, and brand experience.',
                  ),
                  const SizedBox(height: 16),
                  _buildDetailCard(
                    Icons.engineering_outlined,
                    _provider?.capability ?? 'Design + Supervision',
                    'Provides comprehensive design documents and supports checking whether construction follows the approved design.',
                  ),
                  const SizedBox(height: 32),
                  _buildLeftAlignedTitle('Client Feedback'),
                  const SizedBox(height: 16),
                  _buildFeedbackSection(),
                  const SizedBox(height: 48),
                ],
              ),
            ),
    );
  }

  Widget _buildFeedbackSection() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator(color: AppColors.espresso)),
      );
    }

    final dimensions = _summary?.dimensionAverages ?? {};
    if (dimensions.isEmpty && _reviews.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F3F1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          'No reviews yet.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
        ),
      );
    }

    return Column(
      children: [
        if (dimensions.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F3F1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: dimensions.entries.map((entry) {
                final score = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildRatingBar(entry.key, score.toStringAsFixed(1), score / 5),
                );
              }).toList(),
            ),
          ),
        if (dimensions.isNotEmpty && _reviews.isNotEmpty) const SizedBox(height: 20),
        ..._reviews.asMap().entries.map((entry) {
          final review = entry.value;
          final owner = _reviewOwners[review.projectShopOwnerId];
          final name = owner?.fullName ?? 'Cafe Owner';
          final role = owner?.shopName.isNotEmpty == true
              ? 'Owner of ${owner!.shopName}'
              : 'Project Owner';
          final tags = review.scores
              .where((s) => s.score >= 4)
              .map((s) => s.dimension)
              .toList();
          return Padding(
            padding: EdgeInsets.only(bottom: entry.key < _reviews.length - 1 ? 16 : 0),
            child: _buildReviewCard(
              _initialsFrom(name),
              name,
              role,
              review.overallRating.round().clamp(1, 5),
              review.comment != null ? '"${review.comment}"' : 'No comment provided.',
              tags,
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEBEBEB),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
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
            value: progress.clamp(0.0, 1.0),
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
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < rating ? Icons.star : Icons.star_border,
                    size: 12,
                    color: const Color(0xFF56642B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            text,
            style: GoogleFonts.inter(fontSize: 13, fontStyle: FontStyle.italic, color: AppColors.textSecondary, height: 1.5),
          ),
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tags
                  .map(
                    (t) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9F9F9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        t,
                        style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w600, color: const Color(0xFF56642B)),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}
