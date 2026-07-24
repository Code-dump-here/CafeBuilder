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
  ContractResponse? _contract;
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
        }
      }

      if (workingId == null) {
        setState(() {
          _loading = false;
          _error = 'No active project engagement found.';
        });
        return;
      }

      _activeWorkingId = workingId;

      final results = await Future.wait([
        ProjectWorkingService.getProjectWorking(workingId),
        ContractService.getContracts(projectWorkingId: workingId, pageSize: 1),
        DesignService.getDesigns(projectWorkingId: workingId, pageSize: 50),
        ConstructionService.getConstructionItems(projectWorkingId: workingId, pageSize: 50),
      ]);

      final workingRes = results[0] as ProjectWorkingResponse;
      final contractsRes = results[1] as PaginationResponse<ContractResponse>;
      final designsRes = results[2] as PaginationResponse<DesignResponse>;
      final itemsRes = results[3] as PaginationResponse<ConstructionItemResponse>;

      // Load tasks for construction items
      List<ConstructionTaskResponse> tasks = [];
      for (final item in itemsRes.items) {
        try {
          final tList = await ConstructionService.getTasks(constructionItemId: item.id);
          tasks.addAll(tList.items);
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _working = workingRes;
          _contract = contractsRes.items.isNotEmpty ? contractsRes.items.first : null;
          _designs = designsRes.items;
          _constructionItems = itemsRes.items;
          _allTasks = tasks;
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
        title: const Text('Accept & Finalize Project'),
        content: const Text('Are you sure you want to mark this project engagement as completed?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.espresso),
            child: const Text('Confirm Acceptance', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ProjectWorkingService.updateProjectWorkingStatus(_activeWorkingId!, 'completed');
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
          SnackBar(content: Text('Failed to complete project: $e')),
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
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center, style: GoogleFonts.inter(color: AppColors.textSecondary)),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _loadWorkspaceData, child: const Text('Retry')),
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

                        // 1. Contract OTP Sign-off Banner
                        if (_contract != null && _contract!.status == 'pending_otp') ...[
                          _buildContractOtpBanner(_contract!),
                          const SizedBox(height: 20),
                        ] else if (_contract != null && _contract!.status == 'confirmed') ...[
                          _buildContractConfirmedBanner(_contract!),
                          const SizedBox(height: 20),
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
    final statusColor = design.status == 'approved'
        ? Colors.green.shade700
        : design.status == 'revision'
            ? Colors.red.shade700
            : Colors.orange.shade800;

    final firstImage = design.images.isNotEmpty ? design.images.first.viewUrl : null;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.outlineVariant.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (firstImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  firstImage,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 140,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    design.title,
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.espresso),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                  child: Text(
                    design.status.toUpperCase(),
                    style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Type: ${design.type} · Version ${design.version.toStringAsFixed(1)}',
              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (design.status == 'submitted' || design.status == 'in_progress') ...[
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _approveDesign(design.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.espresso,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 36),
                      ),
                      child: const Text('Approve'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _requestRevision(design.id),
                      style: OutlinedButton.styleFrom(minimumSize: const Size(0, 36)),
                      child: const Text('Request Revision'),
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final statusEnum = design.status == 'approved'
                            ? ReviewItemStatus.approved
                            : design.status == 'revision'
                                ? ReviewItemStatus.revision
                                : ReviewItemStatus.needReview;
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
                      icon: const Icon(Icons.remove_red_eye, size: 14),
                      label: const Text('View Detail'),
                      style: OutlinedButton.styleFrom(minimumSize: const Size(0, 36)),
                    ),
                  ),
                ]
              ],
            ),
          ],
        ),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(6)),
                child: Text('${_constructionItems.length} Milestones', style: GoogleFonts.inter(fontSize: 11, color: Colors.green.shade800, fontWeight: FontWeight.bold)),
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
            ..._constructionItems.map((item) => _buildConstructionItemCard(item)),
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
                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
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
                        final imgUrl = task.imageUrl;
                        if (imgUrl != null) {
                          showDialog(
                            context: context,
                            builder: (ctx) => Dialog(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.network(imgUrl, fit: BoxFit.cover),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Final Acceptance & Review',
            style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.espresso),
          ),
          const SizedBox(height: 8),
          Text(
            isCompleted
                ? 'Project completed & accepted. Thank you for building with CafeBuilder!'
                : 'When all design and construction deliverables meet your expectations, click below to mark project completed and rate provider.',
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (!isCompleted)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _completeProject,
                    icon: const Icon(Icons.verified, size: 16),
                    label: const Text('Accept & Complete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.espresso,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 44),
                    ),
                  ),
                )
              else ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showReviewDialog,
                    icon: const Icon(Icons.star_rate, size: 16),
                    label: const Text('Write Provider Review'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade800,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 44),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
