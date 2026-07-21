import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../models/responses/api_responses.dart';
import '../services/post_service.dart';
import '../services/apply_service.dart';

/// Owner-side: review who applied to a project's job posts and accept/reject.
class ProjectApplicantsPage extends StatefulWidget {
  final int projectId;
  final String projectName;

  const ProjectApplicantsPage({super.key, required this.projectId, required this.projectName});

  @override
  State<ProjectApplicantsPage> createState() => _ProjectApplicantsPageState();
}

class _ProjectApplicantsPageState extends State<ProjectApplicantsPage> {
  bool _loading = true;
  String? _error;
  List<PostResponse> _posts = [];
  Map<int, List<ApplyResponse>> _appliesByPost = {};
  final Set<int> _actingOn = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final postsResult = await PostService.getPosts(projectShopOwnerId: widget.projectId);
      final applies = <int, List<ApplyResponse>>{};
      for (final post in postsResult.items) {
        final res = await ApplyService.getApplies(postId: post.id);
        applies[post.id] = res.items;
      }
      if (mounted) {
        setState(() {
          _posts = postsResult.items;
          _appliesByPost = applies;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _accept(ApplyResponse apply) async {
    setState(() => _actingOn.add(apply.id));
    try {
      await ApplyService.accept(apply.id);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to accept: $e')));
      }
    } finally {
      if (mounted) setState(() => _actingOn.remove(apply.id));
    }
  }

  Future<void> _reject(ApplyResponse apply) async {
    setState(() => _actingOn.add(apply.id));
    try {
      await ApplyService.reject(apply.id);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to reject: $e')));
      }
    } finally {
      if (mounted) setState(() => _actingOn.remove(apply.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF8F6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.espresso),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Applicants',
          style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.espresso),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.espresso));
    }
    if (_error != null) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 40),
          Icon(Icons.error_outline, color: Colors.red.shade300, size: 40),
          const SizedBox(height: 12),
          Text('Could not load applicants', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.espresso)),
          const SizedBox(height: 4),
          Text(_error!, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
        ],
      );
    }
    if (_posts.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 60),
          Center(
            child: Column(
              children: [
                Icon(Icons.campaign_outlined, color: AppColors.placeholder, size: 40),
                const SizedBox(height: 12),
                Text('No job posts yet', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.espresso)),
                const SizedBox(height: 4),
                Text(
                  'Create a post to invite designers or constructors to ${widget.projectName}.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _posts.length,
      itemBuilder: (context, index) {
        final post = _posts[index];
        final applies = _appliesByPost[post.id] ?? [];
        return _buildPostSection(post, applies);
      },
    );
  }

  Widget _buildPostSection(PostResponse post, List<ApplyResponse> applies) {
    final pending = applies.where((a) => a.status == 'pending').toList();
    final others = applies.where((a) => a.status != 'pending').toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(post.title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.espresso)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: post.status == 'open' ? const Color(0xFFD9EAA3) : AppColors.outlineVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  post.status.toUpperCase(),
                  style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.espresso),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${post.serviceKind} · ${applies.length} application${applies.length == 1 ? '' : 's'}',
            style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          if (applies.isEmpty)
            Text('No applications yet.', style: GoogleFonts.inter(fontSize: 12, color: AppColors.placeholder))
          else ...[
            ...pending.map((a) => _buildApplyCard(a)),
            if (others.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('DECIDED', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1, color: AppColors.placeholder)),
              const SizedBox(height: 8),
              ...others.map((a) => _buildApplyCard(a)),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildApplyCard(ApplyResponse apply) {
    final isPending = apply.status == 'pending';
    final busy = _actingOn.contains(apply.id);
    Color statusColor;
    switch (apply.status) {
      case 'accepted':
        statusColor = const Color(0xFF56642B);
        break;
      case 'rejected':
        statusColor = Colors.red.shade400;
        break;
      default:
        statusColor = AppColors.placeholder;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F3F2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.espresso,
                child: Text(
                  (apply.providerDisplayName ?? '?').characters.first.toUpperCase(),
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  apply.providerDisplayName ?? 'Provider #${apply.serviceProviderProfileId}',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.espresso),
                ),
              ),
              if (!isPending)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    apply.status.toUpperCase(),
                    style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: statusColor),
                  ),
                ),
            ],
          ),
          if (apply.proposal.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(apply.proposal, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary), maxLines: 4, overflow: TextOverflow.ellipsis),
          ],
          if (apply.estimatedDurationDays != null) ...[
            const SizedBox(height: 6),
            Text(
              'Estimated: ${apply.estimatedDurationDays} days',
              style: GoogleFonts.inter(fontSize: 10, color: AppColors.placeholder),
            ),
          ],
          if (isPending) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: busy ? null : () => _reject(apply),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.red.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text('Decline', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red.shade400)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: busy ? null : () => _accept(apply),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.espresso,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: busy
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text('Accept', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
