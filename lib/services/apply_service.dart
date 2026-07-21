import '../models/responses/api_responses.dart';
import 'api_client.dart';

/// Owner-side: review and act on provider applications to a post.
/// (Provider-side submission lives in the web designer app.)
class ApplyService {
  static Future<PaginationResponse<ApplyResponse>> getApplies({
    int pageNumber = 1,
    int pageSize = 50,
    int? postId,
    int? serviceProviderProfileId,
    String? status,
  }) async {
    final params = <String, dynamic>{
      'pageNumber': pageNumber,
      'pageSize': pageSize,
      if (postId != null) 'postId': postId,
      if (serviceProviderProfileId != null) 'serviceProviderProfileId': serviceProviderProfileId,
      if (status != null) 'status': status,
    };
    final response = await ApiClient.authGet('/applies', params);
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return ResponseData.fromJson(
      body,
      (d) => PaginationResponse.fromJson(d, ApplyResponse.fromJson),
    ).data!;
  }

  /// Owner accepts an application — creates the engagement (project_working, status=accepted).
  static Future<void> accept(int applyId) async {
    final response = await ApiClient.authPost('/applies/$applyId/accept', {});
    ApiClient.throwIfError(response);
  }

  /// Owner rejects an application.
  static Future<void> reject(int applyId) async {
    final response = await ApiClient.authPost('/applies/$applyId/reject', {});
    ApiClient.throwIfError(response);
  }
}
