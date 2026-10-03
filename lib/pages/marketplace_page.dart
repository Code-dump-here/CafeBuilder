import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../models/marketplace_state.dart';
import '../services/api_client.dart';
import '../services/post_service.dart';
import '../services/project_service.dart';
import '../services/service_provider_service.dart';
import '../models/responses/api_responses.dart';
import '../utils/money.dart';
import '../widgets/notifications_sheet.dart';

class MarketplacePage extends StatefulWidget {
  final bool showBackButton;
  const MarketplacePage({super.key, this.showBackButton = false});

  @override
  State<MarketplacePage> createState() => _MarketplacePageState();
}

class _MarketplacePageState extends State<MarketplacePage>
    with SingleTickerProviderStateMixin {
  static const String _fallbackImage =
      'https://images.unsplash.com/photo-1554118811-1e0d58224f24?auto=format&fit=crop&q=80&w=600';

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  /// The owner's completed projects, kept apart from
  /// `MarketplaceState.broadcasts` because they are projects, not postings.
  final List<BroadcastProject> _completedProjects = [];

  List<BroadcastProject> _matchingSearch(List<BroadcastProject> items) {
    final q = _searchQuery.toLowerCase();
    if (q.isEmpty) return List.of(items);
    return items
        .where((item) =>
            item.title.toLowerCase().contains(q) ||
            item.location.toLowerCase().contains(q) ||
            item.style.toLowerCase().contains(q))
        .toList();
  }
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

  /// Same sheet the project detail screen opens. The login guard matters
  /// here in a way it does not there: the marketplace is a tab on the home
  /// page, so it builds for signed-out visitors too.
  void _showNotifications() async {
    if (!await ApiClient.isLoggedIn() || !mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NotificationsSheet(onNotificationRead: () {}),
    );
  }

  /// Loads the two tabs: the owner's own open postings, and their own
  /// completed projects.
  ///
  /// Both halves are scoped to the signed-in owner. The page used to ask for
  /// every post on the platform with no filter at all, which made the first tab
  /// a public marketplace and the second one "every post anywhere that is no
  /// longer open" — someone else's filled posting read as a completed project
  /// of yours, and a post closed on day one of a six-month build read as
  /// finished work.
  Future<void> _fetchPosts() async {
    try {
      final shopOwnerId = await ShopOwnerService.ensureShopOwnerId();
      final projects = await ProjectService.getProjects(
        ownerId: shopOwnerId,
        pageSize: 100,
      );
      final mine = {for (final p in projects.items) p.id: p};

      final posts = await PostService.getPosts(
        pageNumber: 1,
        pageSize: 100,
        status: 'open',
      );
      if (!mounted) return;

      // Newest first. This used to sort the mapped list by descending numeric
      // id; ids are uuids now, so `int.tryParse` returned null for every row
      // and the comparison was constant — the list silently kept whatever
      // order the server sent. `createdAt` is what "newest" actually meant, so
      // sort on that, before mapping.
      final myOpenPosts = posts.items
          .where((post) => mine.containsKey(post.projectShopOwnerId))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      final completed = projects.items
          .where((project) => project.status.toLowerCase() == 'completed')
          .toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      setState(() {
        MarketplaceState.broadcasts
          ..clear()
          ..addAll(myOpenPosts.map(_broadcastFromPost));
        _completedProjects
          ..clear()
          ..addAll(completed.map(_broadcastFromProject));
      });
    } catch (e) {
      debugPrint('Error fetching the market page: $e');
    }
  }

  BroadcastProject _broadcastFromPost(PostResponse post) {
    // The AI concept image is carried inside the description the owner posted.
    String imageUrl = _fallbackImage;
    final aiImageMatch = RegExp(r'🖼️ AI_IMAGE: (.+)').firstMatch(post.description);
    if (aiImageMatch != null && aiImageMatch.group(1)!.trim().isNotEmpty) {
      imageUrl = aiImageMatch.group(1)!.trim();
    }
    return BroadcastProject(
      id: post.id.toString(),
      title: post.title.isNotEmpty ? post.title : 'Marketplace Project',
      location: post.location.isNotEmpty ? post.location : 'Remote',
      style: post.style.isNotEmpty ? post.style : 'Concept',
      budgetTier: post.budgetTier.isNotEmpty ? post.budgetTier : 'TBD',
      description: post.description.isNotEmpty
          ? post.description
          : 'A beautiful architecture project.',
      requirements:
          post.requirements.isNotEmpty ? post.requirements : ['Interior Design'],
      date: post.expectedStart.isNotEmpty
          ? post.expectedStart
          : post.createdAt.toString().substring(0, 10),
      proposalsCount: 0,
      commentsCount: 0,
      status: post.status,
      imageUrl: imageUrl,
    );
  }

  /// A finished project rendered as a card. It carries no recruitment data —
  /// there is no posting behind it any more — so the fields a post would fill
  /// read from the project itself.
  BroadcastProject _broadcastFromProject(ProjectResponse project) {
    return BroadcastProject(
      id: project.id,
      title: project.name.isNotEmpty ? project.name : 'Project',
      location: project.address.isNotEmpty ? project.address : 'Remote',
      style: '${project.areaM2.toStringAsFixed(0)} m²',
      budgetTier: formatVnd(project.budget),
      description: 'Completed on '
          '${project.updatedAt.toString().substring(0, 10)}.',
      requirements: const <String>[],
      date: project.updatedAt.toString().substring(0, 10),
      proposalsCount: 0,
      commentsCount: 0,
      status: project.status,
      imageUrl: _fallbackImage,
    );
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
    final openItems = _matchingSearch(MarketplaceState.broadcasts);
    final completedItems = _matchingSearch(_completedProjects);

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
            onPressed: _showNotifications,
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
            // Was a `tune` icon that did nothing — there are no filters on
            // this screen to open. A search field's suffix earns its place by
            // clearing the query, which otherwise takes selecting the whole
            // string by hand.
            suffixIcon: _searchQuery.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close,
                        color: AppColors.espresso, size: 20),
                    tooltip: 'Clear search',
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
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
                  ? 'Your finished projects will appear here.'
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
                // Address and style shared one line and each ended up with
                // half a phone width. In a Wrap they take the width they need
                // and the style drops to its own line when the address is long.
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _buildIconLabel(Icons.location_on, project.location),
                    _buildIconLabel(Icons.color_lens_outlined, project.style),
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
                        open
                            ? 'View Detail'
                            : project.status.toLowerCase() == 'completed'
                                ? 'Completed'
                                : 'Assigned',
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
                          Text(project.status.toUpperCase(),
                              style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.placeholder)),
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
                                    color: const Color(0xFFD9EAA3).withValues(alpha: 0.9),
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
                      const SizedBox(height: 28),
                      _buildSectionLabel('PROJECT DESCRIPTION'),
                      const SizedBox(height: 10),
                      _buildRichDescription(project.description),
                      const SizedBox(height: 28),
                      _buildSectionLabel('SERVICE REQUIREMENTS'),
                      const SizedBox(height: 10),
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
                                          fontSize: 12,
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

  /// Heading for a block of the detail sheet.
  ///
  /// The sheet used to set every label at 9pt in the placeholder grey and
  /// every value at 13pt in the secondary grey, so a heading carried no more
  /// weight than the sentence under it and the whole sheet read as one page of
  /// grey. A heading is darker, larger and sits above a rule; the text under it
  /// is darker and roomier (see `_buildRichDescription`).
  Widget _buildSectionLabel(String text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppColors.espresso,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Container(height: 1, color: AppColors.outlineVariant),
      ],
    );
  }

  /// Icon + label pair sized to its text.
  ///
  /// `MainAxisSize.min` keeps it compact inside a `Wrap`, and the `Flexible`
  /// lets a long address wrap onto further lines instead of running past the
  /// card — a `Wrap` hands its children the full row width to work with.
  Widget _buildIconLabel(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 12, color: AppColors.placeholder),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            style: GoogleFonts.inter(
                fontSize: 11, color: AppColors.textSecondary),
          ),
        ),
      ],
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
          Text(label.toUpperCase(),
              style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          Text(val,
              style: GoogleFonts.playfairDisplay(
                  fontSize: 16,
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
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    height: 1.6)),
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
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    height: 1.6)),
        ],
      );
    }

    return Text(text,
        style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.textPrimary,
            height: 1.6));
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
