import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../models/responses/api_responses.dart';
import '../services/notification_service.dart';

/// Bottom sheet listing the account's notifications — shared by every
/// screen that shows the notification bell (see [TopNav]).
class NotificationsSheet extends StatefulWidget {
  final int accountId;
  final VoidCallback onNotificationRead;
  const NotificationsSheet({super.key, required this.accountId, required this.onNotificationRead});

  @override
  State<NotificationsSheet> createState() => NotificationsSheetState();
}

class NotificationsSheetState extends State<NotificationsSheet> {
  List<NotificationResponse> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final res = await NotificationService.getNotifications(widget.accountId);
      if (mounted) {
        setState(() {
          _notifications = res.items;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
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
              border: Border(bottom: BorderSide(color: AppColors.outlineVariant.withOpacity(0.5))),
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
                              backgroundColor: noti.isRead ? Colors.grey.shade200 : AppColors.primaryFixed,
                              child: Icon(
                                Icons.notifications,
                                color: noti.isRead ? Colors.grey : AppColors.espresso,
                                size: 18,
                              ),
                            ),
                            title: Text(
                              noti.title,
                              style: GoogleFonts.inter(
                                fontWeight: noti.isRead ? FontWeight.normal : FontWeight.bold,
                                fontSize: 14,
                                color: AppColors.espresso,
                              ),
                            ),
                            subtitle: Text(
                              noti.content,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                            ),
                            onTap: () async {
                              if (!noti.isRead) {
                                setState(() {
                                  noti.isRead = true;
                                });
                                widget.onNotificationRead();
                                try {
                                  await NotificationService.markAsRead(noti.id);
                                } catch (_) {}
                              }
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
