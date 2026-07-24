import '../models/responses/api_responses.dart';
import 'api_client.dart';

class ConstructionService {
  // --- Milestones (Construction Items) ---

  static Future<ConstructionItemResponse> createMilestone({
    required int projectWorkingId,
    int? parentId,
    required String name,
    String? description,
    String? category,
    required String estimateAt, // yyyy-MM-dd
    required int createdBy,
  }) async {
    final response = await ApiClient.authPost('/construction-items', {
      'projectWorkingId': projectWorkingId,
      if (parentId != null) 'parentId': parentId,
      'name': name,
      if (description != null) 'description': description,
      if (category != null) 'category': category,
      'estimateAt': estimateAt,
      'createdBy': createdBy,
    });
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return ConstructionItemResponse.fromJson(body);
  }

  static Future<PaginationResponse<ConstructionItemResponse>> getMilestones({
    int pageNumber = 1,
    int pageSize = 10,
    int? projectWorkingId,
    int? parentId,
    String? status,
  }) async {
    final params = <String, dynamic>{
      'pageNumber': pageNumber,
      'pageSize': pageSize,
      if (projectWorkingId != null) 'projectWorkingId': projectWorkingId,
      if (parentId != null) 'parentId': parentId,
      if (status != null) 'status': status,
    };
    final response = await ApiClient.authGet('/construction-items', params);
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return PaginationResponse.fromJson(body, ConstructionItemResponse.fromJson);
  }

  static Future<PaginationResponse<ConstructionItemResponse>> getConstructionItems({
    int pageNumber = 1,
    int pageSize = 10,
    int? projectWorkingId,
    int? parentId,
    String? status,
  }) => getMilestones(
        pageNumber: pageNumber,
        pageSize: pageSize,
        projectWorkingId: projectWorkingId,
        parentId: parentId,
        status: status,
      );

  static Future<ConstructionItemResponse> updateMilestone(
    int id, {
    String? name,
    String? description,
    String? category,
    String? estimateAt,
  }) async {
    final response = await ApiClient.authPut('/construction-items/$id', {
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (category != null) 'category': category,
      if (estimateAt != null) 'estimateAt': estimateAt,
    });
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return ConstructionItemResponse.fromJson(body);
  }

  static Future<ConstructionItemResponse> updateMilestoneStatus(
    int id,
    String status,
  ) async {
    final response = await ApiClient.authPut('/construction-items/$id/status', {
      'status': status,
    });
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return ConstructionItemResponse.fromJson(body);
  }

  static Future<void> deleteMilestone(int id) async {
    final response = await ApiClient.authDelete('/construction-items/$id');
    ApiClient.throwIfError(response);
  }

  // --- Tasks (Inside a Milestone) ---

  static Future<ConstructionTaskResponse> createTask({
    required int constructionItemId,
    required String name,
    String? description,
    String? imageUrl,
    String? estimateAt,
    required int createdBy,
  }) async {
    final response = await ApiClient.authPost('/construction-tasks', {
      'constructionItemId': constructionItemId,
      'name': name,
      if (description != null) 'description': description,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (estimateAt != null) 'estimateAt': estimateAt,
      'createdBy': createdBy,
    });
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return ConstructionTaskResponse.fromJson(body);
  }

  static Future<PaginationResponse<ConstructionTaskResponse>> getTasks({
    int pageNumber = 1,
    int pageSize = 10,
    required int constructionItemId,
    String? status,
  }) async {
    final params = <String, dynamic>{
      'pageNumber': pageNumber,
      'pageSize': pageSize,
      'constructionItemId': constructionItemId,
      if (status != null) 'status': status,
    };
    final response = await ApiClient.authGet('/construction-tasks', params);
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return PaginationResponse.fromJson(body, ConstructionTaskResponse.fromJson);
  }

  static Future<ConstructionTaskResponse> updateTask(
    int id, {
    String? name,
    String? description,
    String? imageUrl,
    String? estimateAt,
    String? reason,
  }) async {
    final response = await ApiClient.authPut('/construction-tasks/$id', {
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (estimateAt != null) 'estimateAt': estimateAt,
      if (reason != null) 'reason': reason,
    });
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return ConstructionTaskResponse.fromJson(body);
  }

  static Future<ConstructionTaskResponse> updateTaskStatus(
    int id,
    String status,
  ) async {
    final response = await ApiClient.authPut('/construction-tasks/$id/status', {
      'status': status,
    });
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return ConstructionTaskResponse.fromJson(body);
  }

  static Future<void> deleteTask(int id) async {
    final response = await ApiClient.authDelete('/construction-tasks/$id');
    ApiClient.throwIfError(response);
  }
}
