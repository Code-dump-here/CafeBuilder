import '../models/requests/post_requests.dart';
import '../models/responses/api_responses.dart';
import 'api_client.dart';

/// Owner-side: create and manage job posts that providers apply to.
class PostService {
  static Future<PaginationResponse<PostResponse>> getPosts({
    int pageNumber = 1,
    int pageSize = 50,
    int? projectShopOwnerId,
    String? serviceKind,
    String? status,
    String? search,
  }) async {
    final params = <String, dynamic>{
      'pageNumber': pageNumber,
      'pageSize': pageSize,
      if (projectShopOwnerId != null) 'projectShopOwnerId': projectShopOwnerId,
      if (serviceKind != null) 'serviceKind': serviceKind,
      if (status != null) 'status': status,
      if (search != null) 'search': search,
    };
    final response = await ApiClient.authGet('/posts', params);
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return ResponseData.fromJson(
      body,
      (d) => PaginationResponse.fromJson(d, PostResponse.fromJson),
    ).data!;
  }

  static Future<PostResponse> getPost(int id) async {
    final response = await ApiClient.authGet('/posts/$id');
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return ResponseData.fromJson(body, (d) => PostResponse.fromJson(d)).data!;
  }

  static Future<PostResponse> createPost(CreatePostRequest request) async {
    final response = await ApiClient.authPost('/posts', request.toJson());
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return ResponseData.fromJson(body, (d) => PostResponse.fromJson(d)).data!;
  }

  static Future<PostResponse> updatePost(int id, UpdatePostRequest request) async {
    final response = await ApiClient.authPut('/posts/$id', request.toJson());
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return ResponseData.fromJson(body, (d) => PostResponse.fromJson(d)).data!;
  }

  static Future<void> deletePost(int id) async {
    final response = await ApiClient.authDelete('/posts/$id');
    ApiClient.throwIfError(response);
  }
}
