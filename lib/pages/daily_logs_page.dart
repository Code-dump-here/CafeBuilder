import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/responses/api_responses.dart';
import '../models/responses/quotation_payment_responses.dart';
import '../services/daily_log_service.dart';
import '../theme/app_colors.dart';

/// The site diary, as the owner reads it.
///
/// Read-only by design: the provider files a report per working day with
/// photos, and this screen is how the owner follows progress without driving
/// to the site. Reading stays open at every engagement status server-side, so
/// the log is still here after handover — which is usually when someone needs
/// to check what happened on a particular day.
///
/// A project can run a designer and a contractor at once, so the engagement is
/// picked first when there is more than one; the diary belongs to an
/// engagement, not to the project.
class DailyLogsPage extends StatefulWidget {
  /// Every engagement on the project.
  final List<ProjectWorkingResponse> projectWorkings;

  final String projectName;

  const DailyLogsPage({
    super.key,
    required this.projectWorkings,
    required this.projectName,
  });

  @override
  State<DailyLogsPage> createState() => _DailyLogsPageState();
}

class _DailyLogsPageState extends State<DailyLogsPage> {
  String? _selectedWorkingId;
  List<DailyLogResponse> _logs = [];

  bool _loading = true;
  String? _error;

  DateTimeRange? _range;

  final _dayFormat = DateFormat('dd/MM/yyyy');
  final _apiDayFormat = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    _selectedWorkingId = widget.projectWorkings.isNotEmpty
        ? widget.projectWorkings.first.id
        : null;
    _load();
  }

  Future<void> _load() async {
    if (_selectedWorkingId == null) {
      setState(() {
        _loading = false;
        _logs = [];
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await DailyLogService.getLogs(
        projectWorkingId: _selectedWorkingId,
        fromDate:
            _range == null ? null : _apiDayFormat.format(_range!.start),
        toDate: _range == null ? null : _apiDayFormat.format(_range!.end),
        pageSize: 50,
      );
      if (!mounted) return;
      setState(() {
        _logs = page.items;
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

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      // A report cannot exist for a day that has not happened yet.
      lastDate: DateTime.now(),
      initialDateRange: _range,
    );
    if (picked == null) return;
    setState(() => _range = picked);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Nhật ký thi công',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.espresso,
          ),
        ),
      ),
      body: widget.projectWorkings.isEmpty
          ? _EmptyView(
              message: 'Dự án này chưa có nhà cung cấp nào nhận việc, nên chưa '
                  'có nhật ký thi công nào.',
            )
          : Column(
              children: [
                _buildFilters(),
                Expanded(
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.espresso,
                          ),
                        )
                      : _error != null
                          ? _ErrorView(message: _error!, onRetry: _load)
                          : RefreshIndicator(
                              onRefresh: _load,
                              child: _buildList(),
                            ),
                ),
              ],
            ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      color: AppColors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Only worth a picker when there is a real choice to make; with one
          // provider it would be a control that does nothing.
          if (widget.projectWorkings.length > 1) ...[
            SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: widget.projectWorkings.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, index) {
                  final working = widget.projectWorkings[index];
                  final selected = working.id == _selectedWorkingId;
                  return ChoiceChip(
                    selected: selected,
                    label: Text(
                      working.providerDisplayName,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : AppColors.espresso,
                      ),
                    ),
                    backgroundColor: Colors.white,
                    selectedColor: AppColors.espresso,
                    side: const BorderSide(color: AppColors.outlineVariant),
                    showCheckmark: false,
                    onSelected: (_) {
                      setState(() => _selectedWorkingId = working.id);
                      _load();
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _pickRange,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.outlineVariant),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.date_range_outlined,
                          size: 16,
                          color: AppColors.espresso,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _range == null
                                ? 'Tất cả các ngày'
                                : '${_dayFormat.format(_range!.start)} – '
                                    '${_dayFormat.format(_range!.end)}',
                            style: GoogleFonts.inter(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_range != null) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    setState(() => _range = null);
                    _load();
                  },
                  child: Text(
                    'Xoá lọc',
                    style: GoogleFonts.inter(fontSize: 12),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_logs.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            _range == null
                ? 'Nhà cung cấp chưa ghi nhật ký thi công nào.'
                : 'Không có nhật ký nào trong khoảng ngày đã chọn.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 13, color: Colors.black54),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      itemCount: _logs.length,
      itemBuilder: (_, index) => _LogCard(log: _logs[index]),
    );
  }
}

