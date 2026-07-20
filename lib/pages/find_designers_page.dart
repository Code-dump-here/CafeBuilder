import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../models/responses/api_responses.dart';
import '../services/api_client.dart';
import '../services/service_provider_service.dart';
import 'designer_detail_page.dart';

class FindDesignersPage extends StatefulWidget {
  const FindDesignersPage({super.key});

  @override
  State<FindDesignersPage> createState() => _FindDesignersPageState();
}

class _FindDesignersPageState extends State<FindDesignersPage> {
  final TextEditingController _searchController = TextEditingController();
  List<ServiceProviderResponse> _designers = [];
  bool _loading = true;
  String? _error;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadDesigners();
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
    _debounce = Timer(const Duration(milliseconds: 400), _loadDesigners);
  }

  Future<void> _loadDesigners() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await ServiceProviderService.getProviders(
        capability: 'designer',
        pageSize: 50,
        search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
      );
      if (mounted) {
        setState(() {
          _designers = result.items;
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
          _error = 'Failed to load designers';
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
            hintText: 'Search style, designer, or concept...',
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
              'Find Designers',
              style: GoogleFonts.playfairDisplay(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.espresso,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Connect with architects and interior designers specialized in high-end café aesthetics.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Design Style', true),
                  const SizedBox(width: 8),
                  _buildFilterChip('Cafe Experience', false),
                  const SizedBox(width: 8),
                  _buildFilterChip('Pricing', false),
                ],
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
                    ElevatedButton(onPressed: _loadDesigners, child: const Text('Retry')),
                  ],
                ),
              )
            else if (_designers.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Text(
                  'No designers found.',
                  style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
                ),
              )
            else
              for (final designer in _designers) _buildDesignerCard(designer),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.espresso : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isSelected ? AppColors.espresso : AppColors.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.espresso,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.keyboard_arrow_down,
            size: 16,
            color: isSelected ? Colors.white : AppColors.espresso,
          ),
        ],
      ),
    );
  }

  Widget _buildDesignerCard(ServiceProviderResponse provider) {
    final tier = ServiceProviderService.tierLabel(provider);
    final type = ServiceProviderService.typeLabel(provider);
    final image1 = ServiceProviderService.imageFor(provider.id, 0);
    final image2 = ServiceProviderService.imageFor(provider.id, 1);
    final experience = provider.yearsExperience != null
        ? '${provider.yearsExperience}+ years experience'
        : 'Cafe design specialist';
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
                  provider.displayName.isNotEmpty ? provider.displayName[0].toUpperCase() : 'D',
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
              _buildTag(provider.capability),
              _buildTag(provider.providerType),
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
        style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary),
      ),
    );
  }
}
