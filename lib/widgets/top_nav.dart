import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../services/api_client.dart';
import '../services/notification_service.dart';
import 'notifications_sheet.dart';

/// Persistent top bar shown above every tab in [HomePage] — the top-level
/// counterpart to the bottom nav. Same content (title, notification bell,
/// profile avatar) on every tab instead of each tab building its own.
class TopNav extends StatefulWidget implements PreferredSizeWidget {
  final String title;

  /// Switches HomePage to the Profile tab — same effect as tapping
  /// "PROFILE" in the bottom nav.
  final VoidCallback onProfileTap;

  const TopNav({super.key, this.title = 'Design Cafe', required this.onProfileTap});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  State<TopNav> createState() => _TopNavState();
}

class _TopNavState extends State<TopNav> {
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    final accountId = await ApiClient.getAccountId();
    if (accountId == null) return;
    try {
      final count = await NotificationService.getUnreadCount(accountId);
      if (mounted) setState(() => _unreadCount = count);
    } catch (_) {
      // Non-blocking — badge just stays at 0 if this fails.
    }
  }

  Future<void> _showNotifications() async {
    final accountId = await ApiClient.getAccountId();
    if (accountId == null || !mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NotificationsSheet(
        accountId: accountId,
        onNotificationRead: () {
          if (mounted && _unreadCount > 0) setState(() => _unreadCount--);
        },
      ),
    );
    _loadUnreadCount();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.title,
              style: GoogleFonts.playfairDisplay(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: AppColors.espresso,
                letterSpacing: -0.5,
              ),
            ),
            Row(
              children: [
                GestureDetector(
                  onTap: _showNotifications,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.notifications_none_rounded, color: AppColors.espresso, size: 28),
                      if (_unreadCount > 0)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                            child: Text(
                              _unreadCount > 9 ? '9+' : '$_unreadCount',
                              style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: widget.onProfileTap,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primaryFixed, width: 2),
                      image: const DecorationImage(
                        image: NetworkImage('https://cdn3.iconfinder.com/data/icons/avatars-flat/33/man_5-512.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
