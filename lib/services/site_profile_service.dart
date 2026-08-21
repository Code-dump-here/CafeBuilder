import '../models/responses/site_profile_responses.dart';
import 'api_client.dart';

/// The measured premises behind a project.
///
/// The owner writes this one — unlike materials or checklists, which the
/// provider authors. Providers can read it, and edit it once they have an
/// accepted engagement, but on this app it is the owner's own record of their
/// building.
class SiteProfileService {
  /// The profile for a project, or `null` when nobody has measured it yet.
  ///
  /// A 404 here is an ordinary state, not a failure: most projects have no
  /// profile until someone fills the form in. Callers get `null` so they can
  /// show the "record the premises" prompt instead of an error.
  static Future<SiteProfileResponse?> getByProject(
    String projectShopOwnerId,
  ) async {
    final response =
        await ApiClient.authGet('/site-profiles/by-project/$projectShopOwnerId');
    if (response.statusCode == 404) return null;
    ApiClient.throwIfError(response);
    return SiteProfileResponse.fromJson(ApiClient.parseBody(response));
  }

  /// Create the profile. Floors and openings can ride along, so the first
  /// submit files the whole thing in one round trip.
  static Future<SiteProfileResponse> create({
    required String projectShopOwnerId,
    double? lengthM,
    double? widthM,
    double? frontageWidthM,
    double? ceilingHeightM,
    double? roadWidthM,
    String? orientation,
    int? floorCount,
    bool hasMezzanine = false,
    String? structureNote,
    String? existingConditionNote,
  }) async {
    final response = await ApiClient.authPost('/site-profiles', {
      'projectShopOwnerId': projectShopOwnerId,
      if (lengthM != null) 'lengthM': lengthM,
      if (widthM != null) 'widthM': widthM,
      if (frontageWidthM != null) 'frontageWidthM': frontageWidthM,
      if (ceilingHeightM != null) 'ceilingHeightM': ceilingHeightM,
      if (roadWidthM != null) 'roadWidthM': roadWidthM,
      if (orientation != null) 'orientation': orientation,
      if (floorCount != null) 'floorCount': floorCount,
      'hasMezzanine': hasMezzanine,
      if (structureNote != null) 'structureNote': structureNote,
      if (existingConditionNote != null)
        'existingConditionNote': existingConditionNote,
    });
    ApiClient.throwIfError(response);
    return SiteProfileResponse.fromJson(ApiClient.parseBody(response));
  }

  static Future<SiteProfileResponse> update(
    String id, {
    double? lengthM,
    double? widthM,
    double? frontageWidthM,
    double? ceilingHeightM,
    double? roadWidthM,
    String? orientation,
    int? floorCount,
    bool? hasMezzanine,
    String? structureNote,
    String? existingConditionNote,
  }) async {
    final response = await ApiClient.authPut('/site-profiles/$id', {
      if (lengthM != null) 'lengthM': lengthM,
      if (widthM != null) 'widthM': widthM,
      if (frontageWidthM != null) 'frontageWidthM': frontageWidthM,
      if (ceilingHeightM != null) 'ceilingHeightM': ceilingHeightM,
      if (roadWidthM != null) 'roadWidthM': roadWidthM,
      if (orientation != null) 'orientation': orientation,
      if (floorCount != null) 'floorCount': floorCount,
      if (hasMezzanine != null) 'hasMezzanine': hasMezzanine,
      if (structureNote != null) 'structureNote': structureNote,
      if (existingConditionNote != null)
        'existingConditionNote': existingConditionNote,
    });
    ApiClient.throwIfError(response);
    return SiteProfileResponse.fromJson(ApiClient.parseBody(response));
  }

  /// Approve the surveyed measurements into the project.
  ///
  /// Writes the sum of the per-floor areas to `projects.areaM2`, which is the
  /// number every project screen and the AI payload read. Owner only — the
  /// provider records the measurements but does not put them into force.
  ///
  /// 409 when no floor declares an area yet, or the project is already closed.
  static Future<SiteProfileResponse> approveMeasurements(String id) async {
    final response =
        await ApiClient.authPost('/site-profiles/$id/approve-measurements', {});
    ApiClient.throwIfError(response);
    return SiteProfileResponse.fromJson(ApiClient.parseBody(response));
  }

