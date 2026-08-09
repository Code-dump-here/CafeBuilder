import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../models/responses/api_responses.dart';
import '../services/project_working_service.dart';
import '../services/design_service.dart';
import 'file_review_detail_page.dart';

class DesignerWorkspacePage extends StatefulWidget {
  final int? projectWorkingId;

  const DesignerWorkspacePage({super.key, this.projectWorkingId});

  @override
  State<DesignerWorkspacePage> createState() => _DesignerWorkspacePageState();
}

class _DesignerWorkspacePageState extends State<DesignerWorkspacePage> {
  bool _loading = true;
  String? _error;
  int? _activeWorkingId;
  ProjectWorkingResponse? _working;
  List<DesignResponse> _designs = [];

  @override
  void initState() {
    super.initState();
    _loadWorkspaceData();
  }

  Future<void> _loadWorkspaceData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      int? workingId = widget.projectWorkingId;
      if (workingId == null) {
        final workings = await ProjectWorkingService.getProjectWorkings(pageSize: 1);
        if (workings.items.isNotEmpty) {
          workingId = workings.items.first.id;
        } else {
          workingId = 0;
        }
      }

      if (workingId == 0) {
        setState(() {
          _loading = false;
          _activeWorkingId = 0;
          _error = null;
        });
        return;
      }

      _activeWorkingId = workingId;
      final workingRes = await ProjectWorkingService.getProjectWorking(workingId);
      final projectId = workingRes.projectShopOwnerId;

      final workingsPage = await ProjectWorkingService.getProjectWorkings(projectShopOwnerId: projectId, pageSize: 50);
      final allWorkingIds = workingsPage.items.map((w) => w.id).toList();

      List<DesignResponse> allDesigns = [];

      for (int wId in allWorkingIds) {
        final results = await DesignService.getDesigns(projectWorkingId: wId, pageSize: 50);
        allDesigns.addAll(results.items);
      }

