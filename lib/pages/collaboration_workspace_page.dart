import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../models/responses/api_responses.dart';
import '../services/project_working_service.dart';
import '../services/contract_service.dart';
import '../services/design_service.dart';
import '../services/construction_service.dart';
import '../services/review_service.dart';
import 'contract_otp_page.dart';
import 'file_review_detail_page.dart';
import 'design_deliverables_detail_page.dart';
import 'construction_progress_detail_page.dart';

class CollaborationWorkspacePage extends StatefulWidget {
  final int? projectWorkingId;

  const CollaborationWorkspacePage({super.key, this.projectWorkingId});

  @override
  State<CollaborationWorkspacePage> createState() => _CollaborationWorkspacePageState();
}

class _CollaborationWorkspacePageState extends State<CollaborationWorkspacePage> {
  bool _loading = true;
  String? _error;

  int? _activeWorkingId;
  ProjectWorkingResponse? _working;
  List<ContractResponse> _contracts = [];
  List<DesignResponse> _designs = [];
  List<ConstructionItemResponse> _constructionItems = [];
  List<ConstructionTaskResponse> _allTasks = [];

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

      // Fetch all workings for this project to aggregate everything
      final workingsPage = await ProjectWorkingService.getProjectWorkings(projectShopOwnerId: projectId, pageSize: 50);
      final allWorkingIds = workingsPage.items.map((w) => w.id).toList();

      List<ContractResponse> allContracts = [];
      List<DesignResponse> allDesigns = [];
      List<ConstructionItemResponse> allItems = [];
      List<ConstructionTaskResponse> allTasks = [];

      for (int wId in allWorkingIds) {
        final results = await Future.wait([
          ContractService.getContracts(projectWorkingId: wId, pageSize: 50),
          DesignService.getDesigns(projectWorkingId: wId, pageSize: 50),
          ConstructionService.getConstructionItems(projectWorkingId: wId, pageSize: 50),
        ]);
        
        allContracts.addAll((results[0] as PaginationResponse<ContractResponse>).items);
        allDesigns.addAll((results[1] as PaginationResponse<DesignResponse>).items);
        final itemsRes = (results[2] as PaginationResponse<ConstructionItemResponse>);
        allItems.addAll(itemsRes.items);

        for (final item in itemsRes.items) {
          try {
            final tList = await ConstructionService.getTasks(constructionItemId: item.id);
            allTasks.addAll(tList.items);
          } catch (_) {}
        }
      }

