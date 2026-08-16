import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import '../models/responses/api_responses.dart';
import 'api_client.dart';

class AiRecommendationService {
  // ── List all recommendations (paginated) ────────────────────────────────────
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
    // The list endpoint returns a pagination wrapper directly (no ResponseData)
    return PaginationResponse.fromJson(body, AiRecommendationResponse.fromJson);
  }

  // ── Get single recommendation by id ────────────────────────────────────────
  static Future<AiRecommendationResponse> getRecommendation(int id) async {
    final response = await ApiClient.authGet('/ai-recommendations/$id');
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return AiRecommendationResponse.fromJson(body);
  }

  // ── Create recommendation (POST → 202 Accepted) ─────────────────────────────
  /// Returns the queued job as an [AiRecommendationResponse] with state='queued'.
  /// The caller should then poll [pollUntilComplete] to wait for the result.
  static Future<AiRecommendationResponse> createRecommendation({
    required int briefId,
    List<String> mustHaveZones = const [],
    List<String> niceToHaveZones = const [],
    String notes = '',
    bool generateImage = true,
    String? imageView,
    int? detailLevel,
    int alternativesCount = 1,
    List<String> referenceImageUrls = const [],
  }) async {
    final response = await ApiClient.authPost('/ai-recommendations', {
      'briefId': briefId,
      'mustHaveZones': mustHaveZones,
      'niceToHaveZones': niceToHaveZones,
      'notes': notes,
      'generateImage': generateImage,
      if (imageView != null) 'imageView': imageView,
      if (detailLevel != null) 'detailLevel': detailLevel,
      'alternativesCount': alternativesCount,
      'referenceImageUrls': referenceImageUrls,
    });

    // 202 Accepted → queued job (not a full recommendation yet)
    // 200/201 → already-completed recommendation
    if (response.statusCode >= 400) {
      ApiClient.throwIfError(response);
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    dev.log('[AiRecommendationService] create response status=${response.statusCode} body=$body', name: 'AI');
    return AiRecommendationResponse.fromJson(body);
  }

  // ── Poll until job completes ─────────────────────────────────────────────────
  /// Polls GET /ai-recommendations/{id} every [intervalSeconds] until the
  /// job state is 'completed' or 'failed', or [maxAttempts] is exceeded.
  static Future<AiRecommendationResponse> pollUntilComplete(
    int id, {
    int intervalSeconds = 4,
    int maxAttempts = 30, // 30 × 4s = 2 minutes max
    void Function(AiRecommendationResponse)? onPoll,
  }) async {
    int attempts = 0;
    while (attempts < maxAttempts) {
      await Future.delayed(Duration(seconds: intervalSeconds));
      attempts++;
      try {
        final rec = await getRecommendation(id);
        dev.log('[AiRecommendationService] poll #$attempts id=$id state=${rec.state}', name: 'AI');
        onPoll?.call(rec);
        if (rec.isCompleted || rec.isFailed) return rec;
      } catch (e) {
        dev.log('[AiRecommendationService] poll error: $e', name: 'AI', level: 900);
      }
    }
    // Return the last known state even if not completed
    return getRecommendation(id);
  }
}
