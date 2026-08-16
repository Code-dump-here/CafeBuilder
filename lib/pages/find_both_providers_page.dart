import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../models/responses/api_responses.dart';
import '../services/api_client.dart';
import '../services/service_provider_service.dart';
import 'designer_detail_page.dart';

/// Browses providers whose capability is exactly 'both' (design AND
/// construction under one roof), as its own category.
///
/// A both-capability studio already shows up mixed into both
/// [FindDesignersPage] and [FindConstructorsPage] — the backend's
/// `capability` filter includes 'both' rows in either of those lists (see
/// `ServiceProviderProfileService.cs`). This page exists so an owner can
/// deliberately browse the "does everything" category on its own,
/// instead of only ever stumbling onto one mixed into a design- or
/// construction-only search.
class FindBothProvidersPage extends StatefulWidget {
  /// When browsing for a specific project, the project is already known —
  /// carried through so the hire request skips project selection.
  final int? contextProjectId;
  final String? contextProjectName;

  const FindBothProvidersPage({
    super.key,
    this.contextProjectId,
    this.contextProjectName,
  });

  @override
  State<FindBothProvidersPage> createState() => _FindBothProvidersPageState();
}

class _FindBothProvidersPageState extends State<FindBothProvidersPage> {
  final TextEditingController _searchController = TextEditingController();
  List<ServiceProviderResponse> _providers = [];
  bool _loading = true;
  String? _error;
  Timer? _debounce;
  // Bumped on every _loadProviders call — a response is only applied if it's
  // still the most recent request, so a slow earlier response can't
  // overwrite a newer search's results.
  int _requestSeq = 0;

  @override
  void initState() {
    super.initState();
    _loadProviders();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _loadProviders);
  }

  Future<void> _loadProviders() async {
    final seq = ++_requestSeq;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await ServiceProviderService.getProviders(
        capability: 'both',
        pageSize: 50,
        search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
      );
      if (mounted && seq == _requestSeq) {
        setState(() {
          _providers = result.items;
          _loading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted && seq == _requestSeq) {
        setState(() {
          _loading = false;
          _error = e.message;
        });
      }
    } catch (_) {
      if (mounted && seq == _requestSeq) {
        setState(() {
          _loading = false;
          _error = 'Failed to load design & build studios';
        });
      }
    }
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
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search studio or concept...',
            hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.placeholder),
            prefixIcon: const Icon(Icons.search, color: AppColors.placeholder, size: 20),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 0),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide(color: AppColors.outlineVariant.withOpacity(0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: const BorderSide(color: AppColors.espresso),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Find Design & Build',
              style: GoogleFonts.playfairDisplay(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.espresso,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.contextProjectName != null
                  ? 'Browsing design & build studios for "${widget.contextProjectName}". A single hire covers both design and construction on this project.'
                  : 'Studios that handle design and construction under one roof — one hire, one point of contact for the whole build.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator(color: AppColors.espresso)),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    ElevatedButton(onPressed: _loadProviders, child: const Text('Retry')),
                  ],
                ),
              )
            else if (_providers.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Text(
                  'No design & build studios found.',
                  style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
                ),
              )
            else
              for (final provider in _providers) _buildProviderCard(provider),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderCard(ServiceProviderResponse provider) {
    final tier = ServiceProviderService.tierLabel(provider);
    final type = ServiceProviderService.typeLabel(provider);
    final image1 = ServiceProviderService.imageFor(provider.id, 0);
    final image2 = ServiceProviderService.imageFor(provider.id, 1);
    final experience = provider.yearsExperience != null
        ? '${provider.yearsExperience}+ years experience'
        : 'Full-service cafe studio';
    final services = provider.portfolioHeadline ?? provider.capability;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.espresso,
                child: Text(
                  provider.displayName.isNotEmpty ? provider.displayName[0].toUpperCase() : 'S',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider.displayName,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.espresso,
                      ),
                    ),
                    Text(
                      type,
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        letterSpacing: 1.0,
                        fontWeight: FontWeight.bold,
                        color: AppColors.placeholder,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFD9EAA3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, size: 12, color: Color(0xFF56642B)),
                    const SizedBox(width: 4),
                    Text(
                      provider.avgRating.toStringAsFixed(1),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF56642B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildTag(provider.providerType),
              _buildTag('Design & Build'),
              if (provider.isVerified) _buildTag('Verified'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.architecture, size: 14, color: AppColors.placeholder),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  experience,
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.espresso),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.handshake_outlined, size: 14, color: AppColors.placeholder),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  services,
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.espresso),
                ),
              ),
            ],
          ),
          if (provider.bio != null && provider.bio!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              provider.bio!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
              webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                    image1,
                    width: MediaQuery.of(context).size.width * 0.6,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
              webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                        image2,
                        width: 140,
                        height: 90,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: tier == 'PARTNER' ? const Color(0xFFE0E0E0) : AppColors.espresso,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  tier,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: tier == 'PARTNER' ? AppColors.espresso : Colors.white,
                  ),
                ),
              ),
              OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DesignerDetailPage(
                        serviceProviderProfileId: provider.id,
                        contextProjectId: widget.contextProjectId,
                        contextProjectName: widget.contextProjectName,
                        // Left null on purpose — a both-capability studio's
                        // hire should default to a 'both' engagement (see
                        // DesignerDetailPage), not be forced into a single
                        // scope. The project's own slot-conflict check
                        // still blocks it if either slot is already taken.
                      ),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.espresso,
                  side: const BorderSide(color: AppColors.espresso),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  minimumSize: const Size(0, 0),
                ),
                child: Text(
                  'View Profile',
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F3F1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
      ),
    );
  }
}
