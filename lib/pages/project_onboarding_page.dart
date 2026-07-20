import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../services/project_service.dart';
import '../services/design_brief_service.dart';
import '../services/api_client.dart';
import '../services/service_provider_service.dart';
import '../models/requests/project_requests.dart';
import '../models/requests/design_brief_requests.dart';
import 'ai_design_report_page.dart';

class _FloorItem {
  TextEditingController nameCtrl;
  TextEditingController lengthCtrl;
  TextEditingController widthCtrl;

  _FloorItem(String name)
      : nameCtrl = TextEditingController(text: name),
        lengthCtrl = TextEditingController(text: '15.0'),
        widthCtrl = TextEditingController(text: '15.0');

  double get length => double.tryParse(lengthCtrl.text) ?? 15.0;
  double get width => double.tryParse(widthCtrl.text) ?? 15.0;
  double get area => length * width;

  void dispose() {
    nameCtrl.dispose();
    lengthCtrl.dispose();
    widthCtrl.dispose();
  }
}

class ProjectOnboardingPage extends StatefulWidget {
  const ProjectOnboardingPage({super.key});

  @override
  State<ProjectOnboardingPage> createState() => _ProjectOnboardingPageState();
}

class _ProjectOnboardingPageState extends State<ProjectOnboardingPage> {
  int _currentStep = 0;
  final int _totalSteps = 9;

  // Form State
  String _selectedRole = 'cafe_owner';
  final _cafeNameCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  String _projectType = 'New'; // New, Renovation
  final List<String> _selectedCafeTypes = ['Dine-in Cafe'];
  final _conceptNarrativeCtrl = TextEditingController();
  final List<String> _selectedKeywords = ['Premium'];
  final _differentiatorsCtrl = TextEditingController();
  String _selectedStyleRef = 'Modern Organic';
  final List<String> _selectedAudiences = ['Freelancers'];
  String _selectedBudgetLevel = 'Premium'; // Economy, Standard, Premium, Luxury
  double _totalBudget = 1500000000;
  double _pctConstruction = 0.40;
  double _pctFurniture = 0.30;
  double _pctLighting = 0.15;
  double _pctBranding = 0.15;
  String _selectedMood = 'Warm & Cozy';
  String _selectedSoul = 'Modern Minimal';
  final List<String> _selectedFunctionalAreas = ['Customer Seating', 'Coffee Bar', 'Order Counter'];
  static const _allFunctionalAreas = [
    'Customer Seating',
    'Coffee Bar',
    'Order Counter',
    'Commercial Kitchen',
    'Restrooms',
    'Back of House',
  ];
  static const _styleReferenceImages = {
    'Modern Organic': 'https://images.unsplash.com/photo-1554118811-1e0d58224f24?auto=format&fit=crop&q=80&w=300',
    'Classic Editorial': 'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?auto=format&fit=crop&q=80&w=300',
  };
  static const _soulStyleImages = {
    'Modern Minimal': 'https://images.unsplash.com/photo-1498804103079-a6351b050096?auto=format&fit=crop&q=80&w=400',
    'Japandi': 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&q=80&w=400',
    'Industrial': 'https://images.unsplash.com/photo-1521017432531-fbd92d768814?auto=format&fit=crop&q=80&w=400',
    'Vintage': 'https://images.unsplash.com/photo-1559925393-8be0ec4767c8?auto=format&fit=crop&q=80&w=400',
  };
  final _addressCtrl = TextEditingController();
  final List<_FloorItem> _floors = [_FloorItem('Ground Floor')];
  double _ceilingHeight = 3.2;
  double _storefrontWidth = 8.0;

  double get _totalArea => _floors.fold(0.0, (sum, f) => sum + f.area);

