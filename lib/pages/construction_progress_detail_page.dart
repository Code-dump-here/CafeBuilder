import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../models/responses/api_responses.dart';

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

  List<ConstructionItemResponse> get _filteredItems {
    if (_selectedFilter == 'All') return widget.items;
    if (_selectedFilter == 'In Progress') {
      return widget.items.where((i) => i.status == 'in_progress').toList();
    }
    return widget.items
        .where(
            (i) => i.status.toLowerCase() == _selectedFilter.toLowerCase())
        .toList();
  }

  int get _completedCount =>
      widget.items.where((i) => i.status == 'completed').length;
  int get _inProgressCount =>
      widget.items.where((i) => i.status == 'in_progress').length;
  int get _pendingCount =>
      widget.items.where((i) => i.status == 'pending').length;
  double get _overallProgress => widget.items.isEmpty
      ? 0
      : _completedCount / widget.items.length;

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

  Widget _buildMilestoneCard(ConstructionItemResponse item, int index) {
    final itemTasks =
        widget.allTasks.where((t) => t.constructionItemId == item.id).toList();
    final completedTasks =
        itemTasks.where((t) => t.status == 'completed').length;
    final taskProgress =
        itemTasks.isEmpty ? 0.0 : completedTasks / itemTasks.length;

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

  void _showTaskImage(ConstructionTaskResponse task) {
    String? imgUrl = task.imageUrl;
    if (imgUrl == null) return;
    if (!imgUrl.startsWith('http')) {
      if (imgUrl.startsWith('/')) imgUrl = imgUrl.substring(1);
      imgUrl =
          'https://storage.googleapis.com/smartcoffeebuilder_bucket/$imgUrl';
    }
    final url = imgUrl;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
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
