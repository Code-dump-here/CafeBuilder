import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../services/project_service.dart';
import '../services/api_client.dart';
import '../services/service_provider_service.dart';
import '../models/responses/api_responses.dart';
import 'designer_workspace_page.dart';
import 'collaboration_page.dart';
import 'proposals_page.dart';
import 'contract_otp_page.dart';
import 'contract_details_page.dart';
import 'collaboration_workspace_page.dart';
import '../services/contract_service.dart';
import '../services/project_working_service.dart';
import '../widgets/notifications_sheet.dart';
import 'home_page.dart';
import 'chat_thread_page.dart';
import '../services/chat_service.dart';
import '../services/post_service.dart';
import 'edit_project_page.dart';
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
  String _ownerFirstName = 'Owner';
  List<ProjectWorkingResponse> _projectWorkings = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProject();
  }

  void _showNotifications() async {
    final accountId = await ApiClient.getAccountId();
    if (accountId == null || !mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NotificationsSheet(
        accountId: accountId,
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
        ShopOwnerService.getCurrentOwnerFirstName(),
        ProjectWorkingService.getProjectWorkings(projectShopOwnerId: widget.projectId, pageSize: 50),
      ]);
      if (mounted) {
        setState(() {
          _project = results[0] as ProjectResponse;
          _ownerFirstName = results[1] as String;
          _projectWorkings = (results[2] as PaginationResponse<ProjectWorkingResponse>).items;
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
    return status[0].toUpperCase() + status.substring(1);
  }

  String _formatMoney(double value) {
    if (value >= 1000000) return '\$${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '\$${(value / 1000).toStringAsFixed(0)}k';
    return '\$${value.toStringAsFixed(0)}';
  }

  String _formatMoneyFull(double value) {
    final s = value.toStringAsFixed(0);
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final fromEnd = s.length - i;
      buf.write(s[i]);
      if (fromEnd > 1 && fromEnd % 3 == 1) buf.write(',');
    }
    return '\$$buf';
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
      floatingActionButton: project == null
          ? null
          : FloatingActionButton(
              onPressed: () {},
              backgroundColor: AppColors.espresso,
              child: const Icon(Icons.add, color: Colors.white),
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
                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
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
              fontSize: 10,
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
                        Text('Budget', style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary)),
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
                  Text('Total Budget', style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary)),
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
                  Text('Area', style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary)),
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
            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.white.withOpacity(0.5)),
          ),
          const SizedBox(height: 16),
          Text(
            'Lighting Plan Approval',
            style: GoogleFonts.playfairDisplay(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined, size: 14, color: Colors.white.withOpacity(0.7)),
              const SizedBox(width: 8),
              Text(
                'Oct 28, 2024',
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
              Text(time, style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary)),
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
              Text('View All', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.placeholder)),
            ],
          ),
          const SizedBox(height: 20),
          _buildActivityItem('Designer uploaded revised render', '2 hours ago', const Color(0xFFD9EAA3)),
          _buildActivityItem('Contractor submitted quotation', 'Yesterday', const Color(0xFFD9EAA3)),
          _buildActivityItem('$_ownerFirstName approved Floor Layout v.2', 'Oct 24', AppColors.outlineVariant, hasLine: false),
        ],
      )
    );
  }

  Widget _buildPendingApprovals() {
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
          _buildApprovalItem('Sign Pending Contract', onTap: () async {
            // Find the project working and contract
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => const Center(child: CircularProgressIndicator(color: AppColors.espresso)),
            );
            try {
              final workings = await ProjectWorkingService.getProjectWorkings(projectShopOwnerId: _project!.id, pageSize: 1);
              if (workings.items.isEmpty) throw Exception('No active engagement found.');
              
              final contracts = await ContractService.getContracts(projectWorkingId: workings.items.first.id, pageSize: 50);
              final pendingContracts = contracts.items.where((c) => c.status == 'pending_otp').toList();
              if (pendingContracts.isEmpty) throw Exception('No pending contract found for this engagement.');
              
              if (mounted) {
                Navigator.pop(context); // close dialog
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ContractOtpPage(contract: pendingContracts.first)),
                ).then((_) => _loadProject());
              }
            } catch (e) {
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
              }
            }
          }),
          const SizedBox(height: 8),
          _buildApprovalItem('Approve 3D Layout'),
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
          if (_projectWorkings.isEmpty)
            Text('No providers or requests yet.', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary))
          else
            ..._projectWorkings.map((pw) {
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
          if (_project != null && _project!.openPosts.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Recruiting', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: AppColors.outline)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _project!.openPosts.map((post) {
                final label = post.serviceKind == 'both'
                    ? 'Designer + Constructor'
                    : (post.serviceKind.isNotEmpty ? (post.serviceKind[0].toUpperCase() + post.serviceKind.substring(1)) : 'Provider');
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryFixed.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$label · ${post.status}',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.espresso),
                  ),
                );
              }).toList(),
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
                  style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary),
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
                  label: Text('Post Opening', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.espresso)),
                ),
                TextButton.icon(
                  onPressed: _browseProvidersForProject,
                  icon: const Icon(Icons.person_search_outlined, size: 14, color: AppColors.espresso),
                  label: Text('Find Provider', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.espresso)),
                ),
              ],
            ),
        ],
      ),
    );
  }

  /// A project holds one designer slot and one constructor slot. A slot is
  /// taken once a provider is actually on the project — a pending invite
  /// ('requested') doesn't hold one, and a rejected/terminated engagement
  /// releases it. A 'both' engagement is one provider filling both slots.
  static const _engagedStatuses = {'accepted', 'completed'};

  bool _roleTaken(String role) {
    return _projectWorkings.any((pw) {
      if (!_engagedStatuses.contains(pw.status.toLowerCase())) return false;
      final type = pw.contractType.toLowerCase();
      return type == role || type == 'both';
    });
  }

  bool get _designTaken => _roleTaken('design');
  bool get _constructionTaken => _roleTaken('construction');

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
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: submitting
                          ? null
                          : () async {
                              setSheetState(() => submitting = true);
                              try {
                                await PostService.createPost(CreatePostRequest(
                                  projectShopOwnerId: _project!.id,
                                  serviceKind: selectedKind,
                                  title: _project!.name,
                                  description: descriptionController.text.trim().isEmpty
                                      ? 'Looking for a provider to work on ${_project!.name}.'
                                      : descriptionController.text.trim(),
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

  Future<void> _navigateToWorkspace(BuildContext context, String targetContractType, {bool isChat = false}) async {
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
      
      ProjectWorkingResponse? matchedWorking;
      for (final w in workings.items) {
        final type = w.contractType.toLowerCase();
        if (type == targetContractType.toLowerCase() || type == 'company') {
          matchedWorking = w;
          break;
        }
      }

      if (matchedWorking == null && workings.items.isNotEmpty) {
        // Fallback to first available if we are looking for a generic one
        matchedWorking = workings.items.first;
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

      if (isChat) {
        // conversationId is a separate entity from the engagement id —
        // find (or create) the real thread before opening it.
        final conversationId = await ChatService.getOrCreateConversation(matchedWorking.id);
        if (mounted) {
          Navigator.pop(context); // close dialog
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatThreadPage(
                conversationId: conversationId,
                title: matchedWorking!.providerDisplayName.isNotEmpty ? 'Chat with ${matchedWorking.providerDisplayName}' : 'Chat',
              ),
            ),
          );
        }
      } else if (mounted) {
        final workingId = matchedWorking.id;
        Navigator.pop(context); // close dialog
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CollaborationWorkspacePage(projectWorkingId: workingId),
          ),
        );
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
              _buildActionCard(
                Icons.check_circle_outline,
                'Approve',
                onTap: () {
                  _navigateToWorkspace(context, 'designer');
                },
              ),
              const SizedBox(height: 12),
              _buildActionCard(
                Icons.design_services_outlined,
                'Design',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const DesignerWorkspacePage(projectWorkingId: 0)),
                  );
                },
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
                Icons.group_outlined, 
                'Collab', 
                onTap: () {
                  _navigateToWorkspace(context, 'designer', isChat: true);
                },
              ),
              const SizedBox(height: 12),
              _buildActionCard(
                Icons.construction_outlined,
                'Constructor',
                onTap: () {
                  _navigateToWorkspace(context, 'constructor');
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
        final res = await ContractService.getContracts(projectWorkingId: working.id, pageSize: 1);
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
    final conMo = engagements.where((e) => ["requested", "accepted"].contains(e.status)).toList();
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
        title: const Text('Huỷ dự án'),
        content: const Text('Bạn có chắc chắn muốn huỷ dự án này? Thao tác này sẽ huỷ tất cả hợp tác đang mở.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Không')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Huỷ dự án', style: TextStyle(color: Colors.white)),
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
    final canCancel = ["briefed", "in_progress"].contains(project.status.toLowerCase());
    final isCompleted = project.status.toLowerCase() == "completed";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (project.status.toLowerCase() == 'in_progress') ...[
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
              label: const Text('Huỷ dự án'),
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

  Widget _buildRecruitingStatus(List<OpenPostResponse> posts) {
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
              Text('FINDING PROVIDERS...', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: AppColors.espresso)),
            ],
          ),
          const SizedBox(height: 16),
          ...posts.map((post) {
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
                        Text(post.serviceKind.toUpperCase(), style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary)),
                        const SizedBox(width: 16),
                        const Icon(Icons.timer_outlined, size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text('Deadline: $deadlineStr', style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary)),
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
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProposalsPage(openPosts: posts)),
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

