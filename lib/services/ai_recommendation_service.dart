import '../models/responses/api_responses.dart';
import 'api_client.dart';

class AiRecommendationService {
  static Future<PaginationResponse<AiRecommendationResponse>> getRecommendations({
    int pageNumber = 1,
    int pageSize = 10,
    int? briefId,
  }) async {
    final response = await ApiClient.authGet('/api/ai-recommendations', {
      'pageNumber': pageNumber,
      'pageSize': pageSize,
      if (briefId != null) 'briefId': briefId,
    });
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return ResponseData.fromJson(
      body,
      (d) => PaginationResponse.fromJson(d, AiRecommendationResponse.fromJson),
    ).data!;
  }

  static Future<AiRecommendationResponse> getRecommendation(int id) async {
    final response = await ApiClient.authGet('/api/ai-recommendations/$id');
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return ResponseData.fromJson(body, (d) => AiRecommendationResponse.fromJson(d)).data!;
  }

  static Future<AiRecommendationResponse> createRecommendation({
    required int briefId,
    required String conceptSummary,
    required String payload,
    double? estimatedDesignCost,
    double? estimatedConstructionCost,
  }) async {
    final response = await ApiClient.authPost('/api/ai-recommendations', {
      'briefId': briefId,
      'conceptSummary': conceptSummary,
      'payload': payload,
      if (estimatedDesignCost != null) 'estimatedDesignCost': estimatedDesignCost,
      if (estimatedConstructionCost != null)
        'estimatedConstructionCost': estimatedConstructionCost,
    });
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return ResponseData.fromJson(body, (d) => AiRecommendationResponse.fromJson(d)).data!;
  }
}
