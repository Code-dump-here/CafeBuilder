import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import 'project_success_page.dart';
import '../services/ai_recommendation_service.dart';
import '../models/responses/api_responses.dart';

class DesignSynthesisLoadingPage extends StatefulWidget {
  final String cafeName;
  final String location;
  final String style;
  final String budgetLevel;
  final double totalBudget;
  final String mood;
  final String role;
  final double area;
  final int briefId;
  final List<String> mustHaveZones;
  final List<String> niceToHaveZones;
  final String notes;
  final List<String> referenceImageUrls;

  const DesignSynthesisLoadingPage({
    super.key,
    required this.cafeName,
    required this.location,
    required this.style,
    required this.budgetLevel,
    required this.totalBudget,
    required this.mood,
    required this.role,
    required this.area,
    this.briefId = 0,
    this.mustHaveZones = const [],
    this.niceToHaveZones = const [],
    this.notes = '',
    this.referenceImageUrls = const [],
  });

  @override
  State<DesignSynthesisLoadingPage> createState() => _DesignSynthesisLoadingPageState();
}

class _DesignSynthesisLoadingPageState extends State<DesignSynthesisLoadingPage> {
  int _statusIndex = 0;
  double _progress = 0.0;
  Timer? _progressTimer;
  Timer? _statusTimer;
  bool _apiDone = false;
  AiRecommendationResponse? _report;

  late final List<String> _loadingStatuses = [
    'Initializing space analysis...',
    'Analyzing spatial metrics for ${widget.area.toStringAsFixed(0)} m²...',
    'Cross-referencing brand concept narrative...',
    'Synthesizing spatial constraints & allocations...',
    'Generating optimal functional layout grid...',
    'Rendering 3D architectural interior visualization...',
    'Compiling comprehensive Design Synthesis Report...',
  ];

