import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../models/responses/api_responses.dart';
import '../services/comment_service.dart';
import '../widgets/comments_section.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/material_cost_sheet.dart';
import 'acceptance_checklist_page.dart';

class ConstructionProgressDetailPage extends StatefulWidget {
  final List<ConstructionItemResponse> items;
  final List<ConstructionTaskResponse> allTasks;

  const ConstructionProgressDetailPage({
    super.key,
    required this.items,
    required this.allTasks,
  });

  @override
  State<ConstructionProgressDetailPage> createState() =>
      _ConstructionProgressDetailPageState();
}

class _ConstructionProgressDetailPageState
    extends State<ConstructionProgressDetailPage> {
  String _selectedFilter = 'All';
  final _filters = ['All', 'Pending', 'In Progress', 'Completed'];

  /// Top-level milestones only. `GET /api/construction-items` returns the whole
  /// tree flattened when no `parentId` is passed, so sub-items arrive alongside
  /// their parents. Counting them as milestones inflated every denominator and
  /// the "N Milestones" chip.
  List<ConstructionItemResponse> get _milestones =>
      widget.items.where((i) => i.parentId == null).toList();

  List<ConstructionItemResponse> get _filteredItems {
    if (_selectedFilter == 'All') return _milestones;
    if (_selectedFilter == 'In Progress') {
      return _milestones.where((i) => i.status == 'in_progress').toList();
    }
    return _milestones
        .where(
            (i) => i.status.toLowerCase() == _selectedFilter.toLowerCase())
        .toList();
  }

  /// [item] plus every descendant, so a milestone's progress accounts for work
  /// filed under its sub-items too. Walks breadth-first with a visited set, so
  /// a malformed parent chain can't loop forever.
  Set<String> _subtreeIds(ConstructionItemResponse item) {
    final ids = <String>{item.id};
    var frontier = <String>{item.id};
    while (frontier.isNotEmpty) {
      final next = widget.items
          .where((i) =>
              i.parentId != null &&
              frontier.contains(i.parentId) &&
              !ids.contains(i.id))
          .map((i) => i.id)
          .toSet();
      ids.addAll(next);
      frontier = next;
    }
    return ids;
  }

  /// How far along one milestone is, in 0..1.
  ///
  /// An explicit `completed` status wins outright — the constructor said it's
  /// done. Otherwise it's derived from the tasks under it (its own and its
  /// sub-items'), which is the fix for the real complaint: ticking tasks used
  /// to move nothing, because progress read milestone status alone and the
  /// backend never rolls task completion up into the parent item.
  ///
  /// A milestone with no tasks and no completed status contributes 0. We don't
  /// invent a part-score for `in_progress` — the status chip already says so,
  /// and a made-up number is worse than an honest zero.
  double _milestoneProgress(ConstructionItemResponse item) {
    if (item.status == 'completed') return 1.0;
    final ids = _subtreeIds(item);
    final tasks =
        widget.allTasks.where((t) => ids.contains(t.constructionItemId));
    if (tasks.isEmpty) return 0.0;
    final done = tasks.where((t) => t.status == 'completed').length;
    return done / tasks.length;
  }

  /// Counts a milestone as complete when it has actually reached 100%, so the
  /// chip agrees with the bar rather than tracking status in isolation.
  int get _completedCount =>
      _milestones.where((i) => _milestoneProgress(i) >= 1.0).length;
  int get _inProgressCount =>
      _milestones.where((i) => i.status == 'in_progress').length;
  int get _pendingCount =>
      _milestones.where((i) => i.status == 'pending').length;

  double get _overallProgress {
    final milestones = _milestones;
    if (milestones.isEmpty) return 0;
    final total =
        milestones.map(_milestoneProgress).fold<double>(0, (a, b) => a + b);
    return total / milestones.length;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredItems;

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
          'Construction Progress',
          style: GoogleFonts.playfairDisplay(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.espresso,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Summary card
          _buildSummaryCard(),

          // Filter chips
          _buildFilterRow(),

          // List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.construction_outlined,
                            size: 56,
                            color: AppColors.placeholder.withOpacity(0.4)),
                        const SizedBox(height: 16),
                        Text(
                          _selectedFilter == 'All'
                              ? 'No milestones yet'
                              : 'No $_selectedFilter milestones',
                          style: GoogleFonts.playfairDisplay(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.espresso),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Construction milestones created by the constructor will appear here.',
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
                      return _buildMilestoneCard(filtered[index], index);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.espresso,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Overall Progress',
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.7),
                    letterSpacing: 0.5),
              ),
              Text(
                '${(_overallProgress * 100).round()}%',
                style: GoogleFonts.playfairDisplay(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _overallProgress,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFFD9EAA3)),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 20),
          // Stats row
          Row(
            children: [
              _buildStatChip(
                label: 'Completed',
                count: _completedCount,
                color: const Color(0xFF4CAF50),
              ),
              const SizedBox(width: 8),
              _buildStatChip(
                label: 'In Progress',
                count: _inProgressCount,
                color: const Color(0xFFFFC107),
              ),
              const SizedBox(width: 8),
              _buildStatChip(
                label: 'Pending',
                count: _pendingCount,
                color: Colors.white.withOpacity(0.5),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(
      {required String label,
      required int count,
      required Color color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.6)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _filters.map((f) {
            final isSelected = _selectedFilter == f;
            return GestureDetector(
              onTap: () => setState(() => _selectedFilter = f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.espresso
                      : const Color(0xFFF0EBE6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  f,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? Colors.white
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Open the sign-off screen for a milestone.
  ///
  /// Refreshes nothing on return by design: this page is handed its items by
  /// the caller, and grading a checklist doesn't change milestone status — the
  /// provider still has to close it once the gate opens.
  void _openChecklist(ConstructionItemResponse item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AcceptanceChecklistPage(
          constructionItemId: item.id.toString(),
          milestoneName: item.name,
        ),
      ),
    );
  }

  void _openMaterialCost(ConstructionItemResponse item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => MaterialCostSheet(
        constructionItemId: item.id.toString(),
        milestoneName: item.name,
      ),
    );
  }

  Widget _buildMilestoneCard(ConstructionItemResponse item, int index) {
    // Same subtree the summary counts, so a card's bar can't disagree with the
    // overall figure it feeds into.
    final subtree = _subtreeIds(item);
    final itemTasks = widget.allTasks
        .where((t) => subtree.contains(t.constructionItemId))
        .toList();
    final completedTasks =
        itemTasks.where((t) => t.status == 'completed').length;
    final taskProgress = _milestoneProgress(item);

    final statusColor = item.status == 'completed'
        ? const Color(0xFF2E7D32)
        : item.status == 'in_progress'
            ? const Color(0xFFE65100)
            : AppColors.placeholder;
    final statusBg = item.status == 'completed'
        ? const Color(0xFFE8F5E9)
        : item.status == 'in_progress'
            ? const Color(0xFFFFF3E0)
            : const Color(0xFFF0EBE6);
    final statusLabel = item.status == 'completed'
        ? 'Completed'
        : item.status == 'in_progress'
            ? 'In Progress'
            : 'Pending';
    final statusIcon = item.status == 'completed'
        ? Icons.check_circle
        : item.status == 'in_progress'
            ? Icons.timelapse
            : Icons.radio_button_unchecked;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding:
                const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Milestone number circle
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: item.status == 'completed'
                            ? const Color(0xFF2E7D32)
                            : item.status == 'in_progress'
                                ? const Color(0xFFE65100)
                                : const Color(0xFFF0EBE6),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: item.status == 'completed'
                            ? const Icon(Icons.check,
                                size: 18, color: Colors.white)
                            : Text(
                                '${index + 1}',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: item.status == 'in_progress'
                                      ? Colors.white
                                      : AppColors.espresso,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.espresso,
                            ),
                          ),
                          if (item.description != null &&
                              item.description!.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              item.description!,
                              style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  height: 1.4),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon,
                              size: 12, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            statusLabel,
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: statusColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Payment state moves independently of work status — a
                // milestone can be finished and unpaid, or paid while still
                // running — so it gets its own badge instead of being folded
                // into the status pill. Only shown when true: an "unpaid"
                // chip on every card would be noise.
                if (item.isPaid) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.account_balance_wallet,
                            size: 12, color: Color(0xFF2E7D32)),
                        const SizedBox(width: 4),
                        Text(
                          'Đã thanh toán',
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2E7D32)),
                        ),
                      ],
                    ),
                  ),
                ],

                // Acceptance and cost, side by side. Both read from the same
                // milestone and both are things the owner acts on, so they sit
                // together rather than behind a menu.
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _openChecklist(item),
                        icon: const Icon(Icons.fact_check_outlined, size: 16),
                        label: Text(
                          'Nghiệm thu',
                          style: GoogleFonts.inter(fontSize: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _openMaterialCost(item),
                        icon: const Icon(Icons.inventory_2_outlined, size: 16),
                        label: Text(
                          'Vật tư',
                          style: GoogleFonts.inter(fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),

                // Dates
                if (item.estimateAt != null || item.actualAt != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (item.estimateAt != null) ...[
                        Icon(Icons.schedule,
                            size: 12, color: AppColors.placeholder),
                        const SizedBox(width: 4),
                        Text(
                          'Est: ${_formatDate(item.estimateAt!)}',
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.placeholder),
                        ),
                      ],
                      if (item.estimateAt != null &&
                          item.actualAt != null)
                        const SizedBox(width: 16),
                      if (item.actualAt != null) ...[
                        Icon(Icons.event_available,
                            size: 12, color: Colors.green.shade600),
                        const SizedBox(width: 4),
                        Text(
                          'Actual: ${_formatDate(item.actualAt!)}',
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              color: Colors.green.shade600),
                        ),
                      ],
                    ],
                  ),
                ],

                // Category chip
                if (item.category != null &&
                    item.category!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0EBE6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.category!,
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.espresso),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Task progress
          if (itemTasks.isNotEmpty) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              height: 1,
              color: const Color(0xFFF0EBE6),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tasks (${itemTasks.length})',
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.espresso),
                      ),
                      Text(
                        '$completedTasks/${itemTasks.length} done',
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Task progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: taskProgress,
                      backgroundColor:
                          const Color(0xFFF0EBE6),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        taskProgress == 1.0
                            ? const Color(0xFF2E7D32)
                            : AppColors.espresso,
                      ),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Task list
                  ...itemTasks.map((task) => _buildTaskRow(task)),
                ],
              ),
            ),
          ],
          // Per-milestone thread — lets the owner query a specific item
          // instead of raising it in a general chat.
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: CommentsSection(
              targetType: CommentService.targetConstructionItem,
              targetId: item.id,
              title: 'Notes',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskRow(ConstructionTaskResponse task) {
    final isDone = task.status == 'completed';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isDone ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: isDone
                ? const Color(0xFF2E7D32)
                : AppColors.placeholder,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.name,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isDone
                        ? AppColors.textSecondary
                        : AppColors.espresso,
                    decoration: isDone
                        ? TextDecoration.lineThrough
                        : null,
                    fontWeight: isDone
                        ? FontWeight.normal
                        : FontWeight.w500,
                  ),
                ),
                if (task.description != null &&
                    task.description!.isNotEmpty)
                  Text(
                    task.description!,
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.placeholder),
                  ),
              ],
            ),
          ),
          // Photo icon if task has image
          if (task.imageUrl != null)
            GestureDetector(
              onTap: () => _showTaskImage(task),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0EBE6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.photo,
                    size: 14, color: AppColors.espresso),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showTaskImage(ConstructionTaskResponse task) async {
    String? imgUrl = task.imageUrl;
    if (imgUrl == null) return;
    if (!imgUrl.startsWith('http')) {
      if (imgUrl.startsWith('/')) imgUrl = imgUrl.substring(1);
      imgUrl =
          'https://storage.googleapis.com/smartcoffeebuilder_bucket/$imgUrl';
    }
    final url = imgUrl;

    final confirmed = await showConfirmDialog(
      context,
      title: 'View Photo',
      message: 'View this task photo?',
      confirmLabel: 'View',
    );
    if (!confirmed || !mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
              webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                url,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Container(
                  padding: const EdgeInsets.all(24),
                  color: Colors.white,
                  child: const Text('Failed to load image'),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle),
                  child: const Icon(Icons.close,
                      color: Colors.white, size: 18),
                ),
              ),
            ),
            if (task.name.isNotEmpty)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(12)),
                  ),
                  child: Text(
                    task.name,
                    style: GoogleFonts.inter(
                        color: Colors.white, fontSize: 13),
                    textAlign: TextAlign.center,
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
