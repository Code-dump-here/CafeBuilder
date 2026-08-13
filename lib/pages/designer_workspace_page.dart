import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../models/responses/api_responses.dart';
import '../services/project_working_service.dart';
import '../services/design_service.dart';
import 'design_deliverables_detail_page.dart';

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
          // Drafts the provider hasn't submitted aren't the owner's business.
          _designs = DesignService.ownerVisible(allDesigns);
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
                    errorBuilder: (_, __, ___) => _buildFilePlaceholder(firstImage),
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
                        // Open the real deliverables page (live images +
                        // comments) rather than FileReviewDetailPage, whose
                        // revision timeline is hardcoded mock data.
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DesignDeliverablesDetailPage(
                              designs: [design],
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

  /// Asks the provider to end the engagement. Ending one needs both sides to
  /// agree, so this files a request rather than cancelling anything outright.
  Future<void> _terminateEngagement() async {
    if (_activeWorkingId == null) return;
    final reasonController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đề nghị huỷ hợp tác'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hợp tác chỉ dừng khi bên còn lại đồng ý. Đề nghị của bạn sẽ được '
              'gửi cho nhà cung cấp để họ phản hồi.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Lý do (tuỳ chọn)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Không')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Gửi đề nghị', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    final reason = reasonController.text.trim();
    reasonController.dispose();
    if (confirm != true) return;

    try {
      final updated = await ProjectWorkingService.requestTermination(
        _activeWorkingId!,
        reason: reason,
      );
      if (mounted) {
        final ended = updated.status.toLowerCase() == 'terminated';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ended
                ? 'Hợp tác đã kết thúc.'
                : 'Đã gửi đề nghị huỷ — đang chờ nhà cung cấp phản hồi.'),
          ),
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

  /// Answers a request the provider raised.
  Future<void> _respondToTermination(bool approve) async {
    if (_activeWorkingId == null) return;
    if (approve) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Đồng ý huỷ hợp tác'),
          content: const Text(
            'Hợp tác sẽ kết thúc ngay khi bạn đồng ý. Hành động này không thể hoàn tác.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Không')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Đồng ý huỷ', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    try {
      await ProjectWorkingService.respondToTermination(
        _activeWorkingId!,
        approve: approve,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(approve
                ? 'Hợp tác đã kết thúc.'
                : 'Đã từ chối đề nghị huỷ — hợp tác tiếp tục.'),
          ),
        );
        _loadWorkspaceData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  /// Withdraws our own pending request.
  Future<void> _withdrawTerminationRequest() async {
    if (_activeWorkingId == null) return;
    try {
      await ProjectWorkingService.cancelTerminationRequest(_activeWorkingId!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã rút lại đề nghị huỷ.')),
        );
        _loadWorkspaceData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  /// Pending-request banner — mirrors the one in the collaboration workspace
  /// so a provider's request is visible from whichever workspace the owner
  /// happens to be in.
  Widget _buildTerminationBanner() {
    final w = _working;
    if (w == null) return const SizedBox.shrink();
    final raisedByProvider = w.terminationRequestedBy?.toLowerCase() == 'provider';
    final note = w.terminationRequestNote;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE65100).withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.pause_circle_outline, size: 20, color: Color(0xFFE65100)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  raisedByProvider
                      ? 'Nhà cung cấp đề nghị huỷ hợp tác'
                      : 'Đang chờ nhà cung cấp phản hồi đề nghị huỷ',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: const Color(0xFFE65100),
                  ),
                ),
              ),
            ],
          ),
          if (note != null && note.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Lý do: $note',
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary, height: 1.4)),
          ],
          const SizedBox(height: 8),
          Text(
            raisedByProvider
                ? 'Hợp tác vẫn đang chạy cho tới khi bạn phản hồi.'
                : 'Hợp tác vẫn đang chạy cho tới khi họ đồng ý.',
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 12),
          if (raisedByProvider)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _respondToTermination(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.espresso,
                      side: const BorderSide(color: AppColors.outlineVariant),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Từ chối'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _respondToTermination(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                    ),
                    child: const Text('Đồng ý huỷ'),
                  ),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _withdrawTerminationRequest,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.espresso,
                  side: const BorderSide(color: AppColors.outlineVariant),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Rút lại đề nghị'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    if (_working == null) return const SizedBox();
    
    final bool isAwaitingAcceptance = _working!.isAwaitingAcceptance;
    final bool canTerminate = _working!.status == 'accepted';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // "Báo hoàn thành" (request-completion) is provider-only — the backend
        // enforces EngagementActor.Provider — so it's not shown in this
        // owner-side app. The owner's counterpart is "Nghiệm thu" (accept),
        // which lives in the Collaboration Workspace.
        if (isAwaitingAcceptance)
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
          
        if (_working!.isAwaitingTerminationApproval) ...[
          const SizedBox(height: 16),
          _buildTerminationBanner(),
        ] else if (canTerminate) ...[
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _terminateEngagement,
            icon: const Icon(Icons.cancel_outlined, color: Colors.red),
            label: const Text('Đề nghị huỷ hợp tác'),
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

  Widget _buildFilePlaceholder(String? url, {double iconSize = 48, double height = 160}) {
    IconData icon = Icons.palette_outlined;
    Color iconColor = AppColors.outlineVariant;
    Color bgColor = const Color(0xFFF0EBE6);
    String ext = '';

    if (url != null) {
      final lower = url.toLowerCase().split('?').first;
      final isImage = lower.endsWith('.jpg') || lower.endsWith('.jpeg') ||
                      lower.endsWith('.png') || lower.endsWith('.gif') ||
                      lower.endsWith('.webp') || lower.contains('unsplash.com') ||
                      lower.contains('image');
      if (!isImage) {
        if (lower.endsWith('.pdf')) {
          icon = Icons.picture_as_pdf;
          iconColor = const Color(0xFFD32F2F);
          bgColor = const Color(0xFFFFEBEE);
          ext = 'PDF';
        } else if (lower.endsWith('.doc') || lower.endsWith('.docx')) {
          icon = Icons.description;
          iconColor = const Color(0xFF1976D2);
          bgColor = const Color(0xFFE3F2FD);
          ext = 'DOC';
        } else if (lower.endsWith('.xls') || lower.endsWith('.xlsx') || lower.endsWith('.csv')) {
          icon = Icons.table_chart;
          iconColor = const Color(0xFF388E3C);
          bgColor = const Color(0xFFE8F5E9);
          ext = 'XLS';
        } else if (lower.endsWith('.zip') || lower.endsWith('.rar')) {
          icon = Icons.folder_zip;
          iconColor = const Color(0xFFF57C00);
          bgColor = const Color(0xFFFFF3E0);
          ext = 'ZIP';
        } else {
          icon = Icons.insert_drive_file;
          iconColor = const Color(0xFF757575);
          bgColor = const Color(0xFFF5F5F5);
          ext = 'FILE';
        }
      }
    }

    return Container(
      height: height,
      width: double.infinity,
      color: bgColor,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: iconSize, color: iconColor),
            if (ext.isNotEmpty && iconSize >= 40) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  ext,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
