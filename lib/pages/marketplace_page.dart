import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../models/marketplace_state.dart';
import '../services/post_service.dart';

class MarketplacePage extends StatefulWidget {
  final bool showBackButton;
  const MarketplacePage({super.key, this.showBackButton = false});

  @override
  State<MarketplacePage> createState() => _MarketplacePageState();
}

class _MarketplacePageState extends State<MarketplacePage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late final TabController _tabController;

  // ──────────────────────────────────────────────────────────────────
  // Status helpers
  // ──────────────────────────────────────────────────────────────────
  static bool _isOpen(BroadcastProject p) {
    final s = p.status.toLowerCase().replaceAll(RegExp(r'[\s_-]'), '');
    return s == 'open' ||
        s == 'openforproposals' ||
        s == 'pending' ||
        s == 'active';
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchPosts();
    MarketplaceState.onBroadcastsChanged = () {
      if (mounted) setState(() {});
    };
  }

  Future<void> _fetchPosts() async {
    try {
      final response = await PostService.getPosts(pageNumber: 1, pageSize: 100);
      if (!mounted) return;
      setState(() {
        final serverBroadcasts = response.items.map((post) {
              // Try to extract AI-generated image URL from description
              String imageUrl = 'https://images.unsplash.com/photo-1554118811-1e0d58224f24?auto=format&fit=crop&q=80&w=600';
              final aiImageMatch = RegExp(r'🖼️ AI_IMAGE: (.+)').firstMatch(post.description);
              if (aiImageMatch != null && aiImageMatch.group(1)!.trim().isNotEmpty) {
                imageUrl = aiImageMatch.group(1)!.trim();
              }
              return BroadcastProject(
              id: post.id.toString(),
              title: post.title.isNotEmpty ? post.title : 'Marketplace Project',
              location: post.location.isNotEmpty ? post.location : 'Remote',
              style: post.style.isNotEmpty ? post.style : 'Concept',
              budgetTier:
                  post.budgetTier.isNotEmpty ? post.budgetTier : 'TBD',
              description: post.description.isNotEmpty
                  ? post.description
                  : 'A beautiful architecture project.',
              requirements: post.requirements.isNotEmpty
                  ? post.requirements
                  : ['Interior Design'],
              date: post.expectedStart.isNotEmpty
                  ? post.expectedStart
                  : post.createdAt.toString().substring(0, 10),
              proposalsCount: 0,
              commentsCount: 0,
              status: post.status,
              imageUrl: imageUrl,
            );
            }).toList();

        serverBroadcasts.sort((a, b) {
          final idA = int.tryParse(a.id) ?? 0;
          final idB = int.tryParse(b.id) ?? 0;
          return idB.compareTo(idA);
        });

        if (serverBroadcasts.isNotEmpty) {
          MarketplaceState.broadcasts.clear();
          MarketplaceState.broadcasts.addAll(serverBroadcasts);
        }
      });
    } catch (e) {
      debugPrint('Error fetching posts: $e');
    }
  }

  @override
  void dispose() {
    MarketplaceState.onBroadcastsChanged = null;
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // ──────────────────────────────────────────────────────────────────
  // Build
  // ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final all = MarketplaceState.broadcasts.where((item) {
      final q = _searchQuery.toLowerCase();
      return item.title.toLowerCase().contains(q) ||
          item.location.toLowerCase().contains(q) ||
          item.style.toLowerCase().contains(q);
    }).toList();

    final openItems = all.where(_isOpen).toList();
    final completedItems = all.where((p) => !_isOpen(p)).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            if (widget.showBackButton) _buildHeader(),
            _buildSearchBar(),
            _buildTabBar(openItems.length, completedItems.length),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildProjectList(openItems),
                  _buildProjectList(completedItems, isCompleted: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────
  // Tab bar
  // ──────────────────────────────────────────────────────────────────
  Widget _buildTabBar(int openCount, int completedCount) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF0EBE6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppColors.espresso,
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textSecondary,
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.campaign_rounded, size: 16),
                const SizedBox(width: 6),
                const Text('Open'),
                if (openCount > 0) ...[
                  const SizedBox(width: 6),
                  _buildBadge(openCount, isSelected: true),
                ],
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_outline_rounded, size: 16),
                const SizedBox(width: 6),
                const Text('Completed'),
                if (completedCount > 0) ...[
                  const SizedBox(width: 6),
                  _buildBadge(completedCount, isSelected: false),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(int count, {required bool isSelected}) {
    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, _) {
        // Determine which tab is currently selected by index
        final isActiveTab = isSelected
            ? _tabController.index == 0
            : _tabController.index == 1;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: isActiveTab
                ? Colors.white.withValues(alpha: 0.25)
                : AppColors.espresso.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isActiveTab ? Colors.white : AppColors.espresso,
            ),
          ),
        );
      },
    );
  }

  // ──────────────────────────────────────────────────────────────────
  // Project list
  // ──────────────────────────────────────────────────────────────────
  Widget _buildProjectList(List<BroadcastProject> items,
      {bool isCompleted = false}) {
    if (items.isEmpty) return _buildEmptyState(isCompleted: isCompleted);
    return RefreshIndicator(
      color: AppColors.espresso,
      onRefresh: _fetchPosts,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: items.length,
        itemBuilder: (context, index) => _buildProjectCard(items[index]),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (widget.showBackButton)
                IconButton(
                  icon:
                      const Icon(Icons.arrow_back, color: AppColors.espresso),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 24,
                ),
              if (widget.showBackButton) const SizedBox(width: 8),
              const Icon(Icons.store_mall_directory_rounded,
                  color: AppColors.espresso, size: 28),
              const SizedBox(width: 8),
              Text(
                'Market place',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.espresso,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded,
                color: AppColors.espresso),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (val) => setState(() => _searchQuery = val),
          decoration: InputDecoration(
            hintText: 'Search architectural projects...',
            hintStyle:
                GoogleFonts.inter(fontSize: 13, color: AppColors.placeholder),
            prefixIcon: const Icon(Icons.search,
                color: AppColors.placeholder, size: 20),
            suffixIcon: IconButton(
              icon: const Icon(Icons.tune, color: AppColors.espresso, size: 20),
              onPressed: () {},
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({bool isCompleted = false}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isCompleted
                  ? Icons.check_circle_outline_rounded
                  : Icons.find_in_page_outlined,
              size: 64,
              color: AppColors.placeholder,
            ),
            const SizedBox(height: 16),
            Text(
              isCompleted
                  ? 'No completed projects yet'
                  : 'No open projects found',
              style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.espresso),
            ),
            const SizedBox(height: 8),
            Text(
              isCompleted
                  ? 'Projects that have been assigned will appear here.'
                  : 'Try adjusting your search criteria.',
              textAlign: TextAlign.center,
              style:
                  GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectCard(BroadcastProject project) {
    final open = _isOpen(project);

    Color badgeColor;
    Color textColor;

    if (open) {
      badgeColor = const Color(0xFFD9EAA3).withValues(alpha: 0.85);
      textColor = const Color(0xFF56642B);
    } else if (project.status.toLowerCase() == 'urgent') {
      badgeColor = const Color(0xFFFFDAD9);
      textColor = const Color(0xFFBA1A1A);
    } else {
      // Completed / assigned
      badgeColor = const Color(0xFFDDE8FF);
      textColor = const Color(0xFF1A4DC7);
    }

    // Friendly label for completed states
    String badgeLabel = project.status;
    if (!open && project.status.toLowerCase() != 'urgent') {
      badgeLabel = 'Assigned';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: ColorFiltered(
                  colorFilter: open
                      ? const ColorFilter.mode(
                          Colors.transparent, BlendMode.multiply)
                      : const ColorFilter.matrix([
                          0.2126, 0.7152, 0.0722, 0, 0,
                          0.2126, 0.7152, 0.0722, 0, 0,
                          0.2126, 0.7152, 0.0722, 0, 0,
                          0,      0,      0,      1, 0,
                        ]),
                  child: Image.network(
              webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                    project.imageUrl,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              // Dim overlay for completed
              if (!open)
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: Container(
                    height: 160,
                    color: Colors.black.withValues(alpha: 0.25),
                  ),
                ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badgeLabel,
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
              ),
              // Lock icon for completed
              if (!open)
                const Positioned(
                  bottom: 12,
                  left: 12,
                  child: Icon(Icons.lock_outline_rounded,
                      color: Colors.white70, size: 20),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  project.title,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: open ? AppColors.espresso : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on,
                        size: 12, color: AppColors.placeholder),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(project.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                              fontSize: 11, color: AppColors.textSecondary)),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.color_lens_outlined,
                        size: 12, color: AppColors.placeholder),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(project.style,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                              fontSize: 11, color: AppColors.textSecondary)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  project.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: AppColors.outlineVariant),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.description_outlined,
                            size: 16, color: AppColors.placeholder),
                        const SizedBox(width: 4),
                        Text('${project.proposalsCount} Proposals',
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textSecondary)),
                        const SizedBox(width: 14),
                        const Icon(Icons.chat_bubble_outline_rounded,
                            size: 15, color: AppColors.placeholder),
                        const SizedBox(width: 4),
                        Text('${project.commentsCount}',
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: open ? () => _showProjectDetail(project) : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            open ? AppColors.espresso : AppColors.outlineVariant,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppColors.outlineVariant,
                        disabledForegroundColor: AppColors.outline,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6)),
                        elevation: 0,
                      ),
                      child: Text(
                        open ? 'View Detail' : 'Assigned',
                        style: GoogleFonts.inter(
                            fontSize: 11, fontWeight: FontWeight.bold),
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

  void _showProjectDetail(BroadcastProject project) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD9EAA3),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              project.style.toUpperCase(),
                              style: GoogleFonts.inter(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF56642B)),
                            ),
                          ),
                          Text('ID: ${project.id}',
                              style: GoogleFonts.inter(
                                  fontSize: 11, color: AppColors.placeholder)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        project.title,
                        style: GoogleFonts.playfairDisplay(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.espresso),
                      ),
                      Text(project.location,
                          style: GoogleFonts.inter(
                              fontSize: 13, color: AppColors.textSecondary)),
                      const SizedBox(height: 16),
                      // Project image (AI-generated 3D visualization)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          children: [
                            Image.network(
              webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                              project.imageUrl,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                height: 200,
                                color: const Color(0xFFF0EBE6),
                                child: const Center(
                                  child: Icon(Icons.image_not_supported_outlined,
                                      color: AppColors.placeholder, size: 48),
                                ),
                              ),
                            ),
                            if (project.imageUrl.contains('imageArtifact') ||
                                !project.imageUrl.contains('unsplash'))
                              Positioned(
                                top: 10,
                                right: 10,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD9EAA3).withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'AI RENDERED',
                                    style: GoogleFonts.inter(
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF56642B),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                              child: _buildMetricCard(
                                  'Expected Start', project.date)),
                          const SizedBox(width: 8),
                          Expanded(
                              child: _buildMetricCard(
                                  'Budget Tier', project.budgetTier)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'PROJECT DESCRIPTION',
                        style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: AppColors.placeholder,
                            letterSpacing: 1.0),
                      ),
                      const SizedBox(height: 8),
                      _buildRichDescription(project.description),
                      const SizedBox(height: 24),
                      Text(
                        'SERVICE REQUIREMENTS',
                        style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: AppColors.placeholder,
                            letterSpacing: 1.0),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: project.requirements
                            .map((req) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: AppColors.outlineVariant)),
                                  child: Text(req,
                                      style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.espresso)),
                                ))
                            .toList(),
                      ),
                      if (MarketplaceState.isServiceProvider) ...[
                        const SizedBox(height: 32),
                        _SubmitProposalForm(
                          project: project,
                          onSubmitted: () => setState(() {}),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricCard(String label, String val) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: AppColors.placeholder)),
          const SizedBox(height: 4),
          Text(val,
              style: GoogleFonts.playfairDisplay(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.espresso)),
        ],
      ),
    );
  }

  Widget _buildRichDescription(String text) {
    final RegExp imageRegex = RegExp(r'🖼️\s*AI_IMAGE:\s*(https?://\S+)');
    final match = imageRegex.firstMatch(text);
    
    if (match != null) {
      final before = text.substring(0, match.start).trim();
      final url = match.group(1)!;
      final after = text.substring(match.end).trim();
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (before.isNotEmpty)
            Text(before,
                style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.5)),
          if (before.isNotEmpty) const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
              url,
              width: double.infinity,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
          if (after.isNotEmpty) const SizedBox(height: 16),
          if (after.isNotEmpty)
            Text(after,
                style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.5)),
        ],
      );
    }

    return Text(text,
        style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.5));
  }
}

