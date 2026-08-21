import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'pages/splash_screen.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/forgot_password_page.dart';
import 'pages/sms_otp_page.dart';
import 'pages/sms_change_password_page.dart';
import 'pages/success_page.dart';
import 'pages/verify_account_page.dart';
import 'pages/home_page.dart';
import 'pages/project_onboarding_page.dart';
import 'pages/package_details_page.dart';
import 'pages/element_details_page.dart';
import 'pages/chat_page.dart';
import 'pages/collaboration_workspace_page.dart';
import 'services/api_client.dart';
import 'services/ai_chat_service.dart';

/// Bypass SSL certificate verification in debug builds.
/// Remove or gate behind !kReleaseMode before publishing to production.
class _DevHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (cert, host, port) => true;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _DevHttpOverrides();

  // Paint the first frame before touching Firebase.
  //
  // This used to `await AiChatService.init()` here. That call reaches out to
  // Firebase and, on web, to the reCAPTCHA endpoint for App Check — so any
  // stall in that handshake left `runApp` unreached and the app on a blank
  // white page indefinitely, with nothing logged to explain it. A try/catch
  // doesn't help: a hang isn't a failure.
  //
  // The assistant is optional and already reports its own readiness through
  // `AiChatService.isAvailable`, so it can finish arriving after the UI is up.
  runApp(const CafeBuilderApp());
  unawaited(AiChatService.init());
}

class CafeBuilderApp extends StatelessWidget {
  const CafeBuilderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Design Cafe',
      debugShowCheckedModeBanner: false,
      navigatorKey: ApiClient.navigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF9E896A)),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/forgot': (context) => const ForgotPasswordPage(),
        '/sms-otp': (context) => const SmsOtpPage(),
        '/sms-change-password': (context) =>
            const SmsChangePasswordPage(),
        '/success': (context) => const SuccessPage(),
        '/verify-account': (context) => const VerifyAccountPage(),
        '/home': (context) => const HomePage(),
        '/project-onboarding': (context) => const ProjectOnboardingPage(),
        '/package-details': (context) => const PackageDetailsPage(),
        '/element-details': (context) => const ElementDetailsPage(),
        '/chat': (context) => const ChatPage(),
        '/collab-workspace': (context) => const CollaborationWorkspacePage(),
      },
    );
  }
}
