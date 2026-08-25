import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/responses/api_responses.dart';
import '../services/notification_service.dart';
import '../theme/app_colors.dart';
import '../utils/notification_link.dart';

/// Full text of a single notification.
///
/// The list rows clip title and body to keep the rows even, which meant a
/// notification longer than two lines could not be read anywhere in the app.
/// This screen is the place that shows all of it.
class NotificationDetailPage extends StatefulWidget {
  final NotificationResponse notification;

  /// Called once when this screen marks the notification read, so the bell
  /// badge and any list behind it can drop their count without a refetch.
  final VoidCallback? onRead;

  const NotificationDetailPage({
    super.key,
    required this.notification,
    this.onRead,
  });

  @override
  State<NotificationDetailPage> createState() => _NotificationDetailPageState();
}

class _NotificationDetailPageState extends State<NotificationDetailPage> {
  bool _opening = false;

  @override
  void initState() {
    super.initState();
    _markRead();
  }

  /// Opening a notification is reading it. Done optimistically — the row is
  /// already showing as read by the time the request lands, and a failure here
  /// costs nothing that the next load won't correct.
  Future<void> _markRead() async {
    final noti = widget.notification;
    if (noti.isRead) return;
    setState(() => noti.isRead = true);
    widget.onRead?.call();
    try {
      await NotificationService.markAsRead(noti.id);
    } catch (_) {}
  }

  Future<void> _openReference() async {
    setState(() => _opening = true);
    final opened = await openNotificationReference(context, widget.notification);
    if (!mounted) return;
    setState(() => _opening = false);
    if (!opened) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("That item is no longer available — it may have been removed."),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final noti = widget.notification;
    final hasReference = notificationHasReference(noti);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.espresso),
        title: Text(
          'Notification',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.espresso,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryFixed.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    notificationTypeLabel(noti.type),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.espresso,
                    ),
                  ),
                ),
                Text(
                  notificationFullTime(noti.createdAt),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Selectable so a long reference or an amount inside the body can be
            // copied out rather than retyped.
            SelectableText(
              noti.title,
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.espresso,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.outlineVariant.withValues(alpha: 0.6),
                ),
              ),
              child: SelectableText(
                noti.content.isEmpty ? 'No further details.' : noti.content,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  height: 1.6,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (hasReference) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _opening ? null : _openReference,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.espresso,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: _opening
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.open_in_new, size: 18),
                  label: Text(
                    'Open project',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
