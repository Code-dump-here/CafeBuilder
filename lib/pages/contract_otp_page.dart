import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../models/responses/api_responses.dart';
import '../services/contract_service.dart';
import '../services/api_client.dart';
import '../services/service_provider_service.dart'; // for ShopOwnerService

class ContractOtpPage extends StatefulWidget {
  final ContractResponse contract;
  
  const ContractOtpPage({super.key, required this.contract});

  @override
  State<ContractOtpPage> createState() => _ContractOtpPageState();
}

class _ContractOtpPageState extends State<ContractOtpPage> {
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;

  Future<void> _confirmOtp() async {
    final code = _otpController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the OTP code.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final accountId = await ApiClient.getAccountId();
      if (accountId == null) {
        throw Exception('User account ID not found. Please log in again.');
      }
      await ContractService.confirmOtp(
        widget.contract.id,
        otpCode: code,
        confirmedBy: accountId,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        // Show success
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('Contract Confirmed'),
            content: const Text('You have successfully signed the contract! The engagement will now proceed to the next phase.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx); // close dialog
                  Navigator.pop(context, true); // return success
                },
                child: const Text('OK'),
              )
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.espresso),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Sign Contract',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.espresso,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CONTRACT OVERVIEW',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: AppColors.placeholder,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.outlineVariant.withOpacity(0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.contract.title,
                      style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.espresso),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Agreed Value', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                        Text(
                          '\$${widget.contract.agreedValue.toStringAsFixed(0)}',
                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF56642B)),
                        ),
                      ],
                    ),
                    if (widget.contract.terms != null && widget.contract.terms!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Divider(color: AppColors.outlineVariant),
                      const SizedBox(height: 12),
                      Text('Terms & Conditions', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.espresso)),
                      const SizedBox(height: 4),
                      Text(
                        widget.contract.terms!,
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary, height: 1.5),
                      ),
                    ]
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'OTP VERIFICATION',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: AppColors.placeholder,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Please enter the 6-digit OTP code sent to your email to digitally sign this contract.',
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 8.0, color: AppColors.espresso),
                decoration: InputDecoration(
                  hintText: '000000',
                  hintStyle: GoogleFonts.inter(fontSize: 24, color: AppColors.placeholder, letterSpacing: 8.0),
                  filled: true,
                  fillColor: Colors.white,
                  counterText: '',
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.outlineVariant.withOpacity(0.5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.espresso, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.espresso))
                  : ElevatedButton(
                      onPressed: _confirmOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.espresso,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Text(
                        'Confirm & Sign',
                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