  @override
  void dispose() {
    _cafeNameCtrl.dispose();
    _locationCtrl.dispose();
    _conceptNarrativeCtrl.dispose();
    _differentiatorsCtrl.dispose();
    _addressCtrl.dispose();
    for (var f in _floors) {
      f.dispose();
    }
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
    } else {
      _startDesignSynthesis();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      Navigator.maybePop(context);
    }
  }

  bool _isSaving = false;

  List<String> get _niceToHaveZones =>
      _allFunctionalAreas.where((area) => !_selectedFunctionalAreas.contains(area)).toList();

  List<String> get _referenceImageUrls {
    final urls = <String>[];
    final styleRef = _styleReferenceImages[_selectedStyleRef];
    if (styleRef != null) urls.add(styleRef);
    final soulRef = _soulStyleImages[_selectedSoul];
    if (soulRef != null && !urls.contains(soulRef)) urls.add(soulRef);
    return urls;
  }

  String _buildAiNotes() {
    final floorSummary = _floors.map((f) => '${f.nameCtrl.text}: ${f.area.toStringAsFixed(1)} m²').join(', ');
    return [
      if (_conceptNarrativeCtrl.text.isNotEmpty) _conceptNarrativeCtrl.text,
      'Role: $_selectedRole',
      'Project type: $_projectType',
      'Style: $_selectedSoul',
      'Mood: $_selectedMood',
      'Budget level: $_selectedBudgetLevel',
      'Total budget: $_totalBudget',
      'Target audience: ${_selectedAudiences.join(', ')}',
      'Cafe type: ${_selectedCafeTypes.join(', ')}',
      if (_differentiatorsCtrl.text.isNotEmpty) 'Differentiators: ${_differentiatorsCtrl.text}',
      'Total area: ${_totalArea.toStringAsFixed(1)} m²',
      'Ceiling height: $_ceilingHeight m',
      'Storefront width: $_storefrontWidth m',
      'Floors: $floorSummary',
    ].join('\n');
  }

  Future<void> _startDesignSynthesis() async {
    setState(() => _isSaving = true);
    int briefId = 0;
    String? errorMessage;
    try {
      final shopOwnerId = await ShopOwnerService.ensureShopOwnerId();
      final project = await ProjectService.createProject(CreateProjectRequest(
        ownerId: shopOwnerId,
        name: _cafeNameCtrl.text.isEmpty ? 'My Cafe' : _cafeNameCtrl.text,
        address: _addressCtrl.text.isEmpty ? _locationCtrl.text : _addressCtrl.text,
        areaM2: _totalArea,
        budget: _totalBudget,
      ));

      final brief = await DesignBriefService.createDesignBrief(CreateDesignBriefRequest(
        projectId: project.id,
        targetCustomer: _selectedAudiences.join(', '),
        style: _selectedSoul,
        mood: _selectedMood,
        businessModel: _selectedCafeTypes.join(', '),
        brandNote: _conceptNarrativeCtrl.text.isNotEmpty ? _conceptNarrativeCtrl.text : null,
        businessGoals: _differentiatorsCtrl.text.isNotEmpty ? _differentiatorsCtrl.text : null,
      ));
      briefId = brief.id;
    } on ApiException catch (e) {
      errorMessage = e.message;
    } catch (_) {
      errorMessage = 'Failed to create project. Please try again.';
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }

    if (!mounted) return;
    if (errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DesignSynthesisLoadingPage(
          cafeName: _cafeNameCtrl.text.isEmpty ? 'My Cafe' : _cafeNameCtrl.text,
          location: _locationCtrl.text.isEmpty ? 'City, Country' : _locationCtrl.text,
          style: _selectedSoul,
          budgetLevel: _selectedBudgetLevel,
          totalBudget: _totalBudget,
          mood: _selectedMood,
          role: _selectedRole,
          area: _totalArea,
          briefId: briefId,
          mustHaveZones: List<String>.from(_selectedFunctionalAreas),
          niceToHaveZones: _niceToHaveZones,
          notes: _buildAiNotes(),
          referenceImageUrls: _referenceImageUrls,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.espresso),
          onPressed: _prevStep,
        ),
        title: Text(
          'Onboarding',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.espresso,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Slide indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Step ${_currentStep + 1} of $_totalSteps',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        '${((_currentStep + 1) / _totalSteps * 100).toInt()}% Complete',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF56642B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (_currentStep + 1) / _totalSteps,
                      backgroundColor: AppColors.outlineVariant.withOpacity(0.3),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.espresso),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: _buildStepContent(),
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStepRole();
      case 1:
        return _buildStepProjectBasics();
      case 2:
        return _buildStepConcept();
      case 3:
        return _buildStepAudience();
      case 4:
        return _buildStepBudget();
      case 5:
        return _buildStepMood();
      case 6:
        return _buildStepSoul();
      case 7:
        return _buildStepFunctionalAreas();
      case 8:
        return _buildStepSpaceInfo();
      default:
        return Container();
    }
  }

  // --- Step 1: Role ---
  Widget _buildStepRole() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tell us about your role',
          style: GoogleFonts.playfairDisplay(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AppColors.espresso,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'To provide the most relevant design insights and management tools, please identify your primary position in this cafe project.',
          style: GoogleFonts.inter(
            fontSize: 14,
            height: 1.5,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 32),
        _buildRoleOption(
          id: 'cafe_owner',
          title: 'I am the cafe owner',
          subtitle: 'Overseeing the entire vision and final decision making for your upcoming space.',
          icon: Icons.storefront_outlined,
        ),
        const SizedBox(height: 16),
        _buildRoleOption(
          id: 'planning_cafe',
          title: 'I am planning to open a cafe',
          subtitle: 'In the early stages of research, inspiration gathering, and feasibility studies.',
          icon: Icons.lightbulb_outline,
        ),
      ],
    );
  }

  Widget _buildRoleOption({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    bool isSel = _selectedRole == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = id),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSel ? AppColors.espresso : AppColors.outlineVariant.withOpacity(0.5),
            width: isSel ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.espresso.withOpacity(isSel ? 0.08 : 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSel ? AppColors.espresso : const Color(0xFFF6F3F1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSel ? Colors.white : AppColors.espresso,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.espresso,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      height: 1.4,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Step 2: Project Basics ---
  Widget _buildStepProjectBasics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Project Basics',
          style: GoogleFonts.playfairDisplay(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AppColors.espresso,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Let's start with the foundation",
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 24),
        _buildTextFieldLabel('Cafe Name'),
        TextField(
          controller: _cafeNameCtrl,
          decoration: _buildInputDec('Your cafe\'s name'),
          style: GoogleFonts.inter(color: AppColors.textPrimary),
        ),
        const SizedBox(height: 20),
        _buildTextFieldLabel('Project Location'),
        TextField(
          controller: _locationCtrl,
          decoration: _buildInputDec('City, Country'),
          style: GoogleFonts.inter(color: AppColors.textPrimary),
        ),
        const SizedBox(height: 24),
        _buildTextFieldLabel('Project Type'),
        Row(
          children: [
            Expanded(
              child: _buildTypeToggle('New', Icons.architecture_rounded),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTypeToggle('Renovation', Icons.home_work_outlined),
            ),
          ],
        ),
        const SizedBox(height: 28),
        _buildTextFieldLabel('Cafe Type (Select all that apply)'),
        ...[
          _buildCafeTypeTile('Dine-in Cafe', 'Full service seating', Icons.local_cafe_outlined),
          _buildCafeTypeTile('Takeaway Cafe', 'Quick grab & go', Icons.storefront),
          _buildCafeTypeTile('Specialty Coffee', 'Premium brewing', Icons.coffee_maker_outlined),
          _buildCafeTypeTile('Bakery Cafe', 'Pastries & coffee', Icons.bakery_dining_outlined),
          _buildCafeTypeTile('Work-Friendly', 'Coworking vibe', Icons.laptop_chromebook_outlined),
        ],
      ],
    );
  }

  Widget _buildTypeToggle(String val, IconData icon) {
    bool isSel = _projectType == val;
    return GestureDetector(
      onTap: () => setState(() => _projectType = val),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: isSel ? AppColors.espresso : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSel ? AppColors.espresso : AppColors.outlineVariant.withOpacity(0.6),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSel ? Colors.white : AppColors.espresso,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              val,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSel ? Colors.white : AppColors.espresso,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCafeTypeTile(String type, String desc, IconData icon) {
    bool selected = _selectedCafeTypes.contains(type);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () {
          setState(() {
            if (selected) {
              if (_selectedCafeTypes.length > 1) {
                _selectedCafeTypes.remove(type);
              }
            } else {
              _selectedCafeTypes.add(type);
            }
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.espresso : AppColors.outlineVariant.withOpacity(0.4),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFF6F3F1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.espresso, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.espresso,
                      ),
                    ),
                    Text(
                      desc,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? AppColors.espresso : AppColors.outlineVariant,
                    width: 2,
                  ),
                ),
                child: selected
                    ? const Center(
                        child: Icon(Icons.circle, size: 10, color: AppColors.espresso),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Step 3: Concept ---
  Widget _buildStepConcept() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What is your cafe concept?',
          style: GoogleFonts.playfairDisplay(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AppColors.espresso,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Describe the soul of your space. Whether it\'s a bustling social hub or a quiet architectural sanctuary, your concept defines every design choice we\'ll make together.',
          style: GoogleFonts.inter(
            fontSize: 13,
            height: 1.5,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 24),
        _buildTextFieldLabel('Concept Narrative'),
        TextField(
          controller: _conceptNarrativeCtrl,
          maxLines: 4,
          maxLength: 500,
          decoration: _buildInputDec('e.g., A brutalist-inspired coffee bar using raw concrete and warm cedarwood, focusing on artisanal pour-overs and a gallery-like atmosphere...'),
          style: GoogleFonts.inter(color: AppColors.textPrimary),
        ),
        const SizedBox(height: 16),
        _buildTextFieldLabel('Atmospheric Keywords'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            'Cozy', 'Premium', 'Minimal', 'Artistic', 'Social', 'Industrial', 'Heritage'
          ].map((kw) {
            bool selected = _selectedKeywords.contains(kw);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (selected) {
                    _selectedKeywords.remove(kw);
                  } else {
                    _selectedKeywords.add(kw);
                  }
                });
              },
              child: Chip(
                label: Text(kw),
                backgroundColor: selected ? AppColors.espresso : Colors.white,
                labelStyle: GoogleFonts.inter(
                  color: selected ? Colors.white : AppColors.espresso,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                side: BorderSide(
                  color: selected ? AppColors.espresso : AppColors.outlineVariant.withOpacity(0.6),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        _buildTextFieldLabel('Key Differentiators'),
        TextField(
          controller: _differentiatorsCtrl,
          maxLines: 3,
          decoration: _buildInputDec('What makes your cafe unique? e.g., On-site roasting, integrated library, custom ergonomic furniture...'),
          style: GoogleFonts.inter(color: AppColors.textPrimary),
        ),
        const SizedBox(height: 24),
        _buildTextFieldLabel('Style Reference'),
        Row(
          children: [
            Expanded(
              child: _buildStyleReferenceCard(
                'Modern Organic',
                'https://images.unsplash.com/photo-1554118811-1e0d58224f24?auto=format&fit=crop&q=80&w=300',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStyleReferenceCard(
                'Classic Editorial',
                'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?auto=format&fit=crop&q=80&w=300',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStyleReferenceCard(String title, String imgUrl) {
    bool isSel = _selectedStyleRef == title;
    return GestureDetector(
      onTap: () => setState(() => _selectedStyleRef = title),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSel ? AppColors.espresso : Colors.transparent,
            width: 2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            children: [
              Image.network(
                imgUrl,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.4),
                ),
              ),
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'STYLE REFERENCE',
                      style: GoogleFonts.inter(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                    Text(
                      title,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSel)
                const Positioned(
                  top: 8,
                  right: 8,
                  child: Icon(Icons.check_circle, color: Colors.white, size: 20),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Step 4: Ideal Audience ---
  Widget _buildStepAudience() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Define your ideal audience',
          style: GoogleFonts.playfairDisplay(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AppColors.espresso,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tailoring your interior design begins with understanding who will inhabit your space. Select the primary groups you aim to serve.',
          style: GoogleFonts.inter(
            fontSize: 13,
            height: 1.5,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 24),
        ...[
          _buildAudienceCard('Students', 'Values focus, affordable comfort, and late-night accessibility for deep study sessions.', 'High-speed Wi-Fi focus', showImg: true, imgUrl: 'https://images.unsplash.com/photo-1523240795612-9a054b0db644?auto=format&fit=crop&q=80&w=500'),
          _buildAudienceCard('Office Workers', 'Needs speed, takeaway efficiency, and professional settings for quick morning meetings.', 'Rapid service workflow', showImg: true, imgUrl: 'https://images.unsplash.com/photo-1522071820081-009f0129c71c?auto=format&fit=crop&q=80&w=500'),
          _buildAudienceCard('Freelancers', 'Seeks aesthetic inspiration, reliable power outlets, and long-stay hospitality.', 'Ergonomic seating priority', showImg: true, imgUrl: 'https://images.unsplash.com/photo-1498050108023-c5249f4df085?auto=format&fit=crop&q=80&w=500'),
          _buildAudienceCard('Families', 'Prioritizes safety, spacious seating, and a welcoming atmosphere for all ages.', 'Low-noise acoustic design', showImg: true, imgUrl: 'https://images.unsplash.com/photo-1529156069898-49953e39b3ac?auto=format&fit=crop&q=80&w=500'),
          _buildAudienceCard('Digital Nomads', 'Driven by community, high-quality caffeine, and "Instagrammable" architectural details.', 'Iconic photo-op corners', showImg: true, imgUrl: 'https://images.unsplash.com/photo-1522202176988-66273c2fd55f?auto=format&fit=crop&q=80&w=500'),
        ],
      ],
    );
  }

  Widget _buildAudienceCard(String title, String desc, String tag, {bool showImg = false, String? imgUrl}) {
    bool selected = _selectedAudiences.contains(title);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () {
          setState(() {
            if (selected) {
              if (_selectedAudiences.length > 1) {
                _selectedAudiences.remove(title);
              }
            } else {
              _selectedAudiences.add(title);
            }
          });
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.espresso : AppColors.outlineVariant.withOpacity(0.4),
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.espresso,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            desc,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              height: 1.4,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF56642B),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                tag,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF56642B),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (selected)
                      const Icon(Icons.check_circle, color: AppColors.espresso, size: 22),
                  ],
                ),
              ),
              if (showImg && imgUrl != null)
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(14),
                    bottomRight: Radius.circular(14),
                  ),
                  child: Image.network(
                    imgUrl,
                    height: 140,
                    fit: BoxFit.cover,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Step 5: Budget Planning ---
  Widget _buildStepBudget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Budget Planning',
          style: GoogleFonts.playfairDisplay(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AppColors.espresso,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Investment expectations',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildBudgetLevelCard('Economy', 'Essential quality', '500Tr - 1 Tỷ', 700000000),
              const SizedBox(width: 12),
              _buildBudgetLevelCard('Standard', 'Good quality balance', '1 Tỷ - 2 Tỷ', 1500000000),
              const SizedBox(width: 12),
              _buildBudgetLevelCard('Premium', 'High-end materials', '2 Tỷ - 5 Tỷ', 3500000000),
              const SizedBox(width: 12),
              _buildBudgetLevelCard('Luxury', 'Bespoke everything', '5 Tỷ+', 6000000000),
            ],
          ),
        ),
        const SizedBox(height: 32),
        _buildTextFieldLabel('Total Investment Budget (VND)'),
        TextField(
          keyboardType: TextInputType.number,
          decoration: _buildInputDec('e.g., 1500000000'),
          style: GoogleFonts.inter(color: AppColors.textPrimary),
          onChanged: (val) {
            final parsed = double.tryParse(val);
            if (parsed != null) {
              setState(() => _totalBudget = parsed);
            }
          },
          controller: TextEditingController()..text = _totalBudget.toStringAsFixed(0),
        ),
        const SizedBox(height: 36),
        _buildTextFieldLabel('Budget Allocation'),
        _buildAllocationSlider('Construction', _pctConstruction, (val) {
          setState(() {
            _pctConstruction = val;
            _balanceAllocations(0);
          });
        }),
        _buildAllocationSlider('Furniture', _pctFurniture, (val) {
          setState(() {
            _pctFurniture = val;
            _balanceAllocations(1);
          });
        }),
        _buildAllocationSlider('Lighting', _pctLighting, (val) {
          setState(() {
            _pctLighting = val;
            _balanceAllocations(2);
          });
        }),
        _buildAllocationSlider('Branding', _pctBranding, (val) {
          setState(() {
            _pctBranding = val;
            _balanceAllocations(3);
          });
        }),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total Allocation:',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.espresso,
              ),
            ),
            Text(
              '${((_pctConstruction + _pctFurniture + _pctLighting + _pctBranding) * 100).toStringAsFixed(0)}% (100% Target)',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF56642B),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _balanceAllocations(int changedIndex) {
    double total = _pctConstruction + _pctFurniture + _pctLighting + _pctBranding;
    if (total == 1.0) return;
    double remainder = 1.0 - (changedIndex == 0 ? _pctConstruction : changedIndex == 1 ? _pctFurniture : changedIndex == 2 ? _pctLighting : _pctBranding);
    
    double prevSum = 0;
    if (changedIndex != 0) prevSum += _pctConstruction;
    if (changedIndex != 1) prevSum += _pctFurniture;
    if (changedIndex != 2) prevSum += _pctLighting;
    if (changedIndex != 3) prevSum += _pctBranding;

    if (prevSum == 0) {
      double split = remainder / 3;
      if (changedIndex != 0) _pctConstruction = split;
      if (changedIndex != 1) _pctFurniture = split;
      if (changedIndex != 2) _pctLighting = split;
      if (changedIndex != 3) _pctBranding = split;
    } else {
      double scale = remainder / prevSum;
      if (changedIndex != 0) _pctConstruction = (_pctConstruction * scale).clamp(0.0, 1.0);
      if (changedIndex != 1) _pctFurniture = (_pctFurniture * scale).clamp(0.0, 1.0);
      if (changedIndex != 2) _pctLighting = (_pctLighting * scale).clamp(0.0, 1.0);
      if (changedIndex != 3) _pctBranding = (_pctBranding * scale).clamp(0.0, 1.0);
    }
  }

  Widget _buildBudgetLevelCard(String name, String desc, String range, double value) {
    bool isSel = _selectedBudgetLevel == name;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedBudgetLevel = name;
          _totalBudget = value;
        });
      },
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSel ? Colors.white : Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSel ? AppColors.espresso : AppColors.outlineVariant.withOpacity(0.5),
            width: isSel ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              name,
              style: GoogleFonts.playfairDisplay(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.espresso,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              desc,
              style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              range,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isSel ? const Color(0xFF56642B) : AppColors.placeholder,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatVND(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }

  Widget _buildAllocationSlider(String label, double val, ValueChanged<double> onChanged) {
    double amt = _totalBudget * val;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.espresso)),
            Text(
              '${(val * 100).toStringAsFixed(0)}% (${_formatVND(amt)} ₫)',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.placeholder),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.espresso,
            inactiveTrackColor: AppColors.outlineVariant.withOpacity(0.4),
            thumbColor: AppColors.espresso,
            overlayColor: AppColors.espresso.withOpacity(0.2),
            trackHeight: 4,
          ),
          child: Slider(
            value: val,
            min: 0.0,
            max: 1.0,
            onChanged: onChanged,
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  // --- Step 6: Mood & Atmosphere ---
  Widget _buildStepMood() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mood & Atmosphere',
          style: GoogleFonts.playfairDisplay(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AppColors.espresso,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Set the emotional tone',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 24),
        ...[
          _buildMoodTile('Warm & Cozy', 'Soft, ambient', [const Color(0xFFD9B48F), const Color(0xFFAC7C58), const Color(0xFF7A4F30)], 'https://images.unsplash.com/photo-1445116572660-236099ec97a0?auto=format&fit=crop&q=80&w=300'),
          _buildMoodTile('Cinematic & Moody', 'Dramatic, focused', [const Color(0xFF323B33), const Color(0xFF5E655F), const Color(0xFFDFE2DE)], 'https://images.unsplash.com/photo-1507133750040-4a8f57021571?auto=format&fit=crop&q=80&w=300'),
          _buildMoodTile('Bright & Clean', 'Natural, abundant', [const Color(0xFFEDEAD8), const Color(0xFFD7CFBC), const Color(0xFFC7BDAB)], 'https://images.unsplash.com/photo-1554118811-1e0d58224f24?auto=format&fit=crop&q=80&w=300'),
          _buildMoodTile('Artistic & Memorable', 'Curated, statement', [const Color(0xFFB15B3C), const Color(0xFFCE9B82), const Color(0xFFE8DCD4)], 'https://images.unsplash.com/photo-1497034825429-c343d7c6a68f?auto=format&fit=crop&q=80&w=300'),
          _buildMoodTile('Premium & Elegant', 'Layered, refined', [const Color(0xFF3E3024), const Color(0xFF9E896A), const Color(0xFFDFDCD7)], 'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?auto=format&fit=crop&q=80&w=300'),
          _buildMoodTile('Natural & Calm', 'Diffused, peaceful', [const Color(0xFF75855F), const Color(0xFFC5CEB8), const Color(0xFFECEFE7)], 'https://images.unsplash.com/photo-1511920170033-f8396924c348?auto=format&fit=crop&q=80&w=300'),
        ],
      ],
    );
  }

  Widget _buildMoodTile(String name, String desc, List<Color> colors, String imgUrl) {
    bool isSel = _selectedMood == name;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () => setState(() => _selectedMood = name),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSel ? AppColors.espresso : AppColors.outlineVariant.withOpacity(0.4),
              width: isSel ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imgUrl,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.espresso,
                      ),
                    ),
                    Text(
                      desc,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.placeholder,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: colors.map((c) => Container(
                        margin: const EdgeInsets.only(right: 6),
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                        ),
                      )).toList(),
                    ),
                  ],
                ),
              ),
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSel ? AppColors.espresso : AppColors.outlineVariant,
                    width: 2,
                  ),
                ),
                child: isSel
                    ? const Center(
                        child: Icon(Icons.circle, size: 10, color: AppColors.espresso),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Step 7: Define your coffee shop's soul ---
  Widget _buildStepSoul() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Define your coffee shop\'s soul',
          style: GoogleFonts.playfairDisplay(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AppColors.espresso,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select an interior style that aligns with your brand\'s vision. Each aesthetic is curated to provide a unique sensory experience for your future customers.',
          style: GoogleFonts.inter(
            fontSize: 13,
            height: 1.5,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 24),
        ...[
          _buildSoulCard('Modern Minimal', 'Cost: \$\$\$', ['#Clean', '#Sleek', '#Functional'], 'https://images.unsplash.com/photo-1498804103079-a6351b050096?auto=format&fit=crop&q=80&w=400'),
          _buildSoulCard('Japandi', 'Cost: \$\$\$', ['#Organic', '#Zen', '#Timeless'], 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&q=80&w=400'),
          _buildSoulCard('Industrial', 'Cost: \$\$', ['#Raw', '#Urban', '#Bold'], 'https://images.unsplash.com/photo-1521017432531-fbd92d768814?auto=format&fit=crop&q=80&w=400'),
          _buildSoulCard('Vintage', 'Cost: \$\$\$', ['#Classic', '#Character', '#Warm'], 'https://images.unsplash.com/photo-1559925393-8be0ec4767c8?auto=format&fit=crop&q=80&w=400'),
        ],
      ],
    );
  }

  Widget _buildSoulCard(String title, String cost, List<String> tags, String imgUrl) {
    bool isSel = _selectedSoul == title;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: GestureDetector(
        onTap: () => setState(() => _selectedSoul = title),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSel ? const Color(0xFF56642B) : AppColors.outlineVariant.withOpacity(0.4),
              width: isSel ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                ),
                child: Image.network(
                  imgUrl,
                  height: 180,
                  fit: BoxFit.cover,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                title,
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.espresso,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.outlineVariant.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  cost,
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.espresso,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: tags.map((t) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Text(
                                t,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.placeholder,
                                ),
                              ),
                            )).toList(),
                          ),
                        ],
                      ),
                    ),
                    if (isSel)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFF56642B),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, color: Colors.white, size: 14),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Step 8: Define Functional Areas ---
  Widget _buildStepFunctionalAreas() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Define Functional Areas',
          style: GoogleFonts.playfairDisplay(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AppColors.espresso,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select the core operational zones for your café interior. These selections will inform the spatial distribution and technical requirements of your 3D architectural plan.',
          style: GoogleFonts.inter(
            fontSize: 13,
            height: 1.5,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 24),
        ...[
          _buildFunctionalAreaCard('Customer Seating', 'Optimized layouts for lounge, communal, or individual workspace seating options.', 'Essential Requirement'),
          _buildFunctionalAreaCard('Coffee Bar', 'Precision-engineered workstation for high-volume espresso and brew service.', 'Technical Specs / Station Needed'),
          _buildFunctionalAreaCard('Order Counter', 'Ergonomic POS zones integrated with display cases and customer queue flow.', 'Essential Requirement'),
          _buildFunctionalAreaCard('Commercial Kitchen', 'Full-service food preparation area including ventilation and heavy equipment.', 'HVAC & Gas Planning Required'),
          _buildFunctionalAreaCard('Restrooms', 'ADA compliant facility design with premium material and lighting finishes.', 'Plumbing Grid Integration'),
          _buildFunctionalAreaCard('Back of House', 'Strategic inventory storage, cold rooms, and staff administrative quarters.', 'Operational Efficiency Zone'),
        ],
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.outlineVariant.withOpacity(0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Automated Area Proportions',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.espresso,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Based on your selections, our AI designer will suggest optimal square footage allocation. You can adjust these proportions in the next step using the Technical Drawing canvas.',
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFD9EAA3).withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.tips_and_updates_outlined, color: Color(0xFF56642B), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Most high-end cafes allocate 60% of floor space to the seating area.',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF56642B),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFunctionalAreaCard(String title, String desc, String requirement) {
    bool selected = _selectedFunctionalAreas.contains(title);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () {
          setState(() {
            if (selected) {
              if (_selectedFunctionalAreas.length > 1) {
                _selectedFunctionalAreas.remove(title);
              }
            } else {
              _selectedFunctionalAreas.add(title);
            }
          });
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.espresso : AppColors.outlineVariant.withOpacity(0.4),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.espresso,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      desc,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      requirement,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.placeholder,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? AppColors.espresso : AppColors.outlineVariant,
                    width: 2,
                  ),
                ),
                child: selected
                    ? const Center(
                        child: Icon(Icons.check, size: 10, color: AppColors.espresso),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Step 9: Space Information ---
  Widget _buildStepSpaceInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Space Information',
          style: GoogleFonts.playfairDisplay(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AppColors.espresso,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Provide accurate operational specifications and details of your plot so that AI can calculate and optimize your cafe space.',
          style: GoogleFonts.inter(
            fontSize: 13,
            height: 1.4,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 24),
        _buildTextFieldLabel('Address'),
        TextField(
          controller: _addressCtrl,
          decoration: _buildInputDec('Enter site address...'),
          style: GoogleFonts.inter(color: AppColors.textPrimary),
        ),
        const SizedBox(height: 20),
        _buildTextFieldLabel('Floor Measurements'),
        ..._floors.asMap().entries.map((entry) {
          int index = entry.key;
          _FloorItem floor = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.outlineVariant.withOpacity(0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildTextFieldLabel('Floor Name'),
                      if (_floors.length > 1)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              floor.dispose();
                              _floors.removeAt(index);
                            });
                          },
                          child: const Icon(Icons.close, color: Colors.grey, size: 20),
                        ),
                    ],
                  ),
                  TextField(
                    controller: floor.nameCtrl,
                    decoration: _buildInputDec('e.g., Ground Floor'),
                    style: GoogleFonts.inter(color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTextFieldLabel('Length (m)'),
                            TextField(
                              keyboardType: TextInputType.number,
                              decoration: _buildInputDec('15.0'),
                              onChanged: (val) {
                                setState(() {}); // Refresh area calculation
                              },
                              controller: floor.lengthCtrl,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTextFieldLabel('Width (m)'),
                            TextField(
                              keyboardType: TextInputType.number,
                              decoration: _buildInputDec('15.0'),
                              onChanged: (val) {
                                setState(() {}); // Refresh area calculation
                              },
                              controller: floor.widthCtrl,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTextFieldLabel('Area (m²)'),
                            Container(
                              height: 48,
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF6F3F1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.outlineVariant.withOpacity(0.6)),
                              ),
                              child: Text(
                                floor.area.toStringAsFixed(1),
                                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.espresso),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
        TextButton.icon(
          onPressed: () {
            setState(() {
              _floors.add(_FloorItem('Floor ${_floors.length + 1}'));
            });
          },
          icon: const Icon(Icons.add, color: AppColors.espresso),
          label: Text('Add Floor', style: GoogleFonts.inter(color: AppColors.espresso, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 24),
        _buildTextFieldLabel('Global Parameters'),
        Row(
          children: [
            Expanded(
              child: _buildParameterField('Est. Total Area (m²)', _totalArea.toStringAsFixed(0)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextFieldLabel('Ceiling Height (m)'),
                  TextField(
                    keyboardType: TextInputType.number,
                    decoration: _buildInputDec('3.2'),
                    onChanged: (val) {
                      final parsed = double.tryParse(val);
                      if (parsed != null) setState(() => _ceilingHeight = parsed);
                    },
                    controller: TextEditingController()..text = _ceilingHeight.toString(),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextFieldLabel('Storefront Width (m)'),
                  TextField(
                    keyboardType: TextInputType.number,
                    decoration: _buildInputDec('8.0'),
                    onChanged: (val) {
                      final parsed = double.tryParse(val);
                      if (parsed != null) setState(() => _storefrontWidth = parsed);
                    },
                    controller: TextEditingController()..text = _storefrontWidth.toString(),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        _buildTextFieldLabel('Attachments'),
        _buildAttachmentTile('Sketch/Floor Plan', 'Sketch.jpg - Sketch outline for AI interpolation', '3.2 MB'),
        _buildAttachmentTile('Walk-through Video', 'Video.mp4 - Panoramic view of the site', '45.0 MB'),
      ],
    );
  }

  Widget _buildParameterField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextFieldLabel(label),
        Container(
          height: 48,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F3F1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.outlineVariant.withOpacity(0.6)),
          ),
          child: Text(
            value,
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.espresso, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildAttachmentTile(String label, String fileName, String size) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.espresso.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.attach_file, color: AppColors.espresso, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.placeholder)),
                Text(
                  fileName,
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(size, style: GoogleFonts.inter(fontSize: 11, color: AppColors.placeholder)),
          const SizedBox(width: 8),
          IconButton(onPressed: () {}, icon: const Icon(Icons.close, size: 18, color: AppColors.outline)),
        ],
      ),
    );
  }

  // --- Base helpers ---
  Widget _buildTextFieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 2),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.espresso,
        ),
      ),
    );
  }

  InputDecoration _buildInputDec(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(color: AppColors.placeholder, fontSize: 13),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.outlineVariant.withOpacity(0.6)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.espresso, width: 1.5),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.outlineVariant.withOpacity(0.3))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: _prevStep,
            child: Text(
              'Previous',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _isSaving ? null : _nextStep,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.espresso,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isSaving) ...[
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Creating project...',
                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ] else ...[
                  Text(
                    _currentStep == _totalSteps - 1 ? 'Generate Synthesis' : 'Continue',
                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, size: 16),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
