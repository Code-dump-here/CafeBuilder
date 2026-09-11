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
    if (!await ApiClient.isLoggedIn()) return;
    try {
      final count = await NotificationService.getUnreadCount();
      if (mounted) setState(() => _unreadCount = count);
    } catch (_) {
      // Non-blocking — badge just stays at 0 if this fails.
    }
  }

  Future<void> _showNotifications() async {
    if (!await ApiClient.isLoggedIn() || !mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NotificationsSheet(
        onNotificationRead: () {
          if (mounted && _unreadCount > 0) setState(() => _unreadCount--);
        },
        onAllNotificationsRead: () {
          if (mounted) setState(() => _unreadCount = 0);
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
            Expanded(
              child: Text(
                widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: AppColors.espresso,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Row(
              children: [
                _BellIconWithAnimation(
                  unreadCount: _unreadCount,
                  onTap: _showNotifications,
                ),
                const SizedBox(width: 16),
                _AnimatedAvatar(
                  onTap: widget.onProfileTap,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BellIconWithAnimation extends StatefulWidget {
  final int unreadCount;
  final VoidCallback onTap;

  const _BellIconWithAnimation({required this.unreadCount, required this.onTap});

  @override
  State<_BellIconWithAnimation> createState() => _BellIconWithAnimationState();
}

class _BellIconWithAnimationState extends State<_BellIconWithAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _bellController;
  late Animation<double> _swingAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _bellController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _swingAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -0.08), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -0.08, end: 0.08), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 0.08, end: -0.04), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -0.04, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _bellController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _bellController.dispose();
    super.dispose();
  }

  void _handleTap() {
    _bellController.forward(from: 0.0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: _handleTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.85 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        child: RotationTransition(
          turns: _swingAnimation,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.notifications_none_rounded, color: AppColors.espresso, size: 28),
              if (widget.unreadCount > 0)
                Positioned(
                  right: -2,
                  top: -2,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.8, end: 1.0),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.elasticOut,
                    builder: (context, scale, child) {
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.redAccent.withValues(alpha: 0.5),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Text(
                            widget.unreadCount > 9 ? '9+' : '${widget.unreadCount}',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedAvatar extends StatefulWidget {
  final VoidCallback onTap;
  const _AnimatedAvatar({required this.onTap});

  @override
  State<_AnimatedAvatar> createState() => _AnimatedAvatarState();
}

class _AnimatedAvatarState extends State<_AnimatedAvatar> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.90 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primaryFixed, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.espresso.withValues(alpha: 0.12),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
            image: const DecorationImage(
              image: NetworkImage('https://cdn3.iconfinder.com/data/icons/avatars-flat/33/man_5-512.png'),
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}
