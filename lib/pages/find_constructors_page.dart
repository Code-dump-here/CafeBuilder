import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../models/responses/api_responses.dart';
import '../services/api_client.dart';
import '../services/service_provider_service.dart';
import 'constructor_detail_page.dart';

class FindConstructorsPage extends StatefulWidget {
  const FindConstructorsPage({super.key});

  @override
  State<FindConstructorsPage> createState() => _FindConstructorsPageState();
}

class _FindConstructorsPageState extends State<FindConstructorsPage> {
  final TextEditingController _searchController = TextEditingController();
  List<ServiceProviderResponse> _constructors = [];
  bool _loading = true;
  String? _error;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadConstructors();
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
    _debounce = Timer(const Duration(milliseconds: 400), _loadConstructors);
  }

  Future<void> _loadConstructors() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await ServiceProviderService.getProviders(
        capability: 'constructor',
        pageSize: 50,
        search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
      );
      if (mounted) {
        setState(() {
          _constructors = result.items;
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
          _error = 'Failed to load contractors';
        });
      }
    }
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const FilterConstructorsSheet(),
    );
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
              'Find Constructors',
              style: GoogleFonts.playfairDisplay(
                fontSize: 16,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Find Constructors',
              style: GoogleFonts.playfairDisplay(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.espresso,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Specialized construction firms for your next F&B masterpiece. From structural integrity to artisan finishing.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _buildDropdown('Specialization')),
                const SizedBox(width: 12),
                Expanded(child: _buildDropdown('Project Scale')),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search firm name...',
                hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.placeholder),
                prefixIcon: const Icon(Icons.search, color: AppColors.placeholder, size: 20),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.outlineVariant.withOpacity(0.5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.espresso),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: InkWell(
                onTap: () => _showFilterSheet(context),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9EAA3).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Detail filter',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF56642B)),
                  ),
                ),
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
                    ElevatedButton(onPressed: _loadConstructors, child: const Text('Retry')),
                  ],
                ),
              )
            else if (_constructors.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Text(
                  'No contractors found.',
                  style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
                ),
              )
            else
              for (final contractor in _constructors) _buildConstructorCard(contractor),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            text,
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
          ),
          const Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.textSecondary),
        ],
      ),
    );
  }

  Widget _buildConstructorCard(ServiceProviderResponse provider) {
    final type = ServiceProviderService.typeLabel(provider);
    final experience = provider.yearsExperience != null
        ? '${provider.yearsExperience}+ years in construction'
        : 'Cafe construction specialist';
    final services = [
      provider.capability,
      if (provider.portfolioHeadline != null) provider.portfolioHeadline!,
      provider.providerType,
    ];
    final image1 = ServiceProviderService.imageFor(provider.id, 0);
    final image2 = ServiceProviderService.imageFor(provider.id, 1);
    final image3 = ServiceProviderService.imageFor(provider.id, 2);

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFD9EAA3).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  type,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF56642B),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F3F1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, size: 12, color: AppColors.espresso),
                    const SizedBox(width: 4),
                    Text(
                      provider.avgRating.toStringAsFixed(1),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.espresso,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            provider.displayName,
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.espresso,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.coffee_outlined, size: 14, color: AppColors.placeholder),
              const SizedBox(width: 8),
              Text(
                experience,
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 14, color: AppColors.placeholder),
              const SizedBox(width: 8),
              Text(
                provider.isVerified ? 'Verified partner · Vietnam' : 'Vietnam',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'CORE SERVICES',
            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: AppColors.placeholder),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: services.map((tag) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.outlineVariant),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                tag,
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.espresso),
              ),
            )).toList(),
          ),
          if (provider.bio != null && provider.bio!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              provider.bio!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
            ),
          ],
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ConstructorDetailPage(
                    serviceProviderProfileId: provider.id,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.espresso,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              minimumSize: const Size(140, 36),
            ),
            child: Text(
              'View Full Portfolio →',
              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'FEATURED PROJECTS',
            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: AppColors.placeholder),
          ),
          const SizedBox(height: 8),
          Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  image1,
                  width: double.infinity,
                  height: 140,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        image2,
                        height: 90,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        image3,
                        height: 90,
                        fit: BoxFit.cover,
                      ),
                    ),
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

class FilterConstructorsSheet extends StatefulWidget {
  const FilterConstructorsSheet({super.key});

  @override
  State<FilterConstructorsSheet> createState() => _FilterConstructorsSheetState();
}

