import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../services/project_service.dart';
import '../services/api_client.dart';
import '../models/responses/api_responses.dart';
import 'proposals_page.dart';
import 'contract_otp_page.dart';
import 'contract_details_page.dart';
import 'design_deliverables_detail_page.dart';
import 'collaboration_workspace_page.dart';
import '../services/contract_service.dart';
import '../services/project_working_service.dart';
import '../services/construction_service.dart';
import '../services/design_service.dart';
import '../widgets/notifications_sheet.dart';
import 'home_page.dart';
import 'messages_page.dart';
import '../services/post_service.dart';
import 'edit_project_page.dart';
import 'ai_advice_page.dart';
import 'find_designers_page.dart';
import 'find_constructors_page.dart';

class ProjectDetailPage extends StatefulWidget {
  final int projectId;

  const ProjectDetailPage({super.key, required this.projectId});

  @override
  State<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends State<ProjectDetailPage> {
  ProjectResponse? _project;
  List<ProjectWorkingResponse> _projectWorkings = [];
  List<ConstructionItemResponse> _constructionItems = [];
  List<DesignResponse> _designs = [];
  List<ContractResponse> _contracts = [];
  bool _loading = true;
  String? _error;

  /// A contract awaiting the owner's OTP. Scans every engagement — looking at
  /// only the first missed contracts on the second provider.
  ContractResponse? get _pendingContract {
    for (final c in _contracts) {
      if (c.status.toLowerCase() == 'pending_otp') return c;
    }
    return null;
  }

  /// Designs still waiting on the owner's approve/revision decision.
  List<DesignResponse> get _designsAwaitingReview => _designs
      .where((d) => const {'pending', 'submitted'}.contains(d.status.toLowerCase()))
      .toList();

  /// Earliest unfinished milestone with a date — the genuine "next" one.
  ConstructionItemResponse? get _nextMilestone {
    final pending = _constructionItems
        .where((i) => i.status.toLowerCase() != 'completed' && i.estimateAt != null)
        .toList()
      ..sort((a, b) => a.estimateAt!.compareTo(b.estimateAt!));
    return pending.isNotEmpty ? pending.first : null;
  }

  /// Most recent work across designs and construction, newest first.
  List<({String title, DateTime at})> get _recentActivity {
    final items = <({String title, DateTime at})>[
      for (final d in _designs)
        (
          title: d.title.isNotEmpty
              ? '${d.title} · ${_designVerb(d.status)}'
              : 'Design ${_designVerb(d.status)}',
          at: d.updatedAt
        ),
      for (final c in _constructionItems)
        (title: '${c.name} · ${_itemVerb(c.status)}', at: c.updatedAt),
    ]..sort((a, b) => b.at.compareTo(a.at));
    return items.take(3).toList();
  }

  static String _designVerb(String status) => switch (status.toLowerCase()) {
        'approved' => 'approved',
        'revision' => 'revision requested',
        'submitted' => 'submitted',
        _ => 'updated',
      };

  static String _itemVerb(String status) => switch (status.toLowerCase()) {
        'completed' => 'completed',
        'in_progress' => 'in progress',
        _ => 'pending',
      };

  String _relativeDay(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inHours < 1) return 'just now';
    if (d.inHours < 24) return '${d.inHours}h ago';
    if (d.inDays == 1) return 'yesterday';
    if (d.inDays < 7) return '${d.inDays} days ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  void initState() {
    super.initState();
    _loadProject();
  }

  void _showNotifications() async {
    if (!await ApiClient.isLoggedIn() || !mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NotificationsSheet(
        onNotificationRead: () {},
      ),
    );
  }

