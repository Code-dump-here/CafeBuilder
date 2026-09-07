import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/responses/quotation_payment_responses.dart';
import '../services/quotation_service.dart';
import '../theme/app_colors.dart';
import '../utils/money.dart';
import '../utils/quotation_scope.dart';
import '../utils/quotation_status.dart';
import '../widgets/confirm_dialog.dart';

class QuotationDetailsPage extends StatefulWidget {
  final String quotationId;
  final QuotationResponse? initialQuotation;

  /// What the bid is pricing — the post's `serviceKind` or the engagement's
  /// `contractType`, whichever the caller has in hand.
  ///
  /// The quotation itself does not carry this: `QuotationResponse` has no
  /// scope field on either side of the wire, so it has to be threaded down
  /// from the screen that already knows which post or engagement is being
  /// looked at. Left null it degrades to [QuotationScope.unknown], which shows
  /// every section — the same behaviour this screen had before.
  final String? scope;

  const QuotationDetailsPage({
    super.key,
    required this.quotationId,
    this.initialQuotation,
    this.scope,
  });

  @override
  State<QuotationDetailsPage> createState() => _QuotationDetailsPageState();
}

class _QuotationDetailsPageState extends State<QuotationDetailsPage> {
  QuotationResponse? _quotation;
  bool _isLoading = true;
  bool _isActionLoading = false;

  @override
  void initState() {
    super.initState();
    _quotation = widget.initialQuotation;
    _fetchQuotation();
  }

