import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../models/marketplace_state.dart';
import '../services/api_client.dart';
import '../services/post_service.dart';
import '../models/responses/api_responses.dart';

class ProjectSuccessPage extends StatefulWidget {
  final String cafeName;
  final String location;
  final String style;
  final String budgetLevel;
  final double totalBudget;
  final String mood;
  final String role;
  final double area;
  final int projectId;
  final int initialStep;
  final AiRecommendationResponse? aiReport;

  const ProjectSuccessPage({
    super.key,
    required this.cafeName,
    required this.location,
    required this.style,
    required this.budgetLevel,
    required this.totalBudget,
    required this.mood,
    required this.role,
    required this.area,
    this.projectId = 0,
    this.initialStep = 0,
    this.aiReport,
  });

  @override
  State<ProjectSuccessPage> createState() => _ProjectSuccessPageState();
}

class _ProjectSuccessPageState extends State<ProjectSuccessPage> {
  late int _flowSubStep;

  // Broadcast settings
  final List<String> _reqs = ['Designer'];
  String _visibility = 'Public'; // Public or Restricted
  String _expectedStart = 'Oct 2024';
  late String _budgetTier;
  late DateTime _submissionDeadline;

  @override
  void initState() {
    super.initState();
    _flowSubStep = widget.initialStep;
    // Compute budget tier
    double lowEstimate = widget.totalBudget * 0.9;
    double highEstimate = widget.totalBudget * 1.15;
    _budgetTier =
        '${(lowEstimate / 1000000).toStringAsFixed(0)}M – ${(highEstimate / 1000000).toStringAsFixed(0)}M VND';
    
    final now = DateTime.now().add(const Duration(days: 30));
    _submissionDeadline = DateTime(now.year, now.month, now.day, 23, 59, 59);
  }

