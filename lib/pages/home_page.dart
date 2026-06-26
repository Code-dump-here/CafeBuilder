import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top AppBar
              _buildAppBar(),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    // Greeting
                    Text(
                      'CHÀO BUỔI SÁNG, CHỦ QUÁN',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary.withOpacity(0.8),
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Xin chào, Alexander',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.espresso,
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Active Project Card
                    _buildActiveProjectCard(),
                    
                    const SizedBox(height: 40),
                    
                    // Quick Actions
                    _buildQuickActions(),
                    
                    const SizedBox(height: 40),
                    
                    // Inspiration Section
                    _buildInspirationSection(),
                    
                    const SizedBox(height: 40),
                    
                    // Recent Documents
                    _buildRecentDocuments(),
                    
                    const SizedBox(height: 100), // Space for bottom nav
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppColors.espresso,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.menu, color: AppColors.espresso, size: 28),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 16),
              Text(
                'Atelier Café',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: AppColors.espresso,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primaryFixed, width: 2),
              image: const DecorationImage(
                image: NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuCdRocndzSsN-UYAyAdDehJe5iER8FIYMiE35WxCJBErozOUf2B3yLChgipuBhVB2ygfuMi7dPypKlDSHVvpvWUNEwx8C9H199dSCEp1Tu738oOGnNuAe3tyDtyMBfFBo0DrDvijOS7KW3cFo5vI8z6GhSGAKWUlR0QnpCnGtGNj6-lhHHKxFyfYkRe1xA8mCEpLYpwWtG1LxWP0NA4RwzOLw-qHhhmkGrZtqHn__ZXAvz-Cz47e0qey8ZAZ_4keMq0p93ycyXaXlbg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveProjectCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.espresso,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.espresso.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative element
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DỰ ÁN CỦA BẠN',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryFixed.withOpacity(0.6),
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Artisan Reserve Roastery',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryFixed,
                          ),
                        ),
                        Text(
                          'Giai đoạn 1: Lập bản thảo',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.primaryFixedDim.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.primaryFixed.withOpacity(0.2)),
                      ),
                      child: const Text(
                        '85%',
                        style: TextStyle(
                          color: AppColors.primaryFixed,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Progress Bar
                Container(
                  width: double.infinity,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: 0.85,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primaryFixed,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Avatars
                    SizedBox(
                      height: 36,
                      width: 100,
                      child: Stack(
                        children: [
                          _buildAvatar(0, 'https://lh3.googleusercontent.com/aida-public/AB6AXuBmkslFEeNh9bICog8Pu0yUiRU0MVi2Qh550V6EZ1kThT19MbWMN4zVOprggD2DGM8aTaO3v-SFr00dwYE-e0_B7AscyQI7qP_827N4BdQaEac77QH2KmN88KF0njIFYahVcjjGymeYOb7yOfVaVa46pLpdWHdNMGCbhCtWywxlHt0gxSrEuu8OpCF40t5Jg_JQFN16gifu1lWXopGQnp7ijpDsEwGfoux5OQ1EUwRraAFfa4I5wrPOhf2oqvOPo9vUX6e3S8a-uk_t'),
                          _buildAvatar(1, 'https://lh3.googleusercontent.com/aida-public/AB6AXuBaM8sdl1PiH-E1VWQi4JUanMwhfPP2SYwD3lSSrrpj1aGNZSAtM_iMdSbG27hpwzz2wsDKu702w9y33yxsz5eDFVWEDSwxCBBeb7dw1K4EEfixxILCgW340Ik7hAFSPPH8BVJ4Lxl-eMHEEc05PlGaIGpoTfuJGDL1zz84IdbNxsntzcLFl6PDv5c56hifhZ5KWBhsiYE4y4JAIPwQ-sY6qamcvBiYR-Dp4EmGOJn5QAasJVuI7mBgxJjreCrnUjXvKIL-ZtdP4AZn'),
                          Positioned(
                            left: 56,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.primaryFixedDim,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.espresso, width: 2),
                              ),
                              child: const Center(
                                child: Text(
                                  '+3',
                                  style: TextStyle(
                                    color: AppColors.espresso,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Button
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryFixed,
                        foregroundColor: AppColors.espresso,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      child: Row(
                        children: const [
                          Text('Tiếp tục', style: TextStyle(fontWeight: FontWeight.w600)),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward, size: 14),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(int index, String url) {
    return Positioned(
      left: index * 28.0,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.espresso, width: 2),
          image: DecorationImage(
            image: NetworkImage(url),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildActionItem(Icons.view_in_ar_rounded, 'Quét mặt bằng'),
        _buildActionItem(Icons.lightbulb_outline_rounded, 'Tìm cảm hứng'),
        _buildActionItem(Icons.handshake_outlined, 'Thuê chuyên gia'),
      ],
    );
  }

  Widget _buildActionItem(IconData icon, String label) {
    return Container(
      width: (MediaQuery.of(context).size.width - 64) / 3,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.espresso, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            label.toUpperCase(),
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: AppColors.espresso,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInspirationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              'Cảm hứng dành cho bạn',
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: AppColors.espresso,
              ),
            ),
            Text(
              'Tất cả',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF56642B),
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 380,
          child: ListView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            children: [
              _buildInspirationCard(
                imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDzWV39I7awqkhB9R7aFYTtS2b9QHLnzYdCdatXXx4-SVlmu2fNk59JXajSnX13L2vnGPwPk2HPvuQDOijoIKlt4SVAw3DawdtAmB6yUdPWw4-SP65ye90zOtLnUp7S8_AW1tS19rGwCRYCJ9_KvewKYPjag6qcC3ZRzEjJIcNEOsNtgf5AOZoqtWDsuYwE5PZuDyVi_FOAn81vupeGes272RFTmLg6_uKI0O4kpM_eXpGjRXNc4uJe8jgNpOYKyK2ciQexj8LpTWey',
                tag: 'JAPANDI',
                title: 'Mộc Trà Quán',
                subtitle: 'Sự cân bằng hoàn hảo giữa gỗ sồi và ánh sáng.',
                width: 280,
              ),
              const SizedBox(width: 20),
              _buildInspirationCard(
                imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDxoZIlfGLUkHEV4ojJ-fQellwEvg21BHHDxw_7YIWdPa8iebzrz8E0bqMUSVopsgaGHD2nZs-WWYMprTtK-qUJ54uEQZgfNhOfetmKb4gpnUuPwRCy6Lce4gIhaiYFyfj9gLGjMbs4q80RxZAupCTu4DLUDWcY3quYao8sdSiqoadmjoVeC_7-fg3M_aSvYMuaKX_reoLCB0tO_baSqFX3l6AxmMNcCwFuuEd-SeIQFIGnX6bmGvhNRLg5KNOpGd1LDMKBf1rok475',
                tag: 'MINIMALIST',
                title: 'Urban Brew Lab',
                subtitle: 'Vẻ đẹp thô mộc của bê tông và thép.',
                width: 260,
                paddingTop: 32,
              ),
              const SizedBox(width: 20),
              _buildInspirationPlaceholder(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInspirationCard({
    required String imageUrl,
    required String tag,
    required String title,
    required String subtitle,
    required double width,
    double paddingTop = 0,
  }) {
    return Padding(
      padding: EdgeInsets.only(top: paddingTop),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: width,
            height: width * 1.33,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
              image: DecorationImage(
                image: NetworkImage(imageUrl),
                fit: BoxFit.cover,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  bottom: 20,
                  left: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryFixed.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(
                        color: AppColors.espresso,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.espresso,
            ),
          ),
          SizedBox(
            width: width,
            child: Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInspirationPlaceholder() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 260,
          height: 260 * 1.33,
          decoration: BoxDecoration(
            color: const Color(0xFFEAE7E7),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Icon(Icons.add_photo_alternate_outlined, color: AppColors.outlineVariant, size: 40),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Khám phá thêm',
          style: GoogleFonts.playfairDisplay(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.espresso,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentDocuments() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tài liệu dự án',
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppColors.espresso,
          ),
        ),
        const SizedBox(height: 20),
        _buildDocumentItem('Sơ đồ mặt bằng Tầng 1', 'Cập nhật 2 giờ trước', Icons.architecture),
        const SizedBox(height: 12),
        _buildDocumentItem('Moodboard: Walnut & Clay', 'Cập nhật Hôm qua', Icons.palette_outlined),
      ],
    );
  }

  Widget _buildDocumentItem(String title, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primaryContainer.withOpacity(0.2)),
            ),
            child: Icon(icon, color: AppColors.espresso, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.espresso,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF56642B),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.more_vert, color: AppColors.outline, size: 20),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        border: Border(top: BorderSide(color: AppColors.outlineVariant.withOpacity(0.3))),
        boxShadow: [
          BoxShadow(
            color: AppColors.espresso.withOpacity(0.08),
            blurRadius: 30,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, Icons.architecture, 'DỰ ÁN'),
          _buildNavItem(1, Icons.collections_outlined, 'THƯ VIỆN'),
          _buildNavItem(2, Icons.design_services_outlined, 'CHUYÊN GIA'),
          _buildNavItem(3, Icons.person_outline, 'CÁ NHÂN'),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    bool isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 26,
            color: isSelected ? AppColors.espresso : AppColors.outline,
            fill: isSelected ? 1.0 : 0.0,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? AppColors.espresso : AppColors.outline,
              letterSpacing: 0.5,
            ),
          ),
          if (isSelected)
            Container(
              margin: const EdgeInsets.only(top: 4),
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
