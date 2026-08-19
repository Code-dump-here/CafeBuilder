import 'dart:convert';

import '../models/responses/api_responses.dart';
import '../models/responses/review3_responses.dart';
import 'api_client.dart';

/// Materials and their cost (review 3).
///
/// Read-only from this app on purpose. The price list is published by the
/// provider and the quantities are theirs to record; the owner sees what was
/// agreed and what it comes to, which is the half that matters for approving
/// a payment batch.
class MaterialService {
  /// The price list published for an engagement.
  static Future<PaginationResponse<MaterialResponse>> getPriceList({
    required String projectWorkingId,
    int pageNumber = 1,
    int pageSize = 50,
  }) async {
    final response = await ApiClient.authGet('/materials', {
      'projectWorkingId': projectWorkingId,
      'pageNumber': pageNumber,
      'pageSize': pageSize,
    });
    ApiClient.throwIfError(response);
    return PaginationResponse.fromJson(
      ApiClient.parseBody(response),
      MaterialResponse.fromJson,
    );
  }

  /// Material lines for one milestone or one task. Pass exactly one id.
  static Future<List<ConstructionMaterialResponse>> getUsages({
    String? constructionItemId,
    String? constructionTaskId,
  }) async {
    final response = await ApiClient.authGet('/materials/usages', {
      if (constructionItemId != null) 'constructionItemId': constructionItemId,
      if (constructionTaskId != null) 'constructionTaskId': constructionTaskId,
    });
    ApiClient.throwIfError(response);
    // This endpoint returns a bare JSON array, not the usual envelope, so
    // ApiClient.parseBody (which casts to Map) cannot be used here.
    final decoded = jsonDecode(response.body);
    final list = decoded is List
        ? decoded
        : ((decoded as Map<String, dynamic>)['items'] as List<dynamic>? ?? []);
    return list
        .map((e) =>
            ConstructionMaterialResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Cost roll-up for a milestone: its own lines plus every child task.
  static Future<MaterialCostSummaryResponse> getCost(
    String constructionItemId,
  ) async {
    final response = await ApiClient.authGet(
      '/materials/cost/construction-items/$constructionItemId',
    );
    ApiClient.throwIfError(response);
    return MaterialCostSummaryResponse.fromJson(ApiClient.parseBody(response));
  }
}