      if (mounted) {
        setState(() {
          _working = workingRes;
          _contracts = allContracts;
          _designs = allDesigns;
          _constructionItems = allItems;
          _allTasks = allTasks;
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

  Future<void> _completeProject() async {
    if (_activeWorkingId == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nghiệm thu hợp tác'),
        content: const Text('Bạn có chắc chắn muốn nghiệm thu và kết thúc hợp tác với nhà cung cấp này không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.espresso),
            child: const Text('Nghiệm thu', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ProjectWorkingService.completeEngagement(_activeWorkingId!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Project marked as completed! You can now write a review.')),
        );
        _loadWorkspaceData();
        _showReviewDialog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()), // Show backend message directly
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _terminateEngagement() async {
    if (_activeWorkingId == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Huỷ ngang hợp tác'),
        content: const Text('Bạn có chắc chắn muốn huỷ ngang hợp tác này? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Không')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Huỷ hợp tác', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ProjectWorkingService.terminateEngagement(_activeWorkingId!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Engagement terminated.')),
        );
        _loadWorkspaceData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())), // Show backend message directly
        );
      }
    }
  }

  void _showReviewDialog() {
    if (_activeWorkingId == null) return;
    double rating = 5.0;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Review Provider'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Rate your experience with this provider:'),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                    onPressed: () => setDialogState(() => rating = (index + 1).toDouble()),
                  );
                }),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: commentController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Write a comment or testimonial...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Skip')),
            ElevatedButton(
              onPressed: () async {
                try {
                  await ReviewService.createReview(
                    projectWorkingId: _activeWorkingId!,
                    overallRating: rating,
                    comment: commentController.text.trim(),
                  );
                  if (mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Review submitted! Thank you.')),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to submit review: $e')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.espresso),
              child: const Text('Submit Review', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showContractDetails(ContractResponse contract) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Contract: ${contract.title}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Status: ${contract.status.toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Agreed Value: \$${contract.agreedValue.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              if (contract.partyInfo != null) ...[
                const Text('Parties Involved:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(contract.partyInfo!),
                const SizedBox(height: 16),
              ],
              const Text('Terms & Conditions:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(contract.terms ?? 'No terms specified.'),
              if (contract.documentUrl != null) ...[
                const SizedBox(height: 16),
                Text('Document URL: ${contract.documentUrl}', style: const TextStyle(color: Colors.blue)),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
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
              child: const Icon(Icons.coffee, size: 16, color: AppColors.primary),
            ),
            const SizedBox(width: 8),
            const Text(
              'Design Cafe Workspace',
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
                          child: const Icon(Icons.construction, size: 64, color: AppColors.espresso),
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
                              ? 'No active engagement or contract found for this project yet. Once a provider is selected and approved, your workspace will appear here.'
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
                          'Project Workspace',
                          style: GoogleFonts.playfairDisplay(
                            color: AppColors.textPrimary,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Engagement ID #${_working?.id} • Provider: ${_working?.providerDisplayName ?? 'Partner Studio'}',
                          style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
                        ),
                        const SizedBox(height: 20),

                        // 1. Contracts Section
                        if (_contracts.isNotEmpty) ...[
                          for (final contract in _contracts) ...[
                            if (contract.status == 'confirmed')
                              _buildContractConfirmedBanner(contract)
                            else if (contract.status == 'pending_otp' &&
                                !_contracts.any((c) => c.status == 'confirmed'))
                              _buildContractOtpBanner(contract),
                            const SizedBox(height: 12),
                          ],
                          const SizedBox(height: 8),
                        ],

                        // 2. Designs Section (Designer Deliverables & Approvals)
                        _buildDesignSection(),
                        const SizedBox(height: 24),

                        // 3. Construction Section (Constructor Milestones & Site Photos)
                        _buildConstructionSection(),
                        const SizedBox(height: 24),

                        // 4. Project Acceptance & Review Section
                        _buildAcceptanceSection(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildContractOtpBanner(ContractResponse contract) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3CD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFEEBA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.mark_email_unread_outlined, color: Color(0xFF856404)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Contract Signature Required (OTP Sent)',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF856404), fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'An OTP has been sent to your registered email to digitally sign contract "${contract.title}". Sign to unlock design & construction phases.',
            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF856404)),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ContractOtpPage(contract: contract)),
              );
              if (result == true) _loadWorkspaceData();
            },
            icon: const Icon(Icons.key, size: 16),
            label: const Text('Enter OTP & Confirm Contract'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.espresso,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => _showContractDetails(contract),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF856404),
              padding: EdgeInsets.zero,
              minimumSize: const Size(50, 30),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              alignment: Alignment.centerLeft,
            ),
            child: const Text('View Contract Document', style: TextStyle(decoration: TextDecoration.underline, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildContractConfirmedBanner(ContractResponse contract) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFD4EDDA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFC3E6CB)),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified, color: Color(0xFF155724), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Contract Confirmed 🔓 (${contract.title})',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF155724)),
            ),
          ),
          TextButton(
            onPressed: () => _showContractDetails(contract),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF155724),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 30),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('View', style: TextStyle(decoration: TextDecoration.underline, fontSize: 12)),
          ),
        ],
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
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DesignDeliverablesDetailPage(
                        designs: _designs,
                        onUpdated: _loadWorkspaceData,
                      ),
                    ),
                  ).then((_) => _loadWorkspaceData());
                },
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(6)),
                      child: Text('${_designs.length} Items', style: GoogleFonts.inter(fontSize: 11, color: Colors.blue.shade800, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.chevron_right, size: 18, color: AppColors.placeholder),
                  ],
                ),
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
            ..._designs.take(2).map((design) => _buildDesignCard(design)),
          if (_designs.length > 2) ...[  
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DesignDeliverablesDetailPage(
                      designs: _designs,
                      onUpdated: _loadWorkspaceData,
                    ),
                  ),
                ).then((_) => _loadWorkspaceData());
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0EBE6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'See all ${_designs.length} designs',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.espresso),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward, size: 14, color: AppColors.espresso),
                  ],
                ),
              ),
            ),
          ],
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
          // Image hero
          if (firstImage != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Stack(
                children: [
                  Image.network(
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
                  // Approve button (primary, full width)
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
                  // Request Revision (secondary)
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
                      icon: const Icon(Icons.remove_red_eye, size: 18, color: AppColors.espresso),
                      label: const Text('View Full Detail'),
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

  Widget _buildConstructionSection() {
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
                'Construction Progress',
                style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.espresso),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ConstructionProgressDetailPage(
                        items: _constructionItems,
                        allTasks: _allTasks,
                      ),
                    ),
                  );
                },
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(6)),
                      child: Text('${_constructionItems.length} Milestones', style: GoogleFonts.inter(fontSize: 11, color: Colors.green.shade800, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.chevron_right, size: 18, color: AppColors.placeholder),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_constructionItems.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text('No construction milestones created by constructor yet.', style: GoogleFonts.inter(fontSize: 12, color: AppColors.placeholder)),
            )
          else
            ..._constructionItems.take(2).map((item) => _buildConstructionItemCard(item)),
          if (_constructionItems.length > 2) ...[  
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ConstructionProgressDetailPage(
                      items: _constructionItems,
                      allTasks: _allTasks,
                    ),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0EBE6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'See all ${_constructionItems.length} milestones',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.espresso),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward, size: 14, color: AppColors.espresso),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConstructionItemCard(ConstructionItemResponse item) {
    final itemTasks = _allTasks.where((t) => t.constructionItemId == item.id).toList();
    final statusColor = item.status == 'completed'
        ? Colors.green.shade700
        : item.status == 'in_progress'
            ? Colors.orange.shade800
            : AppColors.placeholder;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF8F6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  item.name,
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.espresso),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                child: Text(
                  item.status.toUpperCase(),
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: statusColor),
                ),
              ),
            ],
          ),
          if (item.description != null && item.description!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(item.description!, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
          ],
          const SizedBox(height: 8),
          if (itemTasks.isNotEmpty) ...[
            Text('Tasks (${itemTasks.length}):', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.espresso)),
            const SizedBox(height: 6),
            ...itemTasks.map((task) => Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 4),
              child: Row(
                children: [
                  Icon(
                    task.status == 'completed' ? Icons.check_circle : Icons.radio_button_unchecked,
                    size: 14,
                    color: task.status == 'completed' ? Colors.green : AppColors.placeholder,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(task.name, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textPrimary)),
                  ),
                  if (task.imageUrl != null)
                    IconButton(
                      icon: const Icon(Icons.photo, size: 16, color: AppColors.espresso),
                      onPressed: () {
                        String? imgUrl = task.imageUrl;
                        if (imgUrl != null) {
                          if (!imgUrl.startsWith('http')) {
                            if (imgUrl.startsWith('/')) imgUrl = imgUrl.substring(1);
                            imgUrl = 'https://storage.googleapis.com/smartcoffeebuilder_bucket/$imgUrl';
                          }
                          showDialog(
                            context: context,
                            builder: (ctx) => Dialog(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.network(imgUrl!, fit: BoxFit.cover),
                                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
                                ],
                              ),
                            ),
                          );
                        }
                      },
                    ),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildAcceptanceSection() {
    final isCompleted = _working?.status == 'completed';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isCompleted
              ? [const Color(0xFFE8F5E9), const Color(0xFFF1F8E9)]
              : [const Color(0xFFFDF6EE), const Color(0xFFFFF3E0)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCompleted ? const Color(0xFFA5D6A7) : AppColors.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isCompleted ? const Color(0xFF2E7D32) : AppColors.espresso,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isCompleted ? Icons.verified : Icons.handshake_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isCompleted ? 'Project Completed!' : 'Final Acceptance',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isCompleted ? const Color(0xFF2E7D32) : AppColors.espresso,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isCompleted
                          ? 'Congratulations! This project has been signed off.'
                          : 'Ready to finalize? Review all deliverables first.',
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (!isCompleted) ...[
            Text(
              'When all designs and construction milestones meet your expectations, tap below to complete the project and rate your provider.',
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 20),
            if (_working?.status == 'accepted' && _working?.hasConfirmedContract == true)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _completeProject,
                  icon: const Icon(Icons.check_circle, size: 20, color: Colors.white),
                  label: Text(_working?.isAwaitingAcceptance == true ? 'Nghiệm thu (Đang chờ)' : 'Nghiệm thu'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _working?.isAwaitingAcceptance == true ? Colors.green.shade700 : AppColors.espresso,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: _working?.isAwaitingAcceptance == true ? 4 : 0,
                  ),
                ),
              ),
            if (_working?.status == 'accepted') ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _terminateEngagement,
                  icon: const Icon(Icons.cancel, size: 20, color: Colors.red),
                  label: const Text('Huỷ ngang'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.coffee, color: AppColors.espresso, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your cafe project is now complete. Thank you for building with CafeBuilder!',
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showReviewDialog,
                icon: const Icon(Icons.star, size: 20, color: Colors.white),
                label: const Text('Rate Your Provider'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF9A825),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
