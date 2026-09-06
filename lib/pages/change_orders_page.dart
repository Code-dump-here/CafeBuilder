import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/responses/api_responses.dart';
import '../models/responses/change_order_responses.dart';
import '../services/change_order_service.dart';
import '../theme/app_colors.dart';
import '../utils/money.dart';

/// Where the owner answers the money a provider asks for after the contract.
///
/// A change order is not an invoice — it is a request that only takes effect
/// when the other side accepts it. The owner accepts or rejects; they can also
/// raise one themselves, and the provider answers that. Neither side can
/// approve its own, which is what makes the committed total mean something.
///
/// A project can run a designer and a contractor at once, so the screen groups
/// by engagement: each provider has their own contract value and their own
/// running total.
class ChangeOrdersPage extends StatefulWidget {
  /// Every engagement on the project. Each has its own contract and totals.
  final List<ProjectWorkingResponse> projectWorkings;

  final String projectName;

  const ChangeOrdersPage({
    super.key,
    required this.projectWorkings,
    required this.projectName,
  });

  @override
  State<ChangeOrdersPage> createState() => _ChangeOrdersPageState();
}

class _ChangeOrdersPageState extends State<ChangeOrdersPage> {
  /// Engagement id → its orders and totals.
  final Map<String, List<ChangeOrderResponse>> _orders = {};
  final Map<String, ChangeOrderSummaryResponse> _summaries = {};

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
        final page = await ChangeOrderService.getAll(
          projectWorkingId: working.id,
          pageSize: 50,
        );
        final summary = await ChangeOrderService.getSummary(working.id);
        _orders[working.id] = page.items;
        _summaries[working.id] = summary;
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

  Future<void> _accept(ChangeOrderResponse order) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Approve this change order?',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: Text(
          '${order.title}\n\n'
          '${formatVnd(order.amount)} will be added to the committed total '
          'for this engagement. Once approved it cannot be changed.',
          style: GoogleFonts.inter(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.espresso),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _busy.add(order.id));
    try {
      await ChangeOrderService.accept(order.id);
      _toast('Change order approved.');
      await _load();
    } catch (e) {
      _toast(_cleanError(e), error: true);
    } finally {
      if (mounted) setState(() => _busy.remove(order.id));
    }
  }

  Future<void> _reject(ChangeOrderResponse order) async {
    // The reason is required by the server, and it is the only thing the
    // provider gets back — asking for it here avoids a pointless round trip
    // and a rejection they cannot act on.
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Reject change order',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This reason is all the provider receives, so be specific.',
              style: GoogleFonts.inter(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              maxLines: 3,
              style: GoogleFonts.inter(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Why are you turning this down?',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () {
              final text = controller.text.trim();
              if (text.isEmpty) return;
              Navigator.pop(ctx, text);
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (reason == null) return;

    setState(() => _busy.add(order.id));
    try {
      await ChangeOrderService.reject(order.id, rejectReason: reason);
      _toast('Change order rejected.');
      await _load();
    } catch (e) {
      _toast(_cleanError(e), error: true);
    } finally {
      if (mounted) setState(() => _busy.remove(order.id));
    }
  }

  Future<void> _withdraw(ChangeOrderResponse order) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Withdraw this change order?',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'It disappears entirely. Only change orders still awaiting approval can be withdrawn.',
          style: GoogleFonts.inter(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _busy.add(order.id));
    try {
      await ChangeOrderService.withdraw(order.id);
      _toast('Change order withdrawn.');
      await _load();
    } catch (e) {
      _toast(_cleanError(e), error: true);
    } finally {
      if (mounted) setState(() => _busy.remove(order.id));
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
          'Change orders',
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
            'change orders to approve.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 13, color: Colors.black54),
          ),
        ],
      );
    }

    // Anything still awaiting the owner goes to the top of its section, since
    // that is the only reason to open this screen.
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        Text(
          widget.projectName,
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        ...widget.projectWorkings.map(_buildEngagementSection),
      ],
    );
  }

  Widget _buildEngagementSection(ProjectWorkingResponse working) {
    final orders = [..._orders[working.id] ?? <ChangeOrderResponse>[]];
    final summary = _summaries[working.id];

    orders.sort((a, b) {
      if (a.isPending != b.isPending) return a.isPending ? -1 : 1;
      return b.createdAt.compareTo(a.createdAt);
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
          if (summary != null) _SummaryCard(summary: summary),
          const SizedBox(height: 10),
          if (orders.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: Text(
                'No change orders yet.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 13, color: Colors.black45),
              ),
            )
          else
            ...orders.map(
              (order) => _OrderCard(
                order: order,
                busy: _busy.contains(order.id),
                onAccept: () => _accept(order),
                onReject: () => _reject(order),
                onWithdraw: () => _withdraw(order),
              ),
            ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final ChangeOrderSummaryResponse summary;

  const _SummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    String vnd(double? value) =>
        value == null ? 'No signed contract' : formatVnd(value);

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
                  label: 'Contract value',
                  value: vnd(summary.contractValue),
                ),
              ),
              Expanded(
                child: _Metric(
                  label: 'Approved change orders',
                  value: formatVnd(summary.acceptedAmount),
                  hint: '${summary.acceptedCount} items',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  label: 'Waiting on your approval',
                  value: formatVnd(summary.pendingAmount),
                  hint: '${summary.pendingCount} items',
                  highlight: summary.pendingCount > 0,
                ),
              ),
              Expanded(
                child: _Metric(
                  label: 'Committed total',
                  value: vnd(summary.totalCommitted),
                  hint: 'Contract + approved',
                  emphasis: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  label: 'Batches raised',
                  value: formatVnd(summary.billedAmount),
                  hint: 'There are batches for you to pay',
                ),
              ),
              Expanded(
                child: _Metric(
                  label: 'Paid',
                  value: formatVnd(summary.paidAmount),
                  hint: 'Confirmed by the provider',
                ),
              ),
            ],
          ),
          if (summary.acceptedRevisionFee > 0) ...[
            const SizedBox(height: 10),
            Text(
              'Of that, ${formatVnd(summary.acceptedRevisionFee)} is for design '
              'revisions beyond the included allowance.',
              style: GoogleFonts.inter(fontSize: 11, color: Colors.black54),
            ),
          ],
          // Money both sides agreed that has nowhere to be collected. It is
          // invisible on every other screen, so it gets called out here.
          if (summary.unbilledAmount > 0) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 16,
                    color: Colors.amber.shade800,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${formatVnd(summary.unbilledAmount)} agreed '
                      'but not covered by any payment batch — either the engagement has '
                      'no signed contract, or it was approved before the system began '
                      'raising batches for change orders.',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.brown.shade800,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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

