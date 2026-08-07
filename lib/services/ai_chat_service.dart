import 'dart:developer' as dev;

import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../firebase_config.dart';

/// Conversational AI assistant backed by Firebase AI Logic.
///
/// Firebase AI Logic proxies Gemini on Google's side, so no Gemini API key ever
/// reaches the client and there is no server of our own to run. Requests are
/// authorised by App Check when a site key is configured.
class AiChatService {
  const AiChatService._();

  /// Gemini model used for the assistant.
  static const String modelName = 'gemini-3.6-flash';

  static const String _systemPrompt =
      'You are the design assistant inside Design Cafe, an app where cafe owners '
      'plan and build out their coffee shops with designers and constructors. '
      'Give practical, specific advice on cafe interior design, layout, customer '
      'flow, barista workflow, lighting, materials, budgeting and working with '
      'providers. Prefer concrete numbers and trade-offs over generic tips. Keep '
      'answers concise — a few short paragraphs or a tight list. If a question '
      'needs details you do not have (budget, floor area, location, style), ask '
      'one focused follow-up rather than guessing. You cannot see the user\'s '
      'project data, place orders, or contact providers on their behalf; when '
      'something requires that, tell them which part of the app to use.';

  static bool _ready = false;
  static String? _initError;

  /// Whether the assistant can actually be used. False when Firebase has not
  /// been configured yet — see [FirebaseConfig].
  static bool get isAvailable => _ready;

  /// Why initialisation failed, if it did. Null when unconfigured (nothing was
  /// attempted) or when startup succeeded.
  static String? get initError => _initError;

  /// Initialises Firebase and App Check. Safe to call when unconfigured: it
  /// simply leaves the assistant unavailable instead of throwing, so the rest
  /// of the app is unaffected.
  ///
  /// Android and iOS read their settings from the bundled `google-services.json`
  /// / `GoogleService-Info.plist` at build time, so they need nothing from
  /// [FirebaseConfig]. Only web requires options to be supplied explicitly.
  static Future<void> init() async {
    if (kIsWeb && !FirebaseConfig.isConfigured) {
      dev.log(
        'Firebase web config missing — AI assistant disabled on web. '
        'Fill in lib/firebase_config.dart to enable it.',
        name: 'AiChatService',
      );
      return;
    }

    try {
      await Firebase.initializeApp(
        options: kIsWeb ? FirebaseConfig.options : null,
      );
      await _activateAppCheck();
      _ready = true;
    } catch (e) {
      _ready = false;
      _initError = e.toString();
      dev.log('Firebase init failed — AI assistant disabled: $e', name: 'AiChatService');
    }
  }

  /// App Check attests that requests come from a genuine build of this app.
  /// A failure here shouldn't disable the assistant outright — enforcement is
  /// the backend's decision, so we log and carry on.
  static Future<void> _activateAppCheck() async {
    try {
      if (kIsWeb) {
        if (!FirebaseConfig.hasAppCheck) {
          dev.log('No reCAPTCHA site key — App Check skipped on web.', name: 'AiChatService');
          return;
        }
        await FirebaseAppCheck.instance.activate(
          providerWeb: ReCaptchaV3Provider(FirebaseConfig.recaptchaV3SiteKey),
        );
      } else {
        // Defaults: Play Integrity on Android, DeviceCheck on Apple.
        await FirebaseAppCheck.instance.activate();
      }
    } catch (e) {
      dev.log('App Check activation failed: $e', name: 'AiChatService');
    }
  }

  /// Opens a new multi-turn conversation. Throws [StateError] if the assistant
  /// is unavailable — check [isAvailable] first.
  static AiChatSession startSession() {
    if (!_ready) {
      throw StateError('AI assistant is not configured');
    }
    // agentPlatform() (the successor to vertexAI()) bills through the project's
    // Google Cloud account (Blaze), rather than the Gemini Developer API's
    // separate prepay credits. Defaults to the "global" location.
    final model = FirebaseAI.agentPlatform().generativeModel(
      model: modelName,
      systemInstruction: Content.system(_systemPrompt),
    );
    return AiChatSession._(model.startChat());
  }
}

/// A single conversation. The SDK keeps turn history internally, so callers
/// only need to send the new message each time.
class AiChatSession {
  final ChatSession _chat;

  AiChatSession._(this._chat);

  /// Sends [message] and returns the assistant's reply.
  Future<String> send(String message) async {
    final response = await _chat.sendMessage(Content.text(message));
    final text = response.text?.trim();
    if (text == null || text.isEmpty) {
      throw const AiChatException('The assistant returned an empty response.');
    }
    return text;
  }
}

class AiChatException implements Exception {
  final String message;
  const AiChatException(this.message);

  @override
  String toString() => message;
}
