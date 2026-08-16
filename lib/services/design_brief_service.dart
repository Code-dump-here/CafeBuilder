import '../models/requests/design_brief_requests.dart';
import '../models/responses/api_responses.dart';
import 'api_client.dart';

class DesignBriefService {
  static Future<PaginationResponse<DesignBriefResponse>> getDesignBriefs({
    int pageNumber = 1,
    int pageSize = 10,
    int? projectId,
  }) async {
    final params = <String, dynamic>{
      'pageNumber': pageNumber,
      'pageSize': pageSize,
      if (projectId != null) 'projectShopOwnerId': projectId,
    };
    final response = await ApiClient.authGet('/design-briefs', params);
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    // API returns pagination wrapper directly (no ResponseData)
    return PaginationResponse.fromJson(body, DesignBriefResponse.fromJson);
  }

  static Future<DesignBriefResponse> getDesignBrief(int id) async {
    final response = await ApiClient.authGet('/design-briefs/$id');
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return DesignBriefResponse.fromJson(body);
  }

  static Future<DesignBriefResponse> createDesignBrief(CreateDesignBriefRequest request) async {
    final response = await ApiClient.authPost('/design-briefs', request.toJson());
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return DesignBriefResponse.fromJson(body);
  }

  static Future<DesignBriefResponse> updateDesignBrief(
      int id, UpdateDesignBriefRequest request) async {
    final response = await ApiClient.authPut('/design-briefs/$id', request.toJson());
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return DesignBriefResponse.fromJson(body);
  }

  static Future<void> deleteDesignBrief(int id) async {
    final response = await ApiClient.authDelete('/design-briefs/$id');
    ApiClient.throwIfError(response);
  }
}
