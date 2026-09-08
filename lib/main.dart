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
import 'pages/subscription_checkout_page.dart';
import 'pages/subscription_return_page.dart';
import 'pages/subscription_cancel_page.dart';
import 'services/api_client.dart';
import 'services/ai_chat_service.dart';
import 'services/subscription_service.dart';

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

  await SubscriptionService.init();

  runApp(const CafeBuilderApp());
  unawaited(AiChatService.init());
  // The cached flag paints the gated screens immediately; this corrects it
  // against `GET /payments/subscriptions/me/active` a moment later. No-ops
  // when signed out.
  unawaited(SubscriptionService.refreshFromServer());
}

/// The two URLs payOS redirects a mobile payer to when the transaction ends.
///
/// They are configured server-side (`PayOs:MobileReturnUrl` /
/// `PayOs:MobileCancelUrl`) and point at this app's web build with the
/// transaction appended: `/#/payment/success?orderCode=1788...`. The `routes`
/// table cannot express that — a route name arriving with a query string
/// matches nothing — so these are resolved here, where the query can be parsed
/// and the order code handed to the page that reads its status.
Route<dynamic>? _payOsRoute(RouteSettings settings) {
  final uri = Uri.tryParse(settings.name ?? '');
  if (uri == null) return null;

  final orderCode = int.tryParse(uri.queryParameters['orderCode'] ?? '') ??
      // The checkout screen pushes these pages directly, but a named push
      // elsewhere can still pass the code as an argument.
      (settings.arguments is int ? settings.arguments as int : null);

  switch (uri.path) {
    case '/payment/success':
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => SubscriptionReturnPage(orderCode: orderCode),
      );
    case '/payment/cancel':
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => SubscriptionCancelPage(orderCode: orderCode),
      );
    default:
      // Anything else falls through to `routes`.
      return null;
  }
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
        '/subscription-checkout': (context) => const SubscriptionCheckoutPage(),
        '/subscription-return': (context) => const SubscriptionReturnPage(),
        '/subscription-cancel': (context) => const SubscriptionCancelPage(),
      },
      onGenerateRoute: _payOsRoute,
    );
  }
}

