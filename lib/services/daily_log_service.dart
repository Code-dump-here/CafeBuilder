import '../models/responses/api_responses.dart';
import '../models/responses/quotation_payment_responses.dart';
import 'api_client.dart';

/// Daily construction log (review 3) — the owner side, read-only.
///
/// The provider files a report per working day with site photos; the owner
/// follows progress without driving out. Writing requires an `accepted`
/// engagement and a provider account, so this app only reads: there is no
/// create/update/delete counterpart here by design.
///
/// Reading is deliberately open at every engagement status server-side, so the
/// log stays consultable after handover — which is usually when someone needs
/// to check what happened on a particular day.
class DailyLogService {
  /// Reports for an engagement, a milestone or a task — newest day first.
  ///
  /// [fromDate] / [toDate] are `yyyy-MM-dd` and are how a week or a month is
  /// pulled up. Pass a [constructionItemId] to read the diary of one milestone
  /// rather than the whole job.
  static Future<PaginationResponse<DailyLogResponse>> getLogs({
    String? projectWorkingId,
    String? constructionItemId,
    String? constructionTaskId,
    String? fromDate,
    String? toDate,
    int pageNumber = 1,
    int pageSize = 30,
  }) async {
    final params = <String, dynamic>{
      'pageNumber': pageNumber,
      'pageSize': pageSize,
      if (projectWorkingId != null) 'projectWorkingId': projectWorkingId,
      if (constructionItemId != null) 'constructionItemId': constructionItemId,
      if (constructionTaskId != null) 'constructionTaskId': constructionTaskId,
      if (fromDate != null) 'fromDate': fromDate,
      if (toDate != null) 'toDate': toDate,
    };
    final response = await ApiClient.authGet('/daily-logs', params);
    ApiClient.throwIfError(response);
    return PaginationResponse.fromJson(
      ApiClient.parseBody(response),
      DailyLogResponse.fromJson,
    );
  }

  static Future<DailyLogResponse> getById(String id) async {
    final response = await ApiClient.authGet('/daily-logs/$id');
    ApiClient.throwIfError(response);
    return DailyLogResponse.fromJson(ApiClient.parseBody(response));
  }
}
