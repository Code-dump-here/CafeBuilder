import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/responses/review3_responses.dart';
import '../services/checklist_service.dart';
import '../theme/app_colors.dart';

/// Where the shop owner signs off a milestone, item by item.
///
/// This is not a report. Required items that are not `passed` block closing the
/// milestone, approving the design, and accepting the whole engagement — so the
/// verdicts entered here are what release the work.
///
/// Two rules the screen enforces so the provider is never left guessing:
///   * failing an item requires a reason, because "not accepted" with no note
///     gives the provider nothing to act on;
///   * a verdict can be changed later — the provider fixes the problem and the
///     owner re-grades, which is a conversation rather than a one-way gate.
class AcceptanceChecklistPage extends StatefulWidget {
  /// Milestone being signed off. Uuid string.
  final String constructionItemId;

  /// Milestone name, so the screen states what is being accepted.
  final String milestoneName;

  const AcceptanceChecklistPage({
    super.key,
    required this.constructionItemId,
    required this.milestoneName,
  });

  @override
  State<AcceptanceChecklistPage> createState() =>
      _AcceptanceChecklistPageState();
}

class _AcceptanceChecklistPageState extends State<AcceptanceChecklistPage> {
  List<ChecklistItemResponse> _items = [];
  bool _loading = true;
  String? _error;

  /// Ids currently being graded, so only the affected row shows a spinner.
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
      final page = await ChecklistService.getChecklist(
        constructionItemId: widget.constructionItemId,
      );
      if (!mounted) return;
      final items = [...page.items]
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _grade(
    ChecklistItemResponse item, {
    required String status,
  }) async {
    String? note;

    // A failure with no explanation is the one outcome the provider cannot act
    // on, so the reason is collected before the request rather than being an
    // optional afterthought. The server rejects it too — asking here just
    // avoids a pointless round trip.
    if (status == 'failed') {
      note = await _askForReason(item);
      if (note == null) return; // cancelled
    }

    setState(() => _busy.add(item.id));
    try {
      final updated = await ChecklistService.check(
        item.id,
        status: status,
        note: note,
      );
      if (!mounted) return;
      setState(() {
        final i = _items.indexWhere((x) => x.id == item.id);
        if (i != -1) _items[i] = updated;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_readableError(e))),
      );
    } finally {
      if (mounted) setState(() => _busy.remove(item.id));
    }
  }

  Future<String?> _askForReason(ChecklistItemResponse item) async {
    final controller = TextEditingController(text: item.note ?? '');
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Chưa đạt: ${item.name}', style: GoogleFonts.inter()),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Chưa đạt ở chỗ nào, cần sửa gì?',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isEmpty) return;
              Navigator.pop(context, text);
            },
            child: const Text('Gửi'),
          ),
        ],
      ),
    );
  }

  String _readableError(Object e) {
    final raw = e.toString().replaceFirst('Exception: ', '');
    return raw.isEmpty ? 'Không thể chấm nghiệm thu. Vui lòng thử lại.' : raw;
  }

  @override
  Widget build(BuildContext context) {
    final progress = ChecklistProgress.from(_items);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Nghiệm thu',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(progress),
      ),
    );
  }

  Widget _buildBody(ChecklistProgress progress) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 80),
          Icon(Icons.error_outline, size: 40, color: Colors.red.shade400),
          const SizedBox(height: 12),
          Text(
            'Không tải được checklist.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 16),
          Center(
            child: FilledButton(onPressed: _load, child: const Text('Thử lại')),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        Text(
          widget.milestoneName,
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        _GateBanner(progress: progress),
        const SizedBox(height: 16),
        if (_items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Text(
              'Nhà cung cấp chưa lập checklist nghiệm thu cho hạng mục này.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.black54),
            ),
          )
        else
          ..._items.map(
            (item) => _ChecklistTile(
              item: item,
              busy: _busy.contains(item.id),
              onPass: () => _grade(item, status: 'passed'),
              onFail: () => _grade(item, status: 'failed'),
            ),
          ),
      ],
    );
  }
}

/// States up front whether the milestone can be closed, and if not, what is
/// standing in the way — the reason the owner opened this screen.
class _GateBanner extends StatelessWidget {
  final ChecklistProgress progress;

  const _GateBanner({required this.progress});

  @override
  Widget build(BuildContext context) {
    late final Color bg;
    late final Color fg;
    late final IconData icon;
    late final String message;

    if (progress.requiredTotal == 0) {
      bg = Colors.grey.shade100;
      fg = Colors.black87;
      icon = Icons.info_outline;
      message = 'Không có mục bắt buộc — nghiệm thu không bị chặn.';
    } else if (progress.isSatisfied) {
      bg = Colors.green.shade50;
      fg = Colors.green.shade800;
      icon = Icons.check_circle_outline;
      message = 'Mọi mục bắt buộc đã đạt — hạng mục này có thể đóng.';
    } else {
      bg = Colors.amber.shade50;
      fg = Colors.amber.shade900;
      icon = Icons.pending_actions;
      message =
          'Còn ${progress.blockingCount} mục bắt buộc chưa xong — chưa đóng được hạng mục.';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: fg),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: fg,
                  ),
                ),
                if (progress.requiredTotal > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '${progress.requiredPassed}/${progress.requiredTotal} mục bắt buộc đã đạt',
                      style: GoogleFonts.inter(fontSize: 12, color: fg),
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

class _ChecklistTile extends StatelessWidget {
  final ChecklistItemResponse item;
  final bool busy;
  final VoidCallback onPass;
  final VoidCallback onFail;

  const _ChecklistTile({
    required this.item,
    required this.busy,
    required this.onPass,
    required this.onFail,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StatusDot(status: item.status),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (item.description != null &&
                        item.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          item.description!,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (item.isRequired)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Bắt buộc',
                    style: GoogleFonts.inter(fontSize: 10),
                  ),
                ),
            ],
          ),

          // The owner's own note, echoed back so a failed item shows what was
          // asked for without reopening the dialog.
          if (item.note != null && item.note!.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                item.note!,
                style: GoogleFonts.inter(fontSize: 12),
              ),
            ),

          const SizedBox(height: 10),
          Row(
            children: [
              if (busy)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else ...[
                OutlinedButton.icon(
                  onPressed: item.isPassed ? null : onPass,
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Đạt'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: item.isFailed ? null : onFail,
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Chưa đạt'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final String status;

  const _StatusDot({required this.status});

  @override
  Widget build(BuildContext context) {
    final (IconData icon, Color color) = switch (status) {
      'passed' => (Icons.check_circle, Colors.green),
      'failed' => (Icons.cancel, Colors.red),
      _ => (Icons.radio_button_unchecked, Colors.grey),
    };
    return Icon(icon, size: 20, color: color);
  }
}
