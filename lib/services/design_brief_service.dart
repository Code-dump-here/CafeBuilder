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
      if (projectId != null) 'projectId': projectId,
    };
    final response = await ApiClient.authGet('/api/design-briefs', params);
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return ResponseData.fromJson(
      body,
      (d) => PaginationResponse.fromJson(d, DesignBriefResponse.fromJson),
    ).data!;
  }

  static Future<DesignBriefResponse> getDesignBrief(int id) async {
    final response = await ApiClient.authGet('/api/design-briefs/$id');
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return ResponseData.fromJson(body, (d) => DesignBriefResponse.fromJson(d)).data!;
  }

  static Future<DesignBriefResponse> createDesignBrief(CreateDesignBriefRequest request) async {
    final response = await ApiClient.authPost('/api/design-briefs', request.toJson());
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return ResponseData.fromJson(body, (d) => DesignBriefResponse.fromJson(d)).data!;
  }

  static Future<DesignBriefResponse> updateDesignBrief(
      int id, UpdateDesignBriefRequest request) async {
    final response = await ApiClient.authPut('/api/design-briefs/$id', request.toJson());
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return ResponseData.fromJson(body, (d) => DesignBriefResponse.fromJson(d)).data!;
  }

  static Future<void> deleteDesignBrief(int id) async {
    final response = await ApiClient.authDelete('/api/design-briefs/$id');
    ApiClient.throwIfError(response);
  }
}
