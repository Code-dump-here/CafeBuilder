import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../models/responses/api_responses.dart';
import '../services/notification_service.dart';
import '../utils/notification_link.dart';
import '../pages/notification_detail_page.dart';
import '../pages/notifications_page.dart';

/// Bottom sheet listing the account's most recent notifications — shared by
/// every screen that shows the notification bell (see [TopNav]).
///
/// This is a preview, not the inbox: it shows the first page and hands off to
/// [NotificationsPage] for the rest. Tapping a row opens the notification in
/// full rather than jumping straight to the project, because the row itself
/// clips anything longer than two lines.
class NotificationsSheet extends StatefulWidget {
  /// Called once per notification this sheet marks read, so the bell badge
  /// behind it can decrement without waiting for its own poll.
  final VoidCallback onNotificationRead;

  /// Called when *everything* has been marked read in one go.
  ///
  /// Separate from [onNotificationRead] rather than firing it in a loop: the
  /// sheet only holds the first page, so one decrement per visible row would
  /// leave the badge stuck on whatever was still unread further down.
  final VoidCallback? onAllNotificationsRead;

  const NotificationsSheet({
    super.key,
    required this.onNotificationRead,
    this.onAllNotificationsRead,
  });

  @override
  State<NotificationsSheet> createState() => NotificationsSheetState();
}

class NotificationsSheetState extends State<NotificationsSheet> {
  List<NotificationResponse> _notifications = [];
  int _totalItems = 0;
  int _unreadCount = 0;
  bool _loading = true;
  bool _markingAll = false;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    // Both requests go out together. The unread total has to come from the
    // server rather than from the rows on screen: this sheet only holds the
    // first page, so counting them would miss anything older and would offer
    // "all read" while unread notifications were still sitting below.
    final notificationsFuture = NotificationService.getNotifications();
    // -1 marks "the count request failed", so the fallback below can use the
    // visible rows instead of claiming the inbox is already clear.
    final unreadFuture = NotificationService.getUnreadCount().catchError(
      (_) => -1,
    );
    try {
      final res = await notificationsFuture;
      final unread = await unreadFuture;
      if (!mounted) return;
      setState(() {
        _notifications = res.items;
        _totalItems = res.totalItems;
        _unreadCount = unread >= 0
            ? unread
            : res.items.where((n) => !n.isRead).length;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Marks every notification on the account read — not just the page on
  /// screen. The list is refetched afterwards rather than patched in place, so
  /// rows and counts come back from the same source of truth.
  Future<void> _markAllRead() async {
    if (_markingAll || _unreadCount == 0) return;
    setState(() => _markingAll = true);
    try {
      await NotificationService.markAllAsRead();
      if (!mounted) return;
      widget.onAllNotificationsRead?.call();
      setState(() {
        _unreadCount = 0;
        _markingAll = false;
      });
      await _loadNotifications();
    } catch (_) {
      if (!mounted) return;
      setState(() => _markingAll = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not mark all as read.')),
      );
    }
  }

  /// Closes the sheet, then pushes onto the navigator that hosted it. The
  /// navigator is captured first because this widget's context is gone the
  /// moment the sheet route pops.
  Future<void> _replaceSheetWith(Widget page) async {
    final navigator = Navigator.of(context);
    navigator.pop();
    await navigator.push(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppColors.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Notifications',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.espresso,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _notifications.isEmpty
                ? Center(
                    child: Text(
                      'No notifications',
                      style: GoogleFonts.inter(color: AppColors.textSecondary),
                    ),
                  )
                : ListView.builder(
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final noti = _notifications[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: noti.isRead
                              ? Colors.grey.shade200
                              : AppColors.primaryFixed,
                          child: Icon(
                            Icons.notifications,
                            color: noti.isRead
                                ? Colors.grey
                                : AppColors.espresso,
                            size: 18,
                          ),
                        ),
                        title: Row(
                          children: [
                            if (!noti.isRead) ...[
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(right: 6),
                                decoration: const BoxDecoration(
                                  color: AppColors.espresso,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                            Expanded(
                              child: Text(
                                noti.title,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontWeight: noti.isRead
                                      ? FontWeight.normal
                                      : FontWeight.bold,
                                  fontSize: 14,
                                  color: AppColors.espresso,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          noti.content,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        trailing: Text(
                          notificationRelativeTime(noti.createdAt),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: noti.isRead
                                ? AppColors.textSecondary
                                : AppColors.espresso,
                            fontWeight: noti.isRead
                                ? FontWeight.normal
                                : FontWeight.w600,
                          ),
                        ),
                        onTap: () => _replaceSheetWith(
                          NotificationDetailPage(
                            notification: noti,
                            onRead: widget.onNotificationRead,
                          ),
                        ),
                      );
                    },
                  ),
          ),
          // Two actions, not one. Clearing the badge is what people open the
          // bell to do, so it gets the filled button; the inbox — filters,
          // older pages — sits beside it.
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: ElevatedButton.icon(
                        onPressed: (_markingAll || _unreadCount == 0)
                            ? null
                            : _markAllRead,
                        icon: _markingAll
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.done_all, size: 18),
                        label: Text(
                          _unreadCount > 0
                              ? 'Mark all $_unreadCount read'
                              : 'All read',
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.espresso,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: AppColors.outlineVariant,
                          disabledForegroundColor: AppColors.textSecondary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 46,
                    child: OutlinedButton(
                      onPressed: () => _replaceSheetWith(
                        NotificationsPage(
                          onNotificationRead: widget.onNotificationRead,
                          onAllNotificationsRead: widget.onAllNotificationsRead,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.espresso,
                        side: const BorderSide(color: AppColors.espresso),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _totalItems > _notifications.length
                            ? 'View all $_totalItems'
                            : 'View all',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
