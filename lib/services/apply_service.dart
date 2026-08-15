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

    final queryStr = queryParams.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');
    final response = await ApiClient.authGet('/applies?$queryStr');
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);

    return PaginationResponse.fromJson(
      body,
      (json) => ApplyResponse.fromJson(json),
    );
  }

  static Future<ApplyResponse> getApply(int id) async {
    final response = await ApiClient.authGet('/applies/$id');
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return ApplyResponse.fromJson(body['data'] ?? body);
  }

  static Future<ProjectWorkingResponse> acceptApply(int applyId) async {
    final response = await ApiClient.authPost('/applies/$applyId/accept', {});
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return ProjectWorkingResponse.fromJson(body);
  }

  /// Owner declines an application. Only valid while it's still `pending` —
  /// the server 409s once it has been accepted or already rejected.
  ///
  /// Unlike accept, this creates no engagement: the row just moves to
  /// `rejected` and the provider is notified.
  static Future<ApplyResponse> rejectApply(int applyId) async {
    final response = await ApiClient.authPost('/applies/$applyId/reject', {});
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return ApplyResponse.fromJson(body);
  }
}