class _FilterConstructorsSheetState extends State<FilterConstructorsSheet> {
  String selectedBudget = 'MID';
  String selectedSpec = 'Bistro';
  String selectedProjects = '10+';
  String selectedArea = '50 - 100m²';
  String selectedTime = '30-60 days';
  String selectedWarranty = '12 mo';
  bool verifiedPartner = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      height: MediaQuery.of(context).size.height * 0.9,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.espresso),
                onPressed: () => Navigator.pop(context),
              ),
              Text(
                'Filter Constructors',
                style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.espresso),
              ),
              TextButton(
                onPressed: () {},
                child: Text('Reset', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Refine your search for the perfect building partner.',
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('City'),
                            _buildDropdown('HCMC'),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('District'),
                            _buildDropdown('District 1'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildLabel('BUDGET RANGE (VND)'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildChip('NORMAL', selectedBudget, (v) => setState(() => selectedBudget = v)),
                      _buildChip('MID', selectedBudget, (v) => setState(() => selectedBudget = v)),
                      _buildChip('LUXURY', selectedBudget, (v) => setState(() => selectedBudget = v)),
                      _buildChip('LUXURY +', selectedBudget, (v) => setState(() => selectedBudget = v)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildLabel('SPECIALIZATION'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildChip('Specialty Cafe', selectedSpec, (v) => setState(() => selectedSpec = v)),
                      _buildChip('Bistro', selectedSpec, (v) => setState(() => selectedSpec = v)),
                      _buildChip('Roastery', selectedSpec, (v) => setState(() => selectedSpec = v)),
                      _buildChip('Chain/Franchise', selectedSpec, (v) => setState(() => selectedSpec = v)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildLabel('COMPLETED PROJECTS'),
                  Row(
                    children: [
                      Expanded(child: _buildChip('5+', selectedProjects, (v) => setState(() => selectedProjects = v))),
                      const SizedBox(width: 8),
                      Expanded(child: _buildChip('10+', selectedProjects, (v) => setState(() => selectedProjects = v))),
                      const SizedBox(width: 8),
                      Expanded(child: _buildChip('20+', selectedProjects, (v) => setState(() => selectedProjects = v))),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildLabel('FLOOR AREA (M²)'),
                  Row(
                    children: [
                      Expanded(child: _buildChip('< 50m²', selectedArea, (v) => setState(() => selectedArea = v))),
                      const SizedBox(width: 8),
                      Expanded(child: _buildChip('50 - 100m²', selectedArea, (v) => setState(() => selectedArea = v))),
                      const SizedBox(width: 8),
                      Expanded(child: _buildChip('100 - 200m²', selectedArea, (v) => setState(() => selectedArea = v))),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildLabel('COMPLETION TIME'),
                  Row(
                    children: [
                      Expanded(child: _buildChip('< 30 days', selectedTime, (v) => setState(() => selectedTime = v))),
                      const SizedBox(width: 8),
                      Expanded(child: _buildChip('30-60 days', selectedTime, (v) => setState(() => selectedTime = v))),
                      const SizedBox(width: 8),
                      Expanded(child: _buildChip('60-90 days', selectedTime, (v) => setState(() => selectedTime = v))),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.outlineVariant.withOpacity(0.5)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Verified Partner', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.espresso)),
                            Text('Only show constructors vetted by Atelier', style: GoogleFonts.inter(fontSize: 9, color: AppColors.textSecondary)),
                          ],
                        ),
                        Switch(
                          value: verifiedPartner,
                          onChanged: (v) => setState(() => verifiedPartner = v),
                          activeColor: const Color(0xFF56642B),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildLabel('WARRANTY PERIOD'),
                  Row(
                    children: [
                      Expanded(child: _buildChip('6 mo', selectedWarranty, (v) => setState(() => selectedWarranty = v))),
                      const SizedBox(width: 8),
                      Expanded(child: _buildChip('12 mo', selectedWarranty, (v) => setState(() => selectedWarranty = v))),
                      const SizedBox(width: 8),
                      Expanded(child: _buildChip('24 mo', selectedWarranty, (v) => setState(() => selectedWarranty = v))),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildLabel('MINIMUM RATING'),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          Text('4.0', style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.espresso)),
                          const Icon(Icons.star, size: 12, color: AppColors.placeholder),
                        ],
                      ),
                      Column(
                        children: [
                          Text('4.5', style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.espresso)),
                          const Icon(Icons.star, size: 12, color: AppColors.espresso),
                        ],
                      ),
                      Column(
                        children: [
                          Text('5.0', style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.placeholder)),
                          const Icon(Icons.star, size: 12, color: AppColors.placeholder),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: AppColors.outlineVariant.withOpacity(0.5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text('Clear All', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.espresso)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.espresso,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text('Show 12 Results', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: AppColors.placeholder),
      ),
    );
  }

  Widget _buildDropdown(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(text, style: GoogleFonts.inter(fontSize: 13, color: AppColors.espresso)),
          const Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.placeholder),
        ],
      ),
    );
  }

  Widget _buildChip(String label, String selectedValue, Function(String) onSelect) {
    bool isSelected = label == selectedValue;
    return GestureDetector(
      onTap: () => onSelect(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.espresso : Colors.white,
          border: Border.all(color: isSelected ? AppColors.espresso : AppColors.outlineVariant.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
