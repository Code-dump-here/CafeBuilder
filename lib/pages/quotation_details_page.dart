import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/responses/quotation_payment_responses.dart';
import '../services/quotation_service.dart';
import '../theme/app_colors.dart';
import '../utils/quotation_status.dart';
import '../widgets/confirm_dialog.dart';

class QuotationDetailsPage extends StatefulWidget {
  final String quotationId;
  final QuotationResponse? initialQuotation;

  const QuotationDetailsPage({
    super.key,
    required this.quotationId,
    this.initialQuotation,
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
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'VND', decimalDigits: 0);
    // `sent` is the only state the owner can act on: `draft` hasn't been sent
    // yet, `revision_requested` is waiting on the provider's new version, and
    // the rest are final. Status values are the server's enum names verbatim
    // (draft | sent | revision_requested | accepted | rejected | superseded).
    final isPending = q.status.toLowerCase() == 'sent';

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
                _buildHeaderInfo(q, currencyFormatter),
                if (q.items.isNotEmpty) _buildItemsList(q.items, currencyFormatter),
                if (q.paymentTerms.isNotEmpty) _buildPaymentTerms(q.paymentTerms, currencyFormatter),
                _buildRevisionInfo(q, currencyFormatter),
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

  Widget _buildHeaderInfo(QuotationResponse q, NumberFormat formatter) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(q.title, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
          if (q.note != null && q.note!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(q.note!, style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Amount:', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
              Text(formatter.format(q.totalAmount), style: GoogleFonts.inter(fontSize: 20, color: Colors.green[700], fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Status: '),
              Builder(builder: (_) {
                final status = quotationStatusStyle(q.status);
                return Chip(
                  label: Text(
                    status.label,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: status.foreground,
                    ),
                  ),
                  backgroundColor: status.background,
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList(List<QuotationItemResponse> items, NumberFormat formatter) {
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
                      Text('${item.quantity} ${item.unit ?? ''} x ${formatter.format(item.unitPrice)}'.replaceAll('  ', ' '), style: GoogleFonts.inter(fontSize: 12)),
                    ],
                  ),
                ),
                Text(formatter.format(item.amount), style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildPaymentTerms(List<QuotationPaymentTermResponse> terms, NumberFormat formatter) {
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
          ...terms.map((term) => ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(term.name),
            subtitle: term.condition != null && term.condition!.isNotEmpty
                ? Text(term.condition!)
                : null,
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(formatter.format(term.amount), style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                if (term.percentage != null)
                  Text(
                    '${term.percentage!.toStringAsFixed(term.percentage! % 1 == 0 ? 0 : 1)}%',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                  ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildRevisionInfo(QuotationResponse q, NumberFormat formatter) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Revision Terms', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
          const Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Included Revisions'),
            trailing: Text(
              q.freeRevisionCount?.toString() ?? 'Not stated',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Extra Revision Fee'),
            // null is not zero here: it means the provider hasn't published a
            // price per extra round, not that extra rounds are free.
            trailing: Text(
              q.extraRevisionFee != null ? formatter.format(q.extraRevisionFee) : 'Not stated',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
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

  Widget _buildBottomActions() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.white,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _reject,
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Reject'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: _requestRevision,
                child: const Text('Revise'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: _accept,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Accept'),
              ),
            ),
          ],
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
      color: Colors.black.withOpacity(0.3),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
