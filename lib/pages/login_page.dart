import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _obscurePassword = true;
  bool _isLoading = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await AuthService.login(_emailController.text.trim(), _passwordController.text);
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connection failed. Is the server running?'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              // Minimal Navigation
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'CAFEBUILDER',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.espresso,
                      letterSpacing: 4.0,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 60),
              // Main content container
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Header
                    Text(
                      'Welcome Back',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 32,
                        fontWeight: FontWeight.normal,
                        color: AppColors.espresso,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Enter your credentials to access your studio.',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: AppColors.textSecondary.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 56),
                    // Login Form
                    _buildLabel('EMAIL ADDRESS'),
                    _buildUnderlinedInputField(hint: 'name@firm.com'),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildLabel('PASSWORD'),
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/forgot'),
                          child: Text(
                            'Forgot?',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    _buildUnderlinedPasswordField(),
                    const SizedBox(height: 48),
                    // Login Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.espresso,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        onPressed: _isLoading ? null : _login,
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'LOG IN',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 2.0,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 48),
                    // Social Auth
                    Row(
                      children: [
                        const Expanded(child: Divider(color: AppColors.outlineVariant, thickness: 0.5)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'OR CONNECT VIA',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.outline.withOpacity(0.5),
                              letterSpacing: 2.0,
                            ),
                          ),
                        ),
                        const Expanded(child: Divider(color: AppColors.outlineVariant, thickness: 0.5)),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildGoogleButton(),
                      ],
                    ),
                    const SizedBox(height: 64),
                    // Footer Link
                    Center(
                      child: RichText(
                        text: TextSpan(
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: AppColors.textSecondary.withOpacity(0.7),
                          ),
                          children: [
                            const TextSpan(text: 'New here? '),
                            WidgetSpan(
                              child: GestureDetector(
                                onTap: () => Navigator.pushNamed(context, '/register'),
                                child: Text(
                                  'Create an account',
                                  style: TextStyle(
                                    color: AppColors.espresso,
                                    fontWeight: FontWeight.w500,
                                    decoration: TextDecoration.underline,
                                    decorationThickness: 1,
                                    decorationColor: AppColors.espresso.withOpacity(0.3),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),
                    // Minimal Footer
                    Center(
                      child: Text(
                        '© 2024 CAFEBUILDER',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: AppColors.outline.withOpacity(0.4),
                          letterSpacing: 2.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.outline,
          letterSpacing: 2.0,
        ),
      ),
    );
  }

  Widget _buildUnderlinedInputField({required String hint}) {
    return TextField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      style: GoogleFonts.inter(color: AppColors.espresso, fontSize: 16),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: AppColors.outlineVariant, fontSize: 16),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.outlineVariant),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.espresso),
        ),
      ),
    );
  }

  Widget _buildUnderlinedPasswordField() {
    return TextField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      style: GoogleFonts.inter(color: AppColors.espresso, fontSize: 16),
      decoration: InputDecoration(
        hintText: '••••••••',
        hintStyle: GoogleFonts.inter(color: AppColors.outlineVariant, fontSize: 16),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.outlineVariant),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.espresso),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: AppColors.outline.withOpacity(0.6),
            size: 20,
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ),
    );
  }

  Widget _buildGoogleButton() {
    return GestureDetector(
      onTap: () {}, // TODO: Implement Google Sign In
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.network(
            'https://www.gstatic.com/images/branding/product/2x/googleg_96dp.png',
            height: 20,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.account_circle_outlined, size: 20, color: AppColors.espresso);
            },
          ),
          const SizedBox(width: 12),
          Text(
            'Google',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
