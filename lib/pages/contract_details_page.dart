import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../models/responses/api_responses.dart';
import '../services/contract_service.dart';
import '../widgets/confirm_dialog.dart';

class ContractDetailsPage extends StatefulWidget {
  final ContractResponse contract;

  /// The provider this contract came from, e.g. "Studio X · Designer".
  /// Resolved by the caller from the engagement; empty when unknown.
  final String providerName;

  const ContractDetailsPage({
    super.key,
    required this.contract,
    this.providerName = '',
  });

  @override
  State<ContractDetailsPage> createState() => _ContractDetailsPageState();
}

class _ContractDetailsPageState extends State<ContractDetailsPage> {
  late ContractResponse _contract;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _contract = widget.contract;
  }

  Future<void> _launchUrl(String urlString) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Open Document',
      message: 'This will open the contract document in another app. Continue?',
      confirmLabel: 'Open',
    );
    if (!confirmed || !mounted) return;

    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the contract document')),
        );
      }
    }
  }

  void _showOtpBottomSheet() {
    final TextEditingController otpController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _OtpBottomSheet(
        contractId: _contract.id,
        otpController: otpController,
        onConfirmed: (updatedContract) {
          setState(() {
            _contract = updatedContract;
          });
          Navigator.pop(ctx);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Contract confirmed successfully!'),
              backgroundColor: Color(0xFF4CAF50),
            ),
          );
        },
      ),
    );
  }

  Future<void> _sendOtp() async {
    setState(() => _isLoading = true);
    try {
      final updated = await ContractService.sendOtp(_contract.id);
      setState(() {
        _contract = updated;
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP has been sent to your email.'), backgroundColor: Color(0xFF4CAF50)),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send OTP: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Amounts are VND. This formatted them as US dollars, so a 50,000,000
    // VND contract read as "$50,000,000.00".
    final currencyFormatter =
        NumberFormat.currency(locale: 'vi_VN', symbol: 'VND', decimalDigits: 0);
    final isPendingOtp = _contract.status.toLowerCase() == 'pending_otp';
    final isDrafted = _contract.status.toLowerCase() == 'drafted';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F3F0), // Paper-like background
      appBar: AppBar(
        title: Text(
          'Contract Document',
          style: GoogleFonts.playfairDisplay(color: AppColors.espresso, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.espresso),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
                border: Border.all(color: const Color(0xFFE5E5E5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      'AGREEMENT OF SERVICES',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                        color: AppColors.espresso,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  _buildSectionTitle('Contract Title'),
                  _buildText(_contract.title, isBold: true, fontSize: 16),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // The engagement id meant nothing to an owner
                            // holding two contracts; the provider's name is
                            // what tells them whose contract this is.
                            _buildSectionTitle(
                              widget.providerName.isEmpty ? 'Engagement' : 'From',
                            ),
                            _buildText(
                              widget.providerName.isEmpty
                                  ? 'Provider not named'
                                  : widget.providerName,
                              isBold: true,
                              maxLines: 2,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _buildSectionTitle('Status'),
                          _buildStatusBadge(_contract.status),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSigningNotice(),
                  const SizedBox(height: 24),
                  const Divider(color: Color(0xFFEEEEEE), thickness: 1),
                  const SizedBox(height: 20),

                  _buildSectionTitle('Agreed Value'),
                  Text(
                    currencyFormatter.format(_contract.agreedValue),
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF56642B),
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (_contract.partyInfo != null && _contract.partyInfo!.isNotEmpty) ...[
                    _buildSectionTitle('Party Info'),
                    _buildText(_contract.partyInfo!),
                    const SizedBox(height: 24),
                  ],

                  if (_contract.terms != null && _contract.terms!.isNotEmpty) ...[
                    _buildSectionTitle('Terms & Conditions'),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9F9F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFEBEBEB)),
                      ),
                      child: _buildText(_contract.terms!, fontSize: 13),
                    ),
                    const SizedBox(height: 24),
                  ],

                  const Divider(color: Color(0xFFEEEEEE), thickness: 1),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildDateColumn('Created At', _contract.createdAt),
                      if (_contract.confirmedAt != null) 
                        _buildDateColumn('Confirmed At', _contract.confirmedAt!),
                      if (_contract.otpExpiresAt != null)
                        _buildDateColumn('OTP Expires', _contract.otpExpiresAt!),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            if (_contract.documentViewUrl != null && _contract.documentViewUrl!.isNotEmpty)
              ElevatedButton.icon(
                onPressed: () => _launchUrl(_contract.documentViewUrl!),
                icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                label: const Text('View Original Document'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.espresso,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomActions(isDrafted, isPendingOtp),
    );
  }

  Future<void> _cancelContract() async {
    setState(() => _isLoading = true);
    try {
      final updated = await ContractService.cancelContract(_contract.id);
      setState(() {
        _contract = updated;
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contract has been cancelled.'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to cancel contract: $e')),
        );
      }
    }
  }

  void _confirmCancel() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Cancel Contract', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to cancel this contract? This action cannot be undone.', style: GoogleFonts.inter()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Keep It', style: GoogleFonts.inter(color: AppColors.textPrimary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _cancelContract();
            },
            child: Text('Yes, Cancel', style: GoogleFonts.inter(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget? _buildBottomActions(bool isDrafted, bool isPendingOtp) {
    if (!isDrafted && !isPendingOtp) return null;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isDrafted)
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _sendOtp,
                icon: _isLoading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send, color: Colors.white),
                label: const Text('Send OTP to Sign'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.espresso,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            if (isPendingOtp)
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _showOtpBottomSheet,
                icon: const Icon(Icons.verified_outlined, color: Colors.white),
                label: const Text('Confirm with OTP'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4B8F4B),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _isLoading ? null : _confirmCancel,
              child: Text(
                'Cancel Contract',
                style: GoogleFonts.inter(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Says plainly whether this contract has been signed.
  ///
  /// The status chip above answers in the API's vocabulary — 'pending_otp'
  /// means nothing to the person being asked to sign — so this states it in
  /// the owner's terms and names the next step when there is one.
  Widget _buildSigningNotice() {
    final status = _contract.status.toLowerCase();

    final (IconData icon, Color fg, Color bg, String title, String detail) =
        switch (status) {
      'confirmed' => (
        Icons.verified_rounded,
        const Color(0xFF2E7D32),
        const Color(0xFFE8F5E9),
        'You have signed this contract',
        _contract.confirmedAt != null
            ? 'Signed on ${DateFormat('MMM dd, yyyy').format(_contract.confirmedAt!.toLocal())} at ${DateFormat('hh:mm a').format(_contract.confirmedAt!.toLocal())}.'
            : 'The work it covers is unlocked.',
      ),
      'pending_otp' => (
        Icons.hourglass_bottom_rounded,
        const Color(0xFFF57F17),
        const Color(0xFFFFF8E1),
        'You have not signed this yet',
        'An OTP has been sent to your email. Enter it below to sign.',
      ),
      'cancelled' => (
        Icons.cancel_outlined,
        const Color(0xFFC62828),
        const Color(0xFFFFEBEE),
        'This contract was cancelled',
        'It cannot be signed. A new one has to be drawn up.',
      ),
      _ => (
        Icons.edit_document,
        const Color(0xFF616161),
        const Color(0xFFF5F5F5),
        'You have not signed this yet',
        'It is still a draft — send the OTP when you are ready to sign.',
      ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: fg),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: fg,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateColumn(String title, DateTime date) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(title),
        _buildText(DateFormat('MMM dd, yyyy').format(date.toLocal()), fontSize: 13, isBold: true),
        _buildText(DateFormat('hh:mm a').format(date.toLocal()), fontSize: 12, color: AppColors.textSecondary),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
          color: AppColors.placeholder,
        ),
      ),
    );
  }

  Widget _buildText(String text, {bool isBold = false, Color color = AppColors.textPrimary, double fontSize = 14, int? maxLines}) {
    return Text(
      text,
      maxLines: maxLines,
      overflow: maxLines == null ? null : TextOverflow.ellipsis,
      style: GoogleFonts.inter(
        fontSize: fontSize,
        fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        color: color,
        height: 1.6,
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'active':
      case 'completed':
        bgColor = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF2E7D32);
        break;
      case 'pending_otp':
        bgColor = const Color(0xFFFFF8E1);
        textColor = const Color(0xFFF57F17);
        break;
      case 'drafted':
      case 'pending':
        bgColor = const Color(0xFFF5F5F5);
        textColor = const Color(0xFF616161);
        break;
      case 'cancelled':
        bgColor = const Color(0xFFFFEBEE);
        textColor = const Color(0xFFC62828);
        break;
      default:
        bgColor = AppColors.outlineVariant;
        textColor = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.toUpperCase().replaceAll('_', ' '),
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ─── OTP Bottom Sheet ────────────────────────────────────────────────────────

class _OtpBottomSheet extends StatefulWidget {
  final String contractId;
  final TextEditingController otpController;
  final ValueChanged<ContractResponse> onConfirmed;

  const _OtpBottomSheet({
    required this.contractId,
    required this.otpController,
    required this.onConfirmed,
  });

  @override
  State<_OtpBottomSheet> createState() => _OtpBottomSheetState();
}

class _OtpBottomSheetState extends State<_OtpBottomSheet> {
  bool _isLoading = false;
  bool _isResending = false;
  String? _error;

  // Countdown timer — 3 minutes = 180 seconds
  static const int _cooldownSeconds = 180;
  int _secondsLeft = 0;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    // Created by _showOtpBottomSheet specifically for this sheet instance
    // and never reused afterward — this is the only place left to dispose it.
    widget.otpController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() => _secondsLeft = _cooldownSeconds);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }
      setState(() {
        if (_secondsLeft > 0) {
          _secondsLeft--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  String get _countdownText {
    final m = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsLeft % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _resendOtp() async {
    setState(() { _isResending = true; _error = null; });
    try {
      await ContractService.sendOtp(widget.contractId);
      if (mounted) {
        _startCountdown();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('New OTP has been sent to your email.'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  Future<void> _confirm() async {
    final code = widget.otpController.text.trim();
    if (code.length != 6) {
      setState(() => _error = 'Please enter a valid 6-digit OTP code.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final updated = await ContractService.confirmOtp(
        widget.contractId,
        otpCode: code,
      );
      widget.onConfirmed(updated);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canResend = _secondsLeft == 0 && !_isResending;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'OTP Verification',
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.espresso,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter the 6-digit OTP code sent to your email to digitally sign this contract.',
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: widget.otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 10.0,
                color: AppColors.espresso,
              ),
              decoration: InputDecoration(
                hintText: '000000',
                hintStyle: GoogleFonts.inter(
                  fontSize: 28,
                  color: AppColors.outlineVariant,
                  letterSpacing: 10.0,
                ),
                filled: true,
                fillColor: AppColors.background,
                counterText: '',
                errorText: _error,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.espresso, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.red.shade300),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.red.shade400, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Resend OTP row
            Center(
              child: _isResending
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.espresso),
                    )
                  : canResend
                      ? TextButton.icon(
                          onPressed: _resendOtp,
                          icon: const Icon(Icons.refresh, size: 16),
                          label: Text(
                            'Resend OTP',
                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          style: TextButton.styleFrom(foregroundColor: AppColors.espresso),
                        )
                      : Text(
                          'Resend OTP in $_countdownText',
                          style: GoogleFonts.inter(fontSize: 13, color: AppColors.placeholder),
                        ),
            ),

            const SizedBox(height: 16),
            _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.espresso))
                : ElevatedButton(
                    onPressed: _confirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.espresso,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text(
                      'Confirm Contract',
                      style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
