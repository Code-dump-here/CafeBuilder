import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/responses/quotation_payment_responses.dart';
import '../services/quotation_service.dart';
import '../theme/app_colors.dart';
import '../utils/money.dart';
import '../utils/quotation_status.dart';
import '../widgets/confirm_dialog.dart';

/// Where the owner compares priced bids and picks a provider.
///
/// This is the screen review 3 was asking for. Before it, the owner chose
/// between providers on one line of free text each; here each bid arrives with
/// its line items, a duration, the instalment schedule and the provider's
/// rating, so there is something to actually compare.
///
/// **Approving is choosing.** `POST /quotations/{id}/accept` accepts the
/// provider's application, opens the engagement, closes the post and drops the
/// rival bids — there is no separate "select this provider" step afterwards,
/// which is why the confirm dialog spells the consequence out.
class QuotationComparisonPage extends StatefulWidget {
  /// The post whose bids are being compared. Every provider who applied to it
  /// has their quotation returned by the same query.
  final String postId;

  final String postTitle;

  const QuotationComparisonPage({
    super.key,
    required this.postId,
    required this.postTitle,
  });

  @override
  State<QuotationComparisonPage> createState() =>
      _QuotationComparisonPageState();
}

class _QuotationComparisonPageState extends State<QuotationComparisonPage> {
  List<QuotationResponse> _quotations = [];

  bool _loading = true;
  String? _error;

  /// Ids mid-request, so only the affected card shows a spinner.
  final Set<String> _busy = {};

  /// True once a bid has been approved in this session — the caller reloads on
  /// the way back because the post and its applications have all just changed.
  bool _accepted = false;

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
      // Page size is 50 rather than the API default of 10 because a bid set is
      // read as a whole; a second page would hide a rival bid from the
      // comparison. The server already scopes results to the signed-in
      // account, so an owner only ever sees bids sent to their own projects.
      final page = await QuotationService.getQuotations(
        postId: widget.postId,
        pageSize: 50,
      );
      if (!mounted) return;
      setState(() {
        _quotations = page.items;
        _loading = false;
      });
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

