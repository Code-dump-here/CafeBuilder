import '../models/responses/api_responses.dart';
import '../models/responses/quotation_payment_responses.dart';
import 'api_client.dart';

/// Quotations (review 3) — the owner side.
///
/// This is the artefact that replaced a single free-text `Apply.proposal`: a
/// provider's bid with priced line items, a duration and the instalment
/// schedule the contract will be built from. The owner reads several of these
/// side by side and approves one.
///
/// The consequential call is [accept]. It is not just a status change: for a
/// quotation attached to an application it also accepts that application,
/// opens the engagement, closes the post and drops the rival bids. There is no
/// separate "choose this provider" step, which is exactly the flow the review
/// board asked for.
///
/// Writing a quotation is the provider's job, so [create]/[update]/[send] have
/// no counterpart here — the server refuses them for an owner account.
class QuotationService {
  /// Bids to compare.
  ///
  /// Pass [postId] for the comparison view: every provider's quotation on one
  /// post, which is the query the decision is actually made from. The server
  /// already scopes results to the signed-in account, so an owner only ever
  /// sees quotations sent to their own projects.
  ///
  /// Page size is 50 rather than the API default of 10 — a bid set is read as
  /// a whole, and a second page would hide a rival bid from the comparison.
  static Future<PaginationResponse<QuotationResponse>> getQuotations({
    String? postId,
    String? applyId,
    String? projectWorkingId,
    String? status,
    int pageNumber = 1,
    int pageSize = 50,
  }) async {
    final params = <String, dynamic>{
      'pageNumber': pageNumber,
      'pageSize': pageSize,
      if (postId != null) 'postId': postId,
      if (applyId != null) 'applyId': applyId,
      if (projectWorkingId != null) 'projectWorkingId': projectWorkingId,
      if (status != null) 'status': status,
    };
    final response = await ApiClient.authGet('/quotations', params);
    ApiClient.throwIfError(response);
    return PaginationResponse.fromJson(
      ApiClient.parseBody(response),
      QuotationResponse.fromJson,
    );
  }

  /// One quotation with its line items, schedule and attachments.
  static Future<QuotationResponse> getById(String id) async {
    final response = await ApiClient.authGet('/quotations/$id');
    ApiClient.throwIfError(response);
    return QuotationResponse.fromJson(ApiClient.parseBody(response));
  }

  /// Approve a bid — and thereby choose its provider.
  ///
  /// For an application-anchored quotation the response carries the engagement
  /// that was just opened; for a directly-hired provider one already existed
  /// and `engagement` comes back null.
  ///
  /// Owner role only: the server does not let an admin approve on the owner's
  /// behalf, because this commits the owner's money.
  static Future<QuotationResponse> accept(String id) async {
    final response = await ApiClient.authPost('/quotations/$id/accept', {});
    ApiClient.throwIfError(response);
    final body = ApiClient.parseBody(response);
    // AcceptQuotationResponse wraps the quotation alongside the engagement.
    // The engagement is refetched by the screens that care, so only the
    // quotation is unwrapped here.
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
  /// Unlike [reject], the reason is **required** by the server — a revision
  /// request with nothing in it gives the provider nothing to change.
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
