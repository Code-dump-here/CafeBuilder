import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class VerifyAccountPage extends StatefulWidget {
  const VerifyAccountPage({super.key});

  @override
  State<VerifyAccountPage> createState() => _VerifyAccountPageState();
}

class _VerifyAccountPageState extends State<VerifyAccountPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Navigation
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
              
              // Icon
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
              
              // Title
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
              
              // Subtitle
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Please enter the 6-digit OTP code sent to your phone number to continue.',
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
              
              // OTP Input
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (i) => _buildOtpBox()),
              ),
              const SizedBox(height: 32),
              
              // Resend code
              Center(
                child: TextButton(
                  onPressed: () {},
                  child: Text(
                    'Resend code now',
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
              
              // Confirm Button
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
                  onPressed: () {
                    Navigator.pushNamed(context, '/success');
                  },
                  child: Text(
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
              
              // Footer Support Link
              Center(
                child: RichText(
                  text: TextSpan(
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                    children: [
                      const TextSpan(text: 'Having trouble? '),
                      WidgetSpan(
                        child: GestureDetector(
                          onTap: () {},
                          child: Text(
                            'Contact Support',
                            style: TextStyle(
                              color: AppColors.espresso,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOtpBox() {
    return Container(
      width: 45,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
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
          if (value.isNotEmpty) {
            FocusScope.of(context).nextFocus();
          }
        },
      ),
    );
  }
}
