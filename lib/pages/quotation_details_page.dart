import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/responses/quotation_responses.dart';
import '../services/quotation_service.dart';
import '../theme/app_colors.dart';
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

  Future<void> _handleAction(String action) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Confirm $action',
      message: 'Are you sure you want to ${action.toLowerCase()} this quotation?',
      confirmLabel: action,
    );
    if (!confirmed) return;

    if (action == 'Request Revision') {
      final noteController = TextEditingController();
      final submitRevision = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Request Revision'),
          content: TextField(
            controller: noteController,
            decoration: const InputDecoration(hintText: 'Enter your revision notes here...'),
            maxLines: 3,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Submit')),
          ],
        ),
      );
      if (submitRevision != true) return;

      setState(() => _isActionLoading = true);
      try {
        await QuotationService.requestRevision(widget.quotationId, note: noteController.text);
        await _fetchQuotation();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      } finally {
        if (mounted) setState(() => _isActionLoading = false);
      }
      return;
    }

    setState(() => _isActionLoading = true);
    try {
      if (action == 'Accept') {
        await QuotationService.acceptQuotation(widget.quotationId);
      } else if (action == 'Reject') {
        await QuotationService.rejectQuotation(widget.quotationId);
      }
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
    final isPending = q.status.toLowerCase() == 'pending' || q.status.toLowerCase() == 'sent';

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
                if (q.documentUrl != null && q.documentUrl!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: ElevatedButton.icon(
                      onPressed: () => launchUrl(Uri.parse(q.documentUrl!)),
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('View Quotation Document'),
                    ),
                  ),
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
          const SizedBox(height: 8),
          Text(q.description, style: GoogleFonts.inter(color: AppColors.textSecondary)),
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
              Chip(
                label: Text(q.status),
                backgroundColor: _getStatusColor(q.status),
              ),
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
                      if (item.description.isNotEmpty)
                        Text(item.description, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                      Text('${item.quantity} ${item.unit} x ${formatter.format(item.unitPrice)}', style: GoogleFonts.inter(fontSize: 12)),
                    ],
                  ),
                ),
                Text(formatter.format(item.totalPrice), style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
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
          ...terms.map((term) => ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(term.description),
            subtitle: term.expectedPaymentDate != null
                ? Text('Expected: ${DateFormat('dd MMM yyyy').format(term.expectedPaymentDate!)}')
                : null,
            trailing: Text(formatter.format(term.amount), style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
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
            trailing: Text(q.maxRevisions.toString(), style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Extra Revision Fee'),
            trailing: Text(formatter.format(q.revisionFee), style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
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
                onPressed: () => _handleAction('Reject'),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Reject'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () => _handleAction('Request Revision'),
                child: const Text('Revise'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _handleAction('Accept'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Accept'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Colors.green.shade100;
      case 'rejected':
        return Colors.red.shade100;
      case 'revisionrequested':
        return Colors.orange.shade100;
      default:
        return Colors.blue.shade100;
    }
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
