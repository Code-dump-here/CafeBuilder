import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../models/responses/api_responses.dart';
import '../services/api_client.dart';
import '../services/project_service.dart';
import '../services/review_service.dart';
import '../services/service_provider_service.dart';
import 'select_project_page.dart';

class ConstructorDetailPage extends StatefulWidget {
  final int serviceProviderProfileId;

  const ConstructorDetailPage({
    super.key,
    required this.serviceProviderProfileId,
  });

  @override
  State<ConstructorDetailPage> createState() => _ConstructorDetailPageState();
}

class _ConstructorDetailPageState extends State<ConstructorDetailPage> {
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
          _error = 'Failed to load contractor profile';
        });
      }
    }
  }

  String get _displayName => _provider?.displayName ?? 'Contractor';
  String get _initial => _displayName.isNotEmpty ? _displayName[0].toUpperCase() : 'C';

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.espresso),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
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
        ),
      );
    }

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
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.espresso))
          : SingleChildScrollView(
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
                          _initial,
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
                              _displayName,
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.espresso,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                if (_provider?.isVerified == true) ...[
                                  const Icon(Icons.verified, size: 14, color: Color(0xFF56642B)),
                                  const SizedBox(width: 4),
                                ],
                                Expanded(
                                  child: Text(
                                    _provider?.portfolioHeadline ??
                                        ServiceProviderService.typeLabel(_provider!),
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
                      Expanded(
                        child: _buildStatCard(
                          'REVIEWS',
                          '${_summary?.reviewCount ?? _reviews.length}',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatCard(
                          'AVG. RATING',
                          (_summary?.averageRating ?? _provider?.avgRating ?? 0).toStringAsFixed(1),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'EXPERIENCE',
                          _provider?.yearsExperience != null ? '${_provider!.yearsExperience} Years' : '—',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatCard(
                          'CAPABILITY',
                          _provider?.capability.toUpperCase() ?? '—',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SelectProjectPage(
                            designerName: _displayName,
                            isConstructor: true,
                            serviceProviderProfileId: _provider!.id,
                            contractType: _provider!.capability,
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
                  _buildServiceItem(Icons.construction_outlined, _provider!.capability, _provider!.providerType),
                  if (_provider!.bio != null && _provider!.bio!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildServiceItem(Icons.info_outline, 'About', _provider!.bio!),
                  ],
                  const SizedBox(height: 32),
                  _buildLeftAlignedTitle('Technical Ratings'),
                  const SizedBox(height: 16),
                  _buildRatingsSection(),
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
                    ServiceProviderService.imageFor(_provider!.id, 0),
                    _provider!.displayName,
                    '${_provider!.providerType.toUpperCase()} • ${_provider!.capability.toUpperCase()}',
                  ),
                  const SizedBox(height: 32),
                  _buildLeftAlignedTitle('Client Testimonials'),
                  const SizedBox(height: 16),
                  _buildTestimonialsSection(),
                  const SizedBox(height: 48),
                ],
              ),
            ),
    );
  }

  Widget _buildRatingsSection() {
    final dimensions = _summary?.dimensionAverages ?? {};
    if (dimensions.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.outlineVariant.withOpacity(0.5)),
        ),
        child: Text(
          'No ratings yet.',
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(
        children: dimensions.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: _buildRatingBar(entry.key, entry.value),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTestimonialsSection() {
    if (_reviews.isEmpty) {
      return Text(
        'No reviews yet.',
        style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
      );
    }

    return Column(
      children: _reviews.map((review) {
        final owner = _reviewOwners[review.projectShopOwnerId];
        final name = owner?.fullName ?? 'Cafe Owner';
        final role = owner?.shopName.isNotEmpty == true ? 'Owner of ${owner!.shopName}' : 'Project Owner';
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildReviewCard(
            name,
            role,
            review.comment != null ? '"${review.comment}"' : 'No comment provided.',
          ),
        );
      }).toList(),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF56642B), size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
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
              '${rating.toStringAsFixed(1)}/5',
              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF56642B)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: (rating / 5.0).clamp(0.0, 1.0),
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

  Widget _buildReviewCard(String name, String role, String text) {
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
                backgroundColor: const Color(0xFFF0E5D8),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.espresso),
                ),
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
