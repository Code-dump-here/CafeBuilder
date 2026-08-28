import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/places_service.dart';
import '../theme/app_colors.dart';
import 'map_tile_preview.dart';

/// Read-only map for a saved address — project detail, provider profile,
/// anywhere the location is shown rather than edited.
///
/// Renders the Static Maps API rather than an interactive map SDK. On a page
/// nobody is going to pan, a single image is one request instead of a map
/// session, needs no plugin or per-platform key wiring, and looks identical on
/// web, Android and iOS. Tapping opens the point in the device's real map app,
/// which is what someone actually wants from here: directions.
///
/// Renders nothing at all when the address has no coordinates, so screens can
/// drop it in unconditionally without guarding every call site.
class LocationMapPreview extends StatelessWidget {
  final String address;
  final double? latitude;
  final double? longitude;

  final double height;

  /// Hides the address line when the surrounding screen already prints it.
  final bool showAddress;

  const LocationMapPreview({
    super.key,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.height = 160,
    this.showAddress = true,
  });

  bool get _canRender =>
      latitude != null && longitude != null && PlacesService.isConfigured;

  Future<void> _openInMaps() async {
    final uri = Uri.parse(PlacesService.directionsUrl(latitude!, longitude!));
    // Best-effort: a device with no browser or map app is a real (if rare)
    // state, and it isn't worth an error dialog on a preview tile.
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_canRender) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _openInMaps,
            borderRadius: BorderRadius.circular(12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  // The tile grid is laid out in pixels, so it needs the real
                  // width rather than `double.infinity` — a wrong number would
                  // push the centre pin off the actual coordinate.
                  LayoutBuilder(
                    builder: (context, constraints) => MapTilePreview(
                      latitude: latitude!,
                      longitude: longitude!,
                      width: constraints.maxWidth,
                      height: height,
                    ),
                  ),
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.directions, size: 12, color: AppColors.espresso),
                          const SizedBox(width: 4),
                          Text(
                            'Directions',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.espresso,
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
        ),
        if (showAddress && address.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.place_outlined, size: 14, color: AppColors.placeholder),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  address,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    height: 1.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
