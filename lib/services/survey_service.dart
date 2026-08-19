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

  static Future<PaginationResponse<SurveyResponse>> getSurveys({
    int pageNumber = 1,
    int pageSize = 10,
    String? projectWorkingId,
  }) async {
    final params = <String, dynamic>{
      'pageNumber': pageNumber,
      'pageSize': pageSize,
      if (projectWorkingId != null) 'projectWorkingId': projectWorkingId,
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