  Future<void> _fetchQuotation() async {
    setState(() => _isLoading = true);
    try {
      final data = await QuotationService.getQuotation(widget.quotationId);
      if (mounted) {
        setState(() {
          _quotation = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load quotation: $e')),
        );
      }
    }
  }

  /// Ask for a different version. The server refuses a blank reason with a
  /// 400, so [showReasonDialog] keeps the button disabled until there is one.
  Future<void> _requestRevision() async {
    final reason = await showReasonDialog(
      context,
      title: 'Request revision',
      hint: 'What needs to change compared to this version?',
      confirmLabel: 'Send request',
      requireText: true,
    );
    if (reason == null) return;
    await _run(
      () => QuotationService.requestRevision(widget.quotationId, reason: reason),
    );
  }

  /// Turn the bid down. The reason is optional server-side but it is the only
  /// feedback the provider gets, so it is asked for here.
  Future<void> _reject() async {
    final reason = await showReasonDialog(
      context,
      title: 'Reject quotation',
      hint: 'Why are you turning this bid down?',
      confirmLabel: 'Reject',
      destructive: true,
    );
    if (reason == null) return;
    await _run(
      () => QuotationService.rejectQuotation(widget.quotationId, reason: reason),
    );
  }

  /// Accepting is choosing: the server also accepts the provider's
  /// application, opens the engagement and supersedes the rival bids, so the
  /// confirmation says so rather than asking a generic "are you sure".
  Future<void> _accept() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Accept this quotation?',
      message: 'Accepting a quotation also chooses this provider: their '
          'application is accepted, the post closes, and every rival bid is '
          'superseded. This cannot be undone.',
      confirmLabel: 'Accept & choose',
    );
    if (!confirmed) return;
    await _run(() => QuotationService.acceptQuotation(widget.quotationId));
  }

  /// Runs one decision behind the blocking loader and reloads afterwards —
  /// the three actions differ only in which call they make.
  Future<void> _run(Future<void> Function() action) async {
    setState(() => _isActionLoading = true);
    try {
      await action();
      await _fetchQuotation();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _quotation == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_quotation == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quotation Error')),
        body: const Center(child: Text('Could not load quotation.')),
      );
    }

    final q = _quotation!;
    // `sent` is the only state the owner can act on: `draft` hasn't been sent
    // yet, `revision_requested` is waiting on the provider's new version, and
    // the rest are final. Status values are the server's enum names verbatim
    // (draft | sent | revision_requested | accepted | rejected | superseded).
    final isPending = q.status.toLowerCase() == 'sent';
    final scope = quotationScopeFrom(widget.scope);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Quotation Details', style: GoogleFonts.playfairDisplay(color: AppColors.espresso, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppColors.espresso),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeaderInfo(q, scope),
                if (q.items.isNotEmpty) _buildItemsList(q.items),
                if (q.paymentTerms.isNotEmpty) _buildPaymentTerms(q.paymentTerms),
                // Design-only: the revision quota and the per-round fee are
                // enforced against `Design` rows, which a construction job has
                // none of. Showing them there advertised a term nothing could
                // ever charge or honour.
                if (scope.showsDesignTerms && _hasRevisionTerms(q))
                  _buildRevisionInfo(q),
                if (q.attachments.isNotEmpty) _buildAttachments(q.attachments),
              ],
            ),
          ),
          if (_isActionLoading)
            const ContainerWithLoader(),
        ],
      ),
      bottomNavigationBar: isPending ? _buildBottomActions() : null,
    );
  }

  /// True when the provider actually published revision terms.
  ///
  /// Both fields null rendered as "Not stated" twice — a section that told the
  /// owner nothing but still asked to be read.
  static bool _hasRevisionTerms(QuotationResponse q) =>
      q.freeRevisionCount != null || q.extraRevisionFee != null;

  Widget _buildHeaderInfo(QuotationResponse q, QuotationScope scope) {
    final scopeLabel = scope.label;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(q.title, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
          // Which set of terms this is. Two bids on the same project can price
          // entirely different work, and the sections below now differ between
          // them, so the document says which one it is instead of leaving the
          // owner to infer it from what is missing.
          if (scopeLabel != null) ...[
            const SizedBox(height: 6),
            Text(
              scopeLabel,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.placeholder,
                letterSpacing: 0.2,
              ),
            ),
          ],
          if (q.note != null && q.note!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(q.note!, style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ],
          const SizedBox(height: 16),
          // A billion-đồng total at 20px no longer collides with its label on
          // a narrow phone: the label keeps its width, the amount wraps under
          // it if it has to.
          _headerRow(
            'Total Amount',
            Text(
              formatVnd(q.totalAmount),
              textAlign: TextAlign.right,
              style: GoogleFonts.inter(fontSize: 20, color: Colors.green[700], fontWeight: FontWeight.bold),
            ),
          ),
          // How long the work will take. The comparison screen has always
          // shown this and the "Compare price, duration and payment terms"
          // banner promises it, but the single-bid screen dropped it — so the
          // one place the owner reads a bid in full was the one place the
          // duration was missing.
          if (q.estimatedDurationDays != null) ...[
            const SizedBox(height: 10),
            _headerRow(
              'Estimated Duration',
              Text(
                '${q.estimatedDurationDays} days',
                textAlign: TextAlign.right,
                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ],
          const SizedBox(height: 10),
          // The badge is pushed to the right edge so it lines up under the
          // amount above it, instead of floating mid-row against a label of
          // whatever width. It wraps rather than overflowing, which matters
          // because `quotationStatusStyle` echoes an unrecognised server enum
          // back verbatim and that string has no length bound.
          _headerRow('Status', _StatusBadge(status: q.status)),
        ],
      ),
    );
  }

  /// A label on the left, its value hard against the right edge.
  ///
  /// Every row in the header now shares this shape, so the values form one
  /// column down the right rather than each starting wherever its own label
  /// happened to end.
  ///
  /// Both halves are [Expanded] so the split is fixed rather than dependent on
  /// how long each label happens to be. That buys two things: the label wraps
  /// instead of overflowing — a bare `Text` reading "Estimated Duration" ran
  /// 305px past the edge at a system text scale of 2.0 on a 320dp screen — and
  /// the value lands on the true right edge every time. A loose `Flexible`
  /// label does neither: it under-uses its share of the row, and the slack it
  /// leaves behind sits to the right of the value, which is what left the
  /// status badge stranded mid-row in the first place.
  static Widget _headerRow(String label, Widget value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Align(alignment: Alignment.centerRight, child: value),
        ),
      ],
    );
  }

  Widget _buildItemsList(List<QuotationItemResponse> items) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Detailed Items', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
          const Divider(),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                      if (item.description != null && item.description!.isNotEmpty)
                        Text(item.description!, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                      Text('${formatQuantity(item.quantity)} ${item.unit ?? ''} x ${formatVnd(item.unitPrice)}'.replaceAll('  ', ' '), style: GoogleFonts.inter(fontSize: 12)),
                    ],
                  ),
                ),
                Text(formatVnd(item.amount), style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildPaymentTerms(List<QuotationPaymentTermResponse> terms) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Payment Milestones', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
          const Divider(),
          // The schedule has no dates — an instalment is triggered by a
          // condition ("on signing", "after handover"), and the percentage is
          // what the owner checks the split against.
          //
          // Laid out as a plain Row rather than a ListTile: a ListTile has a
          // bounded height, and the stacked amount-over-percentage in its
          // trailing slot overflowed it by 11px at system text scale 2.0. A Row
          // takes the height its children need.
          ...terms.map((term) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(term.name, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                      if (term.condition != null && term.condition!.isNotEmpty)
                        Text(
                          term.condition!,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatVnd(term.amount),
                        textAlign: TextAlign.right,
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                      ),
                      if (term.percentage != null)
                        Text(
                          '${formatPercent(term.percentage!)}%',
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildRevisionInfo(QuotationResponse q) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Revision Terms', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
          Text(
            'Applies to rounds of design changes.',
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
          ),
          const Divider(),
          _termRow(
            'Included Revisions',
            q.freeRevisionCount?.toString() ?? 'Not stated',
          ),
          const SizedBox(height: 12),
          // null is not zero here: it means the provider hasn't published a
          // price per extra round, not that extra rounds are free.
          _termRow(
            'Extra Revision Fee',
            q.extraRevisionFee != null ? formatVnd(q.extraRevisionFee!) : 'Not stated',
          ),
        ],
      ),
    );
  }

  /// Files the provider attached to the bid.
  ///
  /// `fileUrl` is the raw object name in the bucket; `fileViewUrl` is the
  /// absolute URL the server already resolved, so it is the one to open.
  Widget _buildAttachments(List<QuotationAttachmentResponse> attachments) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Attachments', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
          const Divider(),
          ...attachments.map((file) {
            final url = file.fileViewUrl;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.attach_file, color: AppColors.espresso),
              title: Text(
                file.fileName?.isNotEmpty == true ? file.fileName! : 'Attachment',
                style: GoogleFonts.inter(fontSize: 14),
              ),
              trailing: const Icon(Icons.open_in_new, size: 18),
              enabled: url != null && url.isNotEmpty,
              onTap: url == null || url.isEmpty
                  ? null
                  : () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
            );
          }),
        ],
      ),
    );
  }

  /// A labelled figure from the terms block.
  static Widget _termRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(label, style: GoogleFonts.inter())),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: GoogleFonts.inter(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  /// The three decisions, ranked.
  ///
  /// They were three equal-width outlined-ish buttons in one row, which said
  /// the owner had three interchangeable options. They are not: accepting also
  /// hires the provider, closes the post and supersedes every rival bid, and
  /// cannot be undone; asking for changes keeps the conversation open; and
  /// rejecting ends it. Reject and Revise were also near-identical outlined
  /// pills distinguished only by a foreground colour, so the destructive one
  /// looked exactly like the harmless one.
  ///
  /// Now: the commitment gets the full width and the only filled surface, and
  /// the two reversible answers sit under it, told apart by weight and colour
  /// rather than by reading them. Stacking also fixes the arithmetic — three
  /// buttons across a 320dp phone left ~85dp each, which "Reject" does not fit
  /// inside its own padding at default text size, let alone scaled up.
  Widget _buildBottomActions() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.outlineVariant)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _accept,
                icon: const Icon(Icons.check_circle_outline, size: 20),
                label: const _ActionLabel('Accept & choose provider'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _requestRevision,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const _ActionLabel('Request changes'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.espresso,
                      side: const BorderSide(color: AppColors.outlineVariant),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      textStyle: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _reject,
                    icon: const Icon(Icons.close, size: 18),
                    label: const _ActionLabel('Reject'),
                    // Red on both the border and the label, so the ending
                    // action does not read as a sibling of the one that keeps
                    // the bid alive.
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                      side: BorderSide(color: Colors.red.shade200),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      textStyle: GoogleFonts.inter(
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
    );
  }

}

/// A button label that shrinks instead of overflowing.
///
/// These labels are full phrases now, and the bar has to survive a 320dp
/// screen at a system text scale of 2.0. Scaling down is the honest failure
/// mode: an ellipsis would turn "Accept & choose provider" into something that
/// no longer says what the button does.
class _ActionLabel extends StatelessWidget {
  final String text;

  const _ActionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(text, maxLines: 1),
    );
  }
}

/// The status pill.
///
/// A `Chip` was doing this job, but it carries Material's own padding and a
/// minimum height built for a tap target, which is why it sat visibly taller
/// and wider than the line it was on. This is the same colours with none of
/// that, and — because it is inside an `Expanded` in [_headerRow] — its text
/// wraps under pressure rather than overflowing the row.
class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final style = quotationStatusStyle(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: style.foreground.withValues(alpha: 0.25)),
      ),
      child: Text(
        style.label,
        textAlign: TextAlign.right,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: style.foreground,
        ),
      ),
    );
  }
}

class ContainerWithLoader extends StatelessWidget {
  const ContainerWithLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.3),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
