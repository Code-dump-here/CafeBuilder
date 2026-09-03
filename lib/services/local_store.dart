import 'package:shared_preferences/shared_preferences.dart';

/// Somewhere small and durable to keep a cache between runs.
///
/// An interface rather than a direct call to `shared_preferences` so the caches
/// can be tested against a fake — persistence is precisely the part whose bugs
/// only show up days later, which is exactly the part that has to be testable
/// without a device and without waiting days.
abstract interface class LocalStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> remove(String key);
}

/// The real one. localStorage on web, SharedPreferences on Android, a plist on
/// iOS — all of them fine for the hundred kilobytes or so these caches hold.
class SharedPreferencesStore implements LocalStore {
  const SharedPreferencesStore();

  @override
  Future<String?> read(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    } catch (_) {
      // A cache that cannot be read is a cache that starts empty. Never a
      // reason to fail the screen that wanted it.
      return null;
    }
  }

  @override
  Future<void> write(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } catch (_) {
      // Likewise: losing a saved cache costs a few requests next time, and
      // nothing else.
    }
  }

  @override
  Future<void> remove(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    } catch (_) {}
  }
}
