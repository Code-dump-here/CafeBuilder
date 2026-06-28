import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import 'project_success_page.dart';

class DesignSynthesisLoadingPage extends StatefulWidget {
  final String cafeName;
  final String location;
  final String style;
  final String budgetLevel;
  final double totalBudget;
  final String mood;
  final String role;
  final double area;

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
  });

  @override
  State<DesignSynthesisLoadingPage> createState() => _DesignSynthesisLoadingPageState();
}

class _DesignSynthesisLoadingPageState extends State<DesignSynthesisLoadingPage> {
  int _statusIndex = 0;
  double _progress = 0.0;
  Timer? _progressTimer;
  Timer? _statusTimer;

  final List<String> _loadingStatuses = [
    'Initializing space analysis...',
    'Analyzing spatial metrics for ${225.toInt()} m²...',
    'Cross-referencing brand concept narrative...',
    'Synthesizing spatial constraints & allocations...',
    'Generating optimal functional layout grid...',
    'Rendering 3D architectural interior visualization...',
    'Compiling comprehensive Design Synthesis Report...',
  ];

  @override
  void initState() {
    super.initState();
    // Progress increment timer
    _progressTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      setState(() {
        _progress += 0.01;
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
  });

  @override
  Widget build(BuildContext context) {
    // Generate ranges based on totalBudget
    double lowEstimate = totalBudget * 0.9;
    double highEstimate = totalBudget * 1.15;

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
                    // Space Analysis
                    _buildSpaceAnalysis(),
                    const SizedBox(height: 32),

                    // Functional Requirements
                    _buildFunctionalRequirements(),
                    const SizedBox(height: 32),

                    // 3D Layout Model section
                    _build3DLayoutModel(),
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

  Widget _buildSpaceAnalysis() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.architecture_outlined, size: 20, color: AppColors.espresso),
            const SizedBox(width: 8),
            Text(
              'Space Analysis',
              style: GoogleFonts.playfairDisplay(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.espresso,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Layout Proportion Bar
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 12,
            child: Row(
              children: [
                Expanded(
                  flex: 60,
                  child: Container(color: AppColors.espresso),
                ),
                Expanded(
                  flex: 22,
                  child: Container(color: const Color(0xFFB19777)),
                ),
                Expanded(
                  flex: 18,
                  child: Container(color: const Color(0xFFDCD2C5)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildProportionLegend('Seating Area', '60%', AppColors.espresso),
            _buildProportionLegend('Brewing Area', '22%', const Color(0xFFB19777)),
            _buildProportionLegend('Utility Area', '18%', const Color(0xFFDCD2C5)),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'RECOMMENDED SPATIAL DETAILS',
          style: GoogleFonts.inter(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: AppColors.placeholder,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 12),
        _buildBulletPoint('Maximize natural light from storefront (8.0m wide window design)'),
        _buildBulletPoint('Incorporate warm, subtle accent zoning (ideal for $mood vibe)'),
        _buildBulletPoint('Ensure clearance around main POS bar to accommodate target audience'),
        _buildBulletPoint('Optimize layout based on calculated ground floor spatial metrics (${225.toInt()} m²)'),
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

  Widget _buildFunctionalRequirements() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.assignment_turned_in_outlined, size: 20, color: AppColors.espresso),
            const SizedBox(width: 8),
            Text(
              'Functional Requirements',
              style: GoogleFonts.playfairDisplay(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.espresso,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildRequirementItem(
          Icons.volume_mute_outlined,
          'Acoustics & Flow',
          'Acoustic treatment for sound buffers, spacing between tables matching the concept, ensuring quiet areas for focus.',
        ),
        _buildRequirementItem(
          Icons.wb_sunny_outlined,
          'Insulation Treatment',
          'Double-glazed storefront window frame matching modern design conventions, ensuring optimal thermal and sound control.',
        ),
        _buildRequirementItem(
          Icons.lightbulb_outline,
          'Ergonomics & Lighting',
          'Dimmable LED configurations, task illumination for individual seats, and dramatic brewing station backlights.',
        ),
        _buildRequirementItem(
          Icons.air,
          'Ventilation & Odor',
          'Dedicated exhaust setup and active cross-ventilation, safeguarding high standard of air and brewing aroma quality.',
        ),
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

  Widget _build3DLayoutModel() {
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
                      'https://images.unsplash.com/photo-1554118811-1e0d58224f24?auto=format&fit=crop&q=80&w=800',
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
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
                      onPressed: () {},
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

  Widget _buildBrandIdentity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.palette_outlined, size: 20, color: AppColors.espresso),
            const SizedBox(width: 8),
            Text(
              'Brand Identity',
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
          children: [
            'Sophisticated',
            'Minimal',
            mood,
            style,
            'Serene',
            'Professional',
          ].map((w) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.outlineVariant.withOpacity(0.5)),
            ),
            child: Text(
              w,
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

  Widget _buildRoadmapTimeline() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.timeline_outlined, size: 20, color: AppColors.espresso),
            const SizedBox(width: 8),
            Text(
              'Roadmap & Timeline',
              style: GoogleFonts.playfairDisplay(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.espresso,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildTimelineStep('1', 'Analysis & Sketch', 'Weeks 1 - 4: Concept design reviews, schematic structural diagrams and material definitions.'),
        _buildTimelineStep('2', 'Layout & Plan', 'Weeks 5 - 8: Technical blueprints detail, electrical mapping, space permit approval files.'),
        _buildTimelineStep('3', 'Construction & Decoration', 'Weeks 9 - 16: Interior masonry contracting, decor deployment & custom workspace fitting.'),
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
