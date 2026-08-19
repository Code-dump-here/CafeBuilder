import '../models/responses/api_responses.dart';
import '../models/responses/review3_responses.dart';
import 'api_client.dart';

/// Acceptance checklist (review 3).
///
/// Split of duties, enforced server-side: the provider builds the list of
/// things to be checked, the **shop owner** grades each one. This app is the
/// owner side, so [check] is the important call here — [create] and [remove]
/// exist for completeness and are refused for owner accounts.
class ChecklistService {
  /// Checklist for one milestone or one design. Pass exactly one id.
  ///
  /// Page size is 50 rather than the API default of 10: the list is read as a
  /// whole to judge whether sign-off can proceed, and a second page would hide
  /// items that are actively blocking it.
  static Future<PaginationResponse<ChecklistItemResponse>> getChecklist({
    String? constructionItemId,
    String? designId,
    String? status,
    int pageNumber = 1,
    int pageSize = 50,
  }) async {
    final params = <String, dynamic>{
      'pageNumber': pageNumber,
      'pageSize': pageSize,
      if (constructionItemId != null) 'constructionItemId': constructionItemId,
      if (designId != null) 'designId': designId,
      if (status != null) 'status': status,
    };
    final response = await ApiClient.authGet('/checklist-items', params);
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return PaginationResponse.fromJson(body, ChecklistItemResponse.fromJson);
  }

  /// Owner marks an item passed or failed.
  ///
  /// A `failed` verdict without [note] is rejected by the server — the whole
  /// point of the checklist is that the provider is told what to fix, so the
  /// UI must collect a reason before calling this.
  static Future<ChecklistItemResponse> check(
    String id, {
    required String status,
    String? note,
    String? evidenceUrl,
  }) async {
    final response = await ApiClient.authPost('/checklist-items/$id/check', {
      'status': status,
      if (note != null && note.isNotEmpty) 'note': note,
      if (evidenceUrl != null && evidenceUrl.isNotEmpty)
        'evidenceUrl': evidenceUrl,
    });
    ApiClient.throwIfError(response);
    return ChecklistItemResponse.fromJson(ApiClient.parseBody(response));
  }

  /// Attach evidence to an item without grading it.
  static Future<ChecklistItemResponse> attachEvidence(
    String id, {
    required String evidenceUrl,
  }) async {
    final response = await ApiClient.authPost(
      '/checklist-items/$id/evidence',
      {'evidenceUrl': evidenceUrl},
    );
    ApiClient.throwIfError(response);
    return ChecklistItemResponse.fromJson(ApiClient.parseBody(response));
  }
}
