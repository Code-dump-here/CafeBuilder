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

  static const String apiKey = 'AIzaSyB_ywXLHQcMRYFNhWcySUAZwYP9GtG6kFI';
  static const String appId = '1:629382907567:web:9bc61796064d8e33cb365a';
  // Project number — shared by every app in the project (from google-services.json).
  static const String messagingSenderId = '629382907567';
  static const String projectId = 'project-c9eeff73-5757-418b-b6a';
  static const String authDomain = 'project-c9eeff73-5757-418b-b6a.firebaseapp.com';
  static const String storageBucket = 'project-c9eeff73-5757-418b-b6a.firebasestorage.app';

  /// reCAPTCHA v3 site key for App Check on web. Register the web app under
  /// Firebase console → App Check to get one. Left empty, App Check is skipped,
  /// which is fine locally but leaves the endpoint unprotected in production.
  static const String recaptchaV3SiteKey = '';

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
