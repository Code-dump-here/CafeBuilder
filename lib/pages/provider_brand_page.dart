import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/responses/provider_brand_responses.dart';
import '../services/provider_brand_service.dart';
import '../theme/app_colors.dart';

/// A provider's public face, as the owner reads it while deciding who to hire.
///
/// Two tabs because they answer different questions. **Giới thiệu** is who they
/// are — story, size, where they work, what they are licensed for. **Dự án mẫu**
/// is what they have actually built.
///
/// Read-only: everything here is maintained by the provider from their own app.
/// The one thing worth reading carefully is the verified badge on a
/// certificate — only an administrator can set it, so a provider cannot vouch
/// for themselves.
class ProviderBrandPage extends StatefulWidget {
  /// Uuid of the provider profile.
  final String serviceProviderProfileId;

  /// Name to show while the brand is still loading.
  final String providerName;

  const ProviderBrandPage({
    super.key,
    required this.serviceProviderProfileId,
    required this.providerName,
  });

  @override
  State<ProviderBrandPage> createState() => _ProviderBrandPageState();
}

class _ProviderBrandPageState extends State<ProviderBrandPage> {
  ProviderBrandResponse? _brand;
  List<ProviderPortfolioResponse> _portfolios = [];
  bool _loading = true;
  String? _error;

  final _money = NumberFormat.decimalPattern('vi_VN');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final brand = await ProviderBrandService.getBrand(
        widget.serviceProviderProfileId,
      );
      final portfolios = await ProviderBrandService.getPortfolios(
        serviceProviderProfileId: widget.serviceProviderProfileId,
      );
      if (!mounted) return;
      setState(() {
        _brand = brand;
        _portfolios = portfolios.items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    // Fails silently on a malformed or unhandled link rather than throwing —
    // a broken link a provider typed in is not the owner's problem to see a
    // stack trace over.
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không mở được liên kết: $url')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          title: Text(
            _brand?.displayName ?? widget.providerName,
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.espresso,
            ),
          ),
          bottom: TabBar(
            labelColor: AppColors.espresso,
            unselectedLabelColor: Colors.black45,
            indicatorColor: AppColors.espresso,
            labelStyle:
                GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
            tabs: [
              const Tab(text: 'Giới thiệu'),
              Tab(text: 'Dự án mẫu (${_portfolios.length})'),
            ],
          ),
        ),
        body: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.espresso))
            : _error != null
                ? _ErrorView(message: _error!, onRetry: _load)
                : TabBarView(
                    children: [_buildBrandTab(), _buildPortfolioTab()],
                  ),
      ),
    );
  }

  // ── Tab 1: who they are ────────────────────────────────────────────────────

  Widget _buildBrandTab() {
    final brand = _brand;
    if (brand == null) {
      return const Center(child: Text('Không có dữ liệu.'));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        if (brand.coverImageViewUrl != null &&
            brand.coverImageViewUrl!.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              brand.coverImageViewUrl!,
              height: 140,
              width: double.infinity,
              fit: BoxFit.cover,
              // A provider's link can rot; a broken image should not take the
              // whole screen down with it.
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                brand.displayName,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (brand.isVerified)
              const Icon(Icons.verified, size: 20, color: AppColors.espresso),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 24,
          runSpacing: 12,
          children: [
            _Fact(
              label: 'Thành lập',
              value: brand.foundedYear?.toString() ?? 'Chưa có',
            ),
            _Fact(
              label: 'Quy mô',
              value: brand.employeeCount == null
                  ? 'Chưa có'
                  : '${brand.employeeCount} người',
            ),
            _Fact(
              label: 'Kinh nghiệm',
              value: brand.yearsExperience == null
                  ? 'Chưa có'
                  : '${brand.yearsExperience} năm',
            ),
            _Fact(
              label: 'Đánh giá',
              value: brand.reviewCount == 0
                  ? 'Chưa có đánh giá'
                  : '${brand.avgRating.toStringAsFixed(1)} · ${brand.reviewCount} lượt',
            ),
          ],
        ),
        if (brand.brandStory != null && brand.brandStory!.isNotEmpty) ...[
          const SizedBox(height: 18),
          Text(
            'Câu chuyện thương hiệu',
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            brand.brandStory!,
            style: GoogleFonts.inter(fontSize: 13, height: 1.5),
          ),
        ],
        if (brand.companyAddress != null &&
            brand.companyAddress!.isNotEmpty) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.place_outlined, size: 16, color: Colors.black45),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  brand.companyAddress!,
                  style:
                      GoogleFonts.inter(fontSize: 13, color: Colors.black87),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 18),
        if (brand.website != null && brand.website!.isNotEmpty)
          _LinkTile(
            icon: Icons.language,
            label: 'Website',
            value: brand.website!,
            onTap: () => _open(brand.website!),
          ),
        if (brand.introVideoViewUrl != null &&
            brand.introVideoViewUrl!.isNotEmpty)
          _LinkTile(
            icon: Icons.play_circle_outline,
            label: 'Video giới thiệu',
            value: brand.introVideoViewUrl!,
            onTap: () => _open(brand.introVideoViewUrl!),
          ),
        ...brand.socialLinks.map(
          (link) => _LinkTile(
            icon: Icons.link,
            label: kSocialPlatformLabels[link.platform] ?? link.platform,
            value: link.label ?? link.url,
            onTap: () => _open(link.url),
          ),
        ),
        if (brand.serviceAreas.isNotEmpty) ...[
          const SizedBox(height: 18),
          Text(
            'Khu vực nhận việc',
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: brand.serviceAreas
                .map((area) => _Chip(text: area.label))
                .toList(),
          ),
        ],
        if (brand.certificates.isNotEmpty) ...[
          const SizedBox(height: 18),
          Text(
            'Giấy phép và chứng chỉ',
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Dấu "đã xác minh" do quản trị viên đặt, nhà cung cấp không tự đặt được.',
            style: GoogleFonts.inter(fontSize: 11, color: Colors.black45),
          ),
          const SizedBox(height: 8),
          ...brand.certificates.map(
            (cert) => _CertificateTile(
              cert: cert,
              onOpen: cert.fileViewUrl == null || cert.fileViewUrl!.isEmpty
                  ? null
                  : () => _open(cert.fileViewUrl!),
            ),
          ),
        ],
      ],
    );
  }

  // ── Tab 2: what they built ─────────────────────────────────────────────────

  Widget _buildPortfolioTab() {
    if (_portfolios.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Nhà cung cấp này chưa đăng dự án mẫu nào.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 13, color: Colors.black45),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: _portfolios
          .map(
            (entry) => _PortfolioCard(
              entry: entry,
              money: _money,
              onOpenVideo: entry.videoViewUrl == null ||
                      entry.videoViewUrl!.isEmpty
                  ? null
                  : () => _open(entry.videoViewUrl!),
            ),
          )
          .toList(),
    );
  }
}

