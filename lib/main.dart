import 'package:flutter/material.dart';
import 'pages/splash_screen.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/forgot_password_page.dart';
import 'pages/sms_otp_page.dart';
import 'pages/sms_change_password_page.dart';
import 'pages/success_page.dart';
import 'pages/role_selection_page.dart';
import 'pages/profile_setup_page.dart';
import 'pages/verify_account_page.dart';
import 'widgets/page_navigator.dart';

void main() {
  runApp(const CafeBuilderApp());
}

class CafeBuilderApp extends StatelessWidget {
  const CafeBuilderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Design Cafe',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF9E896A)),
        useMaterial3: true,
      ),
      home: const PageNavigatorWrapper(child: SplashScreen()),
      routes: {
        '/splash': (context) => const PageNavigatorWrapper(child: SplashScreen()),
        '/login': (context) => const PageNavigatorWrapper(child: LoginPage()),
        '/register': (context) => const PageNavigatorWrapper(child: RegisterPage()),
        '/forgot': (context) => const PageNavigatorWrapper(child: ForgotPasswordPage()),
        '/sms-otp': (context) => const PageNavigatorWrapper(child: SmsOtpPage()),
        '/sms-change-password': (context) =>
            const PageNavigatorWrapper(child: SmsChangePasswordPage()),
        '/success': (context) => const PageNavigatorWrapper(child: SuccessPage()),
        '/role-selection': (context) => const PageNavigatorWrapper(child: RoleSelectionPage()),
        '/profile-setup': (context) => const PageNavigatorWrapper(child: ProfileSetupPage()),
        '/verify-account': (context) => const PageNavigatorWrapper(child: VerifyAccountPage()),
      },
    );
  }
}
