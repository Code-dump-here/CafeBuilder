import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/place_location.dart';
import '../pages/location_picker_page.dart';
import '../services/places_service.dart';
import '../theme/app_colors.dart';

/// Form control for an address. Tapping it opens [LocationPickerPage]; the
/// picked value comes back through [onChanged].
///
/// Falls back to a plain [TextField] when no Google Maps key was compiled in,
/// so a checkout without a key still lets the owner create a project. That
/// fallback is the reason this is a widget rather than a styled button: the two
/// modes have to look like the same field, or the form reads as broken in
/// whichever build the user happens to be running.
class LocationField extends StatefulWidget {
  final PickedLocation? value;
  final ValueChanged<PickedLocation> onChanged;
  final String hintText;

  /// Shown under the picker's title.
  final String pickerSubtitle;

  const LocationField({
    super.key,
    required this.value,
    required this.onChanged,
    this.hintText = 'e.g., 123 Nguyễn Huệ, Quận 1, Hồ Chí Minh',
    this.pickerSubtitle = 'Search for the address, then confirm the pin',
  });

  @override
  State<LocationField> createState() => _LocationFieldState();
}

class _LocationFieldState extends State<LocationField> {
  late final TextEditingController _fallbackCtrl =
      TextEditingController(text: widget.value?.address ?? '');

  @override
  void didUpdateWidget(covariant LocationField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only relevant in fallback mode, and only when the parent replaced the
    // value from outside (a form reset, a load completing). Writing on every
    // rebuild would fight the user's cursor while they type.
    final incoming = widget.value?.address ?? '';
    if (!PlacesService.isConfigured && incoming != _fallbackCtrl.text) {
      _fallbackCtrl.text = incoming;
    }
  }

  @override
  void dispose() {
    _fallbackCtrl.dispose();
    super.dispose();
  }

  Future<void> _openPicker() async {
    final result = await Navigator.push<PickedLocation>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerPage(
          initial: widget.value,
          subtitle: widget.pickerSubtitle,
        ),
      ),
    );
    if (result != null) widget.onChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    if (!PlacesService.isConfigured) return _buildFallbackField();

    final value = widget.value;
    final hasAddress = value != null && !value.isEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _openPicker,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: Row(
            children: [
              Icon(
                hasAddress ? Icons.place : Icons.search,
                size: 20,
                color: hasAddress ? AppColors.espresso : AppColors.placeholder,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasAddress ? value.address : widget.hintText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        height: 1.4,
                        color: hasAddress ? AppColors.textPrimary : AppColors.placeholder,
                      ),
                    ),
                    if (hasAddress) ...[
                      const SizedBox(height: 4),
                      _buildPinBadge(value.hasCoordinates),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, size: 18, color: AppColors.placeholder),
            ],
          ),
        ),
      ),
    );
  }

  /// Whether this address will show up on a map for the providers who read it.
  /// Worth saying out loud on the form — the owner is the only person who can
  /// fix it, and only while they're standing here.
  Widget _buildPinBadge(bool pinned) {
    return Row(
      children: [
        Icon(
          pinned ? Icons.check_circle : Icons.location_off_outlined,
          size: 12,
          color: pinned ? const Color(0xFF56642B) : AppColors.placeholder,
        ),
        const SizedBox(width: 4),
        Text(
          pinned ? 'Pinned on the map' : 'Text only — tap to pin it',
          style: GoogleFonts.inter(
            fontSize: 10,
            color: pinned ? const Color(0xFF56642B) : AppColors.placeholder,
          ),
        ),
      ],
    );
  }

  Widget _buildFallbackField() {
    return TextField(
      controller: _fallbackCtrl,
      onChanged: (text) => widget.onChanged(PickedLocation.textOnly(text)),
      style: GoogleFonts.inter(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: GoogleFonts.inter(color: AppColors.placeholder, fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.espresso, width: 1.5),
        ),
      ),
    );
  }
}
