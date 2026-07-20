import '../models/responses/api_responses.dart';
import 'api_client.dart';

class ProjectWorkingService {
  static Future<PaginationResponse<ProjectWorkingResponse>> getProjectWorkings({
    int pageNumber = 1,
    int pageSize = 10,
    int? projectShopOwnerId,
    int? serviceProviderProfileId,
    String? status,
  }) async {
    final params = <String, dynamic>{
      'pageNumber': pageNumber,
      'pageSize': pageSize,
      if (projectShopOwnerId != null) 'projectShopOwnerId': projectShopOwnerId,
      if (serviceProviderProfileId != null) 'serviceProviderProfileId': serviceProviderProfileId,
      if (status != null) 'status': status,
    };
    final response = await ApiClient.authGet('/project-workings', params);
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return PaginationResponse.fromJson(body, ProjectWorkingResponse.fromJson);
  }

  static Future<ProjectWorkingResponse> getProjectWorking(int id) async {
    final response = await ApiClient.authGet('/project-workings/$id');
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return ProjectWorkingResponse.fromJson(body);
  }

  static Future<DesignBriefResponse> getProjectWorkingBrief(int id) async {
    final response = await ApiClient.authGet('/project-workings/$id/brief');
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return DesignBriefResponse.fromJson(body);
  }

  static Future<EngagementOverviewResponse> getProjectWorkingOverview(int id) async {
    final response = await ApiClient.authGet('/project-workings/$id/overview');
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return EngagementOverviewResponse.fromJson(body);
  }

  static Future<ProjectWorkingResponse> updateProjectWorkingStatus(
    int id,
    String status,
  ) async {
    final response = await ApiClient.authPut('/project-workings/$id/status', {
      'status': status,
    });
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return ProjectWorkingResponse.fromJson(body);
  }

  // --- Direct Hires Path B ---

  static Future<ProjectWorkingResponse> directRequest({
    required int projectShopOwnerId,
    required int serviceProviderProfileId,
    required String contractType,
    required String requestMessage,
  }) async {
    final response = await ApiClient.authPost('/project-workings/direct-request', {
      'projectShopOwnerId': projectShopOwnerId,
      'serviceProviderProfileId': serviceProviderProfileId,
      'contractType': contractType,
      'requestMessage': requestMessage,
    });
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return ProjectWorkingResponse.fromJson(body);
  }

  static Future<ProjectWorkingResponse> acceptDirectRequest(int id) async {
    final response = await ApiClient.authPost('/project-workings/$id/accept', {});
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return ProjectWorkingResponse.fromJson(body);
  }

  static Future<ProjectWorkingResponse> rejectDirectRequest(int id) async {
    final response = await ApiClient.authPost('/project-workings/$id/reject', {});
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return ProjectWorkingResponse.fromJson(body);
  }
}
