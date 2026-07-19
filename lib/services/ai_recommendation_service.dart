import '../models/responses/api_responses.dart';
import 'api_client.dart';

class AiRecommendationService {
  static Future<PaginationResponse<AiRecommendationResponse>> getRecommendations({
    int pageNumber = 1,
    int pageSize = 10,
    int? briefId,
  }) async {
    final response = await ApiClient.authGet('/ai-recommendations', {
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
    final response = await ApiClient.authGet('/ai-recommendations/$id');
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return ResponseData.fromJson(body, (d) => AiRecommendationResponse.fromJson(d)).data!;
  }

  static Future<AiRecommendationResponse> createRecommendation({
    required int briefId,
    required List<String> mustHaveZones,
    required List<String> niceToHaveZones,
    required String notes,
    bool generateImage = true,
    int imageView = 0,
    int detailLevel = 0,
    int alternativesCount = 3,
    List<String> referenceImageUrls = const [],
  }) async {
    final response = await ApiClient.authPost('/ai-recommendations', {
      'briefId': briefId,
      'mustHaveZones': mustHaveZones,
      'niceToHaveZones': niceToHaveZones,
      'notes': notes,
      'generateImage': generateImage,
      'imageView': imageView,
      'detailLevel': detailLevel,
      'alternativesCount': alternativesCount,
      'referenceImageUrls': referenceImageUrls,
    });
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return ResponseData.fromJson(body, (d) => AiRecommendationResponse.fromJson(d)).data!;
  }
}
