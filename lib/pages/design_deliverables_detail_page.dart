import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../models/responses/api_responses.dart';
import '../services/design_service.dart';
import '../services/comment_service.dart';
import '../widgets/comments_section.dart';

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

  List<DesignResponse> get _filteredDesigns {
    if (_selectedFilter == 'All') return _designs;
    return _designs
        .where((d) => d.status.toLowerCase() == _selectedFilter.toLowerCase())
        .toList();
  }

  Future<void> _approveDesign(int designId) async {
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
    }
  }

  Future<void> _requestRevision(int designId) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Request Revision',
            style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Enter feedback for designer...',
            hintStyle:
                GoogleFonts.inter(fontSize: 13, color: AppColors.placeholder),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
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
            child: const Text('Submit', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (reason == null || reason.isEmpty) return;

    try {
      await DesignService.requestRevision(designId, reason: reason);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Revision request submitted.')),
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredDesigns;

    // Tally counts
    final allCount = _designs.length;
    final pendingCount =
        _designs.where((d) => d.status == 'pending').length;
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
                                ? Colors.white.withOpacity(0.3)
                                : AppColors.espresso.withOpacity(0.12),
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
                      size: 56, color: AppColors.placeholder.withOpacity(0.4)),
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
    final isPending = !isApproved && !isRevision;

    final statusColor = isApproved
        ? const Color(0xFF2E7D32)
        : isRevision
            ? const Color(0xFFC62828)
            : const Color(0xFFE65100);
    final statusBg = isApproved
        ? const Color(0xFFE8F5E9)
        : isRevision
            ? const Color(0xFFFFEBEE)
            : const Color(0xFFFFF3E0);
    final statusIcon = isApproved
        ? Icons.check_circle
        : isRevision
            ? Icons.undo
            : Icons.hourglass_empty;
    final statusLabel =
        isApproved ? 'Approved' : isRevision ? 'Revision' : 'Pending';

    final firstImage =
        design.images.isNotEmpty ? design.images.first.viewUrl : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
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
                    ? Image.network(
              webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                        firstImage,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholderImage(),
                      )
                    : _placeholderImage(),
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
                      border: Border.all(color: statusColor.withOpacity(0.4)),
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
                        color: Colors.black.withOpacity(0.55),
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
                          color: const Color(0xFFC62828).withOpacity(0.2)),
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
                const SizedBox(height: 16),

                // Action buttons
                if (isPending) ...[
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _approveDesign(design.id),
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
                          onPressed: () => _requestRevision(design.id),
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
                          onTap: () => _showImageFullScreen(img.viewUrl),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color:
                                      AppColors.outlineVariant.withOpacity(0.4)),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(7),
                              child: Image.network(
              webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                                img.viewUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: const Color(0xFFF0EBE6),
                                  child: const Icon(Icons.image,
                                      size: 20,
                                      color: AppColors.outlineVariant),
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

  Widget _placeholderImage() {
    return Container(
      height: 180,
      width: double.infinity,
      color: const Color(0xFFF0EBE6),
      child: const Center(
        child: Icon(Icons.palette_outlined,
            size: 48, color: AppColors.outlineVariant),
      ),
    );
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
