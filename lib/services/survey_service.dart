import '../models/responses/api_responses.dart';
import 'api_client.dart';

class SurveyService {
  static Future<SurveyResponse> createSurvey({
    required String projectWorkingId,
    required String conditionNote,
    required String reportUrl,
  }) async {
    final response = await ApiClient.authPost('/surveys', {
      'projectWorkingId': projectWorkingId,
      'conditionNote': conditionNote,
      'reportUrl': reportUrl,
    });
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return SurveyResponse.fromJson(body);
  }

  /// Surveys for one anchor. Pass [applyId] for a provider who is still
  /// bidding, [projectWorkingId] once they are engaged — the two are mutually
  /// exclusive server-side.
  ///
  /// [postId] is the owner's view instead: every survey done by every provider
  /// bidding on one listing, so site visits can be compared side by side before
  /// anyone is chosen. Pair it with the same filter on `/quotations`.
  ///
  /// The server scopes results to the caller either way — an owner sees their
  /// own projects, a provider sees only their own surveys.
  static Future<PaginationResponse<SurveyResponse>> getSurveys({
    int pageNumber = 1,
    int pageSize = 10,
    String? projectWorkingId,
    String? applyId,
    String? postId,
  }) async {
    final params = <String, dynamic>{
      'pageNumber': pageNumber,
      'pageSize': pageSize,
      if (projectWorkingId != null) 'projectWorkingId': projectWorkingId,
      if (applyId != null) 'applyId': applyId,
      if (postId != null) 'postId': postId,
    };
    final response = await ApiClient.authGet('/surveys', params);
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return PaginationResponse.fromJson(body, SurveyResponse.fromJson);
  }

  static Future<SurveyResponse> getSurvey(String id) async {
    final response = await ApiClient.authGet('/surveys/$id');
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return SurveyResponse.fromJson(body);
  }

  static Future<SurveyResponse> updateSurvey(
    String id, {
    String? conditionNote,
    String? reportUrl,
  }) async {
    final response = await ApiClient.authPut('/surveys/$id', {
      if (conditionNote != null) 'conditionNote': conditionNote,
      if (reportUrl != null) 'reportUrl': reportUrl,
    });
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return SurveyResponse.fromJson(body);
  }
}
