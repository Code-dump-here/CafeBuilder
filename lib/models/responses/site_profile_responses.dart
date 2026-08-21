/// Response models for the site profile: the measured premises behind a
/// project.
///
/// `projects.areaM2` is the one number the owner typed when they created the
/// project. This is the surveyed record — filled in gradually, with a row per
/// storey and a row per opening, because a three-storey shophouse with five
/// doors cannot be described by a single area.
library;

DateTime _parseDate(dynamic value) =>
    DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();

/// The wire sends decimals as numbers but ints arrive for whole values, so
/// everything numeric goes through this rather than a bare cast.
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

/// One storey of the premises.
class SiteFloorResponse {
  final String id;
  final String siteProfileId;

  /// 1 = ground, 2 = one up, and so on. Negative for a basement, 0 for a
  /// mezzanine. Unique within a profile — there is only one "floor 2".
  final int floorNo;

  final String? name;
  final double? areaM2;
  final double? ceilingHeightM;
  final String? purpose;
  final String? note;

  SiteFloorResponse({
    required this.id,
    required this.siteProfileId,
    required this.floorNo,
    this.name,
    this.areaM2,
    this.ceilingHeightM,
    this.purpose,
    this.note,
  });

  factory SiteFloorResponse.fromJson(Map<String, dynamic> json) =>
      SiteFloorResponse(
        // Ids are uuids server-side — keep them as strings, never parse to int.
        id: json['id']?.toString() ?? '',
        siteProfileId: json['siteProfileId']?.toString() ?? '',
        floorNo: _parseInt(json['floorNo']) ?? 0,
        name: json['name'],
        areaM2: _parseDouble(json['areaM2']),
        ceilingHeightM: _parseDouble(json['ceilingHeightM']),
        purpose: json['purpose'],
        note: json['note'],
      );

  /// What to call this floor in a list. Falls back to the number.
  String get label => (name != null && name!.trim().isNotEmpty)
      ? name!
      : (floorNo == 0
          ? 'Gác lửng'
          : floorNo < 0
              ? 'Hầm B${-floorNo}'
              : 'Tầng $floorNo');
}

/// A door, window, balcony, terrace or skylight.
class SiteOpeningResponse {
  final String id;
  final String siteProfileId;

  /// Null when the opening has not been pinned to a floor yet.
  final String? siteFloorId;

  /// `main_door` | `secondary_door` | `service_door` | `window` | `balcony` |
  /// `terrace` | `skylight`.
  final String type;

  /// May differ from the building's frontage — a side door or a rear balcony.
  final String? orientation;

  final double? widthM;
  final double? heightM;

  /// Identical openings collapsed onto one row.
  final int quantity;

  final String? note;
  final int sortOrder;

  SiteOpeningResponse({
    required this.id,
    required this.siteProfileId,
    this.siteFloorId,
    required this.type,
    this.orientation,
    this.widthM,
    this.heightM,
    required this.quantity,
    this.note,
    required this.sortOrder,
  });

  factory SiteOpeningResponse.fromJson(Map<String, dynamic> json) =>
      SiteOpeningResponse(
        id: json['id']?.toString() ?? '',
        siteProfileId: json['siteProfileId']?.toString() ?? '',
        siteFloorId: json['siteFloorId']?.toString(),
        type: json['type'] ?? 'window',
        orientation: json['orientation'],
        widthM: _parseDouble(json['widthM']),
        heightM: _parseDouble(json['heightM']),
        quantity: _parseInt(json['quantity']) ?? 1,
        note: json['note'],
        sortOrder: _parseInt(json['sortOrder']) ?? 0,
      );
}

/// The premises record. One per project.
class SiteProfileResponse {
  final String id;
  final String projectShopOwnerId;

  /// Depth of the plot — front to back.
  final double? lengthM;
  final double? widthM;

  /// Usually the same as [widthM], but not on a corner or set-back plot.
  final double? frontageWidthM;

  final double? ceilingHeightM;
  final double? roadWidthM;

  /// Compass bearing the frontage faces. Null = not determined.
  final String? orientation;

  final int? floorCount;
  final bool hasMezzanine;
  final String? structureNote;
  final String? existingConditionNote;

  /// length × width, computed server-side. Null unless both are known.
  final double? derivedFootprintM2;

  /// Sum of the per-floor areas. Null when no floor declares one.
  final double? totalFloorAreaM2;

  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  final List<SiteFloorResponse> floors;
  final List<SiteOpeningResponse> openings;

  SiteProfileResponse({
    required this.id,
    required this.projectShopOwnerId,
    this.lengthM,
    this.widthM,
    this.frontageWidthM,
    this.ceilingHeightM,
    this.roadWidthM,
    this.orientation,
    this.floorCount,
    required this.hasMezzanine,
    this.structureNote,
    this.existingConditionNote,
    this.derivedFootprintM2,
    this.totalFloorAreaM2,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.floors,
    required this.openings,
  });

  factory SiteProfileResponse.fromJson(Map<String, dynamic> json) =>
      SiteProfileResponse(
        id: json['id']?.toString() ?? '',
        projectShopOwnerId: json['projectShopOwnerId']?.toString() ?? '',
        lengthM: _parseDouble(json['lengthM']),
        widthM: _parseDouble(json['widthM']),
        frontageWidthM: _parseDouble(json['frontageWidthM']),
        ceilingHeightM: _parseDouble(json['ceilingHeightM']),
        roadWidthM: _parseDouble(json['roadWidthM']),
        orientation: json['orientation'],
        floorCount: _parseInt(json['floorCount']),
        hasMezzanine: json['hasMezzanine'] == true,
        structureNote: json['structureNote'],
        existingConditionNote: json['existingConditionNote'],
        derivedFootprintM2: _parseDouble(json['derivedFootprintM2']),
        totalFloorAreaM2: _parseDouble(json['totalFloorAreaM2']),
        createdBy: json['createdBy']?.toString(),
        createdAt: _parseDate(json['createdAt']),
        updatedAt: _parseDate(json['updatedAt']),
        floors: (json['floors'] as List<dynamic>? ?? [])
            .map((e) => SiteFloorResponse.fromJson(e as Map<String, dynamic>))
            .toList(),
        openings: (json['openings'] as List<dynamic>? ?? [])
            .map((e) => SiteOpeningResponse.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Vietnamese labels for the two server enums this screen shows.
const Map<String, String> kOrientationLabels = {
  'north': 'Bắc',
  'northeast': 'Đông bắc',
  'east': 'Đông',
  'southeast': 'Đông nam',
  'south': 'Nam',
  'southwest': 'Tây nam',
  'west': 'Tây',
  'northwest': 'Tây bắc',
};

const Map<String, String> kSiteOpeningLabels = {
  'main_door': 'Cửa chính',
  'secondary_door': 'Cửa phụ',
  'service_door': 'Cửa kỹ thuật',
  'window': 'Cửa sổ',
  'balcony': 'Ban công',
  'terrace': 'Sân thượng',
  'skylight': 'Giếng trời',
};
