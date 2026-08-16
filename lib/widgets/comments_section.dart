import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/responses/api_responses.dart';
import '../services/api_client.dart';
import '../services/comment_service.dart';
import '../theme/app_colors.dart';

/// Discussion thread for one work item (a design or a construction item).
///
/// The backend treats owner and provider symmetrically — both post into the
/// same thread — so this renders every author, not just the current user.
/// Deleting is restricted to your own comments, matching the API.
class CommentsSection extends StatefulWidget {
  final String targetType;
  final int targetId;
  final String title;

  const CommentsSection({
    super.key,
    required this.targetType,
    required this.targetId,
    this.title = 'Comments',
  });

  @override
  State<CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends State<CommentsSection> {
  final TextEditingController _controller = TextEditingController();
  List<CommentResponse> _comments = [];
  bool _loading = true;
  bool _sending = false;
  int? _myAccountId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final accountId = await ApiClient.getAccountId();
      final result = await CommentService.getComments(
        targetType: widget.targetType,
        targetId: widget.targetId,
      );
      if (!mounted) return;
      setState(() {
        _myAccountId = accountId;
        _comments = result.items.toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _post() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await CommentService.addComment(
        targetType: widget.targetType,
        targetId: widget.targetId,
        body: text,
      );
      _controller.clear();
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not post comment: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _delete(CommentResponse c) async {
    try {
      await CommentService.deleteComment(c.id);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not delete: $e')),
        );
      }
    }
  }

  String _relative(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 1) return 'just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    if (d.inDays < 7) return '${d.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.forum_outlined, size: 18, color: AppColors.espresso),
            const SizedBox(width: 8),
            Text(
              widget.title,
              style: GoogleFonts.playfairDisplay(
                  fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.espresso),
            ),
            if (_comments.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text('(${_comments.length})',
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
            ],
          ],
        ),
        const SizedBox(height: 12),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator(color: AppColors.espresso, strokeWidth: 2)),
          )
        else if (_comments.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'No comments yet. Leave a note so the other side knows what needs attention.',
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
            ),
          )
        else
          ..._comments.map(_buildComment),
        const SizedBox(height: 8),
        _buildComposer(),
      ],
    );
  }

  Widget _buildComment(CommentResponse c) {
    final mine = _myAccountId != null && c.createdBy == _myAccountId;
    final name = (c.createdByName?.trim().isNotEmpty ?? false)
        ? c.createdByName!.trim()
        : (mine ? 'You' : 'Participant');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: mine ? AppColors.primaryFixed.withOpacity(0.25) : const Color(0xFFF6F3F2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  mine ? 'You' : name,
                  style: GoogleFonts.inter(
                      fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.espresso),
                ),
              ),
              Text(_relative(c.createdAt),
                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
              // The API only lets you remove your own comments.
              if (mine) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _delete(c),
                  child: const Icon(Icons.close_rounded, size: 15, color: AppColors.outline),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(c.body,
              style: GoogleFonts.inter(fontSize: 14, height: 1.5, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildComposer() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            minLines: 1,
            maxLines: 4,
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.espresso),
            decoration: InputDecoration(
              hintText: 'Add a comment...',
              hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.outline),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.outlineVariant.withOpacity(0.6)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.outlineVariant.withOpacity(0.6)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          decoration: BoxDecoration(
            color: _sending ? AppColors.outlineVariant : AppColors.espresso,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: _sending
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.send_rounded, size: 18, color: Colors.white),
            onPressed: _sending ? null : _post,
          ),
        ),
      ],
    );
  }
}
