import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../models/responses/api_responses.dart';
import '../services/project_working_service.dart';
import '../services/project_service.dart';
import '../services/quotation_service.dart';
import '../models/responses/quotation_payment_responses.dart';
import 'quotation_details_page.dart';
import 'payment_batches_page.dart';
import 'change_orders_page.dart';
import '../services/payment_batch_service.dart';
import '../services/change_order_service.dart';
import '../models/responses/change_order_responses.dart';
import '../services/contract_service.dart';
import '../services/design_service.dart';
import '../services/construction_service.dart';
import '../services/review_service.dart';
import '../services/survey_service.dart';
import 'contract_otp_page.dart';
import 'design_deliverables_detail_page.dart';
import 'construction_progress_detail_page.dart';
import 'survey_detail_page.dart';
import '../widgets/confirm_dialog.dart';
import '../utils/money.dart';

class CollaborationWorkspacePage extends StatefulWidget {
  final String? projectWorkingId;

  const CollaborationWorkspacePage({super.key, this.projectWorkingId});

  @override
  State<CollaborationWorkspacePage> createState() => _CollaborationWorkspacePageState();
}

class _CollaborationWorkspacePageState extends State<CollaborationWorkspacePage> {
  bool _loading = true;
  String? _error;

  String? _activeWorkingId;
  ProjectWorkingResponse? _working;
  // Every engagement on the project. The page aggregates designs and
  // construction across all of them, so acceptance has to be per engagement
  // too — pinning it to the one we opened with (always the designer) left the
  // constructor's engagement with no way to be accepted or ended (02/10/2026).
  List<ProjectWorkingResponse> _engagements = [];
  ProjectResponse? _project;
  // Quotations per engagement id. The owner app only reached a quotation from
  // the Proposals screen, so one sent after the proposal was accepted — or one
  // for a direct hire — could never be approved, and the contract could never
  // be built from it (no payment instalments).
  Map<String, List<QuotationResponse>> _quotationsByEngagement = {};
  // Payment instalments per DESIGN engagement id. The server refuses to accept
  // design work while any instalment is unconfirmed (owner uploads the proof,
  // the designer confirms it), so the button has to know before it is pressed.
  Map<String, List<PaymentBatchResponse>> _batchesByEngagement = {};
  // Change orders still waiting for a decision, per engagement id. Like an
  // unpaid instalment, each one blocks accepting the work and closing the
  // project until it is accepted or rejected.
  Map<String, List<ChangeOrderResponse>> _pendingChangeOrdersByEngagement = {};
  List<ContractResponse> _contracts = [];
  List<DesignResponse> _designs = [];
  List<ConstructionItemResponse> _constructionItems = [];
  List<ConstructionTaskResponse> _allTasks = [];
  List<SurveyResponse> _surveys = [];
  List<AppliedConstructionTemplateResponse> _appliedTemplates = [];

  // Guards against a fast double-tap firing the same request twice.
  final Set<String> _pendingDesignActionIds = {};
  bool _engagementActionInProgress = false;

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
      String? workingId = widget.projectWorkingId;
      if (workingId == null) {
        final workings = await ProjectWorkingService.getProjectWorkings(pageSize: 1);
        if (workings.items.isNotEmpty) {
          workingId = workings.items.first.id;
        } else {
          workingId = '';
        }
      }

