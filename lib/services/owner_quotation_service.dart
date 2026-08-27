import '../models/responses/api_responses.dart';
import '../models/responses/quotation_payment_responses.dart';
import 'api_client.dart';

/// Quotations as the **owner's decision surface** — the comparison screen.
///
/// Separate from [QuotationService] on purpose, and the difference is the
/// model, not the endpoints: `quotation_responses.dart` (used by the details
/// screen) does not carry the fields the comparison is actually made on —
/// `version`, the provider's rating / years of experience / verified badge,
/// and instalments expressed as a percentage of the total. Those live in
/// `quotation_payment_responses.dart`, which mirrors what the API returns.
///
/// The consequential call is [accept]. It is not just a status change: for a
/// quotation attached to an application it also accepts that application,
/// opens the engagement, closes the post and supersedes the rival bids. There
/// is no separate "choose this provider" step — approving the bid *is* the
/// choice.
///
/// Writing a quotation is the provider's job, so there is no create/update/
/// send counterpart here: the server refuses them for an owner account.
class OwnerQuotationService {
  /// Every provider's bid on one post — the query the decision is made from.
  ///
  /// Page size is 50 rather than the API default of 10 because a bid set is
  /// read as a whole; a second page would hide a rival bid from the
  /// comparison. The server already scopes results to the signed-in account,
  /// so an owner only ever sees bids sent to their own projects.
  static Future<PaginationResponse<QuotationResponse>> getQuotationsForPost(
    String postId, {
    String? status,
    int pageNumber = 1,
    int pageSize = 50,
  }) async {
    final params = <String, dynamic>{
      'pageNumber': pageNumber,
      'pageSize': pageSize,
      'postId': postId,
      if (status != null) 'status': status,
    };
    final response = await ApiClient.authGet('/quotations', params);
    ApiClient.throwIfError(response);
    return PaginationResponse.fromJson(
      ApiClient.parseBody(response),
      QuotationResponse.fromJson,
    );
  }

  /// Approve a bid — and thereby choose its provider.
  ///
  /// The server answers with `AcceptQuotationResponse`, which wraps the
  /// quotation alongside the engagement it just opened. Only the quotation is
  /// unwrapped here; the screens that need the engagement refetch it.
  static Future<QuotationResponse> accept(String id) async {
    final response = await ApiClient.authPost('/quotations/$id/accept', {});
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    return QuotationResponse.fromJson(
      (body['quotation'] as Map<String, dynamic>?) ?? body,
    );
  }

  /// Turn a bid down for good. [reason] is optional server-side but is the
  /// only feedback the provider gets, so the UI should ask for one.
  static Future<QuotationResponse> reject(String id, {String? reason}) async {
    final response = await ApiClient.authPost('/quotations/$id/reject', {
      if (reason != null && reason.isNotEmpty) 'reason': reason,
    });
    ApiClient.throwIfError(response);
    return QuotationResponse.fromJson(ApiClient.parseBody(response));
  }

  /// Ask the provider for a different version.
  ///
  /// The body key is `reason`, not `note`: the endpoint binds
  /// `RespondQuotationRequest`, and it *rejects the call with 400* when the
  /// reason is missing — unlike [reject], where the server accepts an empty
  /// one.
  static Future<QuotationResponse> requestRevision(
    String id, {
    required String reason,
  }) async {
    final response = await ApiClient.authPost(
      '/quotations/$id/request-revision',
      {'reason': reason},
    );
    ApiClient.throwIfError(response);
    return QuotationResponse.fromJson(ApiClient.parseBody(response));
  }
}