class _SubmitProposalForm extends StatefulWidget {
  final BroadcastProject project;
  final VoidCallback onSubmitted;

  const _SubmitProposalForm(
      {required this.project, required this.onSubmitted});

  @override
  State<_SubmitProposalForm> createState() => _SubmitProposalFormState();
}

class _SubmitProposalFormState extends State<_SubmitProposalForm> {
  final _nameController = TextEditingController();
  final _costController = TextEditingController();
  final _timelineController = TextEditingController();
  final _descController = TextEditingController();
  bool _submitted = false;

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFD9EAA3).withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: const Color(0xFF56642B).withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF56642B), size: 48),
            const SizedBox(height: 12),
            Text(
              'Proposal Submitted!',
              style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.espresso),
            ),
            const SizedBox(height: 4),
            Text(
              'The Cafe Owner will review your offer and get in touch with you.',
              textAlign: TextAlign.center,
              style:
                  GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 24, color: AppColors.outlineVariant),
        Text(
          'SUBMIT PROPOSAL',
          style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: AppColors.placeholder,
              letterSpacing: 1.0),
        ),
        const SizedBox(height: 14),
        TextField(
            controller: _nameController,
            decoration: _inputDecor('Your Designer/Firm Name')),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                  controller: _costController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecor('Est. Cost (\$)')),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                  controller: _timelineController,
                  decoration: _inputDecor('Duration (e.g. 10 weeks)')),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _descController,
          maxLines: 3,
          decoration:
              _inputDecor('Introduce your concept or modifications...'),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            if (_nameController.text.isEmpty ||
                _costController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content:
                        Text('Please fill in your name and cost estimate.')),
              );
              return;
            }
            setState(() {
              final index = MarketplaceState.broadcasts
                  .indexWhere((e) => e.id == widget.project.id);
              if (index != -1) {
                final proj = MarketplaceState.broadcasts[index];
                MarketplaceState.broadcasts[index] = BroadcastProject(
                  id: proj.id,
                  title: proj.title,
                  location: proj.location,
                  style: proj.style,
                  budgetTier: proj.budgetTier,
                  description: proj.description,
                  requirements: proj.requirements,
                  date: proj.date,
                  proposalsCount: proj.proposalsCount + 1,
                  commentsCount: proj.commentsCount,
                  status: proj.status,
                  imageUrl: proj.imageUrl,
                );
              }
              _submitted = true;
            });
            widget.onSubmitted();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.espresso,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 48),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 0,
          ),
          child: Text('Send Proposal Brief',
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold, fontSize: 13)),
        ),
      ],
    );
  }

  InputDecoration _inputDecor(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle:
          GoogleFonts.inter(fontSize: 12, color: AppColors.placeholder),
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
            color: AppColors.outlineVariant.withValues(alpha: 0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.espresso),
      ),
    );
  }
}
