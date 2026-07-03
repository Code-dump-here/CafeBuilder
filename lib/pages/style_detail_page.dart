import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../theme/app_colors.dart';
import 'discovery_page.dart';

class StyleDetailPage extends StatelessWidget {
  final InspirationItem item;

  const StyleDetailPage({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildHeroSection(),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPoeticDescription(),
                    _buildCharacteristicsSection(),
                    _buildMaterialPalette(),
                    _buildInspirationGallery(),
                    const SizedBox(height: 120), // Bottom padding for buttons
                  ],
                ),
              ),
            ],
          ),
          _buildStickyHeader(context),
          _buildBottomActionButtons(),
        ],
      ),
    );
  }

  Widget _buildStickyHeader(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 100,
        padding: const EdgeInsets.fromLTRB(16, 40, 16, 0),
        decoration: BoxDecoration(
          color: AppColors.background.withOpacity(0.8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.primary),
              onPressed: () => Navigator.pop(context),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.white.withOpacity(0.5),
              ),
            ),
            Text(
              'Atelier Cafe',
              style: GoogleFonts.playfairDisplay(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.share_outlined, color: AppColors.primary),
              onPressed: () {},
              style: IconButton.styleFrom(
                backgroundColor: AppColors.white.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return SliverToBoxAdapter(
      child: Stack(
        children: [
          Hero(
            tag: 'style-${item.imageUrl}',
            child: Container(
              height: 530,
              width: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(item.imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.6),
                  ],
                  stops: const [0.6, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 24,
            left: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aesthetic Exploration'.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryFixed,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${item.category} Style',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPoeticDescription() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: Text(
        'Where Scandinavian functionalism meets Japanese rustic minimalism. A dialogue between the cold north and the warm east, crafting a sanctuary of intentional simplicity and organic warmth.',
        style: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w400,
          fontStyle: FontStyle.italic,
          color: AppColors.textSecondary,
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildCharacteristicsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('KEY CHARACTERISTICS'),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.9,
            children: [
              _buildCharacteristicCard(Icons.grid_view_rounded, 'Minimalist Form', 'Clean lines and uncluttered spatial arrangements.'),
              _buildCharacteristicCard(Icons.eco_rounded, 'Natural Materials', 'Untreated wood, stone, and woven fibers.'),
              _buildCharacteristicCard(Icons.light_mode_rounded, 'Soft Lighting', 'Diffused luminosity that prioritizes shadow play.'),
              _buildCharacteristicCard(Icons.palette_rounded, 'Neutral Palette', 'Muted earth tones mixed with cool grays.'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCharacteristicCard(IconData icon, String title, String desc) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F3F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 32),
          const Spacer(),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialPalette() {
    final materials = [
      {'name': 'Light Oak', 'url': 'https://lh3.googleusercontent.com/aida-public/AB6AXuCTdEGFsZHjd7GKeFoAgjWG9A-2rwa9hed6V0-BiHU8gk3isrApak3ZKQfiSFTnnINmlki2XVRCOBos9CCsNeZU1arQ3nKTqocUz6u2y3Wx0e0J43DDQm3aNRNxscr5pSCjc2jDd8uhEyS3G6UmPo-CufGjOwRwP_0vPvBz7PXaJfMLDXfhoNk5Ct-ErDYxWzXsT_TCQ9UXkMbWTBKMh08mNhez2cO6iRRm3sJOnLIhLb_cZbb0UJviRQa6khug0g8qpo4rhaX0F799'},
      {'name': 'Earth Plaster', 'url': 'https://lh3.googleusercontent.com/aida-public/AB6AXuAu6PEHgC85biTtePIQRB5BM7BxAxlm5ngtw05DjbOM1n4I9wkBnWdmt8p5okZ7Ftlu4rdCcCDBa67zgNxJOM9BoYlUVg3x412BxytoSp73-s2CKxpTZpgaSvTclH75TG91qMLvyibs3cZzu1m9_cMnMlXsITsqnOwyqDQ93uqHPjcG0kSopTjmT-CKg1Aui8YUgs55-R44_Ytgme8gKtIvgi2RYepWX7aCXs0kw0HJXKiewDvlP7s0-OlH1_lHLmyDN9-mrG5150Ev'},
      {'name': 'Natural Linen', 'url': 'https://lh3.googleusercontent.com/aida-public/AB6AXuB6RfTVYicyKwaobzVtO7EMp35mz9AWi6_gu12vZSl9epkbhHHisN--mHji_dPcoIt3kihGyxCZdducl888nXC6eJoVH_lUccqjuht7vKreiVriE7YmjWiReRH0JBoYJwX0i689ti6Fji44fiVyMazSBKJTLbtsMtPyOs7mbg1mD9vCnVKpC5CLUrWMK0CxTSFJhNz6vDXIN0XXcORiDkySiX31p3QBVkrlKAX2ilIalpP84ABfB5D6dxZh2pmrpOMATSrlb65YPhlT'},
      {'name': 'Espresso Ash', 'url': 'https://lh3.googleusercontent.com/aida-public/AB6AXuCkFQCbn_kE8no1MQ0Z7A7PScwq_GWrU9jv6Rkdcpu8qwAp2O1pP5xhekIdakatv6EDKP_be7gsUVbEeWOo1VpmHqgOvJAxrlxTf1k89NJtxvNlsd3-Y1qsilXTWqSdkjsnfK2UM692UBaG0sUKm6P1_wLiLP0tRenqJCx99a_DydgR6CCc_no9xd8o2wNmV8zUhGCTXN0aCDCoy4lGdNCCfAYARKmaK6OnTgrsBKD3o93tO52MjK4p_hPGYvCaHcjv6ONzDLdJFAIW'},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildSectionHeader('MATERIAL PALETTE'),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: materials.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 24),
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFE4E2E1), width: 2),
                        ),
                        child: CircleAvatar(
                          backgroundImage: NetworkImage(materials[index]['url']!),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        materials[index]['name']!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInspirationGallery() {
    final images = [
      {'url': 'https://lh3.googleusercontent.com/aida-public/AB6AXuCyCyUBdV5UWOtqzdGO_vuzXoDvmUWvaYbx8jO74XPrBLOzliI6VW_yN_Qi-ymLQ2WnWyIuViYZjhX5QbD4cRIQ6rlEAyspUYKYpOqNF9KZZFiSFNfWSoprB5nXtOqaV15tzFyjm2w9UA-A5wTfEjyj0VepyU2VLFVXtCjF9HwLTdXXAENkSBFNUMiqC55r7xELVPfzuE_qbQPa2dS4odTEIeaACdv6NeNl1QTyMhWHnjXF-QZ-3Qvj5kR2V4-qkADkPkpiD6LGExSh', 'ratio': 0.75},
      {'url': 'https://lh3.googleusercontent.com/aida-public/AB6AXuBwKbwasY30rHP_dFVSOzvPbQb_iocYPM_tNXSeWo53m-vL2VC-dByGnN4ds6GgwjGG4qzFBtSHXBV9kBwWVbQ83kPUkiGqWDVfJdTFpKRvzvbAshthOOlIVM7cOTyBxwWVOHZkYr553qVCdN9x4-E7qzi_AZ1NLd_DyR_bkXenI4X6yTRRiMATiq55DKXuCYLdKZl4fB-ViHBmAaglh--NHpzADZJkPJ9xTtYcq5QHU4hzAjb9GxH8zK3mjW_pGeNW8-6DFho-ubMJ', 'ratio': 1.0},
      {'url': 'https://lh3.googleusercontent.com/aida-public/AB6AXuCkseKrwFCmhAyRlXAgjoMjpp_OZFWpOHg4F6m6qt4Z4cVDB6U8MvBRcMG6Vc9lXN9EDsMdZdqZYRemi-a0Xo67aekJn9G7z0MEhg_xA7dgFpwHLOcwMouWqXa1x7YuYysv5VUK0w5UbQTDZ4rnmxa4qnoOjrokwU6Pp0KgVE6m3Mnld_t2WVVBSrbuX1GkSi1GFWO4nFkOV3rQSo28EygztWV5eWtIG5ZFkN5GW4AxIXyYz3fQabIMDxSBvCarDJnuufR_oIYJhcDh', 'ratio': 1.77},
      {'url': 'https://lh3.googleusercontent.com/aida-public/AB6AXuBLTaFn4NKnziJcCze5EIF3-CfvFFGrZdn_01dTp5ND3utkRGZZxBgMyT-uJZgnXcN05me1ntPx36O6TbGMOO-E6CrvI2PHfbZ5-yw82X1-1rSOFXGvqGMjgYFYqA8djBl7vDJahlatE8Cz3iXdDBd0PFonDAf93_tzb8B7fw-7JNjVIa3b-5hngf7e4xWVd1y8idYUiIKv5sYSkCdUkIDy70Ny3OBe-KEcdKUK6f0kofvcv8Sit04lRJZURy4trW--q6cr_yaVfzvh', 'ratio': 1.0},
      {'url': 'https://lh3.googleusercontent.com/aida-public/AB6AXuA2bGDy96EcWs223dsg0JlAR-xD12NNYFkGRDwn1AUBIfcYkxVM-7R2BIRI9Itsfzqid6mp8PU67mQXWyXTYW8KRfTYbt956cViiFTDLaS-aDacqZAgkrZvHpGNsAO4KMgbv7o557sYkreIaxnhki_o43yq28Ewm9_M6YeEk600WkBT9l2N6gpj4EA736JkzoFRTkjN9yd47rAgqLnkF8kba_8upqyDUxqickVBvL9CmTEPjPWRVMHWX3oKogd3IfdGjgWYwIAp1Y-3', 'ratio': 0.75},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('INSPIRATION GALLERY'),
          const SizedBox(height: 24),
          MasonryGridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            itemCount: images.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: images[index]['ratio'] as double,
                  child: Image.network(
                    images[index]['url'] as String,
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(width: 32, height: 1, color: AppColors.outlineVariant),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActionButtons() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              AppColors.background,
              AppColors.background.withOpacity(0.95),
              Colors.transparent,
            ],
            stops: const [0.0, 0.7, 1.0],
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.espresso,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.espresso.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.architecture_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        'Apply to Project',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.outlineVariant, width: 2),
              ),
              child: const Icon(Icons.bookmark_border_rounded, color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}