  Future<void> _accept(QuotationResponse quotation) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Accept this quotation?',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: Text(
          '${quotation.providerName ?? 'Provider'} · '
          '${formatVnd(quotation.totalAmount)}\n\n'
          'Accepting a quotation also CHOOSES this provider: their application '
          'is accepted, the post closes, and every rival bid is superseded. '
          'This cannot be undone.',
          style: GoogleFonts.inter(fontSize: 13, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.espresso),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Accept & choose'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _busy.add(quotation.id));
    try {
      await QuotationService.acceptQuotation(quotation.id);
      _accepted = true;
      _toast('Quotation accepted — this provider is now hired.');
      await _load();
    } catch (e) {
      _toast(_cleanError(e), error: true);
    } finally {
      if (mounted) setState(() => _busy.remove(quotation.id));
    }
  }

  Future<void> _reject(QuotationResponse quotation) async {
    // The reason is the only feedback the provider gets. Optional server-side,
    // asked for here — a bid turned down with no explanation tells them
    // nothing about whether to bid differently next time.
    final reason = await showReasonDialog(
      context,
      title: 'Reject quotation',
      hint: 'Why are you turning this bid down?',
      confirmLabel: 'Reject',
      destructive: true,
    );
    if (reason == null) return;

    setState(() => _busy.add(quotation.id));
    try {
      await QuotationService.rejectQuotation(quotation.id, reason: reason);
      _toast('Quotation rejected.');
      await _load();
    } catch (e) {
      _toast(_cleanError(e), error: true);
    } finally {
      if (mounted) setState(() => _busy.remove(quotation.id));
    }
  }

  Future<void> _requestRevision(QuotationResponse quotation) async {
    final reason = await showReasonDialog(
      context,
      title: 'Ask for a different quotation',
      hint: 'What needs to change compared to this version?',
      confirmLabel: 'Send request',
      // Required by the server, not just by us: a revision request with an
      // empty reason is refused with a 400.
      requireText: true,
    );
    if (reason == null) return;

    setState(() => _busy.add(quotation.id));
    try {
      await QuotationService.requestRevision(quotation.id, reason: reason);
      _toast('Request sent — the provider will submit a new version.');
      await _load();
    } catch (e) {
      _toast(_cleanError(e), error: true);
    } finally {
      if (mounted) setState(() => _busy.remove(quotation.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {},
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.espresso),
            // Hand the outcome back so the proposals screen can reload: an
            // approval just accepted an application and closed the post.
            onPressed: () => Navigator.pop(context, _accepted),
          ),
          title: Text(
            'Compare quotations',
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
      ),
    );
  }

  Widget _buildBody() {
    // Only bids the owner can act on are live; the rest stay visible but
    // greyed, so a rejected bid can still be re-read rather than vanishing.
    final live = _quotations.where((q) => !q.isClosed).toList()
      ..sort((a, b) {
        if (a.isAwaitingOwner != b.isAwaitingOwner) {
          return a.isAwaitingOwner ? -1 : 1;
        }
        return a.totalAmount.compareTo(b.totalAmount);
      });
    final closed = _quotations.where((q) => q.isClosed).toList();

    if (_quotations.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'No provider has sent a quotation for this post yet.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 8),
          Text(
            'Providers write a quotation after they apply. You will be notified '
            'as soon as the first one arrives.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.black38,
              height: 1.4,
            ),
          ),
        ],
      );
    }

    // The cheapest live bid, called out on its card. Price is not the only
    // thing that matters — hence a quiet label rather than a recommendation.
    final cheapest = live.isEmpty
        ? null
        : live.reduce((a, b) => a.totalAmount <= b.totalAmount ? a : b);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        Text(
          widget.postTitle,
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          '${_quotations.length} quotations · accepting one is how you choose a provider',
          style: GoogleFonts.inter(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 16),
        ...live.map(
          (quotation) => _QuotationCard(
            quotation: quotation,
            busy: _busy.contains(quotation.id),
            isCheapest: cheapest != null && quotation.id == cheapest.id,
            onAccept: () => _accept(quotation),
            onReject: () => _reject(quotation),
            onRequestRevision: () => _requestRevision(quotation),
          ),
        ),
        if (closed.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Closed',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          ...closed.map(
            (quotation) => _QuotationCard(
              quotation: quotation,
              busy: false,
              isCheapest: false,
              onAccept: () {},
              onReject: () {},
              onRequestRevision: () {},
            ),
          ),
        ],
      ],
    );
  }
}

class _QuotationCard extends StatelessWidget {
  final QuotationResponse quotation;
  final bool busy;
  final bool isCheapest;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onRequestRevision;

  const _QuotationCard({
    required this.quotation,
    required this.busy,
    required this.isCheapest,
    required this.onAccept,
    required this.onReject,
    required this.onRequestRevision,
  });

