import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../models/marketplace_state.dart';
import '../services/post_service.dart';

class ProjectSuccessPage extends StatefulWidget {
  final String cafeName;
  final String location;
  final String style;
  final String budgetLevel;
  final double totalBudget;
  final String mood;
  final String role;
  final double area;
  final int initialStep;

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
    this.initialStep = 0,
  });

  @override
  State<ProjectSuccessPage> createState() => _ProjectSuccessPageState();
}

class _ProjectSuccessPageState extends State<ProjectSuccessPage> {
  late int _flowSubStep;

  // Broadcast settings
  final List<String> _reqs = ['Interior Design', 'MEP Engineering'];
  String _visibility = 'Public'; // Public or Restricted
  String _expectedStart = 'Oct 2024';
  late String _budgetTier;

  @override
  void initState() {
    super.initState();
    _flowSubStep = widget.initialStep;
    // Compute budget tier
    double lowEstimate = widget.totalBudget * 0.9;
    double highEstimate = widget.totalBudget * 1.15;
    _budgetTier = '\$${(lowEstimate / 1000).toStringAsFixed(0)}k – \$${(highEstimate / 1000).toStringAsFixed(0)}k';
  }

  Future<void> _onBroadcastToMarketplace() async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator(color: AppColors.espresso)),
    );

    try {
      // API call to create post
      final request = CreatePostRequest(
        title: widget.cafeName,
        description: 'Redesign of space into a premium ${widget.style.toLowerCase()} cafe inspired by ${widget.mood.toLowerCase()} atmosphere.',
        location: widget.location,
        style: widget.style,
        budgetTier: _budgetTier,
        expectedStart: _expectedStart,
        requirements: _reqs,
      );
      
      final post = await PostService.createPost(request);
      
      if (mounted) {
        Navigator.pop(context); // hide loading
        
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
          imageUrl: 'https://images.unsplash.com/photo-1498804103079-a6351b050096?auto=format&fit=crop&q=80&w=600',
        );

        // Save to global list and notify MarketplacePage to rebuild
        MarketplaceState.activeProject = newBroadcast;
        MarketplaceState.addBroadcast(newBroadcast);

        setState(() {
          _flowSubStep = 2;
        });
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // hide loading
        // Fallback to local logic if API fails
        final id = 'AT-${100 + Random().nextInt(899)}-XC';
        final newBroadcast = BroadcastProject(
          id: id,
          title: widget.cafeName,
          location: widget.location,
          style: widget.style,
          budgetTier: _budgetTier,
          description: 'Redesign of space into a premium ${widget.style.toLowerCase()} cafe inspired by ${widget.mood.toLowerCase()} atmosphere.',
          requirements: _reqs,
          date: _expectedStart,
          proposalsCount: 0,
          commentsCount: 0,
          status: 'Open for Proposals',
          imageUrl: 'https://images.unsplash.com/photo-1498804103079-a6351b050096?auto=format&fit=crop&q=80&w=600',
        );

        MarketplaceState.activeProject = newBroadcast;
        MarketplaceState.addBroadcast(newBroadcast);

        setState(() {
          _flowSubStep = 2;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildFlowContent(),
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
                            fontSize: 10,
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
              Navigator.of(context).popUntil((route) => route.isFirst);
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
              Navigator.of(context).popUntil((route) => route.isFirst);
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
                onPressed: () => setState(() => _flowSubStep = 0),
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
                      'Select multiple',
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.placeholder),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildServiceCheckbox('Interior Design', 'Concept to 3D execution'),
                _buildServiceCheckbox('Construction & Build', 'Full project management'),
                _buildServiceCheckbox('MEP Engineering', 'Mechanical, electrical, plumbing'),
                _buildServiceCheckbox('Branding & Identity', 'Signage and menu design'),
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
                style: GoogleFonts.inter(fontSize: 10, color: AppColors.placeholder),
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
            if (isChecked) {
              _reqs.remove(title);
            } else {
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
    final bId = active != null ? active.id : 'AT-982-XC';
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
                      Text(
                        'Broadcast ID: $bId',
                        style: GoogleFonts.inter(
                          fontSize: 10,
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
              // Switch to service-provider view so Marketplace tab is visible
              MarketplaceState.isServiceProvider = true;
              MarketplaceState.initialIndex = 2;
              // Fire listener so HomePage rebuilds tabs and switches to index 2
              if (MarketplaceState.onRoleChanged != null) {
                MarketplaceState.onRoleChanged!();
              }
              Navigator.of(context).popUntil((route) => route.isFirst);
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
              Navigator.of(context).popUntil((route) => route.isFirst);
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