  Future<void> _loadProject() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        ProjectService.getProject(widget.projectId),
        ProjectWorkingService.getProjectWorkings(projectShopOwnerId: widget.projectId, pageSize: 50),
      ]);
      final workings = (results[1] as PaginationResponse<ProjectWorkingResponse>).items;

      // Real milestone + activity data lives per-engagement, so gather it in
      // parallel rather than serially.
      final items = <ConstructionItemResponse>[];
      final designs = <DesignResponse>[];
      final contracts = <ContractResponse>[];
      if (workings.isNotEmpty) {
        final fetched = await Future.wait([
          for (final w in workings)
            ConstructionService.getMilestones(projectWorkingId: w.id, pageSize: 50)
                .then<Object?>((r) => r)
                .catchError((_) => null),
          for (final w in workings)
            DesignService.getDesigns(projectWorkingId: w.id, pageSize: 50)
                .then<Object?>((r) => r)
                .catchError((_) => null),
          for (final w in workings)
            ContractService.getContracts(projectWorkingId: w.id, pageSize: 50)
                .then<Object?>((r) => r)
                .catchError((_) => null),
        ]);
        for (final r in fetched) {
          if (r is PaginationResponse<ConstructionItemResponse>) items.addAll(r.items);
          // Unsubmitted provider drafts must not reach the owner's design list
          // or the Pending Approvals count derived from it.
          if (r is PaginationResponse<DesignResponse>) {
            designs.addAll(DesignService.ownerVisible(r.items));
          }
          if (r is PaginationResponse<ContractResponse>) contracts.addAll(r.items);
        }
      }

      if (mounted) {
        setState(() {
          _project = results[0] as ProjectResponse;
          _projectWorkings = workings;
          _constructionItems = items;
          _designs = designs;
          _contracts = contracts;
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
          _error = 'Failed to load project';
        });
      }
    }
  }

  // The backend has returned 'inprogress', 'in_progress', and 'active' for
  // the same state at different times — every "is this project active?"
  // check must tolerate all three or it silently dead-ends (e.g. the close
  // project button never rendering for a project whose status came back
  // spelled differently than expected).
  static const _activeStatuses = {'inprogress', 'in_progress', 'active'};

  double _progressFor(ProjectResponse p) {
    final status = p.status.toLowerCase();
    if (status == 'completed') return 1.0;
    if (status == 'draft') return 0.2;
    if (_activeStatuses.contains(status)) return 0.65;
    return 0.4;
  }

  String _statusLabel(String status) {
    if (status.isEmpty) return 'Draft';
    // Backend statuses are snake_case ('in_progress'), so split on the
    // underscore — capitalising the first letter alone leaked "In_progress".
    return status
        .split('_')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(' ');
  }

  // Budgets are stored in VND, not USD. Without the billions tier a typical
  // 1.5 tỷ budget rendered as the unreadable "1500.0M".
  String _formatMoney(double value) {
    if (value >= 1000000000) return '${(value / 1000000000).toStringAsFixed(1)}B ₫';
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M ₫';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}k ₫';
    return '${value.toStringAsFixed(0)} ₫';
  }

  String _formatMoneyFull(double value) {
    final s = value.toStringAsFixed(0);
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final fromEnd = s.length - i;
      buf.write(s[i]);
      if (fromEnd > 1 && fromEnd % 3 == 1) buf.write(',');
    }
    return '$buf ₫';
  }

  @override
  Widget build(BuildContext context) {
    final project = _project;

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
          project?.name ?? 'Project Detail',
          style: GoogleFonts.playfairDisplay(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.espresso,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
        actions: [
          if (project != null)
            IconButton(
              tooltip: 'Ask AI about this project',
              icon: const Icon(Icons.psychology_outlined, color: AppColors.espresso),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AiAdvicePage(project: project)),
              ),
            ),
          if (project != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppColors.espresso),
              onPressed: () async {
                final updated = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => EditProjectPage(project: project)),
                );
                if (updated != null) _loadProject();
              },
            ),
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: AppColors.espresso),
            onPressed: _showNotifications,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.espresso))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 16),
                        TextButton(onPressed: _loadProject, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  color: AppColors.espresso,
                  onRefresh: _loadProject,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        Text(
                          project!.name,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.espresso,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          project.address,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${project.areaM2.toStringAsFixed(0)} m² · ${_statusLabel(project.status)}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.placeholder,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildProgressCard(project),
                        const SizedBox(height: 20),
                        _buildBudgetOverview(project),
                        const SizedBox(height: 24),
                        if (project.providers.isNotEmpty) ...[
                          _buildNextMilestone(),
                          const SizedBox(height: 20),
                          _buildRecentActivity(),
                          const SizedBox(height: 20),
                          _buildPendingApprovals(),
                          const SizedBox(height: 20),
                          _buildProjectTeam(),
                          const SizedBox(height: 24),
                        ] else if (project.openPosts.isNotEmpty) ...[
                          _buildRecruitingStatus(project.openPosts),
                          const SizedBox(height: 24),
                        ] else ...[
                          _buildEmptyProvidersState(),
                          const SizedBox(height: 24),
                        ],
                        Text(
                          'Quick Actions',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.espresso,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildQuickActions(context),
                        const SizedBox(height: 24),
                        _buildProjectActions(project),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildProgressCard(ProjectResponse project) {
    final progress = _progressFor(project);
    final percent = (progress * 100).round();

    return Container(
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: const DecorationImage(
          image: NetworkImage('https://images.unsplash.com/photo-1554118811-1e0d58224f24?auto=format&fit=crop&q=80&w=600'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF56642B).withOpacity(0.8),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Status: ${_statusLabel(project.status)}',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    project.name,
                    style: GoogleFonts.inter(fontSize: 14, color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '$percent%',
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              height: 4,
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), borderRadius: BorderRadius.circular(2)),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress,
                child: Container(decoration: BoxDecoration(color: const Color(0xFFD9EAA3), borderRadius: BorderRadius.circular(2))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetOverview(ProjectResponse project) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'BUDGET OVERVIEW',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: AppColors.placeholder,
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: SizedBox(
              height: 120,
              width: 120,
              child: Stack(
                children: [
                  Center(
                    child: SizedBox(
                      width: 120,
                      height: 120,
                      child: CircularProgressIndicator(
                        value: 1.0,
                        strokeWidth: 12,
                        backgroundColor: AppColors.outlineVariant.withOpacity(0.5),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.espresso),
                      ),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatMoney(project.budget),
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.espresso),
                        ),
                        Text('Budget', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Budget', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Text(
                    _formatMoneyFull(project.budget),
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.espresso),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Area', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Text(
                    '${project.areaM2.toStringAsFixed(0)} m²',
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF56642B)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNextMilestone() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.espresso,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NEXT MILESTONE',
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.white.withOpacity(0.5)),
          ),
          const SizedBox(height: 16),
          Text(
            _nextMilestone?.name ?? 'No upcoming milestone',
            style: GoogleFonts.playfairDisplay(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined, size: 14, color: Colors.white.withOpacity(0.7)),
              const SizedBox(width: 8),
              Text(
                _nextMilestone?.estimateAt != null
                    ? '${_nextMilestone!.estimateAt!.day}/${_nextMilestone!.estimateAt!.month}/${_nextMilestone!.estimateAt!.year}'
                    : 'Scheduled once construction is planned',
                style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withOpacity(0.7)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String text, String time, Color dotColor, {bool hasLine = true}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(width: 8, height: 8, margin: const EdgeInsets.only(top: 4, bottom: 4), decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
            if (hasLine) Container(width: 1, height: 32, color: AppColors.outlineVariant.withOpacity(0.5)),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(text, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.espresso)),
              const SizedBox(height: 2),
              Text(time, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
              if (hasLine) const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivity() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Activity', style: GoogleFonts.playfairDisplay(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.espresso)),
              Text('View All', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.placeholder)),
            ],
          ),
          const SizedBox(height: 20),
          if (_recentActivity.isEmpty)
            Text(
              'No activity yet — updates appear here once your providers submit work.',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary, height: 1.5),
            )
          else
            for (final a in _recentActivity)
              _buildActivityItem(a.title, _relativeDay(a.at), const Color(0xFFD9EAA3)),
        ],
      )
    );
  }

  Widget _buildPendingApprovals() {
    // Nothing awaiting the owner — don't show an empty panel promising action.
    if (_pendingContract == null && _designsAwaitingReview.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pending Approvals', style: GoogleFonts.playfairDisplay(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.espresso)),
          const SizedBox(height: 16),
          // Both items are driven by data loaded with the project, so they
          // only appear when there is genuinely something to act on.
          if (_pendingContract != null)
            _buildApprovalItem(
              'Sign contract: ${_pendingContract!.title}',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ContractOtpPage(contract: _pendingContract!),
                  ),
                ).then((_) => _loadProject());
              },
            ),
          if (_pendingContract != null && _designsAwaitingReview.isNotEmpty)
            const SizedBox(height: 8),
          if (_designsAwaitingReview.isNotEmpty)
            _buildApprovalItem(
              _designsAwaitingReview.length == 1
                  ? 'Review design: ${_designsAwaitingReview.first.title}'
                  : 'Review ${_designsAwaitingReview.length} designs',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DesignDeliverablesDetailPage(
                      designs: _designsAwaitingReview,
                      onUpdated: _loadProject,
                    ),
                  ),
                ).then((_) => _loadProject());
              },
            ),
        ],
      )
    );
  }
  
  Widget _buildApprovalItem(String text, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F3F2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(text, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.espresso)),
            const Icon(Icons.chevron_right, size: 16, color: AppColors.placeholder),
          ],
        ),
      ),
    );
  }

  /// Engagements that belong on the Project Team card. The rule lives in
  /// ProjectWorkingService so this and the provider app agree on who counts
  /// as a member.
  ///
  /// Only the display is filtered — `_projectWorkings` still holds every row,
  /// because the slot rules and the project-completion check read it.
  List<ProjectWorkingResponse> get _teamMembers =>
      ProjectWorkingService.visibleTeam(_projectWorkings);

  Widget _buildProjectTeam() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Project Team', style: GoogleFonts.playfairDisplay(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.espresso)),
          const SizedBox(height: 16),
          if (_teamMembers.isEmpty)
            Text('No providers or requests yet.', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary))
          else
            ..._teamMembers.map((pw) {
              final name = pw.providerDisplayName.isNotEmpty ? pw.providerDisplayName : 'Unknown';
              // E.g. "Designer (Pending)"
              final statusCap = pw.status.isNotEmpty ? (pw.status[0].toUpperCase() + pw.status.substring(1).toLowerCase()) : '';
              final typeCap = pw.contractType.isNotEmpty ? (pw.contractType[0].toUpperCase() + pw.contractType.substring(1).toLowerCase()) : '';
              final roleAndStatus = '$typeCap ${statusCap.isNotEmpty ? '($statusCap)' : ''}'.trim();
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildTeamMember(
                  name, 
                  roleAndStatus, 
                  'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&background=random&color=fff',
                ),
              );
            }),
          if (_stillRecruiting.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Recruiting', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: AppColors.outline)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _stillRecruiting
                  .map((post) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryFixed.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_postLabel(post)} · ${post.status}',
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.espresso),
                        ),
                      ))
                  .toList(),
            ),
          ],
          // Deliberately outside the `_stillRecruiting` block above, and fed
          // `_openPosts` rather than `_stillRecruiting`. Applications keep
          // arriving on a post whose slot is now filled; the owner still needs
          // to see and decline them. `ProposalsPage` disables Accept per-card
          // with a reason when the slot is gone, so nothing unacceptable can be
          // accepted from here.
          if (_openPosts.isNotEmpty) ...[
            const SizedBox(height: 10),
            Center(
              child: TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProposalsPage(
                        openPosts: _openPosts,
                        designTaken: _designTaken,
                        constructionTaken: _constructionTaken,
                      ),
                    ),
                  ).then((_) => _loadProject());
                },
                icon: const Icon(Icons.how_to_reg_outlined, size: 16, color: AppColors.espresso),
                label: Text('View applications',
                    style: GoogleFonts.inter(
                        fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.espresso)),
              ),
            ),
          ],
          // Posts whose role has since been filled are still live on the
          // marketplace pulling in applications nobody can accept.
          if (_stalePosts.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Still posted but already filled',
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: AppColors.outline)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _stalePosts
                  .map((post) => GestureDetector(
                        onTap: () => _closePost(post, stale: true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF6F3F2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.outlineVariant),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_postLabel(post),
                                  style: GoogleFonts.inter(
                                      fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                              const SizedBox(width: 6),
                              const Icon(Icons.close_rounded, size: 13, color: AppColors.outline),
                            ],
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ],
          const SizedBox(height: 8),
          if (_designTaken && _constructionTaken)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  'Team complete — a designer and a constructor are on this project.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: _showRecruitProviderSheet,
                  icon: const Icon(Icons.add_circle_outline, size: 14, color: AppColors.espresso),
                  label: Text('Post Opening', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.espresso)),
                ),
                TextButton.icon(
                  onPressed: _browseProvidersForProject,
                  icon: const Icon(Icons.person_search_outlined, size: 14, color: AppColors.espresso),
                  label: Text('Find Provider', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.espresso)),
                ),
              ],
            ),
        ],
      ),
    );
  }

  /// A project holds one designer slot and one constructor slot; a 'both'
  /// engagement fills both. The rule itself lives in ProjectWorkingService so
  /// every screen that needs it reads the same definition — see the note there
  /// about keeping it in step with the backend.
  bool _roleTaken(String role) =>
      ProjectWorkingService.roleTaken(_projectWorkings, role);

  bool get _designTaken => _roleTaken('design');
  bool get _constructionTaken => _roleTaken('construction');

  String _postLabel(OpenPostResponse p) {
    final k = p.serviceKind.toLowerCase();
    if (k == 'both') return 'Designer + Constructor';
    if (k == 'design') return 'Designer';
    if (k == 'construction') return 'Constructor';
    return p.serviceKind.isEmpty ? 'Provider' : p.serviceKind;
  }

  /// True when a post is still advertised but the role it asks for is now
  /// filled — so it keeps attracting applications that can't be accepted.
  bool _postIsStale(OpenPostResponse p) {
    if (p.status.toLowerCase() != 'open') return false;
    switch (p.serviceKind.toLowerCase()) {
      case 'both':
        return _designTaken || _constructionTaken;
      case 'design':
        return _designTaken;
      case 'construction':
        return _constructionTaken;
      default:
        return false;
    }
  }

  /// Every post still open, whether or not its role has since been filled.
  ///
  /// Distinct from [_stillRecruiting]: a stale post is one whose slot is taken,
  /// so it shouldn't be advertised as recruiting — but it stays open on the
  /// marketplace and keeps collecting applications, and the owner still needs
  /// to reach those applicants to decline them. Gating "View applications" on
  /// [_stillRecruiting] hid the button exactly when the queue needed clearing.
  List<OpenPostResponse> get _openPosts =>
      (_project?.openPosts ?? const <OpenPostResponse>[])
          .where((p) => p.status.toLowerCase() == 'open')
          .toList();

  List<OpenPostResponse> get _stillRecruiting =>
      _openPosts.where((p) => !_postIsStale(p)).toList();

  List<OpenPostResponse> get _stalePosts =>
      (_project?.openPosts ?? const <OpenPostResponse>[]).where(_postIsStale).toList();

  Future<void> _closePost(OpenPostResponse post, {required bool stale}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Close this opening?',
            style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold, color: AppColors.espresso)),
        content: Text(
          stale
              ? 'The ${_postLabel(post)} role is already filled. Closing removes the '
                  'listing from the marketplace so you stop receiving applications.\n\n'
                  'Closed listings are not shown here afterwards — if you need this role '
                  'again, post a new opening.'
              : 'This removes the ${_postLabel(post)} listing from the marketplace. '
                  'You can post a new opening later if you still need this role.',
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep it')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Close listing',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.espresso)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await PostService.updatePost(post.id, UpdatePostRequest(status: 'closed'));
      await _loadProject();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Listing closed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not close listing: $e')),
        );
      }
    }
  }

  Future<void> _editPostDeadline(OpenPostResponse post) async {
    final initial = post.submissionDeadline ?? DateTime.now().add(const Duration(days: 30));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(DateTime.now()) ? initial : DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.espresso,
              onPrimary: Colors.white,
              onSurface: AppColors.espresso,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null) return;

    final deadline = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
    if (!deadline.isAfter(DateTime.now())) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Submission deadline must be later than the current time.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      await PostService.updatePost(post.id, UpdatePostRequest(submissionDeadline: deadline));
      await _loadProject();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Deadline updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update deadline: $e')),
        );
      }
    }
  }

  /// Browse providers with the project already known. Only roles the project
  /// still has an open slot for are offered.
  void _browseProvidersForProject() {
    final project = _project;
    if (project == null) return;

    final needsDesign = !_designTaken;
    final needsConstruction = !_constructionTaken;

    if (!needsDesign && !needsConstruction) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This project already has a designer and a constructor.')),
      );
      return;
    }

    // With only one slot left, pin the engagement to that role so a provider
    // who can do both doesn't silently claim the slot that's already filled.
    final onlyOneSlotLeft = needsDesign != needsConstruction;

    void open(bool constructor) {
      final forcedType = onlyOneSlotLeft ? (constructor ? 'construction' : 'design') : null;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => constructor
              ? FindConstructorsPage(
                  contextProjectId: project.id,
                  contextProjectName: project.name,
                  contextContractType: forcedType,
                )
              : FindDesignersPage(
                  contextProjectId: project.id,
                  contextProjectName: project.name,
                  contextContractType: forcedType,
                ),
        ),
      ).then((_) => _loadProject());
    }

    if (needsDesign && !needsConstruction) return open(false);
    if (needsConstruction && !needsDesign) return open(true);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            Text(
              'Who are you looking for?',
              style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.espresso),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.architecture_rounded, color: AppColors.espresso),
              title: Text('Designers', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.espresso)),
              onTap: () {
                Navigator.pop(sheetContext);
                open(false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.handyman_outlined, color: AppColors.espresso),
              title: Text('Constructors', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.espresso)),
              onTap: () {
                Navigator.pop(sheetContext);
                open(true);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showRecruitProviderSheet() {
    if (_project == null) return;

    final designOpen = !_designTaken;
    final constructionOpen = !_constructionTaken;
    // 'both' is a single provider covering both roles — only offer it while
    // neither slot is taken.
    final bothOpen = designOpen && constructionOpen;

    if (!designOpen && !constructionOpen) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This project already has a designer and a constructor.')),
      );
      return;
    }

    String selectedKind = designOpen ? 'design' : 'construction';
    final descriptionController = TextEditingController(
      text: 'Looking for a provider to work on ${_project!.name}.',
    );
    final now = DateTime.now();
    DateTime submissionDeadline = DateTime(now.year, now.month, now.day, 23, 59, 59).add(const Duration(days: 30));
    bool submitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            Widget kindOption(String value, String label) {
              final selected = selectedKind == value;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setSheetState(() => selectedKind = value),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.espresso : const Color(0xFFF6F3F2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: selected ? Colors.white : AppColors.espresso,
                      ),
                    ),
                  ),
                ),
              );
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Recruit a Provider', style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.espresso)),
                  const SizedBox(height: 4),
                  Text(
                    bothOpen
                        ? 'Post an opening so designers and constructors can apply to this project.'
                        : 'Post an opening for the role this project still needs.',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 20),
                  Text('WHO ARE YOU LOOKING FOR', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: AppColors.outline)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (designOpen) kindOption('design', 'Designer'),
                      if (constructionOpen) kindOption('construction', 'Constructor'),
                      if (bothOpen) kindOption('both', 'Both'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text('DESCRIPTION', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: AppColors.outline)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: descriptionController,
                    maxLines: 3,
                    style: GoogleFonts.inter(fontSize: 14, color: AppColors.espresso),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF6F3F2),
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('SUBMISSION DEADLINE', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: AppColors.outline)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      final today = DateTime.now();
                      final todayDateOnly = DateTime(today.year, today.month, today.day);
                      final picked = await showDatePicker(
                        context: sheetContext,
                        initialDate: submissionDeadline,
                        firstDate: todayDateOnly,
                        lastDate: todayDateOnly.add(const Duration(days: 365)),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: AppColors.espresso,
                                onPrimary: Colors.white,
                                onSurface: AppColors.espresso,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked == null) return;
                      // The backend accepts any deadline from today onward (it stores
                      // end-of-day, Vietnam time) — comparing dates rather than exact
                      // instants keeps "today" pickable no matter what time it is here.
                      if (picked.isBefore(todayDateOnly)) {
                        if (sheetContext.mounted) {
                          ScaffoldMessenger.of(sheetContext).showSnackBar(
                            const SnackBar(
                              content: Text('Submission deadline must be today or later.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                        return;
                      }
                      final deadline = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
                      setSheetState(() => submissionDeadline = deadline);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F3F2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.event_outlined, size: 16, color: AppColors.espresso),
                          const SizedBox(width: 8),
                          Text(
                            '${submissionDeadline.day.toString().padLeft(2, '0')}/${submissionDeadline.month.toString().padLeft(2, '0')}/${submissionDeadline.year}',
                            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.espresso),
                          ),
                          const Spacer(),
                          Text('Tap to change', style: GoogleFonts.inter(fontSize: 11, color: AppColors.placeholder)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: submitting
                          ? null
                          : () async {
                              final now = DateTime.now();
                              final deadlineDateOnly = DateTime(
                                submissionDeadline.year, submissionDeadline.month, submissionDeadline.day,
                              );
                              if (deadlineDateOnly.isBefore(DateTime(now.year, now.month, now.day))) {
                                ScaffoldMessenger.of(sheetContext).showSnackBar(
                                  const SnackBar(
                                    content: Text('Submission deadline must be today or later.'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                              setSheetState(() => submitting = true);
                              try {
                                await PostService.createPost(CreatePostRequest(
                                  projectShopOwnerId: _project!.id,
                                  serviceKind: selectedKind,
                                  title: _project!.name,
                                  description: descriptionController.text.trim().isEmpty
                                      ? 'Looking for a provider to work on ${_project!.name}.'
                                      : descriptionController.text.trim(),
                                  submissionDeadline: submissionDeadline,
                                ));
                                if (sheetContext.mounted) Navigator.pop(sheetContext);
                                await _loadProject();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Opening posted')),
                                  );
                                }
                              } catch (e) {
                                setSheetState(() => submitting = false);
                                if (sheetContext.mounted) {
                                  ScaffoldMessenger.of(sheetContext).showSnackBar(
                                    SnackBar(content: Text('Failed to post opening: $e')),
                                  );
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.espresso,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: submitting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text('Post Opening', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTeamMember(String name, String role, String avatarUrl) {
    return Row(
      children: [
        CircleAvatar(radius: 16, backgroundImage: NetworkImage(avatarUrl)),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.espresso)),
            Text(role, style: GoogleFonts.inter(fontSize: 9, color: AppColors.textSecondary)),
          ],
        )
      ],
    );
  }

  Future<void> _navigateToWorkspace(
    BuildContext context,
    String targetContractType,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator(color: AppColors.espresso)),
    );

    try {
      final workings = await ProjectWorkingService.getProjectWorkings(
        projectShopOwnerId: widget.projectId,
        pageSize: 50,
      );
      
      // Callers pass UI wording ('designer'/'constructor'); the backend stores
      // ServiceKind values ('design'/'construction'/'both'). Without this
      // mapping nothing ever matched and we silently fell through to the first
      // engagement — which could be the wrong provider entirely.
      final target = switch (targetContractType.toLowerCase()) {
        'designer' || 'design' => 'design',
        'constructor' || 'construction' => 'construction',
        final other => other,
      };

      // A rejected or terminated engagement is over — opening its workspace
      // would show the work of a provider no longer on the project.
      const live = {'requested', 'accepted', 'completed'};
      final candidates = workings.items
          .where((w) => live.contains(w.status.toLowerCase()))
          .toList();

      ProjectWorkingResponse? matchedWorking;
      for (final w in candidates) {
        final type = w.contractType.toLowerCase();
        // 'both' means one provider covering design and construction.
        if (type == target || type == 'both') {
          matchedWorking = w;
          break;
        }
      }

      if (matchedWorking == null && candidates.isNotEmpty) {
        // Fallback to first available if we are looking for a generic one
        matchedWorking = candidates.first;
      }

      if (matchedWorking == null) {
        if (mounted) {
          Navigator.pop(context); // close dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No active collaboration found for this project yet.')),
          );
        }
        return;
      }

      if (mounted) {
        final workingId = matchedWorking.id;
        Navigator.pop(context); // close dialog
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CollaborationWorkspacePage(projectWorkingId: workingId),
          ),
        ).then((_) => _loadProject());
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open workspace: $e')),
        );
      }
    }
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: [
              // Approve / Design / Constructor all opened the same
              // project-wide workspace, so they're one action now.
              _buildActionCard(
                Icons.dashboard_customize_outlined,
                'Workspace',
                onTap: () => _navigateToWorkspace(context, 'designer'),
              ),
              const SizedBox(height: 12),
              _buildActionCard(
                Icons.description_outlined,
                'Contract',
                onTap: () => _checkContract(context),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            children: [
              _buildActionCard(
                Icons.forum_outlined,
                'Message',
                onTap: () {
                  // Always let the owner pick the person first — a project can
                  // have a designer and a contractor, and guessing picked one
                  // of them and hid the other.
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MessagesPage(
                        projectId: widget.projectId,
                        projectName: _project?.name,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _checkContract(BuildContext context) async {
    if (_projectWorkings.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No project workings found for this project.')));
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator(color: AppColors.espresso)),
    );

    try {
      final allContracts = <ContractResponse>[];
      for (final working in _projectWorkings) {
        // pageSize: 1 silently hid every contract past the first one on an
        // engagement (e.g. a renegotiated/amended contract) from the
        // "Select Contract" picker below.
        final res = await ContractService.getContracts(projectWorkingId: working.id, pageSize: 50);
        if (res.items.isNotEmpty) {
          allContracts.addAll(res.items);
        }
      }

      if (mounted) {
        Navigator.pop(context); // close loading
        if (allContracts.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No contracts found.')));
        } else if (allContracts.length == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ContractDetailsPage(contract: allContracts.first),
            ),
          ).then((_) => _loadProject());
        } else {
          showModalBottomSheet(
            context: context,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            builder: (ctx) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Select Contract',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                ...allContracts.map((c) => ListTile(
                  leading: const Icon(Icons.description_outlined, color: AppColors.espresso),
                  title: Text(c.title.isNotEmpty ? c.title : 'Contract #${c.id}'),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ContractDetailsPage(contract: c)),
                    ).then((_) => _loadProject());
                  },
                )),
                const SizedBox(height: 16),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // close loading
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  
  Widget _buildActionCard(IconData icon, String label, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.outlineVariant.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.espresso, size: 24),
            const SizedBox(height: 8),
            Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.espresso)),
          ],
        ),
      ),
    );
  }

  Future<void> _completeProject() async {
    final engagements = _projectWorkings;
    final conMo = engagements
        .where((e) => ProjectWorkingService.engagedStatuses.contains(e.status.toLowerCase()))
        .toList();
    final daNghiemThu = engagements.where((e) => e.status == "completed").toList();

    if (conMo.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Còn ${conMo.length} hợp tác chưa đóng, hãy nghiệm thu hoặc huỷ trước.')),
      );
      return;
    }

    if (daNghiemThu.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cần ít nhất một hợp tác đã nghiệm thu để đóng dự án.')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đóng dự án'),
        content: const Text('Bạn có chắc chắn muốn đóng dự án này?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Không')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.espresso),
            child: const Text('Đóng dự án', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ProjectService.completeProject(widget.projectId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Project completed successfully.')),
        );
        _loadProject();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())), // Backend handles message
        );
      }
    }
  }

  Future<void> _cancelProject() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Project'),
        content: const Text(
          'Are you sure you want to cancel this project? This will terminate all open collaborations.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cancel Project', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ProjectService.cancelProject(widget.projectId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Project cancelled successfully.')),
        );
        _loadProject();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Widget _buildProjectActions(ProjectResponse project) {
    final status = project.status.toLowerCase();
    final canCancel = status == 'briefed' || _activeStatuses.contains(status);
    final isCompleted = status == 'completed';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_activeStatuses.contains(status)) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _completeProject,
              icon: const Icon(Icons.verified, size: 20, color: Colors.white),
              label: const Text('Đóng dự án'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.espresso,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (canCancel) ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _cancelProject,
              icon: const Icon(Icons.cancel, size: 20, color: Colors.red),
              label: const Text('Cancel Project'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
        // Delete is only offered once the project is closed — the backend
        // rejects it otherwise ("cancel or complete before deleting").
        if (isCompleted || project.status.toLowerCase() == 'cancelled') ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _deleteProject,
              icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
              label: const Text('Delete project'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _deleteProject() async {
    final name = _project?.name ?? 'this project';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete project?',
            style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold, color: AppColors.espresso)),
        content: Text(
          'This permanently removes "$name" and its history. This cannot be undone.',
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ProjectService.deleteProject(widget.projectId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Project deleted')),
      );
      Navigator.pop(context, true); // back to the list, which reloads
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not delete: $e')),
        );
      }
    }
  }

  Widget _buildRecruitingStatus(List<OpenPostResponse> posts) {
    final openPosts = posts.where((p) => p.status.toLowerCase() == 'open').toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.espresso, width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.campaign_outlined, color: AppColors.espresso, size: 18),
              const SizedBox(width: 8),
              Text('FINDING PROVIDERS...', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: AppColors.espresso)),
            ],
          ),
          const SizedBox(height: 16),
          ...openPosts.map((post) {
            final deadlineStr = post.submissionDeadline != null 
                ? '${post.submissionDeadline!.day}/${post.submissionDeadline!.month}/${post.submissionDeadline!.year}'
                : 'N/A';
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBF8F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post.title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.espresso)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.work_outline, size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(_postLabel(post).toUpperCase(), style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                        const SizedBox(width: 16),
                        const Icon(Icons.timer_outlined, size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text('Deadline: $deadlineStr', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: () => _editPostDeadline(post),
                          icon: const Icon(Icons.edit_calendar_outlined, size: 14, color: AppColors.espresso),
                          label: Text('Edit deadline', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.espresso)),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                            minimumSize: const Size(0, 32),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: () => _closePost(post, stale: false),
                          icon: const Icon(Icons.close_rounded, size: 14, color: Colors.red),
                          label: Text('Close listing', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red)),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                            minimumSize: const Size(0, 32),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
          Center(
            child: ElevatedButton.icon(
              onPressed: openPosts.isEmpty
                  ? null
                  : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProposalsPage(
                      openPosts: openPosts,
                      designTaken: _designTaken,
                      constructionTaken: _constructionTaken,
                    ),
                  ),
                ).then((_) => _loadProject());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.espresso,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                minimumSize: const Size(0, 36),
              ),
              icon: const Icon(Icons.list_alt, size: 14),
              label: Text('View Proposals', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      )
    );
  }

  Widget _buildEmptyProvidersState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.5)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.handshake_outlined, size: 32, color: AppColors.placeholder),
            const SizedBox(height: 12),
            Text('No Providers Yet', style: GoogleFonts.playfairDisplay(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.espresso)),
            const SizedBox(height: 8),
            Text(
              'Broadcast your project to marketplace to find designers and constructors.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const HomePage(initialIndex: 2)),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.espresso,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                minimumSize: const Size(0, 36),
              ),
              child: Text('Find Providers', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