  // ── Floors ────────────────────────────────────────────────────────────────

  /// Add a storey. `floorNo` is unique per profile — a duplicate is a 409.
  static Future<SiteFloorResponse> addFloor(
    String siteProfileId, {
    required int floorNo,
    String? name,
    double? areaM2,
    double? ceilingHeightM,
    String? purpose,
    String? note,
  }) async {
    final response =
        await ApiClient.authPost('/site-profiles/$siteProfileId/floors', {
      'floorNo': floorNo,
      if (name != null) 'name': name,
      if (areaM2 != null) 'areaM2': areaM2,
      if (ceilingHeightM != null) 'ceilingHeightM': ceilingHeightM,
      if (purpose != null) 'purpose': purpose,
      if (note != null) 'note': note,
    });
    ApiClient.throwIfError(response);
    return SiteFloorResponse.fromJson(ApiClient.parseBody(response));
  }

  static Future<SiteFloorResponse> updateFloor(
    String floorId, {
    required int floorNo,
    String? name,
    double? areaM2,
    double? ceilingHeightM,
    String? purpose,
    String? note,
  }) async {
    final response = await ApiClient.authPut('/site-profiles/floors/$floorId', {
      'floorNo': floorNo,
      if (name != null) 'name': name,
      if (areaM2 != null) 'areaM2': areaM2,
      if (ceilingHeightM != null) 'ceilingHeightM': ceilingHeightM,
      if (purpose != null) 'purpose': purpose,
      if (note != null) 'note': note,
    });
    ApiClient.throwIfError(response);
    return SiteFloorResponse.fromJson(ApiClient.parseBody(response));
  }

  static Future<void> removeFloor(String floorId) async {
    final response =
        await ApiClient.authDelete('/site-profiles/floors/$floorId');
    ApiClient.throwIfError(response);
  }

  // ── Openings ──────────────────────────────────────────────────────────────

  /// Add a door / window / balcony. Pin it to a floor by id, or leave it on the
  /// profile as a whole.
  static Future<SiteOpeningResponse> addOpening(
    String siteProfileId, {
    required String type,
    String? siteFloorId,
    String? orientation,
    double? widthM,
    double? heightM,
    int quantity = 1,
    String? note,
  }) async {
    final response =
        await ApiClient.authPost('/site-profiles/$siteProfileId/openings', {
      'type': type,
      if (siteFloorId != null) 'siteFloorId': siteFloorId,
      if (orientation != null) 'orientation': orientation,
      if (widthM != null) 'widthM': widthM,
      if (heightM != null) 'heightM': heightM,
      'quantity': quantity,
      if (note != null) 'note': note,
    });
    ApiClient.throwIfError(response);
    return SiteOpeningResponse.fromJson(ApiClient.parseBody(response));
  }

  static Future<SiteOpeningResponse> updateOpening(
    String openingId, {
    required String type,
    String? siteFloorId,
    String? orientation,
    double? widthM,
    double? heightM,
    int quantity = 1,
    String? note,
  }) async {
    final response =
        await ApiClient.authPut('/site-profiles/openings/$openingId', {
      'type': type,
      if (siteFloorId != null) 'siteFloorId': siteFloorId,
      if (orientation != null) 'orientation': orientation,
      if (widthM != null) 'widthM': widthM,
      if (heightM != null) 'heightM': heightM,
      'quantity': quantity,
      if (note != null) 'note': note,
    });
    ApiClient.throwIfError(response);
    return SiteOpeningResponse.fromJson(ApiClient.parseBody(response));
  }

  static Future<void> removeOpening(String openingId) async {
    final response =
        await ApiClient.authDelete('/site-profiles/openings/$openingId');
    ApiClient.throwIfError(response);
  }
}
