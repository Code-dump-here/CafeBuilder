import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../services/project_service.dart';
import '../services/service_provider_service.dart';
import '../models/requests/project_requests.dart';
import '../models/marketplace_state.dart';
import '../services/api_client.dart';
import '../models/place_location.dart';
import '../widgets/location_field.dart';

class ProjectManualCreatePage extends StatefulWidget {
  const ProjectManualCreatePage({super.key});

  @override
  State<ProjectManualCreatePage> createState() => _ProjectManualCreatePageState();
}

class _ProjectManualCreatePageState extends State<ProjectManualCreatePage> {
  final _nameCtrl = TextEditingController();

  /// Address plus its map pin. Held as a value rather than a controller because
  /// the picker returns both halves at once, and a controller could only carry
  /// the text — the coordinates would have nowhere to live.
  PickedLocation? _location;
  final _areaCtrl = TextEditingController();
  final _budgetCtrl = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _areaCtrl.dispose();
    _budgetCtrl.dispose();
    super.dispose();
  }

  Future<void> _createProject() async {
    final name = _nameCtrl.text.trim();
    final location = _location;
    final address = location?.address.trim() ?? '';
    final areaStr = _areaCtrl.text.trim();
    final budgetStr = _budgetCtrl.text.trim();

    if (name.isEmpty || address.isEmpty || areaStr.isEmpty || budgetStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    final area = double.tryParse(areaStr);
    final budget = double.tryParse(budgetStr);

    if (area == null || area <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid area')),
      );
      return;
    }

    if (budget == null || budget <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid budget')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final shopOwnerId = await ShopOwnerService.ensureShopOwnerId();
      final request = CreateProjectRequest(
        ownerId: shopOwnerId,
        name: name,
        address: address,
        latitude: location?.latitude,
        longitude: location?.longitude,
        areaM2: area,
        budget: budget,
      );
      await ProjectService.createProject(request);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Project created successfully!')),
        );
        // Straight to Home instead of popping back to wherever this was
        // opened from (My Projects, etc.) — Home is always the first
        // route (see main.dart), so this lands there regardless of how
        // deep this page was pushed from. `onNeedsRefresh` tells the
        // still-alive Home instance to re-fetch, since popping back to it
        // doesn't run any of its own refresh logic on its own.
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
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
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  InputDecoration _buildInputDec(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.placeholder),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.outlineVariant.withOpacity(0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.espresso, width: 1.5),
      ),
    );
  }

  Widget _buildTextFieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
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
          'Create Project',
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
                'Manual Project Creation',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.espresso,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter the details of your project below to create it directly without AI assistance.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  height: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
              
              _buildTextFieldLabel('Project Name'),
              TextField(
                controller: _nameCtrl,
                decoration: _buildInputDec('e.g., My Dream Cafe'),
                style: GoogleFonts.inter(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 20),
              
              _buildTextFieldLabel('Location / Address'),
              LocationField(
                value: _location,
                onChanged: (picked) => setState(() => _location = picked),
                pickerSubtitle: 'Where the cafe will be built',
              ),
              const SizedBox(height: 20),
              
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTextFieldLabel('Total Area (m²)'),
                        TextField(
                          controller: _areaCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*'))],
                          decoration: _buildInputDec('e.g., 150'),
                          style: GoogleFonts.inter(color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTextFieldLabel('Budget (VND)'),
                        TextField(
                          controller: _budgetCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: _buildInputDec('e.g., 1500000000'),
                          style: GoogleFonts.inter(color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 48),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _createProject,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.espresso,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          'Create Project',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
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
}
