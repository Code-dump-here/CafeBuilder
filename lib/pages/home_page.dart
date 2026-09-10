import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import 'discovery_page.dart';
import 'dashboard_tab.dart';
import 'profile_tab.dart';
import 'ai_advice_page.dart';
import 'services_tab.dart';
import 'marketplace_page.dart';
import '../models/marketplace_state.dart';
import '../widgets/top_nav.dart';

class HomePage extends StatefulWidget {
  final int? initialIndex;
  const HomePage({super.key, this.initialIndex});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  // The tabs live in an IndexedStack, so DashboardTab's state is built once and
  // never refetches on its own. This key lets us refresh it whenever the user
  // comes back to Home or finishes creating a project.
  final GlobalKey<DashboardTabState> _dashboardKey = GlobalKey<DashboardTabState>();

  void _refreshDashboard() {
    _dashboardKey.currentState?.reload();
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex ?? MarketplaceState.initialIndex;
    MarketplaceState.onRoleChanged = () {
      if (mounted) {
        setState(() {
          _currentIndex = MarketplaceState.initialIndex;
        });
      }
    };
    // Screens deep in the stack (project creation, posting to marketplace)
    // pop straight back to this same Home instance instead of pushing a
    // new one, so their own "we're done" moment can't call
    // `_refreshDashboard()` directly — they call this instead.
    MarketplaceState.onNeedsRefresh = () {
      if (mounted) _refreshDashboard();
    };
  }

  @override
  void dispose() {
    MarketplaceState.onRoleChanged = null;
    MarketplaceState.onNeedsRefresh = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      // Persistent top nav — the top-level counterpart to bottomNavigationBar
      // below. Same on every tab instead of each tab building its own header.
      appBar: TopNav(onProfileTap: () => setState(() => _currentIndex = 4)),
      body: SafeArea(
        top: false,
        child: IndexedStack(
          index: _currentIndex,
          children: [
            DashboardTab(
              key: _dashboardKey,
              onSeeAllInspiration: () => setState(() => _currentIndex = 1),
            ), // 0
            const DiscoveryPage(),            // 1
            const ServicesTab(),              // 2 — always present
            const MarketplacePage(),          // 3 — always present
            const ProfileTab(),               // 4
          ],
        ),
      ),
      floatingActionButton: _currentIndex == 0
          ? _AnimatedFab(
              onPressed: () {
                // Creating a project changes what Home shows, so refetch on return.
                Navigator.pushNamed(context, '/project-onboarding')
                    .then((_) => _refreshDashboard());
              },
            )
          : null,
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.3))),
        boxShadow: [
          BoxShadow(
            color: AppColors.espresso.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, Icons.architecture_rounded,       'HOME'),
          _buildNavItem(1, Icons.collections_outlined,      'GALLERY'),
          _buildNavItem(2, Icons.design_services_outlined,  'SERVICES'),
          _buildNavItem(3, Icons.store_mall_directory_rounded, 'MARKET'),
          _buildNavItem(4, Icons.person_outline_rounded,    'PROFILE'),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final bool isSelected = _currentIndex == index;
    final bool hasBadge = index == 3 && MarketplaceState.activeProject != null;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        setState(() => _currentIndex = index);
        if (index == 0) _refreshDashboard();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedScale(
                  scale: isSelected ? 1.15 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  child: Icon(
                    icon,
                    size: 24,
                    color: isSelected ? AppColors.espresso : AppColors.outline,
                  ),
                ),
                if (hasBadge)
                  Positioned(
                    top: -2,
                    right: -4,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF56642B),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected ? AppColors.espresso : AppColors.outline,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isSelected ? 1.0 : 0.0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isSelected ? 14 : 0,
                height: 3,
                decoration: BoxDecoration(
                  color: AppColors.espresso,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedFab extends StatefulWidget {
  final VoidCallback onPressed;
  const _AnimatedFab({required this.onPressed});

  @override
  State<_AnimatedFab> createState() => _AnimatedFabState();
}

class _AnimatedFabState extends State<_AnimatedFab> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.0, end: 10.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.espresso.withValues(alpha: 0.35),
                blurRadius: 14 + _pulseAnimation.value,
                spreadRadius: _pulseAnimation.value * 0.15,
              ),
            ],
          ),
          child: child,
        );
      },
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _isPressed ? 0.90 : 1.0,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOutCubic,
          child: Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF5A412A), Color(0xFF33210D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add_rounded, color: AppColors.primaryFixed, size: 32),
          ),
        ),
      ),
    );
  }
}

