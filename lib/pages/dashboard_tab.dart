import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../services/service_provider_service.dart';
import '../services/project_service.dart';
import '../services/project_working_service.dart';
import '../services/design_service.dart';
import '../services/construction_service.dart';
import '../services/api_client.dart';
import '../services/notification_service.dart';
import '../models/responses/api_responses.dart';
import 'ai_advice_page.dart';
import 'project_detail_page.dart';
import 'project_onboarding_page.dart';

/// Unified document item shown in the "Project documents" section.
class _DocItem {
  final int projectId;
  final String title;
  final String subtitle;   // formatted updated-at
  final String source;     // 'Design' | 'Construction'
  final IconData icon;
  final DateTime updatedAt;

  const _DocItem({
    required this.projectId,
    required this.title,
    required this.subtitle,
    required this.source,
    required this.icon,
    required this.updatedAt,
  });
}

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => DashboardTabState();
}

/// Public so [HomePage] can hold a key to it and refetch when the Home tab is
/// re-selected — the tabs live in an IndexedStack, so this state is created
/// once and would otherwise keep showing whatever it loaded at startup.
class DashboardTabState extends State<DashboardTab> {
  ShopOwnerResponse? _shopOwner;
  ProjectResponse? _latestProject;
  List<_DocItem> _recentDocs = [];
  bool _loading = true;
  String? _error;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  /// Refetches everything. Call when returning to the Home tab or after an
  /// action elsewhere may have changed the data.
  ///
  /// [showSkeleton] false keeps the current content on screen while reloading,
  /// which is what pull-to-refresh and tab-switching want — the skeleton is
  /// only right on first load.
  Future<void> reload({bool showSkeleton = false}) =>
      _loadDashboard(showSkeleton: showSkeleton, forceRefreshOwner: true);

