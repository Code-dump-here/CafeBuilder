/// Response models for a provider's public face: brand, social links, service
/// areas, certificates, and past work.
///
/// Read-only from this app. The provider maintains all of it; the owner reads
/// it while deciding who to hire, which is the half that matters here.
///
/// Every `*ViewUrl` is the server's resolved, displayable form of the `*Url`
/// beside it — render the view URL.
library;

DateTime _parseDate(dynamic value) =>
    DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();

double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

class ProviderSocialLinkResponse {
  final String id;

  /// `facebook` | `instagram` | `tiktok` | `youtube` | `linkedin` | `zalo` |
  /// `website` | `other`. One row per platform.
  final String platform;

  final String url;
  final String? label;
  final int sortOrder;

  ProviderSocialLinkResponse({
    required this.id,
    required this.platform,
    required this.url,
    this.label,
    required this.sortOrder,
  });

  factory ProviderSocialLinkResponse.fromJson(Map<String, dynamic> json) =>
      ProviderSocialLinkResponse(
        id: json['id']?.toString() ?? '',
        platform: json['platform'] ?? 'other',
        url: json['url'] ?? '',
        label: json['label'],
        sortOrder: _parseInt(json['sortOrder']) ?? 0,
      );
}

class ProviderServiceAreaResponse {
  final String id;
  final String province;
  final String? district;
  final String? note;
  final int sortOrder;

  ProviderServiceAreaResponse({
    required this.id,
    required this.province,
    this.district,
    this.note,
    required this.sortOrder,
  });

  factory ProviderServiceAreaResponse.fromJson(Map<String, dynamic> json) =>
      ProviderServiceAreaResponse(
        id: json['id']?.toString() ?? '',
        province: json['province'] ?? '',
        district: json['district'],
        note: json['note'],
        sortOrder: _parseInt(json['sortOrder']) ?? 0,
      );

  String get label =>
      (district != null && district!.isNotEmpty) ? '$district, $province' : province;
}

class ProviderCertificateResponse {
  final String id;

  /// `license` | `certificate` | `award` | `membership` | `other`.
  final String kind;

  final String name;
  final String? issuer;
  final String? certificateNo;

  /// `yyyy-MM-dd` — a plain date on the wire, not an instant.
  final String? issuedAt;
  final String? expiresAt;

  final String? fileUrl;
  final String? fileViewUrl;

  /// Set by an administrator only. A provider cannot verify their own, which
  /// is exactly what makes the badge worth anything to an owner.
  final bool isVerified;

  /// Null when there is no expiry date to compare against.
  final bool? isExpired;

  final int sortOrder;

  ProviderCertificateResponse({
    required this.id,
    required this.kind,
    required this.name,
    this.issuer,
    this.certificateNo,
    this.issuedAt,
    this.expiresAt,
    this.fileUrl,
    this.fileViewUrl,
    required this.isVerified,
    this.isExpired,
    required this.sortOrder,
  });

  factory ProviderCertificateResponse.fromJson(Map<String, dynamic> json) =>
      ProviderCertificateResponse(
        id: json['id']?.toString() ?? '',
        kind: json['kind'] ?? 'other',
        name: json['name'] ?? '',
        issuer: json['issuer'],
        certificateNo: json['certificateNo'],
        issuedAt: json['issuedAt']?.toString(),
        expiresAt: json['expiresAt']?.toString(),
        fileUrl: json['fileUrl'],
        fileViewUrl: json['fileViewUrl'],
        isVerified: json['isVerified'] == true,
        isExpired: json['isExpired'] == null ? null : json['isExpired'] == true,
        sortOrder: _parseInt(json['sortOrder']) ?? 0,
      );
}

class ProviderBrandResponse {
  final String serviceProviderProfileId;
  final String displayName;
  final String? logoUrl;
  final String? logoViewUrl;
  final String? coverImageUrl;
  final String? coverImageViewUrl;
  final String? introVideoUrl;
  final String? introVideoViewUrl;
  final String? website;
  final String? brandStory;
  final String? companyAddress;
  final int? foundedYear;
  final int? employeeCount;
  final int? yearsExperience;
  final bool isVerified;
  final double avgRating;
  final int reviewCount;
  final List<ProviderSocialLinkResponse> socialLinks;
  final List<ProviderServiceAreaResponse> serviceAreas;
  final List<ProviderCertificateResponse> certificates;

  ProviderBrandResponse({
    required this.serviceProviderProfileId,
    required this.displayName,
    this.logoUrl,
    this.logoViewUrl,
    this.coverImageUrl,
    this.coverImageViewUrl,
    this.introVideoUrl,
    this.introVideoViewUrl,
    this.website,
    this.brandStory,
    this.companyAddress,
    this.foundedYear,
    this.employeeCount,
    this.yearsExperience,
    required this.isVerified,
    required this.avgRating,
    required this.reviewCount,
    required this.socialLinks,
    required this.serviceAreas,
    required this.certificates,
  });

