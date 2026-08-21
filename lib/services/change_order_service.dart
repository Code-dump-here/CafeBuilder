import '../models/responses/api_responses.dart';
import '../models/responses/change_order_responses.dart';
import 'api_client.dart';

/// Change orders — money agreed after the contract.
///
/// The owner's side of the handshake. They can raise one, and they answer the
/// ones the provider raises; what they cannot do is approve their own, which
/// the server refuses with a 401. That is why [accept] and [reject] are only
/// ever offered against a provider-raised charge.
class ChangeOrderService {
  static Future<PaginationResponse<ChangeOrderResponse>> getAll({
    required String projectWorkingId,
    String? status,
    int pageNumber = 1,
    int pageSize = 50,
  }) async {
    final response = await ApiClient.authGet('/change-orders', {
      'projectWorkingId': projectWorkingId,
      if (status != null) 'status': status,
      'pageNumber': pageNumber,
      'pageSize': pageSize,
    });
    ApiClient.throwIfError(response);
    return PaginationResponse.fromJson(
      ApiClient.parseBody(response),
      ChangeOrderResponse.fromJson,
    );
  }

  /// Contract value plus everything accepted since.
  static Future<ChangeOrderSummaryResponse> getSummary(
    String projectWorkingId,
  ) async {
    final response = await ApiClient.authGet('/change-orders/summary', {
      'projectWorkingId': projectWorkingId,
    });
    ApiClient.throwIfError(response);
    return ChangeOrderSummaryResponse.fromJson(ApiClient.parseBody(response));
  }

  /// How many free revision rounds a design has left.
  ///
  /// Worth calling before offering "request changes" on a design: it says
  /// whether the next round is free, and if not, what it will cost.
  static Future<RevisionQuotaResponse> getRevisionQuota(String designId) async {
    final response =
        await ApiClient.authGet('/change-orders/revision-quota/$designId');
    ApiClient.throwIfError(response);
    return RevisionQuotaResponse.fromJson(ApiClient.parseBody(response));
  }

  static Future<ChangeOrderResponse> create({
    required String projectWorkingId,
    required String kind,
    required String title,
    required String reason,
    required double amount,
    String? designId,
    String? constructionItemId,
  }) async {
    final response = await ApiClient.authPost('/change-orders', {
      'projectWorkingId': projectWorkingId,
      'kind': kind,
      'title': title,
      'reason': reason,
      'amount': amount,
      if (designId != null) 'designId': designId,
      if (constructionItemId != null) 'constructionItemId': constructionItemId,
    });
    ApiClient.throwIfError(response);
    return ChangeOrderResponse.fromJson(ApiClient.parseBody(response));
  }

  /// Accept a charge the provider raised. Refused for one the owner raised.
  static Future<ChangeOrderResponse> accept(String id) async {
    final response = await ApiClient.authPost('/change-orders/$id/accept', {});
    ApiClient.throwIfError(response);
    return ChangeOrderResponse.fromJson(ApiClient.parseBody(response));
  }

  /// Reject it. The reason is required — it is all the provider gets back.
  static Future<ChangeOrderResponse> reject(
    String id, {
    required String rejectReason,
  }) async {
    final response = await ApiClient.authPost('/change-orders/$id/reject', {
      'rejectReason': rejectReason,
    });
    ApiClient.throwIfError(response);
    return ChangeOrderResponse.fromJson(ApiClient.parseBody(response));
  }

  /// Withdraw one the owner raised, while it is still pending. An answered
  /// charge is the record of a decision and the server will not remove it.
  static Future<void> withdraw(String id) async {
    final response = await ApiClient.authDelete('/change-orders/$id');
    ApiClient.throwIfError(response);
  }
}
