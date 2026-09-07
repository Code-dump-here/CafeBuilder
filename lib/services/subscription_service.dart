import 'package:flutter/foundation.dart';
import '../models/responses/payment_responses.dart';
import 'api_client.dart';
import 'local_store.dart';
import 'payment_service.dart';

/// Whether this account has a live platform plan, and the cached copy of that
/// answer.
///
/// The server owns the truth — a plan only becomes active when payOS confirms
/// the payment through the webhook. What is stored on the device is a cache so
/// the gated screens can paint before the network answers; every entry point
/// that matters calls [refreshFromServer] and overwrites it.
class SubscriptionService {
  static const String _keyIsSubscribed = 'app_user_is_subscribed';
  static const String _keyPlanName = 'app_user_subscription_plan';
  static const String _keySubscribedAt = 'app_user_subscribed_at';

  static final LocalStore _store = const SharedPreferencesStore();
  
  /// Global notifier for subscription status updates across the app.
  static final ValueNotifier<bool> isSubscribedNotifier = ValueNotifier<bool>(false);

  /// Initialize and load saved subscription status from disk.
  static Future<void> init() async {
    final statusStr = await _store.read(_keyIsSubscribed);
    final status = statusStr == 'true';
    isSubscribedNotifier.value = status;
  }

  /// Re-reads the entitlement from `GET /payments/subscriptions/me/active` and
  /// updates the cache.
  ///
  /// Returns the live subscription, or null when the account has none. Network
  /// and auth failures are swallowed deliberately: this is called on screens
  /// whose job is something else, and losing the blur on a locked image is a
  /// far worse failure mode than showing yesterday's cached answer, so a
  /// failed refresh leaves the cache exactly as it was.
  static Future<SubscriptionResponse?> refreshFromServer() async {
    // Signed out: skip the call entirely. A 401 here would run ApiClient's
    // refresh-token path and, on failure, bounce the app to /login — which is
    // the wrong outcome for a background entitlement check on the splash.
    if (await ApiClient.getAccessToken() == null) return null;

    try {
      final active = await PaymentService.getActiveSubscription();
      final live = active?.isLive ?? false;
      await setSubscribed(
        live,
        planName: active?.planName ?? 'Gói Pro 3D Visual',
      );
      return live ? active : null;
    } catch (e) {
      debugPrint('[SubscriptionService] refresh failed: $e');
      return null;
    }
  }

  /// Current subscription status.
  static bool get isSubscribed => isSubscribedNotifier.value;

  /// Set subscription state and persist it.
  static Future<void> setSubscribed(bool value, {String planName = 'Pro 3D Layout Package'}) async {
    isSubscribedNotifier.value = value;
    await _store.write(_keyIsSubscribed, value ? 'true' : 'false');
    if (value) {
      await _store.write(_keyPlanName, planName);
      await _store.write(_keySubscribedAt, DateTime.now().toIso8601String());
    } else {
      await _store.remove(_keyPlanName);
      await _store.remove(_keySubscribedAt);
    }
  }

  /// Toggle subscription status (convenient for testing/debugging).
  static Future<void> toggleSubscription() async {
    await setSubscribed(!isSubscribed);
  }

  /// Get active plan name.
  static Future<String> getPlanName() async {
    return await _store.read(_keyPlanName) ?? 'Gói Pro 3D Visual';
  }

  /// Get activation timestamp string.
  static Future<String?> getSubscribedAt() async {
    return await _store.read(_keySubscribedAt);
  }
}
