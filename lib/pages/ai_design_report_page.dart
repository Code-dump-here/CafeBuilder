import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import 'project_success_page.dart';
import '../services/ai_recommendation_service.dart';
import '../models/responses/api_responses.dart';

// ── Loading / Synthesis page ─────────────────────────────────────────────────

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

class _DesignSynthesisLoadingPageState extends State<DesignSynthesisLoadingPage>
    with SingleTickerProviderStateMixin {
  int _statusIndex = 0;
  double _progress = 0.0;
  Timer? _progressTimer;
  Timer? _statusTimer;
  bool _apiDone = false;
  AiRecommendationResponse? _report;
  String _currentPollStatus = '';
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  late final List<String> _loadingStatuses = [
    'Initializing space analysis...',
    'Analyzing spatial metrics for ${widget.area.toStringAsFixed(0)} m²...',
    'Cross-referencing brand concept narrative...',
    'Synthesizing spatial constraints & allocations...',
    'Generating optimal functional layout grid...',
    'Rendering 3D architectural interior visualization...',
    'Compiling comprehensive Design Synthesis Report...',
    'Finalizing AI recommendations...',
  ];

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _startAiRecommendation();

    // Progress bar: slow drip until API done, then rush to 100%
    _progressTimer = Timer.periodic(const Duration(milliseconds: 120), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_apiDone) {
          _progress = (_progress + 0.06).clamp(0.0, 1.0);
        } else {
          // Approach 0.90 asymptotically while waiting
          if (_progress < 0.90) _progress += 0.005;
        }
        if (_progress >= 1.0) {
          _progress = 1.0;
          timer.cancel();
          _goToReport();
        }
      });
    });

    // Cycle status messages
    _statusTimer = Timer.periodic(const Duration(milliseconds: 2200), (timer) {
      if (!mounted) { timer.cancel(); return; }
      if (_statusIndex < _loadingStatuses.length - 1) {
        setState(() => _statusIndex++);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _statusTimer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _startAiRecommendation() async {
    try {
      if (widget.briefId <= 0) {
        setState(() => _apiDone = true);
        return;
      }

      // 1. Check if a recommendation already exists for this brief
      final existing = await AiRecommendationService.getRecommendations(
        briefId: widget.briefId,
        pageNumber: 1,
        pageSize: 1,
      );

      if (existing.items.isNotEmpty && existing.items.first.isCompleted) {
        if (mounted) setState(() { _report = existing.items.first; _apiDone = true; });
        return;
      }

      // 2. Create a new AI job (POST → 202 Accepted with queued job)
      final queued = await AiRecommendationService.createRecommendation(
        briefId: widget.briefId,
        mustHaveZones: widget.mustHaveZones,
        niceToHaveZones: widget.niceToHaveZones,
        notes: widget.notes,
        generateImage: true,
        alternativesCount: 1,
        referenceImageUrls: widget.referenceImageUrls,
      );

      if (mounted) setState(() => _currentPollStatus = 'AI job queued (id=${queued.id})…');

      // 3. Poll until completed
      final result = await AiRecommendationService.pollUntilComplete(
        queued.id,
        intervalSeconds: 5,
        maxAttempts: 36, // up to 3 minutes
        onPoll: (rec) {
          if (mounted) {
            setState(() => _currentPollStatus = 'AI job ${rec.state}…');
          }
        },
      );

      if (mounted) setState(() { _report = result; _apiDone = true; });
    } catch (e) {
      debugPrint('[AI Loading] error: $e');
      if (mounted) setState(() => _apiDone = true);
    }
  }

  void _goToReport() {
    if (!mounted) return;
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
              ScaleTransition(
                scale: _pulseAnim,
                child: Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.espresso.withOpacity(0.10),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 72,
                          height: 72,
                          child: CircularProgressIndicator(
                            value: _progress,
                            strokeWidth: 5,
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF56642B)),
                            backgroundColor: AppColors.outlineVariant.withOpacity(0.25),
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
                duration: const Duration(milliseconds: 400),
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
              const SizedBox(height: 32),
              Text(
                '${(_progress * 100).toInt()}%',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.espresso,
                ),
              ),
              if (_currentPollStatus.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  _currentPollStatus,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.placeholder,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── AI Design Report page ────────────────────────────────────────────────────

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

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _formatVnd(double amount) {
    if (amount >= 1e9) return '${(amount / 1e9).toStringAsFixed(1)} tỷ';
    if (amount >= 1e6) return '${(amount / 1e6).toStringAsFixed(0)} triệu';
    return amount.toStringAsFixed(0);
  }

  String _costRange() {
    final min = report?.fitoutMinVnd;
    final max = report?.fitoutMaxVnd;
    if (min != null && max != null) return '${_formatVnd(min)} – ${_formatVnd(max)} VND';
    // Fallback: use totalBudget
    return '${_formatVnd(totalBudget * 0.9)} – ${_formatVnd(totalBudget * 1.15)} VND';
  }

  String _equipRange() {
    final min = report?.equipmentMinVnd;
    final max = report?.equipmentMaxVnd;
    if (min != null && max != null) return '${_formatVnd(min)} – ${_formatVnd(max)} VND';
    return '—';
  }

  String _imageUrl() {
    final url = report?.imageArtifactUrl;
    if (url != null && url.isNotEmpty) return url;
    return 'https://images.unsplash.com/photo-1554118811-1e0d58224f24?auto=format&fit=crop&q=80&w=800';
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
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
              _buildReportHeader(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Concept name & plan summary
                    if (report?.planConceptName != null) ...[
                      _buildConceptName(report!.planConceptName!),
                      const SizedBox(height: 24),
                    ],
                    if (report?.conceptSummary.isNotEmpty == true) ...[
                      _buildConceptSummary(report!.conceptSummary),
                      const SizedBox(height: 24),
                    ],
                    if (report?.planSummary?.isNotEmpty == true) ...[
                      _buildPlanSummary(report!.planSummary!),
                      const SizedBox(height: 32),
                    ],

                    // 3D Layout Image
                    _build3DLayoutImage(context),
                    const SizedBox(height: 32),

                    // Layout zones grid
                    if (report?.layoutZones.isNotEmpty == true) ...[
                      _buildLayoutZones(),
                      const SizedBox(height: 32),
                    ],

                    // Customer flow
                    if (report?.customerFlow.isNotEmpty == true) ...[
                      _buildCustomerFlow(),
                      const SizedBox(height: 32),
                    ],

                    // Costs
                    _buildCostBreakdown(context),
                    const SizedBox(height: 32),

                    // AI Recommendations
                    if (report?.recommendations.isNotEmpty == true) ...[
                      _buildAiRecommendations(),
                      const SizedBox(height: 32),
                    ],

                    // Risk notes
                    if (report?.riskNotes.isNotEmpty == true) ...[
                      _buildRiskNotes(),
                      const SizedBox(height: 32),
                    ],

                    // Seat capacity
                    if (report?.seatCapacityRecommendation != null) ...[
                      _buildSeatCapacity(report!.seatCapacityRecommendation!),
                      const SizedBox(height: 32),
                    ],

                    // Disclaimer
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

                    // CTA buttons
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
                              initialStep: 1,
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

  // ── Section builders ───────────────────────────────────────────────────────

  Widget _buildReportHeader() {
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
              if (report?.state != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: report!.isCompleted
                        ? const Color(0xFFD9EAA3).withOpacity(0.4)
                        : Colors.orange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    report!.state!.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: report!.isCompleted ? const Color(0xFF56642B) : Colors.orange[700],
                    ),
                  ),
                )
              else
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
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildHeaderMetric('FIT-OUT COST', _costRange(), flex: 7),
              const SizedBox(width: 8),
              _buildHeaderMetric('EQUIPMENT', _equipRange(), flex: 6),
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

  Widget _buildHeaderMetric(String label, String value,
      {required int flex, bool isAccent = false}) {
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
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isAccent ? const Color(0xFF56642B) : AppColors.espresso,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConceptName(String name) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3E2A1E), Color(0xFF5C3D2E)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI CONCEPT NAME',
                    style: GoogleFonts.inter(fontSize: 8, color: Colors.white54, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                const SizedBox(height: 4),
                Text(name,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConceptSummary(String summary) {
    return _sectionCard(
      icon: Icons.psychology_outlined,
      title: 'AI Concept Summary',
      badge: 'AI GENERATED',
      child: Text(
        summary,
        style: GoogleFonts.inter(fontSize: 13, height: 1.6, color: AppColors.textSecondary),
      ),
    );
  }

  Widget _buildPlanSummary(String summary) {
    return _sectionCard(
      icon: Icons.summarize_outlined,
      title: 'Plan Summary',
      child: Text(
        summary,
        style: GoogleFonts.inter(fontSize: 13, height: 1.6, color: AppColors.textSecondary),
      ),
    );
  }

  Widget _build3DLayoutImage(BuildContext context) {
    final url = _imageUrl();
    final hasRealImage = report?.imageArtifactUrl?.isNotEmpty == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.blur_on_outlined, size: 20, color: AppColors.espresso),
            const SizedBox(width: 8),
            Text(
              '3D Layout Visualization',
              style: GoogleFonts.playfairDisplay(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.espresso,
              ),
            ),
            const Spacer(),
            if (hasRealImage)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFD9EAA3).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('AI RENDERED',
                    style: GoogleFonts.inter(
                        fontSize: 8, fontWeight: FontWeight.bold, color: const Color(0xFF56642B))),
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
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.network(
              url,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, _, __) => Container(
                height: 200,
                color: Colors.grey[100],
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.image_not_supported_outlined, color: Colors.grey, size: 40),
                      SizedBox(height: 8),
                      Text('Image not available', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (report?.imageView != null) ...[
          const SizedBox(height: 8),
          Text(
            'View type: ${report!.imageView}',
            style: GoogleFonts.inter(fontSize: 11, color: AppColors.placeholder),
          ),
        ],
      ],
    );
  }

  Widget _buildLayoutZones() {
    final zones = report!.layoutZones;
    return _sectionCard(
      icon: Icons.grid_view_rounded,
      title: 'Layout Zones',
      badge: 'AI GENERATED',
      child: Column(
        children: zones.map((z) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: z.isStaffOnly
                        ? const Color(0xFFF0E6D3)
                        : const Color(0xFFD9EAA3).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    z.id,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: z.isStaffOnly ? const Color(0xFF8B5E3C) : const Color(0xFF56642B),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            z.label,
                            style: GoogleFonts.inter(
                                fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                          ),
                          if (z.isStaffOnly) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text('STAFF',
                                  style: GoogleFonts.inter(
                                      fontSize: 8, fontWeight: FontWeight.bold, color: Colors.orange[800])),
                            ),
                          ],
                          const Spacer(),
                          Text(
                            '${z.w.toStringAsFixed(0)}×${z.h.toStringAsFixed(0)} m',
                            style: GoogleFonts.inter(fontSize: 11, color: AppColors.placeholder),
                          ),
                        ],
                      ),
                      if (z.purpose.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          z.purpose,
                          style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary, height: 1.4),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCustomerFlow() {
    final stages = report!.customerFlow;
    return _sectionCard(
      icon: Icons.route_outlined,
      title: 'Customer Flow',
      badge: 'AI GENERATED',
      child: Row(
        children: stages.asMap().entries.map((entry) {
          final i = entry.key;
          final s = entry.value;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.espresso,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${i + 1}',
                            style: GoogleFonts.inter(
                                fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        s.stage.replaceAll('_', ' '),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: AppColors.espresso,
                        ),
                      ),
                    ],
                  ),
                ),
                if (i < stages.length - 1)
                  const Icon(Icons.arrow_forward_ios, size: 10, color: AppColors.placeholder),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCostBreakdown(BuildContext context) {
    return _sectionCard(
      icon: Icons.account_balance_wallet_outlined,
      title: 'Cost Breakdown',
      badge: 'AI ESTIMATED',
      child: Column(
        children: [
          _buildCostRow('Fit-out (construction)', _costRange(), isHighlight: true),
          const SizedBox(height: 12),
          _buildCostRow('Equipment', _equipRange()),
          if (report?.contingencyPercent != null) ...[
            const SizedBox(height: 12),
            _buildCostRow(
              'Contingency',
              '${report!.contingencyPercent!.toStringAsFixed(0)}%',
            ),
          ],
          if (report?.costNotes?.isNotEmpty == true) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F3F1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, size: 14, color: AppColors.placeholder),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      report!.costNotes!,
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCostRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: isHighlight ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.playfairDisplay(
            fontSize: isHighlight ? 15 : 13,
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
            color: isHighlight ? AppColors.espresso : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildAiRecommendations() {
    final sorted = List<AiRecommendationItem>.from(report!.recommendations)
      ..sort((a, b) => b.priority.compareTo(a.priority));

    return _sectionCard(
      icon: Icons.lightbulb_outline,
      title: 'AI Recommendations',
      badge: 'AI GENERATED',
      child: Column(
        children: sorted.map((r) {
          final priorityColor = r.priority >= 3
              ? const Color(0xFF56642B)
              : r.priority == 2
                  ? Colors.orange[700]!
                  : AppColors.textSecondary;
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: priorityColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.star, size: 12, color: priorityColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.title,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          height: 1.4,
                        ),
                      ),
                      if (r.rationale.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          r.rationale,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRiskNotes() {
    return _sectionCard(
      icon: Icons.warning_amber_outlined,
      title: 'Risk Assessment',
      badge: 'AI GENERATED',
      child: Column(
        children: report!.riskNotes.map((risk) {
          final levelColor = risk.level == 'high'
              ? Colors.red[700]!
              : risk.level == 'medium'
                  ? Colors.orange[700]!
                  : const Color(0xFF56642B);
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: levelColor.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: levelColor.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: levelColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          risk.level.toUpperCase(),
                          style: GoogleFonts.inter(
                              fontSize: 8, fontWeight: FontWeight.bold, color: levelColor, letterSpacing: 0.5),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          risk.title,
                          style: GoogleFonts.inter(
                              fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    risk.description,
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                  ),
                  if (risk.mitigation?.isNotEmpty == true) ...[
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.shield_outlined, size: 13, color: Color(0xFF56642B)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Mitigation: ${risk.mitigation}',
                            style: GoogleFonts.inter(
                                fontSize: 11, color: const Color(0xFF56642B), height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSeatCapacity(int seats) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFD9EAA3).withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF56642B).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.chair_outlined, color: Color(0xFF56642B), size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RECOMMENDED SEAT CAPACITY',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF56642B),
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$seats seats',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.espresso,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Reusable card wrapper ──────────────────────────────────────────────────

  Widget _sectionCard({
    required IconData icon,
    required String title,
    String? badge,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: AppColors.espresso),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.espresso,
                ),
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFD9EAA3).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badge,
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
        child,
      ],
    );
  }
}
