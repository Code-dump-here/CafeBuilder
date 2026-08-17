import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../services/auth_service.dart';
import '../services/service_provider_service.dart';
import '../services/api_client.dart';
import '../models/responses/api_responses.dart';
import 'my_projects_page.dart';
import 'account_settings_page.dart';
import 'help_page.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  ShopOwnerResponse? _shopOwner;
  bool _loading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final owner = await ShopOwnerService.getCurrentShopOwner(forceRefresh: true);
      if (mounted) {
        setState(() {
          _shopOwner = owner;
          _loading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadError = e.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadError = 'Failed to load your profile.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                const SizedBox(height: 16),
                if (_loadError != null) ...[
                  _buildLoadErrorBanner(),
                  const SizedBox(height: 16),
                ],
                _buildProfileCard(),
                const SizedBox(height: 32),
                _buildMenuSection(),
                const SizedBox(height: 32),
                _buildSettingsSection(),
                const SizedBox(height: 32),
                _buildLogoutButton(context),
                const SizedBox(height: 100), // Bottom nav space
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Shown when the profile fetch fails, instead of silently falling back
  // to generic placeholder copy with no indication anything went wrong.
  Widget _buildLoadErrorBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC62828).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFC62828), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _loadError ?? 'Failed to load your profile.',
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFFC62828)),
            ),
          ),
          TextButton(
            onPressed: _loadProfile,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image: const DecorationImage(
                    image: NetworkImage('https://cdn3.iconfinder.com/data/icons/avatars-flat/33/man_5-512.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                bottom: -2,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFF56642B),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, color: Colors.white, size: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            _loading ? '...' : (_shopOwner?.fullName ?? 'Shop Owner'),
            style: GoogleFonts.playfairDisplay(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _shopOwner?.shopName ?? 'Project Owner / Cafe Owner',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFD9EAA3).withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, color: Color(0xFF33210D), size: 16),
                const SizedBox(width: 8),
                Text(
                  'Premium Member',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection() {
    return Column(
      children: [
        _buildMenuItem(
          Icons.architecture_rounded, 
          'Project Management',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MyProjectsPage()),
            );
          },
        ),
        _buildMenuItem(Icons.dashboard_customize_outlined, 'My Moodboards', onTap: () => _showComingSoon(context)),
        _buildMenuItem(Icons.person_search_outlined, 'My Application', onTap: () => _showComingSoon(context)),
        _buildMenuItem(Icons.history_rounded, 'Consultation History', onTap: () => _showComingSoon(context)),
      ],
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Coming soon')),
    );
  }

  Widget _buildSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 16),
          child: Text(
            'SETTINGS & SUPPORT',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: AppColors.outline,
            ),
          ),
        ),
        _buildMenuItem(
          Icons.settings_outlined,
          'Account Settings',
          onTap: () async {
            final updated = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AccountSettingsPage()),
            );
            if (updated == true) _loadProfile();
          },
        ),
        _buildMenuItem(
          Icons.help_outline_rounded,
          'Help',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HelpPage()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMenuItem(IconData icon, String title, {VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F3F2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.outline, size: 20),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFBA1A1A).withOpacity(0.2)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () async {
          await AuthService.logout();
          if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
        },
        borderRadius: BorderRadius.circular(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout_rounded, color: Color(0xFFBA1A1A), size: 20),
            const SizedBox(width: 12),
            Text(
              'Log out',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFBA1A1A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