  @override
  Widget build(BuildContext context) {
    final status = quotationStatusStyle(quotation.status);

    return Opacity(
      opacity: quotation.isClosed ? 0.7 : 1,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: quotation.status == 'accepted'
                ? Colors.green.shade300
                : AppColors.outlineVariant,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: status.background,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    status.label,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: status.foreground,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'v${quotation.version}',
                  style: GoogleFonts.inter(fontSize: 11, color: Colors.black54),
                ),
                if (isCheapest) ...[
                  const SizedBox(width: 8),
                  Text(
                    'lowest price',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  formatVnd(quotation.totalAmount),
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Provider identity comes down with the quotation itself, so the
            // owner can weigh price against track record without leaving the
            // comparison to open a profile.
            Row(
              children: [
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primaryFixedDim,
                  child: Icon(
                    Icons.storefront_outlined,
                    size: 17,
                    color: AppColors.espresso,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              quotation.providerName ?? 'Provider',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (quotation.providerIsVerified == true) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.verified,
                              size: 14,
                              color: Colors.blue.shade600,
                            ),
                          ],
                        ],
                      ),
                      Row(
                        children: [
                          if (quotation.providerAvgRating != null) ...[
                            Icon(
                              Icons.star,
                              size: 12,
                              color: Colors.amber.shade700,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              quotation.providerAvgRating!.toStringAsFixed(1),
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(width: 10),
                          ],
                          if (quotation.providerYearsExperience != null)
                            Text(
                              '${quotation.providerYearsExperience} years experience',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: Colors.black54,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (quotation.estimatedDurationDays != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${quotation.estimatedDurationDays} days',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'estimated',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: Colors.black38,
                        ),
                      ),
                    ],
                  ),
              ],
            ),

            const SizedBox(height: 10),
            Text(
              quotation.title,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (quotation.note != null && quotation.note!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                quotation.note!,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
            ],

            if (quotation.items.isNotEmpty) ...[
              const SizedBox(height: 10),
              _Section(
                label: 'Line items',
                children: quotation.items
                    .map(
                      (item) => _LineRow(
                        left: item.name,
                        sub: '${formatQuantity(item.quantity)}'
                            '${item.unit != null ? ' ${item.unit}' : ''}'
                            ' × ${formatVnd(item.unitPrice)}',
                        right: formatVnd(item.amount),
                      ),
                    )
                    .toList(),
              ),
            ],

            if (quotation.paymentTerms.isNotEmpty) ...[
              const SizedBox(height: 10),
              _Section(
                // Worth its own block: these exact rows become the instalments
                // the owner will be asked to pay once the contract is signed.
                label: 'Payment terms',
                children: quotation.paymentTerms
                    .map(
                      (term) => _LineRow(
                        left: term.name,
                        sub: term.condition,
                        right: term.percentage != null
                            ? '${formatPercent(term.percentage!)}% · '
                                '${formatVnd(term.amount)}'
                            : formatVnd(term.amount),
                      ),
                    )
                    .toList(),
              ),
            ],

            if (quotation.attachments.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: quotation.attachments.map((attachment) {
                  // `fileViewUrl` is the absolute URL the server resolved;
                  // `fileUrl` is only the storage key, so a chip without the
                  // former stays inert rather than opening a broken link.
                  final url = attachment.fileViewUrl;
                  final openable = url != null && url.isNotEmpty;
                  return InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: openable
                        ? () => launchUrl(
                              Uri.parse(url),
                              mode: LaunchMode.externalApplication,
                            )
                        : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.outlineVariant),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.attach_file,
                            size: 12,
                            color: Colors.black45,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            attachment.fileName ?? 'Attachment',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: Colors.black54,
                            ),
                          ),
                          if (openable) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.open_in_new,
                              size: 11,
                              color: Colors.black45,
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],

            if (quotation.revisionReason != null &&
                quotation.revisionReason!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'You asked for changes: ${quotation.revisionReason}',
                style: GoogleFonts.inter(fontSize: 12, color: Colors.black54),
              ),
            ],
            if (quotation.rejectReason != null &&
                quotation.rejectReason!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'You rejected this: ${quotation.rejectReason}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.red.shade700,
                ),
              ),
            ],

            if (quotation.isAwaitingOwner) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.espresso,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: busy ? null : onAccept,
                      child: busy
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Accept & choose',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: busy ? null : onRequestRevision,
                      child: Text(
                        'Ask for another',
                        style: GoogleFonts.inter(fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Reject',
                    onPressed: busy ? null : onReject,
                    icon: Icon(Icons.close, color: Colors.red.shade700),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String label;
  final List<Widget> children;

  const _Section({required this.label, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 4),
        ...children,
      ],
    );
  }
}

class _LineRow extends StatelessWidget {
  final String left;
  final String? sub;
  final String right;

  const _LineRow({required this.left, this.sub, required this.right});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  left,
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.black87),
                ),
                if (sub != null && sub!.isNotEmpty)
                  Text(
                    sub!,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: Colors.black38,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            right,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
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
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