      if (mounted) {
        setState(() {
          _working = workingRes;
          _designs = allDesigns;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _approveDesign(int designId) async {
    try {
      await DesignService.approveDesign(designId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Design approved successfully!')),
        );
        _loadWorkspaceData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Approval failed: $e')),
        );
      }
    }
  }

  Future<void> _requestRevision(int designId) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Request Revision'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Enter feedback for designer...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.espresso),
            child: const Text('Submit', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (reason == null || reason.isEmpty) return;

    try {
      await DesignService.requestRevision(designId, reason: reason);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Revision request submitted.')),
        );
        _loadWorkspaceData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.primaryFixed,
              child: const Icon(Icons.design_services, size: 16, color: AppColors.primary),
            ),
            const SizedBox(width: 8),
            const Text(
              'Designer Workspace',
              style: TextStyle(
                color: AppColors.appName,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: _loadWorkspaceData,
          ),
        ],
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.espresso))
          : (_error != null || _activeWorkingId == 0)
              ? SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 80),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF6F3F1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.design_services, size: 64, color: AppColors.espresso),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'No Active Workspace',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.espresso,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _activeWorkingId == 0 
                              ? 'No active engagement or contract found for this project yet. Once a designer is selected and approved, your workspace will appear here.'
                              : _error!,
                          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
                          textAlign: TextAlign.center,
                        ),
                        if (_activeWorkingId != 0) ...[
                          const SizedBox(height: 32),
                          ElevatedButton.icon(
                            onPressed: _loadWorkspaceData,
                            icon: const Icon(Icons.refresh, size: 18, color: Colors.white),
                            label: const Text('Try Again'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.espresso,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                              textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  color: AppColors.espresso,
                  onRefresh: _loadWorkspaceData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Designer Workspace',
                          style: GoogleFonts.playfairDisplay(
                            color: AppColors.textPrimary,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Engagement ID #${_working?.id} • Designer: ${_working?.providerDisplayName ?? 'Partner Studio'}',
                          style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
                        ),
                        const SizedBox(height: 20),
                        
                        _buildDesignSection(),
                        const SizedBox(height: 24),
                        _buildActionButtons(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildDesignSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Design Deliverables',
                style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.espresso),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(6)),
                child: Text('${_designs.length} Items', style: GoogleFonts.inter(fontSize: 11, color: Colors.blue.shade800, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_designs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text('No design deliverables uploaded by designer yet.', style: GoogleFonts.inter(fontSize: 12, color: AppColors.placeholder)),
            )
          else
            ..._designs.map((design) => _buildDesignCard(design)),
        ],
      ),
    );
  }

  Widget _buildDesignCard(DesignResponse design) {
    final isApproved = design.status == 'approved';
    final isRevision = design.status == 'revision';
    final isPending = !isApproved && !isRevision;

    final statusColor = isApproved
        ? const Color(0xFF2E7D32)
        : isRevision
            ? const Color(0xFFC62828)
            : const Color(0xFFE65100);
    final statusBg = isApproved
        ? const Color(0xFFE8F5E9)
        : isRevision
            ? const Color(0xFFFFEBEE)
            : const Color(0xFFFFF3E0);
    final statusLabel = isApproved ? '✓ Approved' : isRevision ? '↩ Revision' : '⏳ Pending';

    final firstImage = design.images.isNotEmpty ? design.images.first.viewUrl : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (firstImage != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Stack(
                children: [
                  Image.network(
              webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                    firstImage,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 160,
                      color: const Color(0xFFF6F3F1),
                      child: const Center(child: Icon(Icons.image_not_supported, color: AppColors.outlineVariant, size: 40)),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        statusLabel,
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              height: 80,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFF6F3F1),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    statusLabel,
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor),
                  ),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  design.title,
                  style: GoogleFonts.playfairDisplay(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.espresso),
                ),
                const SizedBox(height: 4),
                Text(
                  '${design.type} · Version ${design.version.toStringAsFixed(1)}',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.placeholder),
                ),
                const SizedBox(height: 16),
                if (isPending) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _approveDesign(design.id),
                      icon: const Icon(Icons.check_circle_outline, size: 18, color: Colors.white),
                      label: const Text('Approve Design'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _requestRevision(design.id),
                      icon: const Icon(Icons.edit_note, size: 18, color: AppColors.espresso),
                      label: const Text('Request Revision'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.espresso,
                        side: const BorderSide(color: AppColors.outlineVariant),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ] else
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final statusEnum = isApproved
                            ? ReviewItemStatus.approved
                            : ReviewItemStatus.revision;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FileReviewDetailPage(
                              title: design.title,
                              imageUrl: firstImage ?? 'https://images.unsplash.com/photo-1554118811-1e0d58224f24?auto=format&fit=crop&q=80&w=600',
                              status: statusEnum,
                              designId: design.id,
                              onUpdated: _loadWorkspaceData,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.remove_red_eye_outlined, size: 18, color: AppColors.espresso),
                      label: const Text('View Details'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.espresso,
                        side: const BorderSide(color: AppColors.outlineVariant),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _requestCompletion() async {
    if (_activeWorkingId == null) return;
    try {
      await ProjectWorkingService.requestCompletion(_activeWorkingId!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Báo hoàn thành thành công.')),
        );
        _loadWorkspaceData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), duration: const Duration(seconds: 5)),
        );
      }
    }
  }

  Future<void> _terminateEngagement() async {
    if (_activeWorkingId == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Huỷ hợp tác'),
        content: const Text('Bạn có chắc chắn muốn huỷ ngang hợp tác này không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Không')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Huỷ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ProjectWorkingService.terminateEngagement(_activeWorkingId!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã huỷ hợp tác.')),
        );
        _loadWorkspaceData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), duration: const Duration(seconds: 5)),
        );
      }
    }
  }

  Widget _buildActionButtons() {
    if (_working == null) return const SizedBox();
    
    final bool canRequestCompletion = _working!.status == 'accepted' && _working!.hasConfirmedContract && !_working!.isAwaitingAcceptance;
    final bool isAwaitingAcceptance = _working!.isAwaitingAcceptance;
    final bool canTerminate = _working!.status == 'accepted';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (canRequestCompletion)
          ElevatedButton.icon(
            onPressed: _requestCompletion,
            icon: const Icon(Icons.check_circle, color: Colors.white),
            label: const Text('Báo hoàn thành'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          )
        else if (isAwaitingAcceptance)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.hourglass_empty, color: Colors.orange.shade800, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Đang chờ nghiệm thu',
                  style: GoogleFonts.inter(
                    color: Colors.orange.shade800,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          
        if (canTerminate) ...[
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _terminateEngagement,
            icon: const Icon(Icons.cancel_outlined, color: Colors.red),
            label: const Text('Huỷ ngang'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ],
    );
  }
}
