import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../models/responses/api_responses.dart';
import '../services/notification_service.dart';
import '../services/project_working_service.dart';
import '../services/apply_service.dart';
import '../pages/project_detail_page.dart';

/// Bottom sheet listing the account's notifications — shared by every
/// screen that shows the notification bell (see [TopNav]).
class NotificationsSheet extends StatefulWidget {
  final VoidCallback onNotificationRead;
  const NotificationsSheet({
    super.key,
    required this.onNotificationRead,
  });

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

  /// Compact relative time for a notification list — "now", "5m", "3h",
  /// "2d", then falls back to a short date once it's over a week old.
  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  // Resolves a notification's (referenceType, referenceId) to a project and
  // opens it. Only 'project' carries a ProjectShopOwner.Id directly;
  // 'project_provider' and 'project_application' reference an engagement or
  // an apply row, so those need one extra lookup to find the project they
  // belong to. Unknown/missing reference data no-ops rather than guessing.
  Future<void> _openReference(NotificationResponse noti) async {
    final type = noti.referenceType;
    final id = noti.referenceId;
    if (type == null || id == null || !mounted) return;

    try {
      int? projectId;
      switch (type) {
        case 'project':
          projectId = id;
          break;
        case 'project_provider':
          final working = await ProjectWorkingService.getProjectWorking(id);
          projectId = working.projectShopOwnerId;
          break;
        case 'project_application':
          final apply = await ApplyService.getApply(id);
          projectId = apply.projectShopOwnerId;
          break;
      }
      if (projectId != null && mounted) {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProjectDetailPage(projectId: projectId!),
          ),
        );
      }
    } catch (_) {
      // The referenced project/engagement/apply may have been deleted since
      // the notification was created — fail quietly rather than error out
      // of the sheet.
    }
  }

  Future<void> _loadNotifications() async {
    try {
      final res = await NotificationService.getNotifications();
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
              border: Border(
                bottom: BorderSide(
                  color: AppColors.outlineVariant.withOpacity(0.5),
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
                          _relativeTime(noti.createdAt),
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
                          await _openReference(noti);
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