class _OrderCard extends StatelessWidget {
  final ChangeOrderResponse order;
  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onWithdraw;

  const _OrderCard({
    required this.order,
    required this.busy,
    required this.onAccept,
    required this.onReject,
    required this.onWithdraw,
  });

  @override
  Widget build(BuildContext context) {
    late final Color statusBg;
    late final Color statusFg;
    if (order.isAccepted) {
      statusBg = Colors.green.shade50;
      statusFg = Colors.green.shade800;
    } else if (order.isRejected) {
      statusBg = Colors.red.shade50;
      statusFg = Colors.red.shade700;
    } else {
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
          // Four badges and a price never fit one phone-width line once the
          // construction item carries a real name, so the badges run in a Wrap
          // and spill onto extra lines instead of being clipped.
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
                        kChangeOrderStatusLabels[order.status] ?? order.status,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: statusFg,
                        ),
                      ),
                    ),
                    Text(
                      kChangeOrderKindLabels[order.kind] ?? order.kind,
                      style: GoogleFonts.inter(fontSize: 11, color: Colors.black54),
                    ),
                    if (order.constructionItemName != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blueGrey.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          order.constructionItemName!,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Colors.blueGrey.shade800,
                          ),
                        ),
                      ),
                    if (order.revisionNo != null)
                      Text(
                        'round ${order.revisionNo}',
                        style: GoogleFonts.inter(fontSize: 11, color: Colors.black54),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                order.needsPricing
                    ? 'Not priced'
                    : formatVnd(order.amount),
                textAlign: TextAlign.right,
                style: GoogleFonts.inter(
                  fontSize: order.needsPricing ? 12 : 15,
                  fontWeight: FontWeight.w700,
                  color: order.needsPricing ? Colors.black45 : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            order.title,
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            order.reason,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.black54,
              height: 1.4,
            ),
          ),
          if (order.rejectReason != null && order.rejectReason!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'You rejected this: ${order.rejectReason}',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.red.shade700,
              ),
            ),
          ],
          if (!order.raisedByProvider) ...[
            const SizedBox(height: 6),
            Text(
              'You raised this one — the provider approves it.',
              style: GoogleFonts.inter(fontSize: 11, color: Colors.black45),
            ),
          ],
          // The system opened this fee because the owner asked for a round past
          // the free quota, but the quotation never published a rate. There is
          // nothing to decide until the provider fills in a number.
          if (order.needsPricing) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.espresso.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.hourglass_empty,
                    size: 16,
                    color: AppColors.espresso,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Waiting for the provider to price this revision round. The quotation '
                      'published no revision rate, so there is nothing for you to approve yet.',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          // Where the money got to after both sides agreed — otherwise the card
          // stops at 'Đã duyệt' and the owner never learns they owe it.
          if (order.paymentBatchId != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 14,
                  color: Colors.black45,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    kChangeOrderBillingLabels[order.paymentBatchStatus] ??
                        'Batches raised',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
          ] else if (order.acceptedButNotBilled) ...[
            const SizedBox(height: 6),
            Text(
              'Approved, but no payment batch covers it yet.',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: Colors.amber.shade900,
              ),
            ),
          ],
          if (order.isPending) ...[
            const SizedBox(height: 12),
            if (busy)
              const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.espresso,
                  ),
                ),
              )
            // Only the side that did NOT raise it gets to answer. The server
            // refuses the other way round, so offering the buttons would be
            // offering a guaranteed 401.
            else if (order.raisedByProvider)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onReject,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                      ),
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.espresso,
                      ),
                      // Approving an unpriced fee would settle it at 0 VND, and
                      // a decision is final — so there is no button to press
                      // until the provider puts a number on it.
                      onPressed: order.needsPricing ? null : onAccept,
                      child: const Text('Approve'),
                    ),
                  ),
                ],
              )
            else
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: onWithdraw,
                  icon: const Icon(Icons.undo, size: 16),
                  label: const Text('Withdraw'),
                ),
              ),
          ],
        ],
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
