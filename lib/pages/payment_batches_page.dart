import '../utils/upload_constraints.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/responses/api_responses.dart';
import '../models/responses/quotation_payment_responses.dart';
import '../services/payment_batch_service.dart';
import '../theme/app_colors.dart';
import '../utils/money.dart';

/// Where the owner pays the provider by instalment.
///
/// The platform holds no money — that was the decision the review board signed
/// off on, and it is what shapes this screen. The owner transfers directly,
/// records it here with a receipt, and the provider confirms against their own
/// bank account. Nothing on this page moves funds; it is the evidence trail
/// that both sides reconcile against, which is exactly what the board asked
/// for: *"có thể không giữ tiền nhưng phải có phần upload minh chứng giao dịch
/// theo từng giai đoạn"*.
///
/// A project can run a designer and a contractor at once, so the screen groups
/// by engagement: each has its own contract and its own schedule.
class PaymentBatchesPage extends StatefulWidget {
  /// Every engagement on the project. Instalments hang off each one's contract.
  final List<ProjectWorkingResponse> projectWorkings;

  final String projectName;

  const PaymentBatchesPage({
    super.key,
    required this.projectWorkings,
    required this.projectName,
  });

  @override
  State<PaymentBatchesPage> createState() => _PaymentBatchesPageState();
}

class _PaymentBatchesPageState extends State<PaymentBatchesPage> {
  /// Engagement id → its instalments.
  final Map<String, List<PaymentBatchResponse>> _batches = {};

  bool _loading = true;
  String? _error;

  /// Ids mid-request, so only the affected card shows a spinner.
  final Set<String> _busy = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      for (final working in widget.projectWorkings) {
        final page = await PaymentBatchService.getBatches(
          projectWorkingId: working.id,
          pageSize: 50,
        );
        _batches[working.id] = page.items;
      }
      if (!mounted) return;
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _cleanError(e);
        _loading = false;
      });
    }
  }

  static String _cleanError(Object e) {
    final text = e.toString();
    return text.startsWith('Exception: ') ? text.substring(11) : text;
  }

  void _toast(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red.shade700 : null,
      ),
    );
  }

  Future<void> _submitProof(PaymentBatchResponse batch) async {
    final result = await showModalBottomSheet<_ProofDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProofSheet(batch: batch),
    );
    if (result == null) return;

    setState(() => _busy.add(batch.id));
    try {
      String? objectName;
      if (result.bytes != null && result.filename != null) {
        objectName = await PaymentBatchService.uploadProofImage(
          bytes: result.bytes!,
          filename: result.filename!,
        );
      }
      await PaymentBatchService.submitProof(
        batch.id,
        imageUrl: objectName,
        amount: result.amount,
        transferredAt: result.transferredAt,
        note: result.note,
      );
      _toast('Proof submitted. The provider will check it and confirm.');
      await _load();
    } catch (e) {
      _toast(_cleanError(e), error: true);
    } finally {
      if (mounted) setState(() => _busy.remove(batch.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Payment batches',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.espresso,
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.espresso))
          : _error != null
              ? _ErrorView(message: _error!, onRetry: _load)
              : RefreshIndicator(onRefresh: _load, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (widget.projectWorkings.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'No provider has taken work on this project yet, so there are no '
            'payment batches.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 13, color: Colors.black54),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        Text(
          widget.projectName,
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          'The platform never holds your money. You transfer it to the provider '
          'directly and record it here; the batch closes once they confirm receipt.',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.black54,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        ...widget.projectWorkings.map(_buildEngagementSection),
      ],
    );
  }

  Widget _buildEngagementSection(ProjectWorkingResponse working) {
    final batches = [..._batches[working.id] ?? <PaymentBatchResponse>[]];
    final summary = PaymentBatchSummary.from(batches);

    // Anything still waiting on the owner rises to the top — that is the only
    // reason to open this screen. Within each group the agreed schedule order
    // is kept, so the instalments read as the plan they came from.
    batches.sort((a, b) {
      if (a.needsOwnerAction != b.needsOwnerAction) {
        return a.needsOwnerAction ? -1 : 1;
      }
      return a.sortOrder.compareTo(b.sortOrder);
    });

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            working.providerDisplayName,
            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (batches.isNotEmpty)
            _SummaryCard(summary: summary),
          const SizedBox(height: 10),
          if (batches.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: Text(
                'No payment batches yet. They are generated from the payment terms of '
                'the approved quotation, as soon as the contract is signed.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.black45,
                  height: 1.4,
                ),
              ),
            )
          else
            ...batches.map(
              (batch) => _BatchCard(
                batch: batch,
                busy: _busy.contains(batch.id),
                onSubmitProof: () => _submitProof(batch),
              ),
            ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final PaymentBatchSummary summary;

  const _SummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _Metric(
                  label: 'Contract total',
                  value: formatVnd(summary.total),
                ),
              ),
              Expanded(
                child: _Metric(
                  label: 'Confirmed',
                  value: formatVnd(summary.confirmed),
                  hint: '${summary.confirmedCount} batches',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  label: 'Awaiting provider confirmation',
                  value: formatVnd(summary.awaitingConfirmation),
                  hint: '${summary.awaitingCount} batches',
                ),
              ),
              Expanded(
                child: _Metric(
                  label: 'Still to pay',
                  value: formatVnd(summary.outstanding),
                  hint: 'Not yet confirmed',
                  emphasis: true,
                  highlight: summary.actionableCount > 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final String? hint;
  final bool emphasis;
  final bool highlight;

  const _Metric({
    required this.label,
    required this.value,
    this.hint,
    this.emphasis = false,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 11, color: Colors.black54),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: emphasis ? 15 : 13,
            fontWeight: FontWeight.w700,
            color: highlight
                ? Colors.amber.shade900
                : emphasis
                    ? AppColors.espresso
                    : Colors.black87,
          ),
        ),
        if (hint != null)
          Text(
            hint!,
            style: GoogleFonts.inter(fontSize: 10, color: Colors.black38),
          ),
      ],
    );
  }
}