      if (workingId.isEmpty) {
        setState(() {
          _loading = false;
          _activeWorkingId = '';
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

      // Project status decides the closing banner and the "Close project"
      // button. A failure only costs that part of the page.
      ProjectResponse? project;
      try {
        project = await ProjectService.getProject(projectId);
      } catch (_) {}

      // Listing by engagement returns both anchors: quotations filed on the
      // engagement itself and the won bid filed under the application it grew
      // from (a quotation priced after the proposal was accepted can only sit
      // on the engagement).
      final quotationsByEngagement = <String, List<QuotationResponse>>{};
      for (final w in workingsPage.items) {
        if (w.status.toLowerCase() == 'rejected') continue;
        try {
          final page = await QuotationService.getQuotations(
            projectWorkingId: w.id,
            pageSize: 20,
          );
          quotationsByEngagement[w.id] = page.items;
        } catch (_) {}
      }

      // Every engagement except rejected / ended-early ones: accepting the work
      // and closing the project both wait on these (server PaymentSettlementRules).
      final batchesByEngagement = <String, List<PaymentBatchResponse>>{};
      final pendingChangeOrdersByEngagement = <String, List<ChangeOrderResponse>>{};
      for (final w in workingsPage.items) {
        final s = w.status.toLowerCase();
        if (s == 'rejected' || s == 'terminated') continue;
        try {
          final page = await PaymentBatchService.getBatches(projectWorkingId: w.id, pageSize: 50);
          batchesByEngagement[w.id] = page.items;
        } catch (_) {}
        try {
          final page = await ChangeOrderService.getAll(projectWorkingId: w.id, status: 'pending');
          pendingChangeOrdersByEngagement[w.id] = page.items;
        } catch (_) {}
      }

      List<ContractResponse> allContracts = [];
      List<DesignResponse> allDesigns = [];
      List<ConstructionItemResponse> allItems = [];
      List<ConstructionTaskResponse> allTasks = [];
      List<SurveyResponse> allSurveys = [];
      List<AppliedConstructionTemplateResponse> allTemplates = [];

      for (String wId in allWorkingIds) {
        final results = await Future.wait([
          ContractService.getContracts(projectWorkingId: wId, pageSize: 50),
          DesignService.getDesigns(projectWorkingId: wId, pageSize: 50),
          ConstructionService.getConstructionItems(projectWorkingId: wId, pageSize: 50),
          // Surveys are per-engagement like the rest; a failure here shouldn't
          // cost the owner the whole workspace, so it degrades to an empty list.
          SurveyService.getSurveys(projectWorkingId: wId, pageSize: 50)
              .then<Object?>((r) => r)
              .catchError((_) => null),
        ]);

        allContracts.addAll(ContractService.ownerVisible(
            (results[0] as PaginationResponse<ContractResponse>).items));
        allDesigns.addAll((results[1] as PaginationResponse<DesignResponse>).items);
        final itemsRes = (results[2] as PaginationResponse<ConstructionItemResponse>);
        allItems.addAll(itemsRes.items);
        final surveyRes = results[3];
        if (surveyRes is PaginationResponse<SurveyResponse>) {
          allSurveys.addAll(surveyRes.items);
        }

        // Quy trình nhà thầu đang chạy (review 3). Lỗi ở đây không được làm hỏng cả workspace:
        // engagement chưa ký hợp đồng thì chưa áp mẫu nào, và bản BE cũ chưa có endpoint này.
        try {
          allTemplates.addAll(await ConstructionService.getAppliedTemplates(wId));
        } catch (_) {}

        for (final item in itemsRes.items) {
          try {
            // Without an explicit pageSize this defaulted to 10, so a milestone
            // with more tasks than that had its progress computed over a
            // truncated list — the bar could never reach 100%.
            final tList = await ConstructionService.getTasks(
                constructionItemId: item.id, pageSize: 100);
            allTasks.addAll(tList.items);
          } catch (_) {}
        }
      }

      if (mounted) {
        setState(() {
          _working = workingRes;
          _engagements = workingsPage.items;
          _project = project;
          _quotationsByEngagement = quotationsByEngagement;
          _batchesByEngagement = batchesByEngagement;
          _pendingChangeOrdersByEngagement = pendingChangeOrdersByEngagement;
          _contracts = allContracts;
          _designs = DesignService.ownerVisible(allDesigns);
          _constructionItems = allItems;
          _allTasks = allTasks;
          _surveys = allSurveys;
          _appliedTemplates = allTemplates;
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

  Future<void> _approveDesign(String designId) async {
    if (_pendingDesignActionIds.contains(designId)) return;
    setState(() => _pendingDesignActionIds.add(designId));
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
    } finally {
      if (mounted) setState(() => _pendingDesignActionIds.remove(designId));
    }
  }

  Future<void> _requestRevision(String designId) async {
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

    if (reason == null) return; // user cancelled
    if (reason.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter feedback before submitting.')),
        );
      }
      return;
    }
    if (_pendingDesignActionIds.contains(designId)) return;
    setState(() => _pendingDesignActionIds.add(designId));

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
    } finally {
      if (mounted) setState(() => _pendingDesignActionIds.remove(designId));
    }
  }

  /// "Design" / "Construction" — the scope an engagement covers, for labels.
  static String _scopeLabel(ProjectWorkingResponse w) {
    switch (w.contractType.toLowerCase()) {
      case 'design':
        return 'Design';
      case 'construction':
        return 'Construction';
      case 'both':
        return 'Design & construction';
      default:
        return w.contractType;
    }
  }

  /// Accepts ONE provider's work. The project itself stays open until every
  /// engagement is closed and the owner closes it.
  Future<void> _completeEngagement(ProjectWorkingResponse w) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Accept ${_scopeLabel(w).toLowerCase()} work'),
        content: Text(
          'Accept the ${_scopeLabel(w).toLowerCase()} work of ${w.providerDisplayName} and close '
          'this engagement? Other providers on the project are not affected.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.espresso),
            child: const Text('Accept work', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (_engagementActionInProgress) return;
    setState(() => _engagementActionInProgress = true);

    try {
      await ProjectWorkingService.completeEngagement(w.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${w.providerDisplayName}\'s work accepted. You can now write a review.')),
        );
        _loadWorkspaceData();
        _showReviewDialog(w);
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
    } finally {
      if (mounted) setState(() => _engagementActionInProgress = false);
    }
  }

  /// Asks the provider to end the engagement. This does *not* end it — the
  /// provider has to agree first — so the copy says so rather than claiming
  /// the work is already cancelled.
  Future<void> _terminateEngagement(ProjectWorkingResponse w) async {
    final reasonController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Request to end the engagement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'An engagement only ends when the other side agrees. Your request will be '
              'sent to the provider for a response.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Reason (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Send request', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    final reason = reasonController.text.trim();
    reasonController.dispose();
    if (confirm != true) return;
    if (_engagementActionInProgress) return;
    setState(() => _engagementActionInProgress = true);

    try {
      final updated = await ProjectWorkingService.requestTermination(
        w.id,
        reason: reason,
      );
      if (mounted) {
        // If the provider had already asked, our request counts as agreement
        // and the engagement really is over — report whichever happened.
        final ended = updated.status.toLowerCase() == 'terminated';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ended
                ? 'The engagement has ended.'
                : 'Request sent — waiting for the provider to respond.'),
          ),
        );
        _loadWorkspaceData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())), // Show backend message directly
        );
      }
    } finally {
      if (mounted) setState(() => _engagementActionInProgress = false);
    }
  }

  /// Answers a request the provider raised.
  Future<void> _respondToTermination(ProjectWorkingResponse w, bool approve) async {
    if (approve) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Agree to end the engagement'),
          content: const Text(
            'The engagement ends as soon as you agree. This cannot be undone.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Agree to end it', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }
    if (_engagementActionInProgress) return;
    setState(() => _engagementActionInProgress = true);

    try {
      await ProjectWorkingService.respondToTermination(
        w.id,
        approve: approve,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(approve
                ? 'The engagement has ended.'
                : 'Request declined — the engagement continues.'),
          ),
        );
        _loadWorkspaceData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _engagementActionInProgress = false);
    }
  }

  /// Shown while a termination request is waiting on someone. Which side
  /// raised it decides whether the owner answers it or can withdraw it —
  /// without this the owner had no way to see a provider's request at all.
  Widget _buildTerminationBanner(ProjectWorkingResponse w) {
    final raisedByProvider = w.terminationRequestedBy?.toLowerCase() == 'provider';
    final note = w.terminationRequestNote;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE65100).withValues(alpha: 0.35)),
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
                      ? 'The provider has asked to end the engagement'
                      : 'Waiting for the provider to respond to your request',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: const Color(0xFFE65100),
                  ),
                ),
              ),
            ],
          ),
          if (note != null && note.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Reason: $note',
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            raisedByProvider
                ? 'The engagement continues until you respond.'
                : 'The engagement continues until they agree.',
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
          ),
          // Agreeing to end a signed engagement leaves its scope unfinished,
          // and the server won't close a project like that (ProjectClosureRules).
          // Owners were ending a finished constructor to "get it out of the
          // way" and then found the project stuck — say so before they agree.
          if (raisedByProvider && w.hasConfirmedContract) ...[
            const SizedBox(height: 8),
            Text(
              _deliverablesDone(w)
                  ? 'This work looks finished — accept it instead. Ending a signed engagement '
                      'means the project cannot be closed until someone else completes this part.'
                  : 'Ending a signed engagement means the project cannot be closed until someone '
                      'else completes this part.',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFE65100),
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (raisedByProvider)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _engagementActionInProgress ? null : () => _respondToTermination(w, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.espresso,
                      side: const BorderSide(color: AppColors.outlineVariant),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _engagementActionInProgress ? null : () => _respondToTermination(w, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                    ),
                    child: const Text('Agree to end it'),
                  ),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _engagementActionInProgress ? null : () => _withdrawTerminationRequest(w),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.espresso,
                  side: const BorderSide(color: AppColors.outlineVariant),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Withdraw request'),
              ),
            ),
        ],
      ),
    );
  }

  /// Withdraws our own pending request.
  Future<void> _withdrawTerminationRequest(ProjectWorkingResponse w) async {
    if (_engagementActionInProgress) return;
    setState(() => _engagementActionInProgress = true);
    try {
      await ProjectWorkingService.cancelTerminationRequest(w.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request withdrawn.')),
        );
        _loadWorkspaceData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _engagementActionInProgress = false);
    }
  }

  void _showReviewDialog(ProjectWorkingResponse w) {
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
              Text('Rate your experience with ${w.providerDisplayName}:'),
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
                    projectWorkingId: w.id,
                    overallRating: rating,
                    comment: commentController.text.trim(),
                  );
                  // Two different contexts with two different lifetimes: `ctx`
                  // belongs to the dialog, `context` to the page behind it. The
                  // dialog can be gone while the page is still fine, so one
                  // `mounted` check cannot stand in for both.
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Review submitted! Thank you.')),
                  );
                } catch (e) {
                  // This branch had no guard at all: a review POST that failed
                  // after the user left the screen reached ScaffoldMessenger on
                  // a dead context and threw on top of the error it was
                  // reporting.
                  if (!context.mounted) return;
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
              Text('Agreed Value: ${formatVnd(contract.agreedValue)}', style: const TextStyle(fontWeight: FontWeight.bold)),
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
          : (_error != null || (_activeWorkingId ?? "").isEmpty)
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
                          (_activeWorkingId ?? "").isEmpty 
                              ? 'No active engagement or contract found for this project yet. Once a provider is selected and approved, your workspace will appear here.'
                              : _error!,
                          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
                          textAlign: TextAlign.center,
                        ),
                        if ((_activeWorkingId ?? "").isNotEmpty) ...[
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
                        // This page aggregates contracts, designs and
                        // construction across every engagement on the project,
                        // so label it by project — naming a single engagement
                        // implied a scope the content doesn't have.
                        Text(
                          _working?.projectName.isNotEmpty == true
                              ? _working!.projectName
                              : 'All contracts, designs and construction',
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

                        // 2. Site Survey (the provider's record of existing
                        //    conditions — comes before design work in the real
                        //    sequence, so it reads first here too).
                        _buildSurveySection(),
                        const SizedBox(height: 24),

                        // 3. Designs Section (Designer Deliverables & Approvals)
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

  /// Read-only summary of the site surveys filed against this project. Authored
  /// on the web app by the provider; the owner reviews them here.
  Widget _buildSurveySection() {
    // Most recently filed first — that's the one describing the site now.
    // Ordered by date, not by the version number that is being retired.
    final ordered = [..._surveys]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final latest = ordered.isEmpty ? null : ordered.first;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Site Survey',
                style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.espresso),
              ),
              if (ordered.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            SurveyDetailPage(surveys: _surveys),
                      ),
                    ).then((_) => _loadWorkspaceData());
                  },
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                            color: AppColors.primaryFixed.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(6)),
                        child: Text(
                            '${ordered.length} ${ordered.length == 1 ? 'Survey' : 'Surveys'}',
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.espresso,
                                fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.chevron_right,
                          size: 18, color: AppColors.placeholder),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (latest == null)
            Text(
              'No site survey filed yet.',
              style: GoogleFonts.inter(
                  fontSize: 12, color: AppColors.placeholder),
            )
          else ...[
            Text(
              (latest.conditionNote?.trim().isNotEmpty ?? false)
                  ? latest.conditionNote!.trim()
                  : 'No condition note recorded.',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                  fontSize: 12, height: 1.4, color: AppColors.textSecondary),
            ),
          ],
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
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
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
    // Only a *submitted* design can be acted on. Previously this was
    // "not approved and not revision", which swept in_progress in too and
    // offered Approve on drafts — the backend then rejected it with an error
    // the owner had no way to make sense of.
    final isSubmitted = design.status == 'submitted';
    final isReworking = design.status == 'in_progress';

    final statusColor = isApproved
        ? const Color(0xFF2E7D32)
        : isRevision
            ? const Color(0xFFC62828)
            : isReworking
                ? AppColors.textSecondary
                : const Color(0xFFE65100);
    final statusBg = isApproved
        ? const Color(0xFFE8F5E9)
        : isRevision
            ? const Color(0xFFFFEBEE)
            : isReworking
                ? const Color(0xFFF2EFEC)
                : const Color(0xFFFFF3E0);
    final statusLabel = isApproved
        ? '✓ Approved'
        : isRevision
            ? '↩ Revision requested'
            : isReworking
                ? '✎ Being revised'
                : '⏳ Pending review';

    final firstImage = design.images.isNotEmpty ? design.images.first.viewUrl : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
                        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
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
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
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
                if (isSubmitted) ...[
                  // Approve button (primary, full width)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _pendingDesignActionIds.contains(design.id)
                          ? null
                          : () => _approveDesign(design.id),
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
                      onPressed: _pendingDesignActionIds.contains(design.id)
                          ? null
                          : () => _requestRevision(design.id),
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
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
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
                        appliedTemplates: _appliedTemplates,
                      ),
                    ),
                  ).then((_) => _loadWorkspaceData());
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
                      appliedTemplates: _appliedTemplates,
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
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.4)),
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
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
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
                    task.status == 'completed'
                        ? Icons.check_circle
                        : task.status == 'in_progress'
                            ? Icons.timelapse
                            : Icons.radio_button_unchecked,
                    size: 14,
                    color: task.status == 'completed'
                        ? Colors.green
                        : task.status == 'in_progress'
                            ? const Color(0xFFE65100)
                            : AppColors.placeholder,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(task.name, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textPrimary)),
                  ),
                  if (task.status == 'in_progress')
                    Text(
                      'In progress',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFE65100),
                      ),
                    ),
                  if (task.imageUrl != null)
                    IconButton(
                      icon: const Icon(Icons.photo, size: 16, color: AppColors.espresso),
                      onPressed: () async {
                        String? imgUrl = task.imageUrl;
                        if (imgUrl == null) return;
                        if (!imgUrl.startsWith('http')) {
                          if (imgUrl.startsWith('/')) imgUrl = imgUrl.substring(1);
                          imgUrl = 'https://storage.googleapis.com/smartcoffeebuilder_bucket/$imgUrl';
                        }
                        final confirmed = await showConfirmDialog(
                          context,
                          title: 'View Photo',
                          message: 'View this task photo?',
                          confirmLabel: 'View',
                        );
                        if (!confirmed || !mounted) return;
                        showDialog(
                          context: context,
                          builder: (ctx) => Dialog(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.network(
              webHtmlElementStrategy: WebHtmlElementStrategy.fallback,imgUrl!, fit: BoxFit.cover),
                                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
                              ],
                            ),
                          ),
                        );
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

  /// Mirrors the server's acceptance rule (ProjectWorkingService): the work is
  /// acceptable once the provider reports completion, or once its
  /// deliverables are visibly done — design: an approved design;
  /// construction: every milestone completed. Until then the button stays
  /// disabled, so accepting the designer can't be mistaken for accepting the
  /// constructor's unfinished site.
  bool _deliverablesDone(ProjectWorkingResponse w) {
    final designsOk = _designs.any(
        (d) => d.projectWorkingId == w.id && d.status.toLowerCase() == 'approved');
    final items = _constructionItems.where((i) => i.projectWorkingId == w.id).toList();
    final constructionOk =
        items.isNotEmpty && items.every((i) => i.status.toLowerCase() == 'completed');
    switch (w.contractType.toLowerCase()) {
      case 'design':
        return designsOk;
      case 'construction':
        return constructionOk;
      case 'both':
        return designsOk && constructionOk;
      default:
        return false;
    }
  }

  /// Instalments of one engagement not yet confirmed by the provider.
  List<PaymentBatchResponse> _unsettledBatchesOf(String engagementId) =>
      (_batchesByEngagement[engagementId] ?? const <PaymentBatchResponse>[])
          .where((b) => b.status.toLowerCase() != 'confirmed')
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  /// Every unsettled instalment on the project, as (provider, batch). The
  /// server refuses to close or delete the project while any remain.
  List<(ProjectWorkingResponse, PaymentBatchResponse)> get _unsettledForProject => [
        for (final w in _engagements)
          for (final b in _unsettledBatchesOf(w.id)) (w, b),
      ];

  /// Change orders still waiting for a decision on one engagement.
  List<ChangeOrderResponse> _pendingChangeOrdersOf(String engagementId) =>
      _pendingChangeOrdersByEngagement[engagementId] ?? const <ChangeOrderResponse>[];

  /// Every pending change order on the project, as (provider, order).
  List<(ProjectWorkingResponse, ChangeOrderResponse)> get _pendingChangeOrdersForProject => [
        for (final w in _engagements)
          for (final o in _pendingChangeOrdersOf(w.id)) (w, o),
      ];

  Future<void> _openChangeOrders() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeOrdersPage(
          projectWorkings: _engagements,
          projectName: _working?.projectName ?? 'Project',
        ),
      ),
    );
    if (mounted) _loadWorkspaceData();
  }

  /// What is still owed before [action]: unpaid instalments and change orders
  /// awaiting a decision, with a way to each screen that settles them.
  Widget _buildOutstandingBox({
    required String action,
    required List<(String, PaymentBatchResponse)> batches,
    required List<(String, ChangeOrderResponse)> changeOrders,
  }) {
    final lineStyle = GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary, height: 1.4);
    Widget link(String label, VoidCallback onTap) => TextButton(
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 32),
            foregroundColor: AppColors.espresso,
          ),
          onPressed: onTap,
          child: Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700)),
        );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFB300)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settle these before $action:',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFB27300),
            ),
          ),
          const SizedBox(height: 6),
          for (final (prefix, b) in batches)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                '• $prefix${b.name} · ${formatVnd(b.amount)} — ${_batchStatusHint(b)}',
                style: lineStyle,
              ),
            ),
          for (final (prefix, o) in changeOrders)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                '• ${prefix}Change order "${o.title}" · ${formatVnd(o.amount)} — accept or reject it',
                style: lineStyle,
              ),
            ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 16,
            children: [
              if (batches.isNotEmpty) link('Open Payments', _openPayments),
              if (changeOrders.isNotEmpty) link('Open Change orders', _openChangeOrders),
            ],
          ),
        ],
      ),
    );
  }

  String _batchStatusHint(PaymentBatchResponse b) => switch (b.status.toLowerCase()) {
        'proof_submitted' => 'waiting for the provider to confirm',
        'rejected' => 'proof rejected, upload a new one',
        _ => 'upload your payment proof',
      };

  Future<void> _openPayments() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentBatchesPage(
          projectWorkings: _engagements,
          projectName: _working?.projectName ?? 'Project',
        ),
      ),
    );
    if (mounted) _loadWorkspaceData();
  }

  bool get _projectCompleted => _project?.status.toLowerCase() == 'completed';
  bool get _projectCancelled => _project?.status.toLowerCase() == 'cancelled';

  /// Engagements still holding the project open — the server refuses to close
  /// the project while any of these exist.
  List<ProjectWorkingResponse> get _openEngagements => _engagements
      .where((e) => ProjectWorkingService.engagedStatuses.contains(e.status.toLowerCase()))
      .toList();

  static bool _coversScope(ProjectWorkingResponse w, String scope) {
    final kind = w.contractType.toLowerCase();
    return kind == scope || kind == 'both';
  }

  /// Scopes ('design' / 'construction') whose provider signed a contract and
  /// then ended the engagement midway, with nobody accepted for that scope.
  /// Mirrors rule 4 of the server's ProjectClosureRules: such a project can't
  /// be closed — ending a signed engagement doesn't finish the work.
  List<String> get _abandonedScopes => const ['design', 'construction']
      .where((scope) =>
          _engagements.any((e) =>
              e.status.toLowerCase() == 'terminated' &&
              e.hasConfirmedContract &&
              _coversScope(e, scope)) &&
          !_engagements.any((e) => e.status.toLowerCase() == 'completed' && _coversScope(e, scope)))
      .toList();

  Future<void> _closeProject() async {
    final project = _project;
    if (project == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Close project'),
        content: const Text(
          'Every provider has been accepted or has left the project. Close the project now?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.espresso),
            child: const Text('Close project', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    if (_engagementActionInProgress) return;
    setState(() => _engagementActionInProgress = true);
    try {
      await ProjectService.completeProject(project.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Project closed.')),
        );
        _loadWorkspaceData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _engagementActionInProgress = false);
    }
  }

  Widget _buildAcceptanceSection() {
    final isCompleted = _projectCompleted;
    // Rejected engagements never started — nothing to accept or end.
    final engagements = _engagements
        .where((e) => e.status.toLowerCase() != 'rejected')
        .toList();
    final open = _openEngagements;
    final accepted = _engagements.where((e) => e.status.toLowerCase() == 'completed').toList();
    final abandoned = _abandonedScopes;
    final unpaid = _unsettledForProject;
    final undecided = _pendingChangeOrdersForProject;
    final owesSomething = unpaid.isNotEmpty || undecided.isNotEmpty;
    // Everything but money is in order: show what is left to pay or decide
    // instead of a Close button the server would refuse.
    final closableButUnpaid = !isCompleted &&
        !_projectCancelled &&
        _project != null &&
        open.isEmpty &&
        accepted.isNotEmpty &&
        abandoned.isEmpty &&
        owesSomething;
    final canCloseProject = !isCompleted &&
        !_projectCancelled &&
        _project != null &&
        open.isEmpty &&
        accepted.isNotEmpty &&
        abandoned.isEmpty &&
        !owesSomething;

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
          color: isCompleted ? const Color(0xFFA5D6A7) : AppColors.outlineVariant.withValues(alpha: 0.5),
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
                      isCompleted
                          ? 'Project Completed!'
                          : _projectCancelled
                              ? 'Project Cancelled'
                              : 'Final Acceptance',
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
                          : 'Accept each provider\'s work separately, then close the project.',
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          for (final w in engagements) ...[
            _buildEngagementAcceptanceCard(w),
            const SizedBox(height: 12),
          ],
          if (isCompleted) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
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
          ] else if (canCloseProject) ...[
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _engagementActionInProgress ? null : _closeProject,
                icon: const Icon(Icons.verified, size: 20, color: Colors.white),
                label: const Text('Close project'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),
          ] else if (closableButUnpaid) ...[
            const SizedBox(height: 4),
            _buildOutstandingBox(
              action: 'closing the project',
              batches: [for (final (w, b) in unpaid) ('${_scopeLabel(w)} — ', b)],
              changeOrders: [for (final (w, o) in undecided) ('${_scopeLabel(w)} — ', o)],
            ),
          ] else if (open.isNotEmpty && !_projectCancelled) ...[
            const SizedBox(height: 4),
            Text(
              'The project can be closed once every provider above is accepted or has ended '
              'the engagement (${open.length} still open).',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary, height: 1.5),
            ),
          ] else if (abandoned.isNotEmpty && !_projectCancelled) ...[
            const SizedBox(height: 4),
            Text(
              'The ${abandoned.join(' and ')} work was ended after the contract was signed and '
              'nobody has finished it. Hire a provider to complete it before closing the project, '
              'or cancel the project from the project page.',
              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFE65100), height: 1.5),
            ),
          ],
        ],
      ),
    );
  }

  /// The quotation that prices this engagement, and whether the signed
  /// contract agrees with it. Payment instalments are generated from the
  /// approved quotation's terms, so the contract total has to match it.
  Widget _buildQuotationRow(ProjectWorkingResponse w) {
    final list = [...(_quotationsByEngagement[w.id] ?? const <QuotationResponse>[])]
      ..sort((a, b) => b.version.compareTo(a.version));
    final approved = list.where((q) => q.status.toLowerCase() == 'accepted').firstOrNull;
    final waiting = approved == null
        ? list
            .where((q) => const {'sent', 'revision_requested'}.contains(q.status.toLowerCase()))
            .firstOrNull
        : null;
    final quotation = approved ?? waiting;
    if (quotation == null) return const SizedBox.shrink();

    final needsDecision = quotation.status.toLowerCase() == 'sent';
    final statusText = switch (quotation.status.toLowerCase()) {
      'accepted' => 'Approved',
      'sent' => 'Waiting for your approval',
      'revision_requested' => 'New version requested',
      final other => other,
    };

    final signed = _contracts
        .where((c) => c.projectWorkingId == w.id && c.status == 'confirmed')
        .firstOrNull;
    final mismatch = approved != null &&
        signed != null &&
        (signed.agreedValue - approved.totalAmount).abs() >= 1;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: needsDecision ? const Color(0xFFFFF8E1) : const Color(0xFFF6F3F1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: needsDecision ? const Color(0xFFFFB300) : AppColors.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.request_quote_outlined, size: 18, color: AppColors.espresso),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Quotation v${quotation.version} · ${formatVnd(quotation.totalAmount)}',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.espresso),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              statusText,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: needsDecision ? const Color(0xFFB27300) : AppColors.textSecondary,
              ),
            ),
            if (needsDecision) ...[
              const SizedBox(height: 4),
              Text(
                'Approve it so the contract and its payment instalments follow this price.',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
              ),
            ],
            if (mismatch) ...[
              const SizedBox(height: 6),
              Text(
                'The signed contract (${formatVnd(signed.agreedValue)}) does not match this quotation — '
                'payment instalments follow the quotation.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFE65100),
                  height: 1.4,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 32),
                  foregroundColor: AppColors.espresso,
                ),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => QuotationDetailsPage(
                        quotationId: quotation.id,
                        initialQuotation: quotation,
                        scope: w.contractType,
                      ),
                    ),
                  );
                  if (mounted) _loadWorkspaceData();
                },
                child: Text(
                  needsDecision ? 'Review & approve quotation' : 'View quotation',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// One provider's acceptance state and the actions that apply to it alone.
  Widget _buildEngagementAcceptanceCard(ProjectWorkingResponse w) {
    final status = w.status.toLowerCase();
    final isAccepted = status == 'accepted';
    final ready = w.isAwaitingAcceptance || _deliverablesDone(w);
    // Every scope (design and construction): pay every instalment and decide
    // every change order before accepting the work — the server refuses
    // otherwise (PaymentSettlementRules, 02/10/2026).
    final unsettled = _unsettledBatchesOf(w.id);
    final undecided = _pendingChangeOrdersOf(w.id);
    final owes = unsettled.isNotEmpty || undecided.isNotEmpty;
    final canAccept = ready && !owes;

    final (String chip, Color chipColor) = switch (status) {
      'completed' => ('Accepted', const Color(0xFF2E7D32)),
      'terminated' => ('Ended', Colors.grey.shade700),
      'requested' => ('Invitation pending', const Color(0xFF6D4C41)),
      _ when w.isAwaitingTerminationApproval => ('End requested', const Color(0xFFE65100)),
      _ when ready && owes => ('Payment pending', const Color(0xFFB27300)),
      _ when w.isAwaitingAcceptance => ('Ready for acceptance', Colors.green.shade700),
      _ when !w.hasConfirmedContract => ('Contract not signed', const Color(0xFF6D4C41)),
      _ => ('In progress', AppColors.espresso),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _scopeLabel(w).toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      w.providerDisplayName.isNotEmpty ? w.providerDisplayName : 'Provider',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.espresso,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: chipColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  chip,
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: chipColor),
                ),
              ),
            ],
          ),
          _buildQuotationRow(w),
          if (status == 'requested') ...[
            const SizedBox(height: 8),
            Text(
              'Waiting for the provider to accept the invitation.',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
            ),
          ],
          if (isAccepted && w.isAwaitingAcceptance &&
              (w.completionRequestNote?.trim().isNotEmpty ?? false)) ...[
            const SizedBox(height: 8),
            Text(
              'Provider\'s note: ${w.completionRequestNote}',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
            ),
          ],
          if (isAccepted && w.hasConfirmedContract) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _engagementActionInProgress || !canAccept ? null : () => _completeEngagement(w),
                icon: const Icon(Icons.check_circle, size: 20, color: Colors.white),
                label: Text('Accept ${_scopeLabel(w).toLowerCase()} work'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: w.isAwaitingAcceptance ? Colors.green.shade700 : AppColors.espresso,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.outlineVariant,
                  disabledForegroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
            if (!ready) ...[
              const SizedBox(height: 6),
              Text(
                'Available once ${w.providerDisplayName} finishes and reports completion.',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
              ),
            ] else if (owes) ...[
              const SizedBox(height: 8),
              _buildOutstandingBox(
                action: 'accepting the ${_scopeLabel(w).toLowerCase()} work',
                batches: [for (final b in unsettled) ('', b)],
                changeOrders: [for (final o in undecided) ('', o)],
              ),
            ],
          ],
          if (isAccepted && w.isAwaitingTerminationApproval) ...[
            const SizedBox(height: 12),
            _buildTerminationBanner(w),
          ] else if (isAccepted) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _engagementActionInProgress ? null : () => _terminateEngagement(w),
                icon: const Icon(Icons.cancel, size: 18, color: Colors.red),
                // Reads as a proposal, not a done deal — the provider still
                // has to agree before anything ends.
                label: const Text('Request to end the engagement'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
          if (status == 'completed') ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showReviewDialog(w),
                icon: const Icon(Icons.star, size: 18, color: Color(0xFFF9A825)),
                label: const Text('Rate this provider'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFB27300),
                  side: const BorderSide(color: Color(0xFFF9A825)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ],
      ),
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
                  color: iconColor.withValues(alpha: 0.1),
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
