import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';

class SmsOtpPage extends StatefulWidget {
  const SmsOtpPage({super.key});

  @override
  State<SmsOtpPage> createState() => _SmsOtpPageState();
}

class _SmsOtpPageState extends State<SmsOtpPage> {
  // Six, because that is what the backend sends: OtpService builds a TOTP of
  // Otp:Length digits, which defaults to 6 and is not configured anywhere. The
  // four boxes came from the original Figma mock and survived the commit that
  // wired this screen up, so the code that arrived by e-mail never fit — and
  // the short code was still posted to /auth/reset-password, which counted it
  // as a failed attempt and disabled the request after five tries.
  static const _codeLength = 6;
  final _digitControllers = List.generate(
    _codeLength,
    (_) => TextEditingController(),
  );
  bool _isResending = false;

  String? get _email {
    final args = ModalRoute.of(context)?.settings.arguments;
    return args is Map ? args['email'] as String? : null;
  }

  @override
  void dispose() {
    for (final c in _digitControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _goBackToForgotPassword() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please start from the forgot password screen.'),
        backgroundColor: Colors.red,
      ),
    );
    Navigator.pushReplacementNamed(context, '/forgot');
  }

  // There is no standalone "verify OTP" endpoint for password reset — the
  // code is only actually validated when /auth/reset-password is called on
  // the next screen. This just checks the code is complete and carries it
  // forward alongside the email.
  void _verify() {
    final email = _email;
    if (email == null) {
      _goBackToForgotPassword();
      return;
    }
    final code = _digitControllers.map((c) => c.text).join();
    if (code.length != _codeLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter the full code.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    Navigator.pushReplacementNamed(
      context,
      '/sms-change-password',
      arguments: {'email': email, 'code': code},
    );
  }

  Future<void> _resend() async {
    final email = _email;
    if (email == null) {
      _goBackToForgotPassword();
      return;
    }
    setState(() => _isResending = true);
    try {
      await AuthService.forgotPassword(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('A new code has been sent.')),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connection failed. Is the server running?'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => Navigator.pushReplacementNamed(context, '/forgot'),
                child: const Icon(
                  Icons.arrow_back_ios,
                  size: 20,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'Design Cafe',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: AppColors.appName,
                    letterSpacing: -0.6,
                  ),
                ),
              ),
              const SizedBox(height: 48),
              Text(
                'Input your OTP',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(_codeLength, (i) => _buildOtpBox(i)),
              ),
              const SizedBox(height: 24),
              Center(
                child: GestureDetector(
                  onTap: _isResending ? null : _resend,
                  child: Text(
                    _isResending
                        ? 'Sending…'
                        : "Didn't receive the code? Resend",
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textPrimary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 49,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(36),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _verify,
                  child: Text(
                    'Verify',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Expanded rather than a fixed width: six 54px boxes plus the page's 36px
  // margins overflow anything narrower than about 400px, and four of them used
  // to fit with room to spare. Sharing the row out keeps them on one line on a
  // small phone as well.
  Widget _buildOtpBox(int index) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        height: 54,
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border.all(color: AppColors.outlineVariant),
          borderRadius: BorderRadius.circular(40),
        ),
        child: TextField(
          controller: _digitControllers[index],
          textAlign: TextAlign.center,
          maxLength: 1,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            border: InputBorder.none,
            counterText: '',
            contentPadding: EdgeInsets.zero,
          ),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          onChanged: (value) {
            if (value.isNotEmpty && index < _codeLength - 1) {
              FocusScope.of(context).nextFocus();
            } else if (value.isEmpty && index > 0) {
              // Backspacing out of a box lands in the previous one, as it
              // already does on the account verification screen.
              FocusScope.of(context).previousFocus();
            }
          },
        ),
      ),
    );
  }
}
