import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/responses/api_responses.dart';
import '../services/notification_service.dart';
import '../theme/app_colors.dart';
import '../utils/notification_link.dart';
import 'notification_detail_page.dart';

/// The full notification inbox.
///
/// The bell sheet only ever showed the first page and had no way to reach the
/// rest, so anything older than twenty notifications was unreachable. This
/// screen pages through all of them, filters by read state, and opens each one
/// in full.
class NotificationsPage extends StatefulWidget {
  /// Called whenever this screen marks something read, so the bell badge behind
  /// it can decrement without waiting for its own poll.
  final VoidCallback? onNotificationRead;

  /// Called when everything has been marked read in one go. Kept separate from
  /// [onNotificationRead] because this screen has only loaded some of the
  /// pages — firing the decrement once per loaded row would leave the badge
  /// counting notifications that the server has already cleared.
  final VoidCallback? onAllNotificationsRead;

  const NotificationsPage({
    super.key,
    this.onNotificationRead,
    this.onAllNotificationsRead,
  });

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

/// Read-state filter. `null` on the wire means "don't filter".
enum _ReadFilter { all, unread, read }

class _NotificationsPageState extends State<NotificationsPage> {
  static const int _pageSize = 20;

  final ScrollController _scrollController = ScrollController();
  final List<NotificationResponse> _items = [];

  _ReadFilter _filter = _ReadFilter.all;
  int _page = 1;
  bool _hasNext = false;
  bool _loading = true;
  bool _loadingMore = false;
  bool _markingAll = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  bool? get _isReadParam => switch (_filter) {
        _ReadFilter.all => null,
        _ReadFilter.unread => false,
        _ReadFilter.read => true,
      };

  /// Pull the next page in once the list is within a screen of the bottom, so
  /// scrolling never stops at a loading spinner it could have avoided.
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 400) {
      _loadMore();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await NotificationService.getNotifications(
        pageNumber: 1,
        pageSize: _pageSize,
        isRead: _isReadParam,
      );
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(res.items);
        _page = 1;
        _hasNext = res.hasNext;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load notifications.';
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _loading || !_hasNext) return;
    setState(() => _loadingMore = true);
    try {
      final res = await NotificationService.getNotifications(
        pageNumber: _page + 1,
        pageSize: _pageSize,
        isRead: _isReadParam,
      );
      if (!mounted) return;
      setState(() {
        _items.addAll(res.items);
        _page += 1;
        _hasNext = res.hasNext;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      // Leave `_hasNext` alone so scrolling again retries rather than
      // permanently truncating the list on one flaky request.
      setState(() => _loadingMore = false);
    }
  }

  void _changeFilter(_ReadFilter next) {
    if (_filter == next) return;
    setState(() => _filter = next);
    _load();
  }

  Future<void> _markAllRead() async {
    final unread = _items.where((n) => !n.isRead).length;
    if (unread == 0 || _markingAll) return;
    setState(() => _markingAll = true);
    try {
      await NotificationService.markAllAsRead();
      if (!mounted) return;
      if (widget.onAllNotificationsRead != null) {
        widget.onAllNotificationsRead!();
      } else {
        // Fallback for callers that only handed us the per-item callback. It
        // undercounts when unread rows sit on pages this screen never loaded,
        // which is exactly why [onAllNotificationsRead] exists.
        for (var i = 0; i < unread; i++) {
          widget.onNotificationRead?.call();
        }
      }
      setState(() => _markingAll = false);
      // Refetch rather than patching in place: under the "Unread" filter every
      // row has just left the filter, so the list has to be rebuilt anyway.
      await _load();
    } catch (_) {
      if (!mounted) return;
      setState(() => _markingAll = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not mark all as read.')),
      );
    }
  }

  Future<void> _openDetail(NotificationResponse noti) async {
    final wasUnread = !noti.isRead;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotificationDetailPage(
          notification: noti,
          onRead: widget.onNotificationRead,
        ),
      ),
    );
    if (!mounted) return;
    // The detail screen marks it read on the shared instance, so the row is
    // already correct — except under the "Unread" filter, where it no longer
    // belongs in the list at all.
    if (wasUnread && _filter == _ReadFilter.unread) {
      await _load();
    } else {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.espresso),
        title: Text(
          'Notifications',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.espresso,
          ),
        ),
        actions: [
          if (_items.any((n) => !n.isRead))
            TextButton(
              onPressed: _markingAll ? null : _markAllRead,
              child: Text(
                'Mark all read',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.espresso,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    Widget chip(String label, _ReadFilter value) {
      final selected = _filter == value;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: GestureDetector(
          onTap: () => _changeFilter(value),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? AppColors.espresso : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected
                    ? AppColors.espresso
                    : AppColors.outlineVariant.withValues(alpha: 0.7),
              ),
            ),
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        children: [
          chip('All', _ReadFilter.all),
          chip('Unread', _ReadFilter.unread),
          chip('Read', _ReadFilter.read),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.espresso),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _error!,
              style: GoogleFonts.inter(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _load,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.espresso,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        color: AppColors.espresso,
        child: ListView(
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.25),
            Center(
              child: Column(
                children: [
                  const Icon(
                    Icons.notifications_none,
                    size: 36,
                    color: AppColors.placeholder,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    switch (_filter) {
                      _ReadFilter.unread => 'Nothing unread.',
                      _ReadFilter.read => 'Nothing read yet.',
                      _ReadFilter.all => 'No notifications.',
                    },
                    style: GoogleFonts.inter(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.espresso,
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: _items.length + (_hasNext ? 1 : 0),
        separatorBuilder: (_, _) => Divider(
          height: 1,
          color: AppColors.outlineVariant.withValues(alpha: 0.4),
        ),
        itemBuilder: (context, index) {
          if (index >= _items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: AppColors.espresso,
                    strokeWidth: 2,
                  ),
                ),
              ),
            );
          }
          return _buildRow(_items[index]);
        },
      ),
    );
  }

  Widget _buildRow(NotificationResponse noti) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: CircleAvatar(
        backgroundColor:
            noti.isRead ? Colors.grey.shade200 : AppColors.primaryFixed,
        child: Icon(
          Icons.notifications,
          color: noti.isRead ? Colors.grey : AppColors.espresso,
          size: 18,
        ),
      ),
      title: Row(
        children: [
          if (!noti.isRead)
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(right: 6),
              decoration: const BoxDecoration(
                color: AppColors.espresso,
                shape: BoxShape.circle,
              ),
            ),
          Expanded(
            child: Text(
              noti.title,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontWeight: noti.isRead ? FontWeight.normal : FontWeight.bold,
                fontSize: 14,
                color: AppColors.espresso,
              ),
            ),
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          noti.content,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ),
      trailing: Text(
        notificationRelativeTime(noti.createdAt),
        style: GoogleFonts.inter(
          fontSize: 11,
          color: noti.isRead ? AppColors.textSecondary : AppColors.espresso,
          fontWeight: noti.isRead ? FontWeight.normal : FontWeight.w600,
        ),
      ),
      onTap: () => _openDetail(noti),
    );
  }
}