class _Fact extends StatelessWidget {
  final String label;
  final String value;

  const _Fact({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 11, color: Colors.black54),
          ),
          Text(
            value,
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;

  const _Chip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primaryFixed,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.espresso,
        ),
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _LinkTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: Icon(icon, size: 20, color: AppColors.espresso),
      title: Text(
        label,
        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.inter(fontSize: 11, color: Colors.black45),
      ),
      trailing: const Icon(Icons.open_in_new, size: 16),
      onTap: onTap,
    );
  }
}

class _CertificateTile extends StatelessWidget {
  final ProviderCertificateResponse cert;
  final VoidCallback? onOpen;

  const _CertificateTile({required this.cert, this.onOpen});

  @override
  Widget build(BuildContext context) {
    final detail = [
      kCertificateKindLabels[cert.kind] ?? cert.kind,
      if (cert.issuer != null && cert.issuer!.isNotEmpty) cert.issuer!,
      if (cert.certificateNo != null && cert.certificateNo!.isNotEmpty)
        'số ${cert.certificateNo}',
      if (cert.expiresAt != null) 'hết hạn ${cert.expiresAt}',
    ].join(' · ');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        cert.name,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (cert.isVerified) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.verified,
                          size: 15, color: Colors.green.shade700),
                    ],
                    if (cert.isExpired == true) ...[
                      const SizedBox(width: 6),
                      Text(
                        'hết hạn',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  detail,
                  style: GoogleFonts.inter(fontSize: 11, color: Colors.black54),
                ),
              ],
            ),
          ),
          if (onOpen != null)
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: onOpen,
              icon: const Icon(Icons.open_in_new, size: 16),
            ),
        ],
      ),
    );
  }
}

class _PortfolioCard extends StatelessWidget {
  final ProviderPortfolioResponse entry;
  final NumberFormat money;
  final VoidCallback? onOpenVideo;

  const _PortfolioCard({
    required this.entry,
    required this.money,
    this.onOpenVideo,
  });

  @override
  Widget build(BuildContext context) {
    final detail = [
      if (entry.location != null && entry.location!.isNotEmpty) entry.location!,
      if (entry.style != null && entry.style!.isNotEmpty) entry.style!,
      if (entry.areaM2 != null) '${entry.areaM2!.toStringAsFixed(0)} m²',
      if (entry.durationDays != null) '${entry.durationDays} ngày',
      if (entry.completedAt != null) entry.completedAt!,
    ].join(' · ');

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (entry.coverImageViewUrl != null &&
              entry.coverImageViewUrl!.isNotEmpty)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                entry.coverImageViewUrl!,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (entry.isFeatured) ...[
                      Icon(Icons.star, size: 16, color: Colors.amber.shade700),
                      const SizedBox(width: 4),
                    ],
                    Expanded(
                      child: Text(
                        entry.title,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    _Chip(
                      text: kPortfolioRoleLabels[entry.role] ?? entry.role,
                    ),
                  ],
                ),
                if (detail.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    detail,
                    style:
                        GoogleFonts.inter(fontSize: 12, color: Colors.black54),
                  ),
                ],
                if (entry.contractValue != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    '${money.format(entry.contractValue)} VND',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.espresso,
                    ),
                  ),
                ],
                if (entry.description != null &&
                    entry.description!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    entry.description!,
                    style: GoogleFonts.inter(fontSize: 13, height: 1.4),
                  ),
                ],
                if (entry.images.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 88,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: entry.images.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final image = entry.images[index];
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            image.displayUrl,
                            width: 110,
                            height: 88,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              width: 110,
                              height: 88,
                              color: AppColors.primaryFixed,
                              child: const Icon(
                                Icons.image_not_supported_outlined,
                                size: 18,
                                color: AppColors.espresso,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
                if (onOpenVideo != null) ...[
                  const SizedBox(height: 8),
                  TextButton.icon(
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    onPressed: onOpenVideo,
                    icon: const Icon(Icons.play_circle_outline, size: 18),
                    label: const Text('Xem video công trình'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 40, color: Colors.red.shade400),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Thử lại')),
          ],
        ),
      ),
    );
  }
}