  Future<void> _loadDashboard({
    bool showSkeleton = true,
    bool forceRefreshOwner = false,
  }) async {
    if (showSkeleton) setState(() => _loading = true);
    setState(() => _error = null);
    try {
      final shopOwner =
          await ShopOwnerService.getCurrentShopOwner(forceRefresh: forceRefreshOwner);
      final shopOwnerId = shopOwner.id;

      final projectsResult = await ProjectService.getProjects(
        ownerId: shopOwnerId,
        pageSize: 50,
      );
      // Cancelled projects still get an updatedAt bump when they're cancelled,
      // so without this the newest cancelled project becomes the featured card
      // on Home. Completed ones stay eligible — finished work is worth showing.
      final projects = projectsResult.items
          .where((p) => p.status.toLowerCase() != 'cancelled')
          .toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      ProjectResponse? latest;
      List<_DocItem> docs = [];

      if (projects.isNotEmpty) {
        latest = await ProjectService.getProject(projects.first.id);
        
        // Fetch recent docs across up to 10 most recently updated projects
        final docFutures = projects.take(10).map((p) => _loadRecentDocs(p.id));
        final nestedDocs = await Future.wait(docFutures);
        docs = nestedDocs.expand((e) => e).toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        if (docs.length > 5) {
          docs = docs.sublist(0, 5);
        }
      }

      int unread = 0;
      final accountId = await ApiClient.getAccountId();
      if (accountId != null) {
        try {
          unread = await NotificationService.getUnreadCount(accountId);
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _shopOwner = shopOwner;
          _latestProject = latest;
          _recentDocs = docs;
          _unreadCount = unread;
          _loading = false;
        });
      }
    } on ApiException catch (e) {
      // Never swallow this. A failed fetch leaves _latestProject null, which
      // would otherwise render "Start your first project" — telling the user
      // they have no projects when we simply could not load them.
      if (mounted) {
        setState(() {
          _error = e.message;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Could not reach the server. Check your connection and try again.';
          _loading = false;
        });
      }
    }
  }

  Future<List<_DocItem>> _loadRecentDocs(int projectShopOwnerId) async {
    final workings = await ProjectWorkingService.getProjectWorkings(
      projectShopOwnerId: projectShopOwnerId,
      pageSize: 50,
    );
    if (workings.items.isEmpty) return [];

    final allDocs = <_DocItem>[];

    for (final working in workings.items) {
      // ── Designs ──────────────────────────────────────────
      try {
        final result = await DesignService.getDesigns(
          projectWorkingId: working.id,
          pageSize: 20,
        );
        for (final d in result.items) {
          allDocs.add(_DocItem(
            projectId: projectShopOwnerId,
            title: d.title.isNotEmpty ? d.title : 'Design v${d.version.toStringAsFixed(1)}',
            subtitle: _formatUpdated(d.updatedAt),
            source: 'Design',
            icon: _iconForDesignType(d.type),
            updatedAt: d.updatedAt,
          ));
        }
      } catch (_) {}

      // ── Construction milestones ───────────────────────────
      try {
        final result = await ConstructionService.getMilestones(
          projectWorkingId: working.id,
          pageSize: 20,
        );
        for (final c in result.items) {
          allDocs.add(_DocItem(
            projectId: projectShopOwnerId,
            title: c.name.isNotEmpty ? c.name : 'Milestone',
            subtitle: _formatUpdated(c.updatedAt),
            source: 'Construction',
            icon: _iconForConstructionCategory(c.category),
            updatedAt: c.updatedAt,
          ));
        }
      } catch (_) {}
    }

    allDocs.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return allDocs.take(5).toList();
  }

  double _progressFor(ProjectResponse project) {
    switch (project.status.toLowerCase()) {
      case 'completed':
        return 1.0;
      case 'draft':
        return 0.2;
      case 'inprogress':
      case 'in_progress':
      case 'active':
        return 0.65;
      default:
        return 0.4;
    }
  }

  String _phaseLabel(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return 'Phase 1: Drafting';
      case 'completed':
        return 'Completed';
      case 'inprogress':
      case 'in_progress':
      case 'active':
        return 'Phase 2: In Progress';
      default:
        if (status.isEmpty) return 'Phase 1: Drafting';
        return 'Phase: ${status[0].toUpperCase()}${status.substring(1)}';
    }
  }

  List<String> _providerNames(ProjectResponse project) {
    return project.providers
        .whereType<Map>()
        .map((p) => p['displayName']?.toString().trim() ?? '')
        .where((name) => name.isNotEmpty)
        .toList();
  }

  String _formatUpdated(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inHours < 1) return 'Updated just now';
    if (diff.inHours < 24) return 'Updated ${diff.inHours} hours ago';
    if (diff.inDays == 1) return 'Updated yesterday';
    if (diff.inDays < 7) return 'Updated ${diff.inDays} days ago';
    return 'Updated ${dt.day}/${dt.month}/${dt.year}';
  }

  IconData _iconForDesignType(String type) {
    switch (type.toLowerCase()) {
      case 'layout_2d':
        return Icons.architecture;
      case 'render_3d':
        return Icons.view_in_ar_rounded;
      case 'concept':
        return Icons.palette_outlined;
      case 'technical_drawing':
        return Icons.draw_outlined;
      default:
        return Icons.description_outlined;
    }
  }

  IconData _iconForConstructionCategory(String? category) {
    switch ((category ?? '').toLowerCase()) {
      case 'electrical':
        return Icons.electrical_services_rounded;
      case 'plumbing':
        return Icons.plumbing_rounded;
      case 'flooring':
        return Icons.grid_view_rounded;
      case 'furniture':
        return Icons.chair_outlined;
      case 'painting':
        return Icons.format_paint_rounded;
      default:
        return Icons.construction_rounded;
    }
  }

  String get _greetingName {
    final fullName = _shopOwner?.fullName;
    if (fullName == null || fullName.trim().isEmpty) return 'Owner';
    return ShopOwnerService.firstNameFrom(fullName);
  }

  String get _timeOfDayGreeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'GOOD MORNING';
    if (hour < 17) return 'GOOD AFTERNOON';
    return 'GOOD EVENING';
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Coming soon')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.espresso,
      onRefresh: () => reload(),
      child: SingleChildScrollView(
        // Always scrollable so the pull gesture works even when the content
        // is shorter than the viewport.
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                // Greeting
                Text(
                  '$_timeOfDayGreeting, OWNER',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary.withOpacity(0.8),
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _loading ? 'Hello, ...' : 'Hello, $_greetingName',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.espresso,
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Active Project Card
                _buildActiveProjectCard(),
                
                const SizedBox(height: 40),
                
                // Smart AI Assistant Banner
                _buildAiBanner(context),
                
                const SizedBox(height: 40),
                
                // Quick Actions
                _buildQuickActions(),
                
                const SizedBox(height: 40),
                
                // Inspiration Section
                _buildInspirationSection(),
                
                const SizedBox(height: 40),
                
                // Recent Documents
                _buildRecentDocuments(),
                
                const SizedBox(height: 100), // Space for bottom nav
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveProjectCard() {
    if (_loading) {
      return Container(
        width: double.infinity,
        height: 220,
        decoration: BoxDecoration(
          color: AppColors.espresso,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.primaryFixed),
        ),
      );
    }

    // Checked before the empty state: without this, a failed load looks
    // identical to genuinely having no projects.
    if (_error != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.espresso,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cloud_off_rounded,
                    size: 16, color: AppColors.primaryFixed.withOpacity(0.8)),
                const SizedBox(width: 8),
                Text(
                  "COULDN'T LOAD YOUR PROJECTS",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryFixed.withOpacity(0.8),
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _error!,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.primaryFixedDim.withOpacity(0.9),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _loadDashboard(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryFixed,
                foregroundColor: AppColors.espresso,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                'Try again',
                style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }

    if (_latestProject == null) {
      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProjectOnboardingPage()),
          ).then((_) => _loadDashboard());
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.espresso,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'YOUR PROJECT',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryFixed.withOpacity(0.6),
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Start your first project',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryFixed,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Create a brief to begin your cafe build journey.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.primaryFixedDim.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProjectOnboardingPage()),
                  ).then((_) => _loadDashboard());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryFixed,
                  foregroundColor: AppColors.espresso,
                  elevation: 0,
                ),
                child: const Text('Get Started'),
              ),
            ],
          ),
        ),
      );
    }

    final project = _latestProject!;
    final progress = _progressFor(project);
    final percent = (progress * 100).round();
    final providers = _providerNames(project);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.espresso,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.espresso.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative element
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF4B3621).withOpacity(0.3),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'YOUR PROJECT',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryFixed.withOpacity(0.6),
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          project.name,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryFixed,
                          ),
                        ),
                        Text(
                          _phaseLabel(project.status),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.primaryFixedDim.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4B3621).withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.primaryFixed.withOpacity(0.2)),
                      ),
                      child: Text(
                        '$percent%',
                        style: TextStyle(
                          color: AppColors.primaryFixed,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Progress Bar
                Container(
                  width: double.infinity,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4B3621),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primaryFixed,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Avatars
                    SizedBox(
                      height: 36,
                      width: providers.length > 2 ? 100 : (providers.isEmpty ? 36 : 72),
                      // _buildInitialAvatar returns a Positioned, so it must
                      // always sit directly under a Stack — including the
                      // no-providers case, which otherwise throws a
                      // ParentData/StackParentData error and blanks the page.
                      child: Stack(
                        children: providers.isEmpty
                            ? [_buildInitialAvatar(0, '?')]
                            : [
                                for (var i = 0; i < providers.length && i < 2; i++)
                                  _buildInitialAvatar(
                                    i,
                                    providers[i].isNotEmpty ? providers[i][0].toUpperCase() : '?',
                                  ),
                                if (providers.length > 2)
                                  Positioned(
                                    left: 56,
                                    child: Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryFixedDim,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: AppColors.espresso, width: 2),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '+${providers.length - 2}',
                                          style: const TextStyle(
                                            color: AppColors.espresso,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProjectDetailPage(projectId: project.id),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryFixed,
                        foregroundColor: AppColors.espresso,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      child: const Row(
                        children: [
                          Text('Continue', style: TextStyle(fontWeight: FontWeight.w600)),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward, size: 14),
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
    );
  }

  Widget _buildInitialAvatar(int index, String initial) {
    return Positioned(
      left: index * 28.0,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primaryFixedDim,
          border: Border.all(color: AppColors.espresso, width: 2),
        ),
        child: Center(
          child: Text(
            initial,
            style: const TextStyle(
              color: AppColors.espresso,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(int index, String url) {
    return Positioned(
      left: index * 28.0,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.espresso, width: 2),
          image: DecorationImage(
            image: NetworkImage(url),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildActionItem(Icons.view_in_ar_rounded, 'Scan floor plan'),
        _buildActionItem(Icons.lightbulb_outline_rounded, 'Find inspiration'),
        _buildActionItem(Icons.handshake_outlined, 'Hire expert'),
      ],
    );
  }

  Widget _buildActionItem(IconData icon, String label) {
    return Container(
      width: (MediaQuery.of(context).size.width - 64) / 3,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF4B3621).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.espresso, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            label.toUpperCase(),
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: AppColors.espresso,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInspirationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              'Inspiration for you',
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: AppColors.espresso,
              ),
            ),
            GestureDetector(
              onTap: () => _showComingSoon(context),
              child: Text(
                'See all',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF56642B),
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 460,
          child: ListView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            children: [
              _buildInspirationCard(
                imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDzWV39I7awqkhB9R7aFYTtS2b9QHLnzYdCdatXXx4-SVlmu2fNk59JXajSnX13L2vnGPwPk2HPvuQDOijoIKlt4SVAw3DawdtAmB6yUdPWw4-SP65ye90zOtLnUp7S8_AW1tS19rGwCRYCJ9_KvewKYPjag6qcC3ZRzEjJIcNEOsNtgf5AOZoqtWDsuYwE5PZuDyVi_FOAn81vupeGes272RFTmLg6_uKI0O4kpM_eXpGjRXNc4uJe8jgNpOYKyK2ciQexj8LpTWey',
                tag: 'JAPANDI',
                title: 'Wood Tea House',
                subtitle: 'The perfect balance between oak and light.',
                width: 280,
              ),
              const SizedBox(width: 20),
              _buildInspirationCard(
                imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDxoZIlfGLUkHEV4ojJ-fQellwEvg21BHHDxw_7YIWdPa8iebzrz8E0bqMUSVopsgaGHD2nZs-WWYMprTtK-qUJ54uEQZgfNhOfetmKb4gpnUuPwRCy6Lce4gIhaiYFyfj9gLGjMbs4q80RxZAupCTu4DLUDWcY3quYao8sdSiqoadmjoVeC_7-fg3M_aSvYMuaKX_reoLCB0tO_baSqFX3l6AxmMNcCwFuuEd-SeIQFIGnX6bmGvhNRLg5KNOpGd1LDMKBf1rok475',
                tag: 'MINIMALIST',
                title: 'Urban Brew Lab',
                subtitle: 'The raw beauty of concrete and steel.',
                width: 260,
                paddingTop: 32,
              ),
              const SizedBox(width: 20),
              _buildInspirationPlaceholder(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInspirationCard({
    required String imageUrl,
    required String tag,
    required String title,
    required String subtitle,
    required double width,
    double paddingTop = 0,
  }) {
    return Padding(
      padding: EdgeInsets.only(top: paddingTop),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: width,
            height: width * 1.33,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
              image: DecorationImage(
                image: NetworkImage(imageUrl),
                fit: BoxFit.cover,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  bottom: 20,
                  left: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryFixed.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(
                        color: AppColors.espresso,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.espresso,
            ),
          ),
          SizedBox(
            width: width,
            child: Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInspirationPlaceholder() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 260,
          height: 260 * 1.33,
          decoration: BoxDecoration(
            color: const Color(0xFFEAE7E7),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Center(
            child: Icon(Icons.add_photo_alternate_outlined, color: AppColors.outlineVariant, size: 40),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Explore more',
          style: GoogleFonts.playfairDisplay(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.espresso,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentDocuments() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Project documents',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: AppColors.espresso,
                ),
              ),
            ),
            if (_recentDocs.isNotEmpty)
              Text(
                '${_recentDocs.length} items',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
        if (_loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: CircularProgressIndicator(color: AppColors.espresso, strokeWidth: 2),
            ),
          )
        else if (_recentDocs.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.outlineVariant.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                const Icon(Icons.folder_open_outlined, color: AppColors.outlineVariant, size: 40),
                const SizedBox(height: 8),
                Text(
                  'No documents yet',
                  style: GoogleFonts.inter(fontSize: 14, color: AppColors.outline),
                ),
              ],
            ),
          )
        else
          for (var i = 0; i < _recentDocs.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            _buildDocumentItem(_recentDocs[i]),
          ],
      ],
    );
  }

  Widget _buildAiBanner(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AiAdvicePage()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFD9EAA3).withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF56642B).withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF56642B),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.psychology_outlined, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI Design Assistant',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    'Get instant professional advice for your coffee shop design.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentItem(_DocItem doc) {
    final isConstruction = doc.source == 'Construction';
    final iconBg = isConstruction
        ? const Color(0xFF1A4DC7).withOpacity(0.08)
        : const Color(0xFF4B3621).withOpacity(0.08);
    final iconBorder = isConstruction
        ? const Color(0xFF1A4DC7).withOpacity(0.18)
        : const Color(0xFF4B3621).withOpacity(0.18);
    final iconColor = isConstruction
        ? const Color(0xFF1A4DC7)
        : AppColors.espresso;
    final badgeBg = isConstruction
        ? const Color(0xFFDDE8FF)
        : const Color(0xFFD9EAA3).withOpacity(0.6);
    final badgeText = isConstruction
        ? const Color(0xFF1A4DC7)
        : const Color(0xFF56642B);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProjectDetailPage(projectId: doc.projectId),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.outlineVariant.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: iconBorder),
              ),
              child: Icon(doc.icon, color: iconColor, size: 22),
            ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Source badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    doc.source.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: badgeText,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  doc.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.espresso,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: iconColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      doc.subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.outline, size: 20),
        ],
      ),
    ));
  }

}

