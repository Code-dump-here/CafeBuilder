import '../models/responses/api_responses.dart';
import 'api_client.dart';

class CreatePostRequest {
  final int? projectShopOwnerId;
  final String? serviceKind;
  final String title;
  final String description;
  final DateTime? submissionDeadline;
  // Keep old fields to avoid compilation errors in the UI:
  final String? location;
  final String? style;
  final String? budgetTier;
  final String? expectedStart;
  final List<String>? requirements;

  CreatePostRequest({
    this.projectShopOwnerId,
    this.serviceKind,
    required this.title,
    required this.description,
    this.submissionDeadline,
    this.location,
    this.style,
    this.budgetTier,
    this.expectedStart,
    this.requirements,
  });

  Map<String, dynamic> toJson() => {
        if (projectShopOwnerId != null) 'projectShopOwnerId': projectShopOwnerId,
        if (serviceKind != null) 'serviceKind': serviceKind,
        'title': title,
        'description': description,
        if (submissionDeadline != null) 'submissionDeadline': submissionDeadline!.toIso8601String(),
        if (location != null) 'location': location,
        if (style != null) 'style': style,
        if (budgetTier != null) 'budgetTier': budgetTier,
        if (expectedStart != null) 'expectedStart': expectedStart,
        if (requirements != null) 'requirements': requirements,
      };
}

class UpdatePostRequest {
  final String? title;
  final String? description;
  final String? serviceKind;
  final String? status;
  final DateTime? submissionDeadline;

  UpdatePostRequest({
    this.title,
    this.description,
    this.serviceKind,
    this.status,
    this.submissionDeadline,
  });

  Map<String, dynamic> toJson() => {
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (serviceKind != null) 'serviceKind': serviceKind,
        if (status != null) 'status': status,
        if (submissionDeadline != null) 'submissionDeadline': submissionDeadline!.toIso8601String(),
      };
}

class PostService {
  static Future<PaginationResponse<PostResponse>> getPosts({
    int pageNumber = 1,
    int pageSize = 10,
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
    return PaginationResponse.fromJson(body, PostResponse.fromJson);
  }

  static Future<PostResponse> getPost(int id) async {
    final response = await ApiClient.authGet('/posts/$id');
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return PostResponse.fromJson(body);
  }

  static Future<PostResponse> createPost(CreatePostRequest request) async {
    final response = await ApiClient.authPost('/posts', request.toJson());
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return PostResponse.fromJson(body);
  }

  static Future<PostResponse> updatePost(int id, UpdatePostRequest request) async {
    final response = await ApiClient.authPut('/posts/$id', request.toJson());
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return PostResponse.fromJson(body);
  }

  static Future<void> deletePost(int id) async {
    final response = await ApiClient.authDelete('/posts/$id');
    ApiClient.throwIfError(response);
  }

  // --- Applies related client actions ---

  static Future<ApplyResponse> applyToPost({
    required int postId,
    required String proposal,
    required int estimatedDurationDays,
  }) async {
    final response = await ApiClient.authPost('/applies/apply', {
      'postId': postId,
      'proposal': proposal,
      'estimatedDurationDays': estimatedDurationDays,
    });
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return ApplyResponse.fromJson(body);
  }

  static Future<PaginationResponse<ApplyResponse>> getApplies({
    int pageNumber = 1,
    int pageSize = 10,
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
    return PaginationResponse.fromJson(body, ApplyResponse.fromJson);
  }

  static Future<ApplyResponse> updateApplyProposal(
    int id, {
    required String proposal,
    required int estimatedDurationDays,
  }) async {
    final response = await ApiClient.authPut('/applies/$id/proposal', {
      'proposal': proposal,
      'estimatedDurationDays': estimatedDurationDays,
    });
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return ApplyResponse.fromJson(body);
  }

  static Future<ProjectWorkingResponse> acceptApply(int id) async {
    final response = await ApiClient.authPost('/applies/$id/accept', {});
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return ProjectWorkingResponse.fromJson(body);
  }

  static Future<ApplyResponse> rejectApply(int id) async {
    final response = await ApiClient.authPost('/applies/$id/reject', {});
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return ApplyResponse.fromJson(body);
  }

  static Future<void> withdrawApply(int id) async {
    final response = await ApiClient.authDelete('/applies/$id/withdraw');
    ApiClient.throwIfError(response);
  }
}
