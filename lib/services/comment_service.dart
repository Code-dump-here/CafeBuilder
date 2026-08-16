import '../models/responses/api_responses.dart';
import 'api_client.dart';

/// Comments attach to a single work item — a design deliverable or a
/// construction item. Both the owner and the provider on the engagement can
/// read and post; only the author (or an admin) can delete.
class CommentService {
  const CommentService._();

  /// Backend enum values — anything else is rejected with a 400.
  static const String targetDesign = 'design';
  static const String targetConstructionItem = 'construction_item';

  static Future<PaginationResponse<CommentResponse>> getComments({
    required String targetType,
    required String targetId,
    int pageNumber = 1,
    int pageSize = 50,
  }) async {
    final response = await ApiClient.authGet('/comments', {
      'targetType': targetType,
      'targetId': targetId,
      'pageNumber': pageNumber,
      'pageSize': pageSize,
    });
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return PaginationResponse.fromJson(body, CommentResponse.fromJson);
  }

  /// The author is taken from the auth token server-side, so no id is sent.
  static Future<CommentResponse> addComment({
    required String targetType,
    required String targetId,
    required String body,
  }) async {
    final response = await ApiClient.authPost('/comments', {
      'targetType': targetType,
      'targetId': targetId,
      'body': body,
    });
    ApiClient.throwIfError(response);
    return CommentResponse.fromJson(ApiClient.parseBody(response));
  }

  static Future<void> deleteComment(String id) async {
    final response = await ApiClient.authDelete('/comments/$id');
    ApiClient.throwIfError(response);
  }
}
