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
  }

  @override
  void dispose() {
    MarketplaceState.onRoleChanged = null;
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
            DashboardTab(key: _dashboardKey), // 0
            const DiscoveryPage(),            // 1
            const ServicesTab(),              // 2 — always present
            const MarketplacePage(),          // 3 — always present
            const ProfileTab(),               // 4
          ],
        ),
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                // Creating a project changes what Home shows, so refetch on return.
                Navigator.pushNamed(context, '/project-onboarding')
                    .then((_) => _refreshDashboard());
              },
              backgroundColor: AppColors.espresso,
              shape: const CircleBorder(),
              child: const Icon(Icons.add, color: Colors.white, size: 32),
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
        border: Border(top: BorderSide(color: AppColors.outlineVariant.withOpacity(0.3))),
        boxShadow: [
          BoxShadow(
            color: AppColors.espresso.withOpacity(0.07),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, Icons.architecture,              'HOME'),
          _buildNavItem(1, Icons.collections_outlined,      'GALLERY'),
          _buildNavItem(2, Icons.design_services_outlined,  'SERVICES'),
          _buildNavItem(3, Icons.store_mall_directory_rounded, 'MARKET'),
          _buildNavItem(4, Icons.person_outline,            'PROFILE'),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final bool isSelected = _currentIndex == index;
    // Marketplace tab shows a badge dot when a project has been broadcast
    final bool hasBadge = index == 3 && MarketplaceState.activeProject != null;

    return GestureDetector(
      onTap: () {
        setState(() => _currentIndex = index);
        // Returning to Home should show current data, not whatever was loaded
        // when the tab was first built.
        if (index == 0) _refreshDashboard();
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                icon,
                size: 24,
                color: isSelected ? AppColors.espresso : AppColors.outline,
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
          const SizedBox(height: 3),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? AppColors.espresso : AppColors.outline,
              letterSpacing: 0.4,
            ),
          ),
          if (isSelected)
            Container(
              margin: const EdgeInsets.only(top: 3),
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: AppColors.espresso,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}

