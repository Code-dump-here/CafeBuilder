import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _agreedToTerms = false;

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
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pushReplacementNamed(context, '/login'),
                    child: const Icon(Icons.arrow_back_ios, size: 20, color: AppColors.black),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Design Cafe',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: AppColors.appName,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please enter your email, password, or social account to continue.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 28),
              _buildLabel('Email Address'),
              const SizedBox(height: 4),
              _buildInputField(hint: 'Enter your Email Address'),
              const SizedBox(height: 20),
              _buildLabel('Phone Number'),
              const SizedBox(height: 4),
              _buildInputField(hint: 'Enter your User name'),
              const SizedBox(height: 20),
              _buildLabel('Password'),
              const SizedBox(height: 4),
              _buildPasswordField(
                hint: 'Enter your Password',
                obscure: _obscurePassword,
                onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              const SizedBox(height: 20),
              _buildLabel('Confirm Password'),
              const SizedBox(height: 4),
              _buildPasswordField(
                hint: 'Enter your Password',
                obscure: _obscureConfirm,
                onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
                    child: Container(
                      width: 15,
                      height: 15,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.black),
                        color: _agreedToTerms ? AppColors.primary : AppColors.white,
                      ),
                      child: _agreedToTerms
                          ? const Icon(Icons.check, size: 10, color: AppColors.white)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'I agree to the Terms of Service',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w300,
                      color: AppColors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
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
                  onPressed: () {},
                  child: Text(
                    'Sign Up',
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

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.black,
      ),
    );
  }

  Widget _buildInputField({required String hint}) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.inputBorder),
        borderRadius: BorderRadius.circular(40),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w300,
            color: AppColors.placeholder,
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.inputBorder),
        borderRadius: BorderRadius.circular(40),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        obscureText: obscure,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w300,
            color: AppColors.placeholder,
          ),
          suffixIcon: GestureDetector(
            onTap: onToggle,
            child: Icon(
              obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: AppColors.placeholder,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}