class _LogCard extends StatelessWidget {
  final DailyLogResponse log;

  const _LogCard({required this.log});

  @override
  Widget build(BuildContext context) {
    // `logDate` arrives as `yyyy-MM-dd`. Parsing it rather than reformatting
    // the string keeps a malformed value from being shown as-is.
    final parsed = DateTime.tryParse(log.logDate);
    final dayLabel =
        parsed == null ? log.logDate : DateFormat('dd/MM/yyyy').format(parsed);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
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
                  color: AppColors.primaryFixed,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  dayLabel,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.espresso,
                  ),
                ),
              ),
              const Spacer(),
              if (log.workerCount != null) ...[
                const Icon(Icons.groups_outlined, size: 14, color: Colors.black45),
                const SizedBox(width: 4),
                Text(
                  '${log.workerCount} thợ',
                  style: GoogleFonts.inter(fontSize: 11, color: Colors.black54),
                ),
              ],
            ],
          ),
          if (log.constructionItemName != null ||
              log.constructionTaskName != null) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                if (log.constructionItemName != null)
                  _Tag(text: log.constructionItemName!),
                if (log.constructionTaskName != null)
                  _Tag(text: log.constructionTaskName!),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Text(
            log.workDone,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.black87,
              height: 1.45,
            ),
          ),
          if (log.issueNote != null && log.issueNote!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 16,
                    color: Colors.amber.shade800,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      log.issueNote!,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.brown.shade800,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (log.media.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 92,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: log.media.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, index) {
                  final media = log.media[index];
                  return _MediaThumb(media: media);
                },
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              if (log.weatherNote != null && log.weatherNote!.isNotEmpty) ...[
                const Icon(Icons.cloud_outlined, size: 13, color: Colors.black38),
                const SizedBox(width: 4),
                Text(
                  log.weatherNote!,
                  style: GoogleFonts.inter(fontSize: 11, color: Colors.black45),
                ),
                const SizedBox(width: 12),
              ],
              if (log.createdByName != null)
                Expanded(
                  child: Text(
                    'Ghi bởi ${log.createdByName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.black38,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;

  const _Tag({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(fontSize: 11, color: Colors.black54),
      ),
    );
  }
}

class _MediaThumb extends StatelessWidget {
  final DailyLogMediaResponse media;

  const _MediaThumb({required this.media});

  @override
  Widget build(BuildContext context) {
    final url = media.mediaViewUrl;

    // Video has no thumbnail from the API, and the owner app has no player —
    // a labelled placeholder is more honest than an image widget that would
    // only ever render its error state.
    if (media.mediaType == 'video' || url == null || url.isEmpty) {
      return Container(
        width: 92,
        height: 92,
        decoration: BoxDecoration(
          color: AppColors.primaryFixedDim,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              media.mediaType == 'video'
                  ? Icons.play_circle_outline
                  : Icons.image_outlined,
              size: 22,
              color: AppColors.espresso,
            ),
            const SizedBox(height: 4),
            Text(
              media.mediaType == 'video' ? 'Video' : 'Ảnh',
              style: GoogleFonts.inter(fontSize: 10, color: AppColors.espresso),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () => showDialog<void>(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: GestureDetector(
            onTap: () => Navigator.pop(ctx),
            child: InteractiveViewer(
              child: Image.network(url, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          url,
          width: 92,
          height: 92,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            width: 92,
            height: 92,
            color: AppColors.primaryFixedDim,
            child: const Icon(Icons.broken_image_outlined, size: 22),
          ),
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final String message;

  const _EmptyView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 13, color: Colors.black54),
        ),
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
            OutlinedButton(onPressed: onRetry, child: const Text('Thử lại')),
          ],
        ),
      ),
    );
  }
}