  @override
  void initState() {
    super.initState();
    _startAiRecommendation();
    // Progress increment timer
    _progressTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      setState(() {
        if (_progress < 0.95 || _apiDone) {
          _progress += 0.01;
        }
        if (_progress >= 1.0) {
          _progress = 1.0;
          timer.cancel();
          _goToReport();
        }
      });
    });

    // Update status text message every 600ms
    _statusTimer = Timer.periodic(const Duration(milliseconds: 600), (timer) {
      if (_statusIndex < _loadingStatuses.length - 1) {
        setState(() {
          _statusIndex++;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _statusTimer?.cancel();
    super.dispose();
  }

  Future<void> _startAiRecommendation() async {
    try {
      if (widget.briefId <= 0) return;

      final existing = await AiRecommendationService.getRecommendations(
        briefId: widget.briefId,
        pageNumber: 1,
        pageSize: 1,
      );
      if (existing.items.isNotEmpty) {
        if (mounted) {
          setState(() {
            _report = existing.items.first;
          });
        }
        return;
      }

      final result = await AiRecommendationService.createRecommendation(
        briefId: widget.briefId,
        mustHaveZones: widget.mustHaveZones,
        niceToHaveZones: widget.niceToHaveZones,
        notes: widget.notes,
        generateImage: true,
        imageView: 0,
        detailLevel: 0,
        alternativesCount: 3,
        referenceImageUrls: widget.referenceImageUrls,
      );
      if (mounted) {
        setState(() {
          _report = result;
        });
      }
    } catch (e) {
      debugPrint('AI recommendation error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _apiDone = true;
        });
      }
    }
  }

  void _goToReport() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => AiDesignReportPage(
          cafeName: widget.cafeName,
          location: widget.location,
          style: widget.style,
          budgetLevel: widget.budgetLevel,
          totalBudget: widget.totalBudget,
          mood: widget.mood,
          role: widget.role,
          area: widget.area,
          report: _report,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Premium rotating abstract indicator resembling building layout or coffee cup
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.espresso.withOpacity(0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 70,
                        height: 70,
                        child: CircularProgressIndicator(
                          value: _progress,
                          strokeWidth: 4,
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF56642B)),
                          backgroundColor: AppColors.outlineVariant.withOpacity(0.3),
                        ),
                      ),
                      const Icon(
                        Icons.psychology_outlined,
                        size: 32,
                        color: AppColors.espresso,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 48),
              Text(
                'AI Design Synthesis',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.espresso,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _loadingStatuses[_statusIndex],
                  key: ValueKey<int>(_statusIndex),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              // Percentage number
              Text(
                '${(_progress * 100).toInt()}%',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.espresso,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AiDesignReportPage extends StatelessWidget {
  final String cafeName;
  final String location;
  final String style;
  final String budgetLevel;
  final double totalBudget;
  final String mood;
  final String role;
  final double area;
  final AiRecommendationResponse? report;

  const AiDesignReportPage({
    super.key,
    required this.cafeName,
    required this.location,
    required this.style,
    required this.budgetLevel,
    required this.totalBudget,
    required this.mood,
    required this.role,
    required this.area,
    this.report,
  });

  @override
  Widget build(BuildContext context) {
    // Generate ranges based on totalBudget
    double baseCost = report?.estimatedConstructionCost != null && report!.estimatedConstructionCost! > 0 
        ? report!.estimatedConstructionCost! 
        : totalBudget;
    double lowEstimate = baseCost * 0.9;
    double highEstimate = baseCost * 1.15;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.espresso),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          'AI Design Synthesis Report',
          style: GoogleFonts.playfairDisplay(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.espresso,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Premium banner header
              _buildReportHeader(lowEstimate, highEstimate),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (report?.conceptSummary != null && report!.conceptSummary.isNotEmpty) ...[
                      _buildConceptSummary(report!.conceptSummary),
                      const SizedBox(height: 32),
                    ],
                    // Space Analysis
                    _buildSpaceAnalysis(),
                    const SizedBox(height: 32),

                    // Functional Requirements
                    _buildFunctionalRequirements(),
                    const SizedBox(height: 32),

                    // 3D Layout Model section
                    _build3DLayoutModel(context),
                    const SizedBox(height: 32),

                    // Brand Identity
                    _buildBrandIdentity(),
                    const SizedBox(height: 32),

                    // Roadmap & Timeline
                    _buildRoadmapTimeline(),
                    const SizedBox(height: 48),

                    // Small disclaimer
                    Center(
                      child: Text(
                        'AI estimates are for conceptual reference only and should be certified by a building professional.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: AppColors.placeholder,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Final Action Buttons
                    // Primary CTA: Post directly to Marketplace (broadcast config step)
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProjectSuccessPage(
                              cafeName: cafeName,
                              location: location,
                              style: style,
                              budgetLevel: budgetLevel,
                              totalBudget: totalBudget,
                              mood: mood,
                              role: role,
                              area: area,
                              initialStep: 1, // Jump straight to Broadcast Config
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.podcasts_rounded, size: 18),
                      label: Text(
                        'Post to Marketplace',
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.espresso,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 56),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              // Show "Project Created" confirmation first
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProjectSuccessPage(
                                    cafeName: cafeName,
                                    location: location,
                                    style: style,
                                    budgetLevel: budgetLevel,
                                    totalBudget: totalBudget,
                                    mood: mood,
                                    role: role,
                                    area: area,
                                    initialStep: 0,
                                  ),
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.espresso,
                              side: const BorderSide(color: AppColors.espresso),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(
                              'Save to Dashboard',
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.maybePop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textSecondary,
                              side: BorderSide(color: AppColors.outlineVariant.withOpacity(0.7)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(
                              'Edit details',
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportHeader(double lowEstimate, double highEstimate) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.outlineVariant, width: 0.5)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFD9EAA3).withOpacity(0.4),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'SYNTHESIS REPORT',
                  style: GoogleFonts.inter(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF56642B),
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '•  AI generated design proposal',
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.placeholder),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            cafeName,
            style: GoogleFonts.playfairDisplay(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.espresso,
            ),
          ),
          Text(
            location,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildHeaderMetric('EST. COST', '\$${(lowEstimate / 1000).toStringAsFixed(0)}K - \$${(highEstimate / 1000).toStringAsFixed(0)}K', flex: 7),
              const SizedBox(width: 8),
              _buildHeaderMetric('EST. TIME', '12 - 16 Weeks', flex: 6),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildHeaderMetric('STYLE', style, flex: 7),
              const SizedBox(width: 8),
              _buildHeaderMetric('STATUS', 'Design Phase', flex: 6, isAccent: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderMetric(String label, String value, {required int flex, bool isAccent = false}) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F3F1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: AppColors.placeholder,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.playfairDisplay(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isAccent ? const Color(0xFF56642B) : AppColors.espresso,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConceptSummary(String summary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.psychology_outlined, size: 20, color: AppColors.espresso),
            const SizedBox(width: 8),
            Text(
              'AI Concept Summary',
              style: GoogleFonts.playfairDisplay(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.espresso,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          summary,
          style: GoogleFonts.inter(
            fontSize: 14,
            height: 1.6,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Map<String, int>? _parseZonesFromPayload() {
    final payloadTxt = report?.payload;
    if (payloadTxt == null || payloadTxt.isEmpty) return null;
    try {
      final jsonData = jsonDecode(payloadTxt);
      Map<String, dynamic>? zonesMap;
      if (jsonData is Map) {
        for (final key in ['zones', 'spaceAllocation', 'areas', 'zoneAllocation', 'layout']) {
          if (jsonData[key] is Map) {
            zonesMap = Map<String, dynamic>.from(jsonData[key] as Map);
            break;
          }
        }
      }
      if (zonesMap != null && zonesMap.isNotEmpty) {
        return zonesMap.map((k, v) => MapEntry(k, (v is int) ? v : (v as num).toInt()));
      }
    } catch (_) {}
    return null;
  }

  List<String> _getSpatialDetails() {
    final payloadTxt = report?.payload;
    if (payloadTxt != null && payloadTxt.isNotEmpty) {
      try {
        final jsonData = jsonDecode(payloadTxt);
        if (jsonData is Map) {
          for (final key in ['spatialDetails', 'spatialRecommendations', 'recommendations', 'details', 'suggestions']) {
            if (jsonData[key] is List) {
              final list = (jsonData[key] as List).whereType<String>().toList();
              if (list.isNotEmpty) return list.take(4).toList();
            }
          }
        }
      } catch (_) {}
    }
    final summary = report?.conceptSummary;
    if (summary != null && summary.isNotEmpty) {
      final sentences = summary
          .split(RegExp(r'(?<=[.!?])\s+'))
          .where((s) => s.trim().length > 20)
          .take(4)
          .toList();
      if (sentences.isNotEmpty) return sentences;
    }
    return [
      'Design layout optimized for $style aesthetic with natural flow circulation',
      'Accent zoning tailored for $mood atmosphere — warm lighting and material transitions',
      'Main service counter positioned for rapid throughput and visual hierarchy',
      'Spatial metrics calculated for ${area.toStringAsFixed(0)} m\u00B2 total floor area — ${(area * 0.6).toStringAsFixed(0)} m\u00B2 seating capacity',
    ];
  }

  Widget _buildSpaceAnalysis() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.architecture_outlined, size: 20, color: AppColors.espresso),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Space Analysis',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.espresso,
                ),
              ),
            ),
            Builder(builder: (context) {
              final aiZones = _parseZonesFromPayload();
              if (aiZones == null) return const SizedBox.shrink();
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFD9EAA3).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'AI GENERATED',
                  style: GoogleFonts.inter(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF56642B),
                    letterSpacing: 0.8,
                  ),
                ),
              );
            }),
          ],
        ),
        const SizedBox(height: 16),
        Builder(builder: (context) {
          final aiZones = _parseZonesFromPayload();
          final spatialDetails = _getSpatialDetails();

          int seatingPct = 60;
          int brewingPct = 22;
          int utilityPct = 18;
          String seatingLabel = 'Seating Area';
          String brewingLabel = 'Brewing Area';
          String utilityLabel = 'Utility Area';

          if (aiZones != null && aiZones.length >= 2) {
            final entries = aiZones.entries.toList();
            seatingLabel = entries[0].key;
            seatingPct = entries[0].value;
            brewingLabel = entries[1].key;
            brewingPct = entries[1].value;
            if (entries.length >= 3) {
              utilityLabel = entries[2].key;
              utilityPct = entries[2].value;
            } else {
              utilityPct = (100 - seatingPct - brewingPct).clamp(0, 100);
            }
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  height: 12,
                  child: Row(
                    children: [
                      Expanded(flex: seatingPct, child: Container(color: AppColors.espresso)),
                      Expanded(flex: brewingPct, child: Container(color: const Color(0xFFB19777))),
                      if (utilityPct > 0)
                        Expanded(flex: utilityPct, child: Container(color: const Color(0xFFDCD2C5))),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 6,
                children: [
                  _buildProportionLegend(seatingLabel, '$seatingPct%', AppColors.espresso),
                  _buildProportionLegend(brewingLabel, '$brewingPct%', const Color(0xFFB19777)),
                  if (utilityPct > 0)
                    _buildProportionLegend(utilityLabel, '$utilityPct%', const Color(0xFFDCD2C5)),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                aiZones != null ? 'AI SPATIAL RECOMMENDATIONS' : 'RECOMMENDED SPATIAL DETAILS',
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: AppColors.placeholder,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 12),
              ...spatialDetails.map((detail) => _buildBulletPoint(detail)),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildProportionLegend(String label, String pct, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$label ($pct)',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Icon(Icons.circle, size: 6, color: Color(0xFF56642B)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 13,
                height: 1.4,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getFunctionalRequirements() {
    final payloadTxt = report?.payload;
    if (payloadTxt != null && payloadTxt.isNotEmpty) {
      try {
        final json = jsonDecode(payloadTxt);
        if (json is Map && json.containsKey('functionalRequirements') && json['functionalRequirements'] is List) {
           final items = (json['functionalRequirements'] as List)
              .whereType<Map<String, dynamic>>()
              .take(4)
              .toList();
           if (items.isNotEmpty) return items;
        }
      } catch (_) {}
    }
    
    // Smart contextual fallbacks
    return [
      {
        'icon': Icons.volume_mute_outlined,
        'title': 'Acoustics & Flow',
        'desc': 'Acoustic treatment for sound buffers, spacing between tables matching the $style concept, ensuring quiet areas for focus.',
      },
      {
        'icon': Icons.wb_sunny_outlined,
        'title': 'Insulation Treatment',
        'desc': 'Double-glazed storefront window frame matching modern design conventions, ensuring optimal thermal and sound control.',
      },
      {
        'icon': Icons.lightbulb_outline,
        'title': 'Ergonomics & Lighting',
        'desc': 'Dimmable LED configurations, task illumination tailored for the $mood atmosphere, and dramatic brewing station backlights.',
      },
      {
        'icon': Icons.air,
        'title': 'Ventilation & Odor',
        'desc': 'Dedicated exhaust setup and active cross-ventilation, safeguarding high standard of air and brewing aroma quality.',
      },
    ];
  }

  Widget _buildFunctionalRequirements() {
    final reqs = _getFunctionalRequirements();
    bool isAiGen = report?.payload != null && report!.payload.contains('functionalRequirements');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.assignment_turned_in_outlined, size: 20, color: AppColors.espresso),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Functional Requirements',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.espresso,
                ),
              ),
            ),
            if (isAiGen)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFD9EAA3).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'AI GENERATED',
                  style: GoogleFonts.inter(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF56642B),
                    letterSpacing: 0.8,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        ...reqs.map((e) => _buildRequirementItem(
          e['icon'] as IconData? ?? Icons.settings_outlined,
          e['title']?.toString() ?? 'Requirement',
          e['desc']?.toString() ?? '...',
        )),
      ],
    );
  }

  Widget _buildRequirementItem(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.outlineVariant.withOpacity(0.4)),
            ),
            child: Icon(icon, color: AppColors.espresso, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.espresso,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    height: 1.4,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _extractImageUrl() {
    final payloadTxt = report?.payload;
    if (payloadTxt == null || payloadTxt.isEmpty) {
      return 'https://images.unsplash.com/photo-1554118811-1e0d58224f24?auto=format&fit=crop&q=80&w=800';
    }
    
    try {
      final json = jsonDecode(payloadTxt);
      if (json is Map) {
         // Check common image keys
         for (final key in ['imageUrls', 'imageUrl', 'image', 'url', 'image_url', 'view', 'layoutImage', '3dModel']) {
           if (json.containsKey(key)) {
             if (json[key] is List && (json[key] as List).isNotEmpty) {
               return json[key][0].toString();
             } else if (json[key] is String && (json[key] as String).isNotEmpty) {
               return json[key].toString();
             }
           }
         }
      }
      if (json is List && json.isNotEmpty) {
         return json.first.toString();
      }
    } catch (_) {}
    
    // Fallback: search for any URL ending in standard image formats or just use any URL in the payload
    final imageRegex = RegExp(r'https?:\/\/[^\s"\]\)]+\.(?:jpg|jpeg|png|webp|gif)', caseSensitive: false);
    final imgMatch = imageRegex.firstMatch(payloadTxt);
    if (imgMatch != null) return imgMatch.group(0)!;
    
    final regex = RegExp(r'https?:\/\/[^\s"\]\)]+');
    final match = regex.firstMatch(payloadTxt);
    if (match != null) {
      return match.group(0)!;
    }
    
    return 'https://images.unsplash.com/photo-1554118811-1e0d58224f24?auto=format&fit=crop&q=80&w=800';
  }

  void _showPayloadDetails(BuildContext context) {
    final payloadTxt = report?.payload;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          'AI Generated Technical Payload',
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold, color: AppColors.espresso),
        ),
        content: SingleChildScrollView(
          child: Text(
            (payloadTxt == null || payloadTxt.isEmpty) ? 'No payload data available from AI.' : payloadTxt,
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: GoogleFonts.inter(color: AppColors.espresso, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _build3DLayoutModel(BuildContext context) {
    final imageUrl = _extractImageUrl();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.blur_on_outlined, size: 20, color: AppColors.espresso),
            const SizedBox(width: 8),
            Text(
              '3D Layout Model [AI Generated]',
              style: GoogleFonts.playfairDisplay(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.espresso,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.outlineVariant.withOpacity(0.5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.network(
                      imageUrl,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 200,
                        color: Colors.grey[200],
                        child: const Center(child: Icon(Icons.broken_image, color: Colors.grey, size: 40)),
                      ),
                    ),
                    Container(
                      height: 200,
                      color: Colors.black.withOpacity(0.2),
                    ),
                    const Icon(
                      Icons.play_circle_outline_rounded,
                      size: 64,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Interactive spatial walk-through based on $style style.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => _showPayloadDetails(context),
                      icon: const Icon(Icons.thirteen_mp_outlined, size: 16),
                      label: Text(
                        'View details',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.espresso,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<String> _getBrandKeywords() {
    final payloadTxt = report?.payload;
    if (payloadTxt != null && payloadTxt.isNotEmpty) {
      try {
        final json = jsonDecode(payloadTxt);
        if (json is Map && json.containsKey('brandKeywords') && json['brandKeywords'] is List) {
           final items = (json['brandKeywords'] as List).whereType<String>().toList();
           if (items.isNotEmpty) return items;
        }
      } catch (_) {}
    }
    return ['Sophisticated', 'Minimal', mood, style, 'Dynamic', 'Premium'];
  }

  Widget _buildBrandIdentity() {
    final keywords = _getBrandKeywords();
    bool isAiGen = report?.payload != null && report!.payload.contains('brandKeywords');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.palette_outlined, size: 20, color: AppColors.espresso),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Brand Identity',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.espresso,
                ),
              ),
            ),
            if (isAiGen)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFD9EAA3).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'AI GENERATED',
                  style: GoogleFonts.inter(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF56642B),
                    letterSpacing: 0.8,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'PALETTE & ACCENTS',
          style: GoogleFonts.inter(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: AppColors.placeholder,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildColorBlock(AppColors.espresso, 'Espresso', 'Theme main'),
            const SizedBox(width: 12),
            _buildColorBlock(const Color(0xFFD9C3B0), 'Warm Sand', 'Theme secondary'),
            const SizedBox(width: 12),
            _buildColorBlock(const Color(0xFFFBF9F6), 'Soft Linen', 'Background base'),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'BRAND KEYWORDS',
          style: GoogleFonts.inter(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: AppColors.placeholder,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: keywords.take(6).map((w) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.outlineVariant.withOpacity(0.5)),
            ),
            child: Text(
              w.length > 20 ? w.substring(0, 20) : w,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.espresso,
              ),
            ),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildColorBlock(Color color, String name, String subtitle) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 60,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.outlineVariant.withOpacity(0.5)),
            ),
          ),
          const SizedBox(height: 6),
          Text(name, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.espresso)),
          Text(subtitle, style: GoogleFonts.inter(fontSize: 10, color: AppColors.placeholder)),
        ],
      ),
    );
  }

  List<Map<String, String>> _getTimeline() {
    final payloadTxt = report?.payload;
    if (payloadTxt != null && payloadTxt.isNotEmpty) {
      try {
        final json = jsonDecode(payloadTxt);
        if (json is Map && json.containsKey('timeline') && json['timeline'] is List) {
           final items = (json['timeline'] as List)
              .whereType<Map<String, dynamic>>()
              .map((e) => {
                'title': e['title']?.toString() ?? 'Phase',
                'desc': e['desc']?.toString() ?? e['description']?.toString() ?? '...',
              })
              .take(3)
              .toList();
           if (items.isNotEmpty) return items;
        }
      } catch (_) {}
    }
    return [
      {'title': 'Analysis & Concept (${budgetLevel})', 'desc': 'Weeks 1 - 4: Concept design reviews, schematic structural diagrams and material definitions tailored to the $style style.'},
      {'title': 'Layout & Blueprint', 'desc': 'Weeks 5 - 8: Technical blueprints detail, electrical mapping for $area m2, space permit approval files.'},
      {'title': 'Construction & Decoration', 'desc': 'Weeks 9 - 16: Interior masonry contracting, decor deployment & custom workspace fitting.'},
    ];
  }

  Widget _buildRoadmapTimeline() {
    final steps = _getTimeline();
    bool isAiGen = report?.payload != null && report!.payload.contains('timeline');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.timeline_outlined, size: 20, color: AppColors.espresso),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Roadmap & Timeline',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.espresso,
                ),
              ),
            ),
            if (isAiGen)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFD9EAA3).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'AI GENERATED',
                  style: GoogleFonts.inter(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF56642B),
                    letterSpacing: 0.8,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        ...steps.asMap().entries.map((e) => _buildTimelineStep(
          (e.key + 1).toString(),
          e.value['title']!,
          e.value['desc']!
        )),
      ],
    );
  }

  Widget _buildTimelineStep(String stepNumber, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: AppColors.espresso,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  stepNumber,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            Container(
              width: 2,
              height: 60,
              color: AppColors.outlineVariant.withOpacity(0.8),
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
                style: GoogleFonts.playfairDisplay(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.espresso,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  height: 1.4,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }
}
