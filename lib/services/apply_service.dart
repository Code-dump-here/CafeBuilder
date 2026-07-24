import 'api_client.dart';
import '../models/responses/api_responses.dart';

class ApplyService {
  static Future<PaginationResponse<ApplyResponse>> getApplies({
    int pageNumber = 1,
    int pageSize = 10,
    int? postId,
    String? status,
  }) async {
    final Map<String, dynamic> queryParams = {
      'pageNumber': pageNumber,
      'pageSize': pageSize,
    };
    
    if (postId != null) {
      queryParams['postId'] = postId;
    }
    
    if (status != null && status.isNotEmpty) {
      queryParams['status'] = status;
    }

    final queryStr = queryParams.entries.map((e) => '${e.key}=${e.value}').join('&');
    final response = await ApiClient.authGet('/applies?$queryStr');
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    
    return PaginationResponse.fromJson(
      body,
      (json) => ApplyResponse.fromJson(json),
    );
  }

  static Future<ProjectWorkingResponse> acceptApply(int applyId) async {
    final response = await ApiClient.authPost('/applies/$applyId/accept', {});
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return ProjectWorkingResponse.fromJson(body);
  }
}
