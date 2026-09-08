import 'dart:convert';

import '../models/responses/payment_responses.dart';
import 'api_client.dart';

/// Platform-fee payments through payOS (`api/payments`).
///
/// The flow the API is built around, and the one the three subscription pages
/// follow:
///
///   1. `getPlans()` — what is on sale for this role.
///   2. `createSubscriptionPayment()` — a payOS link for the chosen plan.
///      Called with `platform: 'mobile'`, which is what decides the
///      return/cancel URLs baked into the link; a link created for `web` sends
///      the payer to the Next.js site instead of back to this app.
///   3. The user pays on the payOS page.
///   4. `pollStatus()` until `isFinal` — payOS confirms through the server's
///      webhook, so only the server knows the outcome. The app never marks
///      itself paid.
///   5. `getActiveSubscription()` to read the entitlement that resulted.
///
/// Not to be confused with [PaymentBatchService], which records owner→provider
/// instalments the platform never touches.
class PaymentService {
  /// Plans on sale, optionally narrowed to one role ('owner' | 'provider').
  ///
  /// The only anonymous endpoint here, but it goes through `authGet` like
  /// everything else — sending a token the server ignores costs nothing, and
  /// the pricing screen is behind login anyway.
  static Future<List<SubscriptionPlanResponse>> getPlans({
    String? targetRole,
  }) async {
    final response = await ApiClient.authGet(
      '/payments/plans',
      targetRole == null ? null : {'targetRole': targetRole},
    );
    ApiClient.throwIfError(response);
    final decoded = jsonDecode(response.body);
    // A bare array, not the paginated envelope the list endpoints use.
    final items = decoded is List
        ? decoded
        : (decoded is Map && decoded['items'] is List
            ? decoded['items'] as List
            : const []);
    return items
        .whereType<Map<String, dynamic>>()
        .map(SubscriptionPlanResponse.fromJson)
        .toList();
  }

  /// Opens a payOS checkout for [planId].
  ///
  /// Safe to call twice: the server reuses the account's pending link for the
  /// same plan and platform while it is still inside its expiry window rather
  /// than opening a second billable transaction.
  static Future<CreatePaymentResponse> createSubscriptionPayment({
    required String planId,
  }) async {
    final response = await ApiClient.authPost('/payments/subscriptions', {
      'planId': planId,
      'platform': 'mobile',
    });
    ApiClient.throwIfError(response);
    return CreatePaymentResponse.fromJson(ApiClient.parseBody(response));
  }

  /// One read of a transaction's state. Pass whichever handle you have.
  static Future<PaymentStatusResponse> getStatus({
    int? orderCode,
    String? paymentLinkId,
  }) async {
    final response = await ApiClient.authGet('/payments/status', {
      if (orderCode != null) 'orderCode': orderCode,
      if (paymentLinkId != null) 'paymentLinkId': paymentLinkId,
    });
    ApiClient.throwIfError(response);
    return PaymentStatusResponse.fromJson(ApiClient.parseBody(response));
  }

  /// Polls [getStatus] until the transaction settles or the attempts run out.
  ///
  /// Defaults cover five minutes, a little longer than payOS's 15-minute link
  /// but far past the point a payer is still watching the screen. Returns the
  /// last reading either way — a still-pending result is an answer ("we have
  /// not been told yet"), not a failure, so it is returned rather than thrown.
  ///
  /// [onPoll] fires on every reading so a screen can show progress.
  static Future<PaymentStatusResponse> pollStatus({
    int? orderCode,
    String? paymentLinkId,
    int intervalSeconds = 5,
    int maxAttempts = 60,
    void Function(PaymentStatusResponse status)? onPoll,
    bool Function()? shouldContinue,
  }) async {
    PaymentStatusResponse? last;
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      if (shouldContinue != null && !shouldContinue()) break;

      last = await getStatus(
        orderCode: orderCode,
        paymentLinkId: paymentLinkId,
      );
      onPoll?.call(last);
      if (last.isFinal) return last;

      await Future.delayed(Duration(seconds: intervalSeconds));
    }
    return last ??
        await getStatus(orderCode: orderCode, paymentLinkId: paymentLinkId);
  }

  /// Marks a pending transaction cancelled. Idempotent server-side, so the
  /// cancel screen can call it on arrival without checking first.
  static Future<PaymentStatusResponse> cancel(int orderCode) async {
    // orderCode is a query parameter on this endpoint, not a body field.
    final response =
        await ApiClient.authPost('/payments/cancel?orderCode=$orderCode', {});
    ApiClient.throwIfError(response);
    return PaymentStatusResponse.fromJson(ApiClient.parseBody(response));
  }

  /// The account's live plan, or null when it has none.
  ///
  /// The server answers `null` (a bare JSON `null` body) rather than 404 when
  /// nothing is active, so an empty body is a normal result here.
  static Future<SubscriptionResponse?> getActiveSubscription() async {
    final response = await ApiClient.authGet('/payments/subscriptions/me/active');
    ApiClient.throwIfError(response);
    if (response.body.trim().isEmpty) return null;
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) return null;
    return SubscriptionResponse.fromJson(decoded);
  }

  /// Every plan the account has ever bought, newest first per the server.
  static Future<List<SubscriptionResponse>> getSubscriptionHistory() async {
    final response = await ApiClient.authGet('/payments/subscriptions/me');
    ApiClient.throwIfError(response);
    final decoded = jsonDecode(response.body);
    final items = decoded is List ? decoded : const [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(SubscriptionResponse.fromJson)
        .toList();
  }
}