  factory ProviderBrandResponse.fromJson(Map<String, dynamic> json) =>
      ProviderBrandResponse(
        serviceProviderProfileId:
            json['serviceProviderProfileId']?.toString() ?? '',
        displayName: json['displayName'] ?? '',
        logoUrl: json['logoUrl'],
        logoViewUrl: json['logoViewUrl'],
        coverImageUrl: json['coverImageUrl'],
        coverImageViewUrl: json['coverImageViewUrl'],
        introVideoUrl: json['introVideoUrl'],
        introVideoViewUrl: json['introVideoViewUrl'],
        website: json['website'],
        brandStory: json['brandStory'],
        companyAddress: json['companyAddress'],
        foundedYear: _parseInt(json['foundedYear']),
        employeeCount: _parseInt(json['employeeCount']),
        yearsExperience: _parseInt(json['yearsExperience']),
        isVerified: json['isVerified'] == true,
        avgRating: _parseDouble(json['avgRating']) ?? 0,
        reviewCount: _parseInt(json['reviewCount']) ?? 0,
        socialLinks: (json['socialLinks'] as List<dynamic>? ?? [])
            .map((e) =>
                ProviderSocialLinkResponse.fromJson(e as Map<String, dynamic>))
            .toList(),
        serviceAreas: (json['serviceAreas'] as List<dynamic>? ?? [])
            .map((e) =>
                ProviderServiceAreaResponse.fromJson(e as Map<String, dynamic>))
            .toList(),
        certificates: (json['certificates'] as List<dynamic>? ?? [])
            .map((e) =>
                ProviderCertificateResponse.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class ProviderPortfolioImageResponse {
  final String id;
  final String imageUrl;
  final String? imageViewUrl;
  final String? caption;
  final int sortOrder;

  ProviderPortfolioImageResponse({
    required this.id,
    required this.imageUrl,
    this.imageViewUrl,
    this.caption,
    required this.sortOrder,
  });

  factory ProviderPortfolioImageResponse.fromJson(Map<String, dynamic> json) =>
      ProviderPortfolioImageResponse(
        id: json['id']?.toString() ?? '',
        imageUrl: json['imageUrl'] ?? '',
        imageViewUrl: json['imageViewUrl'],
        caption: json['caption'],
        sortOrder: _parseInt(json['sortOrder']) ?? 0,
      );

  /// What to actually put in an `Image.network`.
  String get displayUrl =>
      (imageViewUrl != null && imageViewUrl!.isNotEmpty) ? imageViewUrl! : imageUrl;
}

/// One past job a provider shows off.
class ProviderPortfolioResponse {
  final String id;
  final String serviceProviderProfileId;
  final String title;
  final String? description;

  /// `design` | `construction` | `both` — which part they did.
  final String role;

  final String? style;
  final String? location;
  final double? areaM2;
  final double? contractValue;

  /// `yyyy-MM-dd`.
  final String? completedAt;

  final int? durationDays;
  final String? videoUrl;
  final String? videoViewUrl;
  final String? coverImageUrl;
  final String? coverImageViewUrl;

  /// Pinned above the rest, ahead of [sortOrder].
  final bool isFeatured;

  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ProviderPortfolioImageResponse> images;

  ProviderPortfolioResponse({
    required this.id,
    required this.serviceProviderProfileId,
    required this.title,
    this.description,
    required this.role,
    this.style,
    this.location,
    this.areaM2,
    this.contractValue,
    this.completedAt,
    this.durationDays,
    this.videoUrl,
    this.videoViewUrl,
    this.coverImageUrl,
    this.coverImageViewUrl,
    required this.isFeatured,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
    required this.images,
  });

  factory ProviderPortfolioResponse.fromJson(Map<String, dynamic> json) =>
      ProviderPortfolioResponse(
        id: json['id']?.toString() ?? '',
        serviceProviderProfileId:
            json['serviceProviderProfileId']?.toString() ?? '',
        title: json['title'] ?? '',
        description: json['description'],
        role: json['role'] ?? 'both',
        style: json['style'],
        location: json['location'],
        areaM2: _parseDouble(json['areaM2']),
        contractValue: _parseDouble(json['contractValue']),
        completedAt: json['completedAt']?.toString(),
        durationDays: _parseInt(json['durationDays']),
        videoUrl: json['videoUrl'],
        videoViewUrl: json['videoViewUrl'],
        coverImageUrl: json['coverImageUrl'],
        coverImageViewUrl: json['coverImageViewUrl'],
        isFeatured: json['isFeatured'] == true,
        sortOrder: _parseInt(json['sortOrder']) ?? 0,
        createdAt: _parseDate(json['createdAt']),
        updatedAt: _parseDate(json['updatedAt']),
        images: (json['images'] as List<dynamic>? ?? [])
            .map((e) => ProviderPortfolioImageResponse.fromJson(
                e as Map<String, dynamic>))
            .toList(),
      );
}

const Map<String, String> kPortfolioRoleLabels = {
  'design': 'Thiết kế',
  'construction': 'Thi công',
  'both': 'Thiết kế và thi công',
};

const Map<String, String> kCertificateKindLabels = {
  'license': 'Giấy phép',
  'certificate': 'Chứng chỉ',
  'award': 'Giải thưởng',
  'membership': 'Hội viên',
  'other': 'Khác',
};

const Map<String, String> kSocialPlatformLabels = {
  'facebook': 'Facebook',
  'instagram': 'Instagram',
  'tiktok': 'TikTok',
  'youtube': 'YouTube',
  'linkedin': 'LinkedIn',
  'zalo': 'Zalo',
  'website': 'Website',
  'other': 'Khác',
};
