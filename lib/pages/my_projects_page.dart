import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../services/project_service.dart';
import '../services/post_service.dart';
import '../services/api_client.dart';
import '../services/service_provider_service.dart';
import '../models/responses/api_responses.dart';
import 'project_detail_page.dart';
import 'project_success_page.dart';
import 'project_onboarding_page.dart';

class MyProjectsPage extends StatefulWidget {
  const MyProjectsPage({super.key});

  @override
  State<MyProjectsPage> createState() => _MyProjectsPageState();
}

class _MyProjectsPageState extends State<MyProjectsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  List<ProjectResponse> _projects = [];
  bool _loading = true;
  String? _error;
  final Set<int> _postedProjectIds = {};

  static const _coverImages = [
    'https://images.unsplash.com/photo-1554118811-1e0d58224f24?auto=format&fit=crop&q=80&w=600',
    'https://images.unsplash.com/photo-1497935586351-b67a49e012bf?auto=format&fit=crop&q=80&w=600',
    'https://images.unsplash.com/photo-1498804103079-a6351b050096?auto=format&fit=crop&q=80&w=600',
    'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&q=80&w=600',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
    _searchController.addListener(() => setState(() {}));
    _loadProjects();
    _loadPostedProjectIds();
  }

  Future<void> _loadProjects() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final shopOwnerId = await ShopOwnerService.ensureShopOwnerId();
      final result = await ProjectService.getProjects(
        ownerId: shopOwnerId,
        pageSize: 50,
      );
      if (mounted) {
        setState(() {
          _projects = result.items;
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
          _error = 'Failed to load projects';
        });
      }
    }
  }

  Future<void> _loadPostedProjectIds() async {
    try {
      final response = await PostService.getPosts(pageNumber: 1, pageSize: 100);
      if (mounted) {
        setState(() {
          _postedProjectIds.clear();
          for (final post in response.items) {
            _postedProjectIds.add(post.projectShopOwnerId);
          }
        });
      }
    } catch (_) {
      // silently ignore – just won't show "already posted" badge
    }
  }

  /// A project is closed once it's completed *or* cancelled. Cancelled ones
  /// used to fall through to the "Active" tab, which is why finished work kept
  /// cluttering the list.
  bool _isClosed(ProjectResponse p) {
    final s = p.status.toLowerCase();
    return s == 'completed' || s == 'cancelled';
  }

  List<ProjectResponse> get _filteredProjects {
    final query = _searchController.text.trim().toLowerCase();
    final byTab = _projects.where((p) {
      final closed = _isClosed(p);
      return _tabController.index == 1 ? closed : !closed;
    });
    if (query.isEmpty) return byTab.toList();
    return byTab
        .where((p) =>
            p.name.toLowerCase().contains(query) ||
            p.address.toLowerCase().contains(query) ||
            p.status.toLowerCase().contains(query))
        .toList();
  }

  String _coverFor(ProjectResponse p) =>
      _coverImages[p.id.abs() % _coverImages.length];

  String _formatUpdated(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays <= 0) return 'Updated today';
    if (diff.inDays == 1) return 'Updated 1 day ago';
    if (diff.inDays < 7) return 'Updated ${diff.inDays} days ago';
    if (diff.inDays < 30) {
      final weeks = (diff.inDays / 7).floor();
      return 'Updated $weeks week${weeks == 1 ? '' : 's'} ago';
    }
    return 'Updated ${dt.day}/${dt.month}/${dt.year}';
  }

  double _progressFor(ProjectResponse p) {
    switch (p.status.toLowerCase()) {
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

  String _statusLabel(String status) {
    if (status.isEmpty) return 'Draft';
    return status
        .split('_')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(' ');
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return const Color(0xFF56642B);
      case 'draft':
        return AppColors.placeholder;
      default:
        return const Color(0xFF56642B);
    }
  }

  void _openProject(ProjectResponse project) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProjectDetailPage(projectId: project.id),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredProjects;
    final focus = filtered.isNotEmpty ? filtered.first : null;
    final history = filtered.length > 1 ? filtered.sublist(1) : <ProjectResponse>[];

    return Scaffold(
      backgroundColor: const Color(0xFFFBF8F6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.espresso),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Project Management',
          style: GoogleFonts.playfairDisplay(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.espresso,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.espresso,
        onRefresh: _loadProjects,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                'My Projects',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.espresso,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Manage your ongoing architectural designs and finished roastery concepts.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search projects...',
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
              const SizedBox(height: 20),
              TabBar(
                controller: _tabController,
                labelColor: AppColors.espresso,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
                unselectedLabelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                indicatorColor: AppColors.espresso,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: AppColors.outlineVariant.withOpacity(0.5),
                tabs: const [
                  Tab(text: 'Active'),
                  Tab(text: 'Closed'),
                ],
              ),
              const SizedBox(height: 24),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: CircularProgressIndicator(color: AppColors.espresso)),
                )
              else if (_error != null)
                _buildMessageState(
                  icon: Icons.error_outline,
                  title: 'Could not load projects',
                  subtitle: _error!,
                  actionLabel: 'Retry',
                  onAction: _loadProjects,
                )
              else if (filtered.isEmpty)
                _buildMessageState(
                  icon: Icons.folder_open_outlined,
                  title: _projects.isEmpty
                      ? 'Start your first project'
                      : (_tabController.index == 1 ? 'No closed projects' : 'No active projects'),
                  subtitle: _projects.isEmpty
                      ? 'Set up your café details and we\'ll help you find a designer or constructor.'
                      : 'Try another tab or clear your search.',
                  actionLabel: _projects.isEmpty ? 'Create a project' : null,
                  onAction: _projects.isEmpty
                      ? () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ProjectOnboardingPage()),
                          );
                          if (mounted) _loadProjects();
                        }
                      : null,
                )
              else ...[
                if (focus != null) ...[
                  Text(
                    _tabController.index == 1 ? 'COMPLETED' : 'CURRENT FOCUS',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: AppColors.placeholder,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildCurrentFocusCard(focus),
                  const SizedBox(height: 32),
                ],
                if (history.isNotEmpty) ...[
                  Text(
                    'RECENT HISTORY',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: AppColors.placeholder,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...history.map((p) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildHistoryCard(p),
                      )),
                ],
              ],
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageState({
    required IconData icon,
    required String title,
    required String subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 40, color: AppColors.placeholder),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.playfairDisplay(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.espresso,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              TextButton(onPressed: onAction, child: Text(actionLabel)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentFocusCard(ProjectResponse project) {
    final progress = _progressFor(project);
    final percent = (progress * 100).round();
    final statusColor = _statusColor(project.status);

    return GestureDetector(
      onTap: () => _openProject(project),
      child: Container(
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              child: Image.network(
              webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                _coverFor(project),
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 140,
                  color: AppColors.outlineVariant,
                  child: const Icon(Icons.storefront, color: AppColors.placeholder),
                ),
              ),
            ),
            Padding(
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
                          color: statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _statusLabel(project.status),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
                      Text(
                        '$percent%',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    project.name,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.espresso,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    project.address,
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progress,
                      child: Container(
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'DETAILS',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: AppColors.placeholder,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetaChip(
                          Icons.square_foot,
                          '${project.areaM2.toStringAsFixed(0)} m²',
                        ),
                      ),
                      Expanded(
                        child: _buildMetaChip(
                          Icons.payments_outlined,
                          _formatBudget(project.budget),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _openProject(project),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.espresso,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                            minimumSize: const Size(0, 40),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Continue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward, size: 14),
                            ],
                          ),
                        ),
                      ),
                      if (!_postedProjectIds.contains(project.id)) ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _postToMarketplace(project),
                            icon: const Icon(Icons.podcasts_rounded, size: 14),
                            label: const Text('Post', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.espresso,
                              side: const BorderSide(color: AppColors.espresso),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              minimumSize: const Size(0, 40),
                            ),
                          ),
                        ),
                      ] else ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFFD9EAA3).withOpacity(0.4),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF56642B).withOpacity(0.3)),
                            ),
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.check_circle_outline, size: 14, color: Color(0xFF56642B)),
                                  const SizedBox(width: 6),
                                  Text('Posted', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF56642B))),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaChip(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.placeholder),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.espresso,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _formatBudget(double budget) {
    if (budget >= 1000000) return '${(budget / 1000000).toStringAsFixed(1)}M';
    if (budget >= 1000) return '${(budget / 1000).toStringAsFixed(0)}K';
    return budget.toStringAsFixed(0);
  }

  Widget _buildHistoryCard(ProjectResponse project) {
    final statusColor = _statusColor(project.status);
    return GestureDetector(
      onTap: () => _openProject(project),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.outlineVariant.withOpacity(0.5)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
              webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                _coverFor(project),
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 64,
                  height: 64,
                  color: AppColors.outlineVariant,
                  child: const Icon(Icons.storefront, size: 20, color: AppColors.placeholder),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.name,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.espresso,
                    ),
                  ),
                  Text(
                    project.address,
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.payments_outlined, size: 10, color: AppColors.placeholder),
                      const SizedBox(width: 4),
                      Text(
                        'Budget: ${_formatBudget(project.budget)}',
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.placeholder),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _statusLabel(project.status),
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                      if (!_postedProjectIds.contains(project.id))
                        GestureDetector(
                          onTap: () => _postToMarketplace(project),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.espresso,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.podcasts_rounded, size: 10, color: Colors.white),
                                const SizedBox(width: 4),
                                Text('Post', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                              ],
                            ),
                          ),
                        )
                      else
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle_outline, size: 11, color: Color(0xFF56642B)),
                            const SizedBox(width: 4),
                            Text('Posted', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF56642B))),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.placeholder),
          ],
        ),
      ),
    );
  }

  void _postToMarketplace(ProjectResponse project) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProjectSuccessPage(
          cafeName: project.name,
          location: project.address,
          style: '',
          budgetLevel: '',
          totalBudget: project.budget,
          mood: '',
          role: 'cafe_owner',
          area: project.areaM2,
          projectId: project.id,
          initialStep: 1,
        ),
      ),
    ).then((_) {
      // Refresh posted IDs after returning from the broadcast screen
      _loadPostedProjectIds();
    });
  }
}
