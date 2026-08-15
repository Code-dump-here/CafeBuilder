import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';

/// Post-registration email check.
///
/// This screen used to be decorative: the digit boxes had no controllers, so
/// nothing could read what was typed, and Confirm simply pushed `/home`. Any
/// code — or none — got you in. It now sends a real code and refuses to
/// continue until the server accepts it.
///
/// The email comes from the `email` route argument (pushed by
/// `role_selection_page` right after the account is created) and falls back to
/// the address stored at sign-in, so a resumed session still works.
class VerifyAccountPage extends StatefulWidget {
  const VerifyAccountPage({super.key});

  @override
  State<VerifyAccountPage> createState() => _VerifyAccountPageState();
}

class _VerifyAccountPageState extends State<VerifyAccountPage> {
  static const int _codeLength = 6;

  final List<TextEditingController> _controllers =
      List.generate(_codeLength, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(_codeLength, (_) => FocusNode());

  String? _email;
  bool _sending = false;
  bool _verifying = false;
  String? _error;
  bool _didRequestInitialCode = false;

  String get _code => _controllers.map((c) => c.text).join();
  bool get _isComplete => _code.length == _codeLength;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Route arguments aren't available in initState.
    if (_didRequestInitialCode) return;
    _didRequestInitialCode = true;
    _resolveEmailThenSend();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> _resolveEmailThenSend() async {
    final args = ModalRoute.of(context)?.settings.arguments;
    var email = (args is Map && args['email'] is String)
        ? args['email'] as String
        : null;
    email ??= await ApiClient.getEmail();

    if (!mounted) return;
    if (email == null || email.isEmpty) {
      // Without an address there is nothing to verify against; send the user
      // back rather than showing a form that can never succeed.
      setState(() => _error = 'Could not determine your email. Please sign in again.');
      return;
    }
    setState(() => _email = email);
    await _sendCode(silent: true);
  }

  Future<void> _sendCode({bool silent = false}) async {
    final email = _email;
    if (email == null || _sending) return;

    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await AuthService.sendAccountOtp(email);
      if (!mounted) return;
      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('A new code is on its way.')),
        );
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not send the code. Check your connection.');
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _confirm() async {
    final email = _email;
    if (email == null || _verifying) return;
    if (!_isComplete) {
      setState(() => _error = 'Enter all $_codeLength digits.');
      return;
    }

    setState(() {
      _verifying = true;
      _error = null;
    });
    try {
      await AuthService.verifyAccountOtp(email: email, code: _code);
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } on ApiException catch (e) {
      if (!mounted) return;
      // Server says the code is wrong or expired — clear it so the next
      // attempt starts from an empty field instead of a stale one.
      for (final c in _controllers) {
        c.clear();
      }
      _focusNodes.first.requestFocus();
      setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not verify the code. Check your connection.');
      }
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = _verifying || _sending;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.maybePop(context),
                    icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    color: AppColors.appName,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Onboarding',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.espresso,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 56),

              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.espresso,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.security_outlined,
                    color: AppColors.white,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              Center(
                child: Text(
                  'Verify Account',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.espresso,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    _email == null
                        ? 'Enter the $_codeLength-digit code we emailed you.'
                        : 'Enter the $_codeLength-digit code sent to $_email.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 48),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(_codeLength, _buildOtpBox),
              ),

              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.red),
                ),
              ],
              const SizedBox(height: 32),

              Center(
                child: TextButton(
                  onPressed: busy || _email == null ? null : () => _sendCode(),
                  child: Text(
                    _sending ? 'Sending…' : 'Resend code now',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.espresso,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 48),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.espresso,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  onPressed: busy || _email == null ? null : _confirm,
                  child: _verifying
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: AppColors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Confirm',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOtpBox(int index) {
    return Container(
      width: 45,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        maxLength: 1,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.espresso,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          counterText: '',
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < _codeLength - 1) {
            _focusNodes[index + 1].requestFocus();
          } else if (value.isEmpty && index > 0) {
            // Backspacing out of a box should land in the previous one.
            _focusNodes[index - 1].requestFocus();
          }
          // Refresh so Confirm enables as soon as the last digit lands.
          setState(() {});
        },
      ),
    );
  }
}
