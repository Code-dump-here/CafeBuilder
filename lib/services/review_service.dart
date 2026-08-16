import '../models/responses/api_responses.dart';
import 'api_client.dart';

class ReviewRequestScore {
  final String dimension;
  final double score;

  ReviewRequestScore({required this.dimension, required this.score});

  Map<String, dynamic> toJson() => {
        'dimension': dimension,
        'score': score,
      };
}

class ReviewService {
  static Future<ReviewResponse> createReview({
    required int projectWorkingId,
    required double overallRating,
    String? comment,
    List<ReviewRequestScore> scores = const [],
  }) async {
    final response = await ApiClient.authPost('/reviews', {
      'projectWorkingId': projectWorkingId,
      'overallRating': overallRating,
      if (comment != null) 'comment': comment,
      'scores': scores.map((e) => e.toJson()).toList(),
    });
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return ReviewResponse.fromJson(body);
  }

  static Future<PaginationResponse<ReviewResponse>> getReviews({
    int pageNumber = 1,
    int pageSize = 10,
  }) async {
    final params = {
      'pageNumber': pageNumber,
      'pageSize': pageSize,
    };
    final response = await ApiClient.authGet('/reviews', params);
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return PaginationResponse.fromJson(body, ReviewResponse.fromJson);
  }

  static Future<ReviewResponse> getReview(int id) async {
    final response = await ApiClient.authGet('/reviews/$id');
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return ReviewResponse.fromJson(body);
  }

  static Future<ReviewResponse> updateReview(
    int id, {
    double? overallRating,
    String? comment,
    List<ReviewRequestScore>? scores,
  }) async {
    final response = await ApiClient.authPut('/reviews/$id', {
      if (overallRating != null) 'overallRating': overallRating,
      if (comment != null) 'comment': comment,
      if (scores != null) 'scores': scores.map((e) => e.toJson()).toList(),
    });
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return ReviewResponse.fromJson(body);
  }

  static Future<void> deleteReview(int id) async {
    final response = await ApiClient.authDelete('/reviews/$id');
    ApiClient.throwIfError(response);
  }

  static Future<List<ReviewResponse>> getReviewsForProvider(
    int serviceProviderProfileId, {
    int pageSize = 50,
  }) async {
    final result = await getReviews(pageNumber: 1, pageSize: pageSize);
    return result.items
        .where((r) => r.serviceProviderProfileId == serviceProviderProfileId)
        .toList();
  }

  static Future<ProviderReviewSummary> getProviderReviewSummary(int serviceProviderProfileId) async {
    final response = await ApiClient.authGet('/reviews/providers/$serviceProviderProfileId/summary');
    ApiClient.throwIfError(response);
    return ProviderReviewSummary.fromJson(ApiClient.parseBody(response));
  }
}
