import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../models/responses/api_responses.dart';
import '../models/responses/change_order_responses.dart';
import '../services/design_service.dart';
import '../services/change_order_service.dart';
import '../services/comment_service.dart';
import '../utils/money.dart';
import '../widgets/comments_section.dart';
import '../widgets/confirm_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

class DesignDeliverablesDetailPage extends StatefulWidget {
  final List<DesignResponse> designs;
  final VoidCallback? onUpdated;

  const DesignDeliverablesDetailPage({
    super.key,
    required this.designs,
    this.onUpdated,
  });

  @override
  State<DesignDeliverablesDetailPage> createState() =>
      _DesignDeliverablesDetailPageState();
}

class _DesignDeliverablesDetailPageState
    extends State<DesignDeliverablesDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<DesignResponse> _designs;
  String _selectedFilter = 'All';
  // Design ids with an approve/revision request currently in flight — guards
  // against a fast double-tap firing the request twice.
  final Set<String> _pendingActionIds = {};

  static const _filters = ['All', 'Pending', 'Approved', 'Revision'];

  @override
  void initState() {
    super.initState();
    _designs = List.from(widget.designs);
    _tabController = TabController(length: _filters.length, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedFilter = _filters[_tabController.index];
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // The "Pending" tab means "awaiting owner review", which is the backend's
  // 'submitted' status — not the literal string 'pending' (which the
  // backend never actually returns). Comparing against 'pending' directly
  // made this tab and its count always show zero designs.
  bool _matchesFilter(DesignResponse d, String filter) {
    switch (filter) {
      case 'Pending':
        return d.status == 'submitted';
      case 'Approved':
        return d.status == 'approved';
      case 'Revision':
        return d.status == 'revision';
      default:
        return true;
    }
  }

  List<DesignResponse> get _filteredDesigns {
    if (_selectedFilter == 'All') return _designs;
    return _designs.where((d) => _matchesFilter(d, _selectedFilter)).toList();
  }

  Future<void> _approveDesign(String designId) async {
    if (_pendingActionIds.contains(designId)) return;
    setState(() => _pendingActionIds.add(designId));
    try {
      await DesignService.approveDesign(designId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Design approved successfully!')),
        );
        setState(() {
          final idx = _designs.indexWhere((d) => d.id == designId);
          if (idx != -1) {
            final old = _designs[idx];
            _designs[idx] = DesignResponse(
              id: old.id,
              projectWorkingId: old.projectWorkingId,
              title: old.title,
              version: old.version,
              type: old.type,
              reason: old.reason,
              status: 'approved',
              createdBy: old.createdBy,
              createdAt: old.createdAt,
              updatedAt: DateTime.now(),
              images: old.images,
            );
          }
        });
        widget.onUpdated?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Approval failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _pendingActionIds.remove(designId));
    }
  }

  /// Mở lịch sử phiên bản của một thiết kế.
  ///
  /// Bản chụp nào cũng mang [DesignVersionResponse.changeSummary] — mô tả "khác bản
  /// trước chỗ nào" — nên chủ quán đọc được diễn biến qua từng vòng sửa thay vì chỉ
  /// thấy bản mới nhất.
  Future<void> _showVersionHistory(DesignResponse design) async {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => FutureBuilder<
            PaginationResponse<DesignVersionResponse>>(
          future: DesignService.getVersions(design.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              ));
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Could not load the version history.\n${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                        fontSize: 13, color: AppColors.placeholder),
                  ),
                ),
              );
            }

            final versions = snapshot.data?.items ?? const <DesignVersionResponse>[];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Text(
                    'Version history · ${design.title}',
                    style: GoogleFonts.playfairDisplay(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: versions.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'No version has been published yet. A snapshot is '
                              'taken each time the designer submits a version or '
                              'you approve one.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                  fontSize: 13, color: AppColors.placeholder),
                            ),
                          ),
                        )
                      : ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.all(20),
                          itemCount: versions.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (_, i) =>
                              _DesignVersionTile(version: versions[i]),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _requestRevision(String designId) async {
    if (_pendingActionIds.contains(designId)) return;

    // Đọc hạn mức TRƯỚC khi mở ô nhập: vòng sửa vượt hạn mức sẽ sinh một khoản phát sinh
    // (change order kind=extra_revision), nên owner phải thấy con số trước khi gõ phản hồi.
    // Lỗi mạng ở đây không chặn luồng — server vẫn là chốt cuối, nó trả 409 nếu thiếu đồng ý.
    RevisionQuotaResponse? quota;
    try {
      quota = await ChangeOrderService.getRevisionQuota(designId);
    } catch (_) {
      quota = null;
    }
    if (!mounted) return;

    final willBeCharged = quota?.nextRevisionCharged ?? false;
    final fee = quota?.extraRevisionFee;

    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Request Revision',
            style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (quota != null) ...[
              _RevisionQuotaBanner(quota: quota, fee: fee),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter feedback for designer...',
                hintStyle: GoogleFonts.inter(
                    fontSize: 13, color: AppColors.placeholder),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.espresso,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
            child: Text(
              willBeCharged ? 'Accept fee & submit' : 'Submit',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (reason == null) return; // user cancelled
    if (reason.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter feedback before submitting.')),
        );
      }
      return;
    }

    setState(() => _pendingActionIds.add(designId));
    try {
      // Bấm nút "Accept fee & submit" CHÍNH LÀ sự đồng ý — gửi kèm để server khỏi trả 409.
      await DesignService.requestRevision(
        designId,
        reason: reason,
        acceptExtraFee: willBeCharged,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(willBeCharged && fee != null
                ? 'Revision requested. An extra fee of ${formatVnd(fee)} was added as a change order.'
                : 'Revision request submitted.'),
          ),
        );
        setState(() {
          final idx = _designs.indexWhere((d) => d.id == designId);
          if (idx != -1) {
            final old = _designs[idx];
            _designs[idx] = DesignResponse(
              id: old.id,
              projectWorkingId: old.projectWorkingId,
              title: old.title,
              version: old.version,
              type: old.type,
              reason: reason,
              status: 'revision',
              createdBy: old.createdBy,
              createdAt: old.createdAt,
              updatedAt: DateTime.now(),
              images: old.images,
            );
          }
        });
        widget.onUpdated?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _pendingActionIds.remove(designId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredDesigns;

    // Tally counts
    final allCount = _designs.length;
    final pendingCount =
        _designs.where((d) => d.status == 'submitted').length;
    final approvedCount =
        _designs.where((d) => d.status == 'approved').length;
    final revisionCount =
        _designs.where((d) => d.status == 'revision').length;
    final counts = [allCount, pendingCount, approvedCount, revisionCount];

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
          'Design Deliverables',
          style: GoogleFonts.playfairDisplay(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.espresso,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF0EBE6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppColors.espresso,
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle:
                  GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold),
              unselectedLabelStyle:
                  GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500),
              dividerColor: Colors.transparent,
              tabs: List.generate(_filters.length, (i) {
                return Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_filters[i]),
                      if (counts[i] > 0) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: _selectedFilter == _filters[i]
                                ? Colors.white.withValues(alpha: 0.3)
                                : AppColors.espresso.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${counts[i]}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _selectedFilter == _filters[i]
                                  ? Colors.white
                                  : AppColors.espresso,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }),
            ),
          ),
        ),
      ),
      body: filtered.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.palette_outlined,
                      size: 56, color: AppColors.placeholder.withValues(alpha: 0.4)),
                  const SizedBox(height: 16),
                  Text(
                    _selectedFilter == 'All'
                        ? 'No designs uploaded yet'
                        : 'No $_selectedFilter designs',
                    style: GoogleFonts.playfairDisplay(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.espresso),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Design files will appear here once the designer uploads them.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                        fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                return _buildDesignCard(filtered[index]);
              },
            ),
    );
  }

  Widget _buildDesignCard(DesignResponse design) {
    final isApproved = design.status == 'approved';
    final isRevision = design.status == 'revision';
    // Only a *submitted* design can be acted on. "Not approved and not
    // revision" used to include 'in_progress' too, which offered
    // Approve/Revision on a draft still being reworked — the backend then
    // rejected it with an error the owner had no way to make sense of. See
    // the identical fix (and fuller explanation) in
    // collaboration_workspace_page.dart's _buildDesignCard.
    final isSubmitted = design.status == 'submitted';
    final isReworking = design.status == 'in_progress';

    final statusColor = isApproved
        ? const Color(0xFF2E7D32)
        : isRevision
            ? const Color(0xFFC62828)
            : isReworking
                ? AppColors.textSecondary
                : const Color(0xFFE65100);
    final statusBg = isApproved
        ? const Color(0xFFE8F5E9)
        : isRevision
            ? const Color(0xFFFFEBEE)
            : isReworking
                ? const Color(0xFFF2EFEC)
                : const Color(0xFFFFF3E0);
    final statusIcon = isApproved
        ? Icons.check_circle
        : isRevision
            ? Icons.undo
            : isReworking
                ? Icons.edit_note
                : Icons.hourglass_empty;
    final statusLabel = isApproved
        ? 'Approved'
        : isRevision
            ? 'Revision'
            : isReworking
                ? 'Being revised'
                : 'Pending';

    final firstImage =
        design.images.isNotEmpty ? design.images.first.viewUrl : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero image
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
            child: Stack(
              children: [
                firstImage != null
                    ? GestureDetector(
                        onTap: () => _handleFileTap(firstImage),
                        child: Image.network(
              webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                          firstImage,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildFilePlaceholder(firstImage),
                        ),
                      )
                    : _buildFilePlaceholder(null),
                // Status badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 13, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          statusLabel,
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: statusColor),
                        ),
                      ],
                    ),
                  ),
                ),
                // Image count badge
                if (design.images.length > 1)
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.photo_library,
                              size: 12, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            '${design.images.length} photos',
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title & version
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        design.title,
                        style: GoogleFonts.playfairDisplay(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.espresso),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0EBE6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'v${design.version.toStringAsFixed(1)}',
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.espresso),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  design.type,
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppColors.placeholder),
                ),

                // Revision reason
                if (isRevision && design.reason != null &&
                    design.reason!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: const Color(0xFFC62828).withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline,
                            size: 14, color: Color(0xFFC62828)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            design.reason!,
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                color: const Color(0xFFC62828),
                                height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Date info
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 12, color: AppColors.placeholder),
                    const SizedBox(width: 4),
                    Text(
                      'Updated ${_formatDate(design.updatedAt)}',
                      style: GoogleFonts.inter(
                          fontSize: 11, color: AppColors.placeholder),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Lịch sử phiên bản — luôn hiện, kể cả khi thiết kế đã duyệt:
                // sau khi duyệt xong chủ quán vẫn cần tra lại từng vòng đã đổi gì.
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => _showVersionHistory(design),
                    icon: const Icon(Icons.history_rounded, size: 16),
                    label: const Text('Version history'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.espresso,
                      padding: EdgeInsets.zero,
                      textStyle: GoogleFonts.inter(
                          fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Action buttons
                if (isSubmitted) ...[
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _pendingActionIds.contains(design.id)
                              ? null
                              : () => _approveDesign(design.id),
                          icon: const Icon(Icons.check_circle_outline,
                              size: 16, color: Colors.white),
                          label: const Text('Approve'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(vertical: 12),
                            textStyle: GoogleFonts.inter(
                                fontWeight: FontWeight.w700, fontSize: 13),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pendingActionIds.contains(design.id)
                              ? null
                              : () => _requestRevision(design.id),
                          icon: const Icon(Icons.edit_note,
                              size: 16, color: AppColors.espresso),
                          label: const Text('Revision'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.espresso,
                            side: const BorderSide(
                                color: AppColors.outlineVariant),
                            padding:
                                const EdgeInsets.symmetric(vertical: 12),
                            textStyle: GoogleFonts.inter(
                                fontWeight: FontWeight.w600, fontSize: 13),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                // Image gallery preview (if multiple images)
                if (design.images.length > 1) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 60,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: design.images.length,
                      itemBuilder: (context, i) {
                        final img = design.images[i];
                        return GestureDetector(
                          onTap: () => _handleFileTap(img.viewUrl),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color:
                                      AppColors.outlineVariant.withValues(alpha: 0.4)),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(7),
                              child: Image.network(
              webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                                img.viewUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _buildFilePlaceholder(
                                  img.viewUrl,
                                  iconSize: 24,
                                  height: 60,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 28),
                // Shared thread — the provider posts into the same list, so a
                // revision request can carry the reason with it.
                CommentsSection(
                  targetType: CommentService.targetDesign,
                  targetId: design.id,
                  title: 'Discussion',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilePlaceholder(String? url, {double iconSize = 48, double height = 180}) {
    IconData icon = Icons.palette_outlined;
    Color iconColor = AppColors.outlineVariant;
    Color bgColor = const Color(0xFFF0EBE6);
    String ext = '';

    if (url != null && !_isImage(url)) {
      final lower = url.toLowerCase().split('?').first;
      if (lower.endsWith('.pdf')) {
        icon = Icons.picture_as_pdf;
        iconColor = const Color(0xFFD32F2F);
        bgColor = const Color(0xFFFFEBEE);
        ext = 'PDF';
      } else if (lower.endsWith('.doc') || lower.endsWith('.docx')) {
        icon = Icons.description;
        iconColor = const Color(0xFF1976D2);
        bgColor = const Color(0xFFE3F2FD);
        ext = 'DOC';
      } else if (lower.endsWith('.xls') || lower.endsWith('.xlsx') || lower.endsWith('.csv')) {
        icon = Icons.table_chart;
        iconColor = const Color(0xFF388E3C);
        bgColor = const Color(0xFFE8F5E9);
        ext = 'XLS';
      } else if (lower.endsWith('.zip') || lower.endsWith('.rar')) {
        icon = Icons.folder_zip;
        iconColor = const Color(0xFFF57C00);
        bgColor = const Color(0xFFFFF3E0);
        ext = 'ZIP';
      } else {
        icon = Icons.insert_drive_file;
        iconColor = const Color(0xFF757575);
        bgColor = const Color(0xFFF5F5F5);
        ext = 'FILE';
      }
    }

    return Container(
      height: height,
      width: double.infinity,
      color: bgColor,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: iconSize, color: iconColor),
            if (ext.isNotEmpty && iconSize >= 40) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  ext,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  bool _isImage(String url) {
    final lowerUrl = url.toLowerCase().split('?').first;
    return lowerUrl.endsWith('.jpg') ||
        lowerUrl.endsWith('.jpeg') ||
        lowerUrl.endsWith('.png') ||
        lowerUrl.endsWith('.gif') ||
        lowerUrl.endsWith('.webp') ||
        lowerUrl.contains('unsplash.com') ||
        lowerUrl.contains('image');
  }

  Future<void> _handleFileTap(String url) async {
    final isImage = _isImage(url);
    final confirmed = await showConfirmDialog(
      context,
      title: isImage ? 'View Image' : 'Open File',
      message: isImage
          ? 'View this image?'
          : 'This will open the file in another app. Continue?',
      confirmLabel: isImage ? 'View' : 'Open',
    );
    if (!confirmed || !mounted) return;

    if (isImage) {
      _showImageFullScreen(url);
    } else {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open file.')),
          );
        }
      }
    }
  }

  void _showImageFullScreen(String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
              webHtmlElementStrategy: WebHtmlElementStrategy.fallback,url, fit: BoxFit.contain),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                      color: Colors.black54, shape: BoxShape.circle),
                  child: const Icon(Icons.close,
                      color: Colors.white, size: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}

/// Hạn mức vòng sửa còn lại của một bản thiết kế, hiện ngay trong hộp thoại
/// "Request Revision".
///
/// Hạn mức đến từ báo giá đã duyệt và tính trên CẢ engagement, không phải trên
/// từng bản vẽ — nên phần "đã dùng" đọc [RevisionQuotaResponse.engagementUsedRevisionCount].
/// [RevisionQuotaResponse.freeRevisionCount] = null nghĩa là không báo giá nào chốt
/// con số, tức không giới hạn: khi đó không hiện gì để khỏi doạ người dùng bằng
/// một hạn mức không tồn tại.
class _RevisionQuotaBanner extends StatelessWidget {
  final RevisionQuotaResponse quota;
  final double? fee;

  const _RevisionQuotaBanner({required this.quota, required this.fee});

  @override
  Widget build(BuildContext context) {
    if (quota.freeRevisionCount == null) return const SizedBox.shrink();

    final charged = quota.nextRevisionCharged;
    final remaining = quota.remainingFreeRevisions ?? 0;

    final color = charged ? const Color(0xFFB3261E) : AppColors.espresso;
    final text = charged
        ? (fee != null
            // Số tiền phải nằm trong câu chữ, không chỉ ở nút bấm: đây là khoản
            // owner sẽ phải trả thật, được ghi thành change order.
            ? 'You have used all ${quota.freeRevisionCount} free revisions '
                '(${quota.engagementUsedRevisionCount} used). This round costs '
                '${formatVnd(fee!)} and will be added as a change order.'
            : 'You have used all ${quota.freeRevisionCount} free revisions. '
                'The provider has not published a price for extra rounds, so the '
                'fee has to be agreed on a change order.')
        : 'Free revisions left: $remaining of ${quota.freeRevisionCount} '
            '(${quota.engagementUsedRevisionCount} used on this collaboration).';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(charged ? Icons.payments_outlined : Icons.info_outline,
              size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                  fontSize: 12, height: 1.4, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

/// Một dòng trong lịch sử phiên bản.
///
/// `changeSummary` được đặt lên trước và nổi bật hơn phần còn lại: đó là câu trả
/// lời cho câu hỏi duy nhất chủ quán mở màn này để hỏi — "vòng vừa rồi đổi gì".
/// Khi provider chưa ghi thì nói thẳng là chưa ghi, thay vì để trống một khoảng
/// làm người đọc tưởng bản này không có thay đổi nào.
class _DesignVersionTile extends StatelessWidget {
  final DesignVersionResponse version;

  const _DesignVersionTile({required this.version});

  @override
  Widget build(BuildContext context) {
    final isApproved = version.snapshotKind == 'approved';
    final accent = isApproved ? const Color(0xFF2E7D32) : AppColors.espresso;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.3)),
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
                  color: accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'v${version.version.toStringAsFixed(1)} · ${version.snapshotKind}',
                  style: GoogleFonts.inter(
                      fontSize: 11, fontWeight: FontWeight.w700, color: accent),
                ),
              ),
              const Spacer(),
              Text(
                _formatDate(version.snapshottedAt),
                style: GoogleFonts.inter(
                    fontSize: 11, color: AppColors.placeholder),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            version.changeSummary?.trim().isNotEmpty == true
                ? version.changeSummary!
                : 'The designer did not describe what changed in this version.',
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 1.45,
              color: version.changeSummary?.trim().isNotEmpty == true
                  ? AppColors.primary
                  : AppColors.placeholder,
              fontStyle: version.changeSummary?.trim().isNotEmpty == true
                  ? FontStyle.normal
                  : FontStyle.italic,
            ),
          ),
          if (version.reason != null && version.reason!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F3F2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.feedback_outlined,
                      size: 14, color: AppColors.placeholder),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Your feedback on that round: ${version.reason}',
                      style: GoogleFonts.inter(
                          fontSize: 11.5,
                          height: 1.4,
                          color: AppColors.placeholder),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (version.images.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 64,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: version.images.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final url = version.images[i].viewUrl;
                  if (url == null || url.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      url,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        width: 64,
                        height: 64,
                        color: const Color(0xFFF6F3F2),
                        child: const Icon(Icons.broken_image_outlined,
                            size: 18, color: AppColors.placeholder),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}
