import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../models/responses/api_responses.dart';
import '../services/apply_service.dart';
import '../services/project_service.dart';
import '../services/survey_service.dart';
import '../widgets/confirm_dialog.dart';
import 'collaboration_workspace_page.dart';
import 'provider_brand_page.dart';
import 'survey_detail_page.dart';

class ProposalsPage extends StatefulWidget {
  /// Posts as the caller knew them. Used only as the initial value — the page
  /// refetches the project on open, because this list is a snapshot from the
  /// previous screen and an empty or stale one silently produced an empty
  /// proposals list with no error to explain it.
  final List<OpenPostResponse> openPosts;

  /// Project to reload posts from. Optional so existing callers keep working;
  /// without it the page falls back to [openPosts] alone.
  final String? projectId;

  /// A project holds one designer slot and one constructor slot. The caller
  /// already knows which are filled, so it passes them down rather than making
  /// this page refetch the engagements.
  final bool designTaken;
  final bool constructionTaken;

  const ProposalsPage({
    super.key,
    required this.openPosts,
    this.projectId,
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

  /// Posts the applications are read from. Seeded from the caller, then
  /// replaced by a fresh fetch so the page stands on its own.
  late List<OpenPostResponse> _posts = widget.openPosts;

  /// Surveys already fetched, keyed by application id, so reopening a card
  /// doesn't refetch.
  final Map<String, List<SurveyResponse>> _surveysByApply = {};
  String? _loadingSurveyFor;

  /// Id of the application currently being declined, so only that card shows a
  /// spinner and the rest stay interactive.
  String? _rejectingId;

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
    for (final post in _posts) {
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

  /// Why the survey rule blocks this application, or null when it doesn't.
  ///
  /// Mirrors `ApplyService.EnsureSurveySubmittedAsync`: a post with a design
  /// phase can only be awarded to someone who has walked the site. A booked
  /// but unattended visit doesn't count — there's nothing for the owner to
  /// read yet. Construction-only posts have no survey step and are exempt.
  ///
  /// Duplicated here so the button greys out with an explanation instead of
  /// firing a request that comes back 409.
  String? _surveyBlock(ApplyResponse apply) {
    if (_kindFor(apply) == 'construction') return null;
    if (apply.hasCompletedSurvey) return null;
    if (apply.surveyCount == 0) {
      return 'This provider has not surveyed the site yet. '
          'A design-scope project can only be awarded after a site visit.';
    }
    return 'The site visit is booked but has not happened yet.';
  }

  /// One-line survey status for the card. No `intl` dependency in this file,
  /// so the date is spelled out by hand — day/month is enough context here.
  String _surveyLabel(ApplyResponse apply) {
    String d(DateTime t) =>
        '${t.day.toString().padLeft(2, '0')}/${t.month.toString().padLeft(2, '0')}';

    if (apply.hasCompletedSurvey) {
      final on = apply.latestSurveyedAt;
      return on != null ? 'Site surveyed ${d(on.toLocal())}' : 'Site surveyed';
    }
    if (apply.surveyCount > 0) {
      final at = apply.latestSurveyScheduledAt;
      return at != null
          ? 'Survey booked for ${d(at.toLocal())} — not done yet'
          : 'Survey booked — not done yet';
    }
    return 'No site survey yet';
  }

  /// Slot conflicts first: "someone else already has this job" is a harder
  /// stop than "they still need to visit", which the provider can still fix.
  String? _blockedReason(ApplyResponse apply) =>
      _slotConflict(apply) ?? _surveyBlock(apply);

  Future<void> _fetchApplies() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Reload the project's posts rather than trusting the snapshot handed
      // over by the previous screen. Applications are read per post, so an
      // empty list here means an empty page with nothing explaining why.
      var posts = _posts;
      if (widget.projectId != null) {
        final project = await ProjectService.getProject(widget.projectId!);
        // Every post, not only the open ones: a post closes as soon as someone
        // is accepted, and the owner still needs to see who else applied.
        if (project.openPosts.isNotEmpty) posts = project.openPosts;
      }


      final List<ApplyResponse> allApplies = [];
      final Map<String, List<SurveyResponse>> surveys = {};

      for (final post in posts) {
        final result = await ApplyService.getApplies(postId: post.id, pageSize: 50);
        allApplies.addAll(result.items);

        // One request per post for every bidder's survey, instead of one per
        // application when a card is opened. `?postId=` exists for exactly this
        // reading: the owner is comparing site visits across providers before
        // awarding, so all of them are wanted at once anyway.
        //
        // Not fatal if it fails — the cards carry their own survey counts, and
        // _openSurvey still falls back to the per-application fetch on a miss.
        try {
          final filed = await SurveyService.getSurveys(postId: post.id, pageSize: 50);

          // Seed an entry for every bidder, empty ones included: "asked, and
          // there are none" is a real answer worth caching, otherwise every
          // surveyless card refetches on each tap to learn the same thing.
          for (final apply in result.items) {
            surveys.putIfAbsent(apply.id, () => []);
          }
          for (final survey in filed.items) {
            final applyId = survey.applyId;
            if (applyId == null) continue;
            surveys.putIfAbsent(applyId, () => []).add(survey);
          }
        } catch (_) {
          // Deliberately left uncached: a miss costs one request later, a
          // wrongly-cached empty list costs the owner the survey entirely.
        }
      }


      // Newest first, so the freshest bid is the one in view.
      allApplies.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (mounted) {
        setState(() {
          _posts = posts;
          _applies = allApplies;
          _surveysByApply
            ..clear()
            ..addAll(surveys);
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

  /// Show the site survey attached to this application.
  ///
  /// Normally a cache hit: _fetchApplies preloads every bidder's survey per
  /// post. The fetch below is the fallback for when that preload failed, and
  /// reads with `?applyId=` — a survey filed while bidding hangs off the
  /// application, not an engagement, because there is no engagement yet.
  Future<void> _openSurvey(ApplyResponse apply) async {
    var surveys = _surveysByApply[apply.id];

    if (surveys == null) {
      setState(() => _loadingSurveyFor = apply.id);
      try {
        final result = await SurveyService.getSurveys(applyId: apply.id, pageSize: 50);
        surveys = result.items;
        _surveysByApply[apply.id] = surveys;
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load the survey: $e')),
        );
        return;
      } finally {
        if (mounted) setState(() => _loadingSurveyFor = null);
      }
    }

    if (!mounted) return;
    if (surveys.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This provider has not filed a survey yet.')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SurveyDetailPage(surveys: surveys!)),
    );
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

  Future<void> _rejectApply(ApplyResponse apply) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Decline this application?',
      message:
          '${apply.providerDisplayName} will be told their application wasn\'t '
          'selected. This cannot be undone, but they can apply again while the '
          'post is open.',
      confirmLabel: 'Decline',
    );
    if (!confirmed || !mounted) return;

    setState(() => _rejectingId = apply.id);

    try {
      await ApplyService.rejectApply(apply.id);
      if (!mounted) return;
      // Refetch rather than patching locally: the row's status is the server's
      // to decide, and a refresh also picks up anything else that moved while
      // this page was open.
      await _fetchApplies();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Application declined.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not decline: $e')),
      );
    } finally {
      if (mounted) setState(() => _rejectingId = null);
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

  /// Opens the applicant's brand page. The owner is comparing bids, and the
  /// name on the card is the only thing identifying who is behind each one —
  /// the portfolio, rating and past work all live one tap away.
  void _openProviderProfile(ApplyResponse apply) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProviderBrandPage(
          serviceProviderProfileId: apply.serviceProviderProfileId,
          providerName: apply.providerDisplayName,
        ),
      ),
    );
  }

  Widget _buildProposalCard(ApplyResponse apply) {
    final bool isPending = apply.status.toLowerCase() == 'pending';
    final String? blockedReason = isPending ? _blockedReason(apply) : null;

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
              // Expanded, not a bare Row. A non-flex child of a Row is laid out
              // with unbounded width, so the Flexible below would have nothing
              // to flex against — that throws during layout and takes the whole
              // proposals list down with it, leaving the page blank.
              Expanded(
                // The card is a Container with a white BoxDecoration, so an
                // ink splash would be painted over by it. A transparent
                // Material gives the ripple a surface of its own without
                // changing how the card looks.
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _openProviderProfile(apply),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 18,
                            backgroundColor: AppColors.primaryFixedDim,
                            child: Icon(Icons.person, color: AppColors.espresso, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              apply.providerDisplayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.espresso),
                            ),
                          ),
                          // Without this nothing tells the owner the name is
                          // more than a label.
                          const SizedBox(width: 2),
                          const Icon(Icons.chevron_right, size: 16, color: AppColors.placeholder),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
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
              // Duration is optional on the wire; say so rather than printing
              // a zero the provider never claimed.
              Text(
                apply.estimatedDurationDays != null
                    ? 'Est. Duration: ${apply.estimatedDurationDays} days'
                    : 'Est. Duration: not stated',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: apply.estimatedDurationDays != null
                      ? AppColors.espresso
                      : AppColors.placeholder,
                ),
              ),
            ],
          ),
          if (_kindFor(apply) != 'construction') ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  apply.hasCompletedSurvey
                      ? Icons.fact_check_outlined
                      : apply.surveyCount > 0
                          ? Icons.event_outlined
                          : Icons.error_outline,
                  size: 14,
                  color: apply.hasCompletedSurvey
                      ? const Color(0xFF56642B)
                      : AppColors.placeholder,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _surveyLabel(apply),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: apply.hasCompletedSurvey
                          ? const Color(0xFF56642B)
                          : AppColors.placeholder,
                    ),
                  ),
                ),
                // Only offer to open it once something has actually been filed.
                if (apply.surveyCount > 0)
                  _loadingSurveyFor == apply.id
                      ? const SizedBox(
                          height: 14,
                          width: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.espresso),
                        )
                      : TextButton(
                          onPressed: () => _openSurvey(apply),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: const Size(0, 28),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'View',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.espresso,
                            ),
                          ),
                        ),
              ],
            ),
          ],
          if (isPending) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    // Declining stays available even when the slot is full —
                    // that's precisely when an owner wants to clear the queue,
                    // and the server allows it for any pending application.
                    onPressed: _rejectingId != null ? null : () => _rejectApply(apply),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.red.shade200),
                      foregroundColor: Colors.red.shade700,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: _rejectingId == apply.id
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text('Decline',
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    // Greyed out rather than hidden, so it's clear the applicant
                    // is still there and why they can't be taken on.
                    onPressed: blockedReason != null || _rejectingId != null
                        ? null
                        : () => _acceptApply(apply),
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
