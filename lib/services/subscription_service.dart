import 'package:flutter/foundation.dart';
import 'local_store.dart';

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
