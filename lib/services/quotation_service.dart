import '../models/responses/api_responses.dart';
import '../models/responses/quotation_responses.dart';
import 'api_client.dart';

class QuotationService {
  static Future<PaginationResponse<QuotationResponse>> getQuotations({
    int pageNumber = 1,
    int pageSize = 10,
    String? applyId,
    String? projectWorkingId,
    String? postId,
    String? status,
  }) async {
    final params = <String, dynamic>{
      'pageNumber': pageNumber,
      'pageSize': pageSize,
      if (applyId != null) 'applyId': applyId,
      if (projectWorkingId != null) 'projectWorkingId': projectWorkingId,
      if (postId != null) 'postId': postId,
      if (status != null) 'status': status,
    };

    final response = await ApiClient.authGet('/quotations', params);
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return PaginationResponse.fromJson(body, QuotationResponse.fromJson);
  }

  static Future<QuotationResponse> getQuotation(String id) async {
    final response = await ApiClient.authGet('/quotations/$id');
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return QuotationResponse.fromJson(body);
  }

  static Future<void> sendQuotation(String id) async {
    final response = await ApiClient.authPost('/quotations/$id/send', {});
    ApiClient.throwIfError(response);
  }

  static Future<void> acceptQuotation(String id) async {
    final response = await ApiClient.authPost('/quotations/$id/accept', {});
    ApiClient.throwIfError(response);
  }

  static Future<void> rejectQuotation(String id, {String? reason}) async {
    final response = await ApiClient.authPost('/quotations/$id/reject', {
      if (reason != null) 'reason': reason,
    });
    ApiClient.throwIfError(response);
  }

  static Future<void> requestRevision(String id, {required String note}) async {
    final response = await ApiClient.authPost('/quotations/$id/request-revision', {
      'note': note,
    });
    ApiClient.throwIfError(response);
  }
}
