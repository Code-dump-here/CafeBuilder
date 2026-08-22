import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../models/responses/api_responses.dart';

class QuoteReviewPage extends StatefulWidget {
  final ContractResponse contract;
  final String providerName;

  const QuoteReviewPage({
    super.key,
    required this.contract,
    this.providerName = '',
  });

  @override
  State<QuoteReviewPage> createState() => _QuoteReviewPageState();
}

class _QuoteReviewPageState extends State<QuoteReviewPage> {
  late ContractResponse _contract;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _contract = widget.contract;
  }

  Future<void> _handleApprove() async {
    setState(() => _isLoading = true);
    try {
      // In a real scenario, this would call an API to approve the quote,
      // moving it to 'pending_otp' or 'confirmed' state.
      // For now, we mock success.
      await Future.delayed(const Duration(seconds: 1)); 
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quote approved successfully!')),
        );
        Navigator.pop(context, true); // true indicates a state change happened
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to approve quote: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleReject() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reject Quote', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to reject this quote completely?', style: GoogleFonts.inter()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.textPrimary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Reject', style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    setState(() => _isLoading = true);
    
    try {
      // Mock reject API call
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quote rejected.')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reject: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRequestModification() async {
    final controller = TextEditingController();
    final feedback = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Request Modification', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Describe the changes you need for this quote/contract:', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'e.g., Please clarify the stages, or reduce the budget for X...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.textPrimary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.espresso),
            child: Text('Submit Request', style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );

    if (feedback == null || feedback.isEmpty) return;
    setState(() => _isLoading = true);

    try {
      // Mock request modification API call
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Modification request sent to the provider.')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send request: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'VND', decimalDigits: 0);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F3F0), // Paper-like background
      appBar: AppBar(
        title: Text(
          'Quote & Milestones Review',
          style: GoogleFonts.playfairDisplay(color: AppColors.espresso, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.espresso),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeaderCard(currencyFormatter),
                const SizedBox(height: 16),
                _buildRevisionPolicyCard(),
                const SizedBox(height: 16),
                _buildStagesCard(currencyFormatter),
                const SizedBox(height: 16),
                _buildDetailedItemsCard(currencyFormatter),
                const SizedBox(height: 16),
                if (_contract.terms != null && _contract.terms!.isNotEmpty)
                  _buildTermsCard(),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.1),
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.espresso),
              ),
            ),
        ],
      ),
      bottomSheet: _buildBottomActionBar(),
    );
  }

  Widget _buildHeaderCard(NumberFormat formatter) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5E5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TOTAL AGREED VALUE',
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppColors.placeholder),
          ),
          const SizedBox(height: 8),
          Text(
            formatter.format(_contract.agreedValue),
            style: GoogleFonts.playfairDisplay(fontSize: 32, fontWeight: FontWeight.bold, color: const Color(0xFF56642B)),
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PROVIDER', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.placeholder)),
                    const SizedBox(height: 4),
                    Text(widget.providerName.isEmpty ? 'Not specified' : widget.providerName, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('DATE SUBMITTED', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.placeholder)),
                    const SizedBox(height: 4),
                    Text(DateFormat('MMM dd, yyyy').format(_contract.createdAt), style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRevisionPolicyCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEBEBEB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.sync, color: AppColors.espresso, size: 20),
              const SizedBox(width: 8),
              Text(
                'Revision Policy',
                style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.espresso),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildPolicyItem(
                  'Allowed Revisions',
                  _contract.allowedRevisions?.toString() ?? 'Unlimited',
                  Icons.replay,
                ),
              ),
              Expanded(
                child: _buildPolicyItem(
                  'Revision Fee',
                  _contract.revisionFee != null && _contract.revisionFee! > 0
                      ? '${NumberFormat.currency(locale: 'vi_VN', symbol: 'VND', decimalDigits: 0).format(_contract.revisionFee)}/time'
                      : 'Free',
                  Icons.payments_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyItem(String title, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: Icon(icon, size: 16, color: AppColors.textSecondary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 2),
              Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStagesCard(NumberFormat formatter) {
    if (_contract.stages.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CONTRACT STAGES (MILESTONES)',
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppColors.placeholder),
          ),
          const SizedBox(height: 16),
          ..._contract.stages.asMap().entries.map((entry) {
            final index = entry.key;
            final stage = entry.value;
            final isLast = index == _contract.stages.length - 1;
            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.espresso.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Text('${index + 1}', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.espresso)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(stage.name, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold)),
                        if (stage.description != null && stage.description!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(stage.description!, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    formatter.format(stage.amount),
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF56642B)),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDetailedItemsCard(NumberFormat formatter) {
    if (_contract.items.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DETAILED QUOTE ITEMS',
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppColors.placeholder),
          ),
          const SizedBox(height: 16),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(1.2),
            },
            children: [
              TableRow(
                children: [
                  Text('Item', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.placeholder)),
                  Text('Qty', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.placeholder)),
                  Text('Total', textAlign: TextAlign.right, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.placeholder)),
                ],
              ),
              const TableRow(children: [SizedBox(height: 8), SizedBox(height: 8), SizedBox(height: 8)]),
              ..._contract.items.map((item) {
                return TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.name, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500)),
                          if (item.description != null && item.description!.isNotEmpty)
                            Text(item.description!, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text('${item.quantity} ${item.unit}', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 13)),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(formatter.format(item.totalPrice), textAlign: TextAlign.right, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                    ),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTermsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TERMS & CONDITIONS',
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppColors.placeholder),
          ),
          const SizedBox(height: 12),
          Text(
            _contract.terms!,
            style: GoogleFonts.inter(fontSize: 13, height: 1.6, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          )
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _handleRequestModification,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.espresso,
                      side: const BorderSide(color: AppColors.outlineVariant),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text('Request Mod', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _handleReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: BorderSide(color: Colors.red.withOpacity(0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text('Reject', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleApprove,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    child: Text('Approve Quote', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
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
