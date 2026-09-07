/// Response models for the payOS platform-fee flow (`api/payments`).
///
/// Separate from `quotation_payment_responses.dart` on purpose: that file is
/// the owner→provider instalment ledger, where the platform holds no money and
/// only records what the two sides transferred between themselves. This file
/// is the other kind of payment entirely — real money the owner pays *to the
/// platform* for a subscription, moved by payOS.
///
/// Enums are serialised by `System.Text.Json` with no converter registered on
/// the API (`AddControllers()` in `Program.cs` takes the defaults), so they
/// arrive as **ordinals**, not names. Every enum here is parsed from an int
/// against the C# declaration order and still accepts a name, so the models
/// survive a `JsonStringEnumConverter` being added later.
library;

DateTime? _parseNullableDate(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

DateTime _parseDate(dynamic value) =>
    DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();

double _parseAmount(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}

/// Reads an enum sent either as its ordinal or as its name.
String _parseEnum(dynamic value, List<String> names, String fallback) {
  if (value == null) return fallback;
  if (value is num) {
    final index = value.toInt();
    return index >= 0 && index < names.length ? names[index] : fallback;
  }
  final text = value.toString();
  return names.contains(text) ? text : fallback;
}

/// `PaymentTransactionStatus { pending, paid, cancelled, failed }`.
const _transactionStatuses = ['pending', 'paid', 'cancelled', 'failed'];

/// `SubscriptionStatus { pending, active, expired, cancelled }`.
const _subscriptionStatuses = ['pending', 'active', 'expired', 'cancelled'];

/// `PaymentPurpose { subscription, post_boost }`.
const _purposes = ['subscription', 'post_boost'];

/// `AccountRole { owner, provider, admin }`.
const _accountRoles = ['owner', 'provider', 'admin'];

// ── Plans ────────────────────────────────────────────────────────────────────

/// One purchasable platform-fee plan. `GET /payments/plans` is anonymous.
class SubscriptionPlanResponse {
  final String id;
  final String name;
  final String? description;

  /// 'owner' | 'provider' | 'admin' — a plan is only sold to its own role.
  final String targetRole;
  final double price;
  final int durationInDays;

  SubscriptionPlanResponse({
    required this.id,
    required this.name,
    this.description,
    required this.targetRole,
    required this.price,
    required this.durationInDays,
  });

  factory SubscriptionPlanResponse.fromJson(Map<String, dynamic> json) =>
      SubscriptionPlanResponse(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        description: json['description']?.toString(),
        targetRole: _parseEnum(json['targetRole'], _accountRoles, 'owner'),
        price: _parseAmount(json['price']),
        durationInDays: (json['durationInDays'] as num?)?.toInt() ?? 0,
      );
}

// ── Creating a payment link ──────────────────────────────────────────────────

/// What `POST /payments/subscriptions` hands back: a live payOS checkout link.
///
/// [orderCode] is the handle for everything afterwards — status polling and
/// cancellation both key off it, and payOS puts it in the query string of the
/// return/cancel URL it redirects to.
class CreatePaymentResponse {
  /// 'subscription' | 'post_boost'.
  final String purpose;
  final String? subscriptionId;
  final String? postId;
  final int orderCode;
  final String paymentLinkId;

  /// The payOS-hosted page to open. It carries the real VietQR code, the bank
  /// details and the transfer content — none of that is ours to render.
  final String checkoutUrl;

  /// Raw VietQR payload string. Only useful with a QR renderer; the app opens
  /// [checkoutUrl] instead, so this is carried but unused.
  final String qrCode;
  final double amount;

  /// payOS link expiry, as **seconds** since epoch (not milliseconds).
  final int expiredAt;

  CreatePaymentResponse({
    required this.purpose,
    this.subscriptionId,
    this.postId,
    required this.orderCode,
    required this.paymentLinkId,
    required this.checkoutUrl,
    required this.qrCode,
    required this.amount,
    required this.expiredAt,
  });

  DateTime get expiresAt =>
      DateTime.fromMillisecondsSinceEpoch(expiredAt * 1000, isUtc: true)
          .toLocal();

  factory CreatePaymentResponse.fromJson(Map<String, dynamic> json) =>
      CreatePaymentResponse(
        purpose: _parseEnum(json['purpose'], _purposes, 'subscription'),
        subscriptionId: json['subscriptionId']?.toString(),
        postId: json['postId']?.toString(),
        orderCode: (json['orderCode'] as num?)?.toInt() ?? 0,
        paymentLinkId: json['paymentLinkId']?.toString() ?? '',
        checkoutUrl: json['checkoutUrl']?.toString() ?? '',
        qrCode: json['qrCode']?.toString() ?? '',
        amount: _parseAmount(json['amount']),
        expiredAt: (json['expiredAt'] as num?)?.toInt() ?? 0,
      );
}

// ── Status polling ───────────────────────────────────────────────────────────

/// `GET /payments/status` — what the app polls after coming back from payOS.
///
/// The webhook is what actually settles a transaction, so the app must never
/// decide on its own that a payment succeeded: it asks until [isFinal].
class PaymentStatusResponse {
  final bool success;

  /// True once the transaction is paid, cancelled or failed — stop polling.
  final bool isFinal;

  /// 'pending' | 'paid' | 'cancelled' | 'failed'.
  final String status;

  /// 'subscription' | 'post_boost'.
  final String purpose;
  final int orderCode;
  final String paymentLinkId;
  final String? subscriptionId;

  /// 'pending' | 'active' | 'expired' | 'cancelled', when this is a plan.
  final String? subscriptionStatus;
  final String? postId;
  final DateTime? postBoostedUntil;
  final double amount;
  final String message;

  PaymentStatusResponse({
    required this.success,
    required this.isFinal,
    required this.status,
    required this.purpose,
    required this.orderCode,
    required this.paymentLinkId,
    this.subscriptionId,
    this.subscriptionStatus,
    this.postId,
    this.postBoostedUntil,
    required this.amount,
    required this.message,
  });

  bool get isPaid => status == 'paid';
  bool get isCancelled => status == 'cancelled';

  factory PaymentStatusResponse.fromJson(Map<String, dynamic> json) =>
      PaymentStatusResponse(
        success: json['success'] == true,
        isFinal: json['isFinal'] == true,
        status: _parseEnum(json['status'], _transactionStatuses, 'pending'),
        purpose: _parseEnum(json['purpose'], _purposes, 'subscription'),
        orderCode: (json['orderCode'] as num?)?.toInt() ?? 0,
        paymentLinkId: json['paymentLinkId']?.toString() ?? '',
        subscriptionId: json['subscriptionId']?.toString(),
        subscriptionStatus: json['subscriptionStatus'] == null
            ? null
            : _parseEnum(
                json['subscriptionStatus'], _subscriptionStatuses, 'pending'),
        postId: json['postId']?.toString(),
        postBoostedUntil: _parseNullableDate(json['postBoostedUntil']),
        amount: _parseAmount(json['amount']),
        message: json['message']?.toString() ?? '',
      );
}

// ── The subscription itself ──────────────────────────────────────────────────

/// A plan the account has bought. `GET /payments/subscriptions/me/active`
/// returns the live one, or null when there is none.
class SubscriptionResponse {
  final String id;
  final String accountId;
  final String planId;
  final String planName;

  /// 'pending' | 'active' | 'expired' | 'cancelled'.
  final String status;
  final DateTime startDate;
  final DateTime endDate;
  final double paidAmount;

  SubscriptionResponse({
    required this.id,
    required this.accountId,
    required this.planId,
    required this.planName,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.paidAmount,
  });

  /// Both halves matter: the server returns the active row, but a client whose
  /// clock has rolled past `endDate` should not keep showing paid features.
  bool get isLive => status == 'active' && endDate.isAfter(DateTime.now());

  factory SubscriptionResponse.fromJson(Map<String, dynamic> json) =>
      SubscriptionResponse(
        id: json['id']?.toString() ?? '',
        accountId: json['accountId']?.toString() ?? '',
        planId: json['planId']?.toString() ?? '',
        planName: json['planName']?.toString() ?? '',
        status: _parseEnum(json['status'], _subscriptionStatuses, 'pending'),
        startDate: _parseDate(json['startDate']),
        endDate: _parseDate(json['endDate']),
        paidAmount: _parseAmount(json['paidAmount']),
      );
}