  Future<void> _selectDeadline(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _submissionDeadline,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.espresso, // header background color
              onPrimary: Colors.white, // header text color
              onSurface: AppColors.espresso, // body text color
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      final deadline = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
      if (!deadline.isAfter(DateTime.now())) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Submission deadline must be later than the current time.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      setState(() => _submissionDeadline = deadline);
    }
  }

  bool _isDeadlineValid() => _submissionDeadline.isAfter(DateTime.now());

  Future<void> _onBroadcastToMarketplace() async {
    // projectId and the shop-owner's own profile id are different id
    // spaces — falling back from one to the other would silently attach
    // this broadcast to whatever unrelated project happens to share that
    // numeric id. Fail loudly instead of guessing; every current caller
    // already passes a real projectId, so this should never actually fire.
    if (widget.projectId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Missing project reference. Please go back and try again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_isDeadlineValid()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Submission deadline must be later than the current time.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator(color: AppColors.espresso)),
    );

    // Declared out here so the catch block's fallback can reuse it — a copy
    // scoped inside try{} isn't visible from catch{}.
    String detailedDescription =
        'Redesign of space into a premium ${widget.style.toLowerCase()} cafe inspired by ${widget.mood.toLowerCase()} atmosphere.\nLocation: ${widget.location}\nStyle: ${widget.style}\nBudget: $_budgetTier\nExpected Start: $_expectedStart';

    try {
      // Map UI requirements to backend serviceKind enum
      bool hasDesign = _reqs.contains('Designer') || _reqs.contains('Both');
      bool hasBuild = _reqs.contains('Constructor') || _reqs.contains('Both');
      String mappedServiceKind = 'design';
      if (hasDesign && hasBuild) {
        mappedServiceKind = 'both';
      } else if (hasBuild) {
        mappedServiceKind = 'construction';
      }

      if (widget.aiReport != null) {
        final r = widget.aiReport!;
        final buffer = StringBuffer();
        buffer.writeln(detailedDescription);
        buffer.writeln('\n--- AI DESIGN SYNTHESIS ---');
        
        if (r.planConceptName != null) {
          buffer.writeln('\n✨ CONCEPT: ${r.planConceptName}');
        }
        if (r.conceptSummary.isNotEmpty) {
          buffer.writeln('\n📝 SUMMARY:\n${r.conceptSummary}');
        }
        if (r.planSummary != null && r.planSummary!.isNotEmpty) {
          buffer.writeln('\n📐 PLAN SUMMARY:\n${r.planSummary}');
        }
        if (r.layoutZones.isNotEmpty) {
          buffer.writeln('\n🏢 LAYOUT ZONES:');
          for (var z in r.layoutZones) {
            buffer.writeln('• ${z.label}: ${(z.w * z.h).toStringAsFixed(1)}m² (${z.purpose})');
          }
        }
        if (r.seatCapacityRecommendation != null) {
          buffer.writeln('\n🪑 RECOMMENDED SEATS: ${r.seatCapacityRecommendation}');
        }
        if (r.imageArtifactUrl != null && r.imageArtifactUrl!.isNotEmpty) {
          buffer.writeln('\n🖼️ AI_IMAGE: ${r.imageArtifactUrl}');
        }
        detailedDescription = buffer.toString();
      }

      final request = CreatePostRequest(
        projectShopOwnerId: widget.projectId,
        serviceKind: mappedServiceKind,
        title: widget.cafeName,
        description: detailedDescription,
        submissionDeadline: _submissionDeadline,
      );
      
      final post = await PostService.createPost(request);
      
      if (mounted) {
        Navigator.pop(context); // hide loading
        
        final aiImageUrl = widget.aiReport?.imageArtifactUrl;
        final newBroadcast = BroadcastProject(
          id: post.id.toString(),
          title: post.title,
          location: post.location,
          style: post.style,
          budgetTier: post.budgetTier,
          description: post.description,
          requirements: post.requirements,
          date: post.expectedStart,
          proposalsCount: 0,
          commentsCount: 0,
          status: 'Open for Proposals',
          imageUrl: (aiImageUrl != null && aiImageUrl.isNotEmpty)
              ? aiImageUrl
              : 'https://images.unsplash.com/photo-1498804103079-a6351b050096?auto=format&fit=crop&q=80&w=600',
        );

        // Save to global list and notify MarketplacePage to rebuild
        MarketplaceState.activeProject = newBroadcast;
        MarketplaceState.addBroadcast(newBroadcast);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Project posted to marketplace.')),
        );
        // Straight to Home instead of the "Project Live" splash (step 2).
        // `onNeedsRefresh` tells the still-alive Home instance to
        // re-fetch, since popping back to it doesn't run any of its own
        // refresh logic on its own.
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // hide loading

        // The post was NOT created. Stay on this step so the user can retry —
        // never advance to "Project Live", which would claim a broadcast that
        // the backend never received.
        final message = e is ApiException ? e.message : 'Could not reach the server.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Broadcast failed: $message'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'RETRY',
              textColor: Colors.white,
              onPressed: _onBroadcastToMarketplace,
            ),
          ),
        );
      }
    }
  }

  void _handleBackNavigation() {
    if (_flowSubStep == 1) {
      Navigator.of(context).pop();
      return;
    }
    if (_flowSubStep == 0) {
      Navigator.of(context).pop();
    }
  }

  bool get _canPopDirectly => _flowSubStep == 0 || _flowSubStep == 1;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _canPopDirectly,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBackNavigation();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildFlowContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildFlowContent() {
    switch (_flowSubStep) {
      case 0:
        return _buildSuccessStep();
      case 1:
        return _buildBroadcastConfigStep();
      case 2:
        return _buildProjectLiveStep();
      default:
        return Container();
    }
  }

  // --- STEP 0: Project Successfully Created! ---
  Widget _buildSuccessStep() {
    return Padding(
      key: const ValueKey<int>(0),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          // Success badge icon
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: Color(0xFFD9EAA3),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.architecture_rounded, color: Color(0xFF56642B), size: 36),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Project Successfully Created!',
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.espresso,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Your coffee shop concept is ready to take flight. Our platform is now ready to connect you with world-class specialists.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          // Project Brief Card
          Container(
            width: double.infinity,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  child: Image.network(
              webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                    'https://images.unsplash.com/photo-1554118811-1e0d58224f24?auto=format&fit=crop&q=80&w=500',
                    height: 140,
                    fit: BoxFit.cover,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF6F3F1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'New Project  • Just Now',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.espresso,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.cafeName,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.espresso,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('LOCATION', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.placeholder)),
                                const SizedBox(height: 4),
                                Text(widget.location, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.espresso)),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('STYLE PROFILE', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.placeholder)),
                                const SizedBox(height: 4),
                                Text(widget.style, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.espresso)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Buttons
          ElevatedButton.icon(
            onPressed: () => setState(() => _flowSubStep = 1),
            icon: const Icon(Icons.podcasts_rounded, size: 18),
            label: Text(
              'Share to Marketplace',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.espresso,
              foregroundColor: Colors.white,
              elevation: 0,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
            },
            icon: const Icon(Icons.people_alt_outlined, size: 18),
            label: Text(
              'Select Partners Manually',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.espresso,
              side: const BorderSide(color: AppColors.espresso),
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
            },
            child: Text(
              'Back to Home',
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- STEP 1: Project Broadcast Config ---
  Widget _buildBroadcastConfigStep() {
    return Column(
      key: const ValueKey<int>(1),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Back toolbar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.espresso),
                onPressed: _handleBackNavigation,
              ),
              const SizedBox(width: 8),
              Text(
                'Project Broadcast',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.espresso,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CURRENT SELECTION',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: AppColors.placeholder,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.outlineVariant.withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
              webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                          'https://images.unsplash.com/photo-1554118811-1e0d58224f24?auto=format&fit=crop&q=80&w=200',
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD9EAA3).withOpacity(0.4),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                widget.style,
                                style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.bold, color: const Color(0xFF56642B)),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.cafeName,
                              style: GoogleFonts.playfairDisplay(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.espresso),
                            ),
                            Text(
                              widget.location,
                              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'SERVICE REQUIREMENTS',
                      style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.placeholder, letterSpacing: 1.0),
                    ),
                    Text(
                      'Select one',
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.placeholder),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildServiceCheckbox('Designer', 'Interior and architectural design'),
                _buildServiceCheckbox('Constructor', 'Full project construction and build'),
                _buildServiceCheckbox('Both', 'End-to-end design and construction'),
                const SizedBox(height: 28),
                Text(
                  'VISIBILITY SETTINGS',
                  style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.placeholder, letterSpacing: 1.0),
                ),
                const SizedBox(height: 12),
                _buildVisibilityRadio('Public Broadcast', 'All verified professionals', true),
                _buildVisibilityRadio('Restricted', 'Invite-only selection', false),
                const SizedBox(height: 28),
                Text(
                  'PROJECT PARAMETERS',
                  style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.placeholder, letterSpacing: 1.0),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: const Color(0xFFF6F3F1), borderRadius: BorderRadius.circular(10)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Expected Start', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.placeholder)),
                            const SizedBox(height: 4),
                            Text(_expectedStart, style: GoogleFonts.playfairDisplay(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.espresso)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: const Color(0xFFF6F3F1), borderRadius: BorderRadius.circular(10)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Budget Tier', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.placeholder)),
                            const SizedBox(height: 4),
                            Text(_budgetTier, style: GoogleFonts.playfairDisplay(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.espresso)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => _selectDeadline(context),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: const Color(0xFFF6F3F1), borderRadius: BorderRadius.circular(10)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Submission Deadline (Tap to change)', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.placeholder)),
                        const SizedBox(height: 4),
                        Text('${_submissionDeadline.day.toString().padLeft(2, '0')}/${_submissionDeadline.month.toString().padLeft(2, '0')}/${_submissionDeadline.year}', style: GoogleFonts.playfairDisplay(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.espresso)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'By broadcasting, you agree to our Project Sharing Terms.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.placeholder),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _onBroadcastToMarketplace,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.espresso,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(
                  'BROADCAST TO MARKETPLACE',
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildServiceCheckbox(String title, String desc) {
    bool isChecked = _reqs.contains(title);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () {
          setState(() {
            if (!isChecked) {
              _reqs.clear();
              _reqs.add(title);
            }
          });
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isChecked ? AppColors.espresso : AppColors.outlineVariant.withOpacity(0.5),
              width: isChecked ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isChecked ? Icons.check_box : Icons.check_box_outline_blank,
                color: isChecked ? AppColors.espresso : AppColors.placeholder,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.playfairDisplay(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.espresso),
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
        ),
      ),
    );
  }

  Widget _buildVisibilityRadio(String title, String desc, bool isPublic) {
    bool selected = (isPublic && _visibility == 'Public') || (!isPublic && _visibility == 'Restricted');
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _visibility = isPublic ? 'Public' : 'Restricted';
          });
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? AppColors.espresso : AppColors.outlineVariant.withOpacity(0.5),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isPublic ? Icons.public : Icons.lock_outline,
                color: selected ? AppColors.espresso : AppColors.placeholder,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.playfairDisplay(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.espresso),
                    ),
                    Text(
                      desc,
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Radio<String>(
                value: isPublic ? 'Public' : 'Restricted',
                groupValue: _visibility,
                activeColor: AppColors.espresso,
                onChanged: (val) {
                  if (val != null) setState(() => _visibility = val);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- STEP 2: Project Done & Live! ---
  Widget _buildProjectLiveStep() {
    final active = MarketplaceState.activeProject;
    // Only ever set from a real backend response — never invent an ID here.
    final bId = active?.id;
    return Padding(
      key: const ValueKey<int>(2),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          // Success badge icon
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: Color(0xFFD9EAA3),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.check, color: Color(0xFF56642B), size: 36),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Project Live',
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.espresso,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Your "${widget.cafeName}" brief is now visible to our curated network of professionals.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          // Info logs
          _buildLiveNotificationCard(
            Icons.access_time,
            'Awaiting Proposals',
            'Our certified interior designers and project managers will review your brief. Expect high-quality offers within 24-48 hours.',
          ),
          const SizedBox(height: 12),
          _buildLiveNotificationCard(
            Icons.notifications_active_outlined,
            'Notification Alerts',
            'Stay updated in real-time. You will receive an instant push notification and email the moment a professional submits a proposal.',
          ),
          const SizedBox(height: 24),
          // Live tag preview
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.outlineVariant.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
              webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                    'https://images.unsplash.com/photo-1498804103079-a6351b050096?auto=format&fit=crop&q=80&w=200',
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
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD9EAA3).withOpacity(0.4),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '• ACTIVE BROADCAST',
                          style: GoogleFonts.inter(
                            fontSize: 7,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF56642B),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.cafeName,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.espresso,
                        ),
                      ),
                      if (bId != null)
                        Text(
                          'Broadcast ID: $bId',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.placeholder,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Primary: Go see project on Marketplace
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to the Marketplace tab (index 3)
              MarketplaceState.initialIndex = 3;
              if (MarketplaceState.onRoleChanged != null) {
                MarketplaceState.onRoleChanged!();
              }
              Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
            },
            icon: const Icon(Icons.store_mall_directory_rounded, size: 18),
            label: Text(
              'View on Marketplace',
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.espresso,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
          const SizedBox(height: 12),
          // Secondary: Just go back to dashboard
          OutlinedButton(
            onPressed: () {
              MarketplaceState.initialIndex = 0;
              Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.espresso,
              side: const BorderSide(color: AppColors.espresso),
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'Back to Dashboard',
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveNotificationCard(IconData icon, String title, String desc) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFD9EAA3).withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF56642B), size: 18),
          ),
          const SizedBox(width: 14),
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
                    fontSize: 11,
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
}
