import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../models/responses/api_responses.dart';
import '../services/apply_service.dart';
import 'collaboration_workspace_page.dart';

class ProposalsPage extends StatefulWidget {
  final List<OpenPostResponse> openPosts;

  /// A project holds one designer slot and one constructor slot. The caller
  /// already knows which are filled, so it passes them down rather than making
  /// this page refetch the engagements.
  final bool designTaken;
  final bool constructionTaken;

  const ProposalsPage({
    super.key,
    required this.openPosts,
    this.designTaken = false,
    this.constructionTaken = false,
  });

  @override
  State<ProposalsPage> createState() => _ProposalsPageState();
}

class _ProposalsPageState extends State<ProposalsPage> {
  bool _loading = true;
  String? _error;
  List<ApplyResponse> _applies = [];

  // Local copies, updated on a successful accept, so a slot filled during this
  // visit still blocks a second accept if we haven't navigated away yet.
  late bool _designTaken = widget.designTaken;
  late bool _constructionTaken = widget.constructionTaken;

  @override
  void initState() {
    super.initState();
    _fetchApplies();
  }

  /// The role an application is for lives on its post, not on the application.
  /// Every apply here was fetched from [widget.openPosts], so the lookup hits.
  String _kindFor(ApplyResponse apply) {
    for (final post in widget.openPosts) {
      if (post.id == apply.postId) return post.serviceKind.toLowerCase();
    }
    return '';
  }

  /// Why this application can't be accepted, or null when it can. A 'both'
  /// application needs both slots free, since one provider would fill each.
  String? _slotConflict(ApplyResponse apply) {
    switch (_kindFor(apply)) {
      case 'design':
        return _designTaken ? 'This project already has a designer.' : null;
      case 'construction':
        return _constructionTaken ? 'This project already has a constructor.' : null;
      case 'both':
        if (_designTaken && _constructionTaken) {
          return 'This project already has a designer and a constructor.';
        }
        if (_designTaken) return 'This project already has a designer.';
        if (_constructionTaken) return 'This project already has a constructor.';
        return null;
      default:
        return null;
    }
  }

  Future<void> _fetchApplies() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final List<ApplyResponse> allApplies = [];
      for (final post in widget.openPosts) {
        final result = await ApplyService.getApplies(postId: post.id, pageSize: 50);
        allApplies.addAll(result.items);
      }
      
      if (mounted) {
        setState(() {
          _applies = allApplies;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load proposals: $e';
          _loading = false;
        });
      }
    }
  }

  Future<void> _acceptApply(ApplyResponse apply) async {
    // The backend closes a post and rejects its other applicants on accept, so
    // it can't be double-filled from one post — but nothing stops a second post
    // for the same role, so the slot is checked here before we call.
    final conflict = _slotConflict(apply);
    if (conflict != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(conflict)));
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator(color: AppColors.espresso)),
    );

    try {
      final working = await ApplyService.acceptApply(apply.id);
      final accepted = working.contractType.toLowerCase();
      if (accepted == 'design' || accepted == 'both') _designTaken = true;
      if (accepted == 'construction' || accepted == 'both') _constructionTaken = true;
      if (mounted) {
        Navigator.pop(context); // close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Proposal accepted successfully! Navigation to workspace...')),
        );
        // Navigate to the newly created engagement
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => CollaborationWorkspacePage(projectWorkingId: working.id),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error accepting proposal: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.espresso),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Proposals',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.espresso,
          ),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.espresso))
          : _error != null
              ? Center(child: Text(_error!, style: GoogleFonts.inter(color: Colors.red)))
              : _applies.isEmpty
                  ? Center(
                      child: Text(
                        'No proposals yet.',
                        style: GoogleFonts.playfairDisplay(fontSize: 18, color: AppColors.textSecondary),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchApplies,
                      color: AppColors.espresso,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _applies.length,
                        itemBuilder: (context, index) {
                          final apply = _applies[index];
                          return _buildProposalCard(apply);
                        },
                      ),
                    ),
    );
  }

  Widget _buildProposalCard(ApplyResponse apply) {
    final bool isPending = apply.status.toLowerCase() == 'pending';
    final String? blockedReason = isPending ? _slotConflict(apply) : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primaryFixedDim,
                    child: Icon(Icons.person, color: AppColors.espresso, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    apply.providerDisplayName,
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.espresso),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isPending ? const Color(0xFFD9EAA3).withOpacity(0.8) : const Color(0xFFF6F3F2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  apply.status.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isPending ? const Color(0xFF56642B) : AppColors.placeholder,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            apply.postTitle,
            style: GoogleFonts.playfairDisplay(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.espresso),
          ),
          const SizedBox(height: 8),
          Text(
            apply.proposal,
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.outlineVariant),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.timer_outlined, size: 14, color: AppColors.placeholder),
              const SizedBox(width: 6),
              Text(
                'Est. Duration: ${apply.estimatedDurationDays} days',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.espresso),
              ),
            ],
          ),
          if (isPending) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.outlineVariant),
                      foregroundColor: AppColors.espresso,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text('Message', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    // Greyed out rather than hidden, so it's clear the applicant
                    // is still there and why they can't be taken on.
                    onPressed: blockedReason != null ? null : () => _acceptApply(apply),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.espresso,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                    ),
                    child: Text('Accept', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
              ],
            ),
            if (blockedReason != null) ...[
              const SizedBox(height: 8),
              Text(
                blockedReason,
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary, height: 1.4),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