/// Vietnamese labels for `PaymentBatchStatus`. Kept next to the card that
/// renders them rather than in a shared constants file, because the wording is
/// written for this screen: "chưa thanh toán" is a to-do for the owner, and
/// would be wrong phrasing on the provider's side.
const Map<String, String> _kStatusLabels = {
  'pending': 'Unpaid',
  'proof_submitted': 'Awaiting confirmation',
  'confirmed': 'Confirmed',
  'rejected': 'Proof rejected',
};

class _BatchCard extends StatelessWidget {
  final PaymentBatchResponse batch;
  final bool busy;
  final VoidCallback onSubmitProof;

  const _BatchCard({
    required this.batch,
    required this.busy,
    required this.onSubmitProof,
  });

  @override
  Widget build(BuildContext context) {
    late final Color statusBg;
    late final Color statusFg;
    switch (batch.status) {
      case 'confirmed':
        statusBg = Colors.green.shade50;
        statusFg = Colors.green.shade800;
        break;
      case 'rejected':
        statusBg = Colors.red.shade50;
        statusFg = Colors.red.shade700;
        break;
      case 'proof_submitted':
        statusBg = Colors.blue.shade50;
        statusFg = Colors.blue.shade800;
        break;
      default:
        statusBg = Colors.amber.shade50;
        statusFg = Colors.amber.shade900;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status, share and origin are badges in a Wrap: together with the
          // amount they are wider than a phone, so they take a second line
          // rather than pushing the amount off the card.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _kStatusLabels[batch.status] ?? batch.status,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: statusFg,
                        ),
                      ),
                    ),
                    if (batch.percentage != null)
                      Text(
                        '${formatPercent(batch.percentage!)}%',
                        style: GoogleFonts.inter(fontSize: 11, color: Colors.black54),
                      ),
                    // An instalment created by a change order is not part of the
                    // price originally agreed — saying so stops it reading as a
                    // batch that appeared from nowhere.
                    if (batch.changeOrderId != null)
                      Text(
                        'from a change order',
                        style: GoogleFonts.inter(fontSize: 11, color: Colors.black54),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                formatVnd(batch.amount),
                textAlign: TextAlign.right,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            batch.name,
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          if (batch.constructionItemName != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.link, size: 14, color: Colors.black45),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Milestone: ${batch.constructionItemName}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (batch.dueAt != null && batch.dueAt!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Due: ${batch.dueAt}',
              style: GoogleFonts.inter(fontSize: 11, color: Colors.black45),
            ),
          ],
          if (batch.rejectReason != null && batch.rejectReason!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(
                'Provider rejected the proof: ${batch.rejectReason}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.red.shade700,
                  height: 1.4,
                ),
              ),
            ),
          ],
          if (batch.proofs.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Proof submitted',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 6),
            ...batch.proofs.map((proof) => _ProofRow(proof: proof)),
          ],
          if (batch.needsOwnerAction) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.espresso,
                ),
                onPressed: busy ? null : onSubmitProof,
                icon: busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.upload_file, size: 18),
                label: Text(
                  batch.status == 'rejected'
                      ? 'Resubmit proof'
                      : 'Mark as paid',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProofRow extends StatelessWidget {
  final PaymentProofResponse proof;

  const _ProofRow({required this.proof});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (proof.imageViewUrl != null && proof.imageViewUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                proof.imageViewUrl!,
                width: 52,
                height: 52,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 52,
                  height: 52,
                  color: AppColors.primaryFixedDim,
                  child: const Icon(Icons.receipt_long, size: 20),
                ),
              ),
            )
          else
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primaryFixedDim,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.receipt_long, size: 20),
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  // A proof with no amount means the whole instalment — see
                  // SubmitPaymentProofRequest. Showing 0 VND would be a lie.
                  proof.amount != null
                      ? formatVnd(proof.amount!)
                      : 'Whole batch',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (proof.transferredAt != null)
                  Text(
                    'Transferred on '
                    '${DateFormat('dd/MM/yyyy HH:mm').format(proof.transferredAt!.toLocal())}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.black45,
                    ),
                  ),
                if (proof.note != null && proof.note!.isNotEmpty)
                  Text(
                    proof.note!,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.black54,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// What the proof sheet collects. Everything is optional: with no bank
/// integration the honest minimum is "I paid this", and demanding a receipt
/// would block a real payment rather than verify it.
class _ProofDraft {
  /// Receipt bytes, not a path — see [PaymentBatchService.uploadProofImage].
  final List<int>? bytes;
  final String? filename;
  final double? amount;
  final DateTime? transferredAt;
  final String? note;

  _ProofDraft({
    this.bytes,
    this.filename,
    this.amount,
    this.transferredAt,
    this.note,
  });
}

class _ProofSheet extends StatefulWidget {
  final PaymentBatchResponse batch;

  const _ProofSheet({required this.batch});

  @override
  State<_ProofSheet> createState() => _ProofSheetState();
}

class _ProofSheetState extends State<_ProofSheet> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _transferredAt = DateTime.now();
  List<int>? _bytes;
  String? _fileName;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    // withData: true for the same reason as chat_thread_page — on web the
    // browser exposes no filesystem path, so bytes are the only thing that
    // ever comes back.
    final result = await FilePicker.pickFiles(
      // Was FileType.image, which on iOS includes .heic — the format every
      // recent iPhone photo is saved in, and one the server refuses. The user
      // picked a receipt from their camera roll and the upload failed.
      type: FileType.custom,
      allowedExtensions: imageExtensions,
      withData: true,
    );
    final picked = result?.files.single;
    if (picked?.bytes == null) return;

    final problem = validateUpload(
      name: picked!.name,
      sizeBytes: picked.size,
      imageOnly: true,
    );
    if (problem != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(problem)));
      return;
    }

    setState(() {
      _bytes = picked.bytes;
      _fileName = picked.name;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _transferredAt,
      firstDate: DateTime(2020),
      // A transfer cannot have happened tomorrow, and a receipt dated in the
      // future is the kind of typo the provider would bounce.
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    setState(() => _transferredAt = picked);
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: insets),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Mark as paid',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.espresso,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${widget.batch.name} · ${formatVnd(widget.batch.amount)}',
                style: GoogleFonts.inter(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 12),
              Text(
                'The platform does not move money for you. Record the transfer you '
                'have already made — a receipt photo helps the provider check it faster.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'Amount transferred',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Leave blank if you transferred the exact batch amount',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.placeholder,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: AppColors.outlineVariant,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: AppColors.outlineVariant,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              Text(
                'Transfer date',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 16,
                        color: AppColors.espresso,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        DateFormat('dd/MM/yyyy').format(_transferredAt),
                        style: GoogleFonts.inter(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              Text(
                'Receipt photo',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: _pickFile,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.outlineVariant,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.image_outlined,
                        size: 16,
                        color: AppColors.espresso,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _fileName ?? 'Choose a transfer screenshot (optional)',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: _fileName == null
                                ? AppColors.placeholder
                                : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              Text(
                'Note',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _noteController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Reference number, bank… helps them check it faster',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.placeholder,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: AppColors.outlineVariant,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: AppColors.outlineVariant,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.espresso,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        final raw = _amountController.text.trim();
                        Navigator.pop(
                          context,
                          _ProofDraft(
                            bytes: _bytes,
                            filename: _fileName,
                            amount: raw.isEmpty ? null : double.tryParse(raw),
                            transferredAt: _transferredAt,
                            note: _noteController.text.trim().isEmpty
                                ? null
                                : _noteController.text.trim(),
                          ),
                        );
                      },
                      child: Text(
                        'Submit proof',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 40, color: Colors.red.shade400),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
