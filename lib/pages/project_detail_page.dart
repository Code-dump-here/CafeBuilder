import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../services/project_service.dart';
import '../services/api_client.dart';
import '../services/service_provider_service.dart';
import '../models/responses/api_responses.dart';
import 'design_packages_page.dart';
import 'collaboration_page.dart';
import 'proposals_page.dart';
import 'contract_otp_page.dart';
import 'collaboration_workspace_page.dart';
import '../services/contract_service.dart';
import '../services/project_working_service.dart';

class ProjectDetailPage extends StatefulWidget {
  final int projectId;

  const ProjectDetailPage({super.key, required this.projectId});

  @override
  State<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends State<ProjectDetailPage> {
  ProjectResponse? _project;
  String _ownerFirstName = 'Owner';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProject();
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
      ]);
      if (mounted) {
        setState(() {
          _project = results[0] as ProjectResponse;
          _ownerFirstName = results[1] as String;
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
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: AppColors.espresso),
            onPressed: () {},
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
              
              final contracts = await ContractService.getContracts(projectWorkingId: workings.items.first.id, pageSize: 1);
              if (contracts.items.isEmpty) throw Exception('No pending contract found for this engagement.');
              
              if (mounted) {
                Navigator.pop(context); // close dialog
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ContractOtpPage(contract: contracts.items.first)),
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
          _buildTeamMember('Elena Vo', 'Lead Designer', 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&q=80&w=150'),
          const SizedBox(height: 12),
          _buildTeamMember('Trung Nguyen', 'General Contractor', 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&q=80&w=150'),
          const SizedBox(height: 20),
          Center(
            child: TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add_circle_outline, size: 14, color: AppColors.espresso),
              label: Text('Invite Stakeholder', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.espresso)),
            ),
          ),
        ],
      ),
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

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              _buildActionCard(
                Icons.check_circle_outline,
                'Approve',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CollaborationWorkspacePage()),
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildActionCard(
                Icons.design_services_outlined,
                'Design',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const DesignPackagesPage()),
                  );
                },
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CollaborationWorkspacePage()),
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildActionCard(
                Icons.construction_outlined,
                'Constructor',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CollaborationWorkspacePage()),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
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
              onPressed: () {},
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

