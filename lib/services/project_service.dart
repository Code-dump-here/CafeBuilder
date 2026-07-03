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
    final response = await ApiClient.authGet('/api/projects', params);
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    final data = ResponseData.fromJson(
      body,
      (d) => PaginationResponse.fromJson(d, ProjectResponse.fromJson),
    );
    return data.data!;
  }

  static Future<ProjectResponse> getProject(int id) async {
    final response = await ApiClient.authGet('/api/projects/$id');
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return ResponseData.fromJson(body, (d) => ProjectResponse.fromJson(d)).data!;
  }

  static Future<ProjectResponse> createProject(CreateProjectRequest request) async {
    final response = await ApiClient.authPost('/api/projects', request.toJson());
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return ResponseData.fromJson(body, (d) => ProjectResponse.fromJson(d)).data!;
  }

  static Future<ProjectResponse> updateProject(int id, UpdateProjectRequest request) async {
    final response = await ApiClient.authPut('/api/projects/$id', request.toJson());
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return ResponseData.fromJson(body, (d) => ProjectResponse.fromJson(d)).data!;
  }

  static Future<void> deleteProject(int id) async {
    final response = await ApiClient.authDelete('/api/projects/$id');
    ApiClient.throwIfError(response);
  }
}
