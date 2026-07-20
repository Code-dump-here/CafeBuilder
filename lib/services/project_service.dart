import '../models/requests/project_requests.dart';
import '../models/responses/api_responses.dart';
import 'api_client.dart';

class ProjectService {
  static Future<PaginationResponse<ProjectResponse>> getProjects({
    int pageNumber = 1,
    int pageSize = 10,
    int? ownerId,
  }) async {
    final params = <String, dynamic>{
      'pageNumber': pageNumber,
      'pageSize': pageSize,
      if (ownerId != null) 'ownerId': ownerId,
    };
    final response = await ApiClient.authGet('/project-shop-owners', params);
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return PaginationResponse.fromJson(body, ProjectResponse.fromJson);
  }

  static Future<ProjectResponse> getProject(int id) async {
    final response = await ApiClient.authGet('/project-shop-owners/$id');
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return ProjectResponse.fromJson(body);
  }

  static Future<ProjectResponse> createProject(CreateProjectRequest request) async {
    final response = await ApiClient.authPost('/project-shop-owners', request.toJson());
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return ProjectResponse.fromJson(body);
  }

  static Future<ProjectResponse> updateProject(int id, UpdateProjectRequest request) async {
    final response = await ApiClient.authPut('/project-shop-owners/$id', request.toJson());
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return ProjectResponse.fromJson(body);
  }

  static Future<void> deleteProject(int id) async {
    final response = await ApiClient.authDelete('/project-shop-owners/$id');
    ApiClient.throwIfError(response);
  }
}
