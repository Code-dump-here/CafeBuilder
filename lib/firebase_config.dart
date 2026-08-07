import 'package:firebase_core/firebase_core.dart';

/// Firebase **web** configuration.
///
/// Only web needs this. Android and iOS read their settings from the bundled
/// `android/app/google-services.json` and `GoogleService-Info.plist` at build
/// time, so the assistant works on those platforms without touching this file.
///
/// These values are identifiers, not secrets — they are meant to ship inside a
/// client app. The Gemini API key is never here: with Firebase AI Logic it stays
/// on Google's servers, and abuse is blocked by App Check.
///
/// To fill these in, either:
///   1. Firebase console → Project settings → Your apps → Web app → SDK setup
///      and copy the values across, or
///   2. run `flutterfire configure`, which generates `firebase_options.dart`
///      instead — then swap [options] for `DefaultFirebaseOptions.currentPlatform`.
///
/// Until [apiKey] and [appId] are set, Firebase is never initialised on web and
/// the AI assistant reports itself unavailable rather than crashing the app.
class FirebaseConfig {
  const FirebaseConfig._();

  static const String apiKey = 'AIzaSyCA8FqhF3ntzBYeIpy1IFOHMUggIXtW-VQ';
  static const String appId = '1:295284732683:web:80f7a160f1d5deb7dca80e';
  // Project number — shared by every app in the project (from google-services.json).
  static const String messagingSenderId = '295284732683';
  static const String projectId = 'project-d9f1553a-255e-41c1-961';
  static const String authDomain = 'project-d9f1553a-255e-41c1-961.firebaseapp.com';
  static const String storageBucket = 'project-d9f1553a-255e-41c1-961.firebasestorage.app';

  /// reCAPTCHA v3 site key for App Check on web. Register the web app under
  /// Firebase console → App Check to get one. Left empty, App Check is skipped,
  /// which is fine locally but leaves the endpoint unprotected in production.
  static const String recaptchaV3SiteKey = '6LcKzHktAAAAAJP-kQ9HhnrS8gE-_m7YHguy4MpV';

  static bool get isConfigured => apiKey.isNotEmpty && appId.isNotEmpty;

  static bool get hasAppCheck => recaptchaV3SiteKey.isNotEmpty;

  static FirebaseOptions get options => const FirebaseOptions(
        apiKey: apiKey,
        appId: appId,
        messagingSenderId: messagingSenderId,
        projectId: projectId,
        authDomain: authDomain,
        storageBucket: storageBucket,
      );
}
