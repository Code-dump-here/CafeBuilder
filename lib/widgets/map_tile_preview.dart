import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/places_service.dart';
import '../theme/app_colors.dart';

/// A flat map centred on one point, composed from raster tiles.
///
/// This exists because MapTiler's **Static Maps API is a paid feature** — it
/// answers 403 with `X-MAPTILER-FREE: 1` on this account — while raster tiles
/// are included in the free tier. So rather than fetching one ready-made
/// image, this lays out the handful of tiles that cover the requested box and
/// offsets them so the point lands dead centre.
///
/// The alternative was an interactive map package (`flutter_map`, MapLibre).
/// That would be a heavier dependency and a WebGL surface on every screen that
/// only ever shows a location — this is a few `Image.network` calls that
/// behave identically on web, Android and iOS, and cost nothing to render.
///
/// Not interactive by design. Panning belongs on a picker, not on a detail
/// card, and tapping opens the real map app instead.
class MapTilePreview extends StatelessWidget {
  final double latitude;
  final double longitude;
  final double width;
  final double height;

  /// 16 shows a city block — close enough to recognise the street, wide enough
  /// to place it. 15 for a neighbourhood, 17 for a building.
  final int zoom;

  /// Hidden for a picker that draws its own centre pin.
  final bool showMarker;

  const MapTilePreview({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.width,
    required this.height,
    this.zoom = 16,
    this.showMarker = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!PlacesService.isConfigured) return _placeholder('Map key not configured');

    const tileSize = PlacesService.tileSize;
    final maxIndex = (1 << zoom) - 1;

    // Where the point sits in the world pixel grid, then the top-left corner
    // of the viewport we want around it.
    final centre = PlacesService.worldPixel(latitude, longitude, zoom);
    final originX = centre.x - width / 2;
    final originY = centre.y - height / 2;

    // First tile touching that corner, and how far into it the corner falls —
    // that remainder is what shifts the whole grid so the point ends up
    // centred rather than snapped to a tile boundary.
    final firstTileX = (originX / tileSize).floor();
    final firstTileY = (originY / tileSize).floor();
    final offsetX = firstTileX * tileSize - originX;
    final offsetY = firstTileY * tileSize - originY;

    final columns = ((width - offsetX) / tileSize).ceil();
    final rows = ((height - offsetY) / tileSize).ceil();

    final tiles = <Widget>[];
    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < columns; col++) {
        final tileX = firstTileX + col;
        final tileY = firstTileY + row;

        // Vertical wrap-around is not a thing — above the north pole or below
        // the south there is no tile, and requesting one returns an error
        // image. Longitude does wrap, so x is taken modulo the grid width.
        if (tileY < 0 || tileY > maxIndex) continue;
        final wrappedX = tileX % (maxIndex + 1);
        final normalisedX = wrappedX < 0 ? wrappedX + maxIndex + 1 : wrappedX;

        tiles.add(Positioned(
          left: offsetX + col * tileSize.toDouble(),
          top: offsetY + row * tileSize.toDouble(),
          width: tileSize.toDouble(),
          height: tileSize.toDouble(),
          child: Image.network(
            PlacesService.tileUrl(zoom, normalisedX, tileY),
            fit: BoxFit.fill,
            // A failed tile leaves a neutral square rather than a broken-image
            // glyph — one missing tile shouldn't make the whole map look wrong.
            errorBuilder: (_, _, _) => Container(color: AppColors.splashBackground),
          ),
        ));
      }
    }

    return SizedBox(
      width: width,
      height: height,
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: AppColors.splashBackground),
            ...tiles,
            if (showMarker)
              Center(
                // Nudged up by half the icon so the pin's *point* sits on the
                // coordinate, not its middle.
                child: Transform.translate(
                  offset: const Offset(0, -14),
                  child: const Icon(
                    Icons.location_on,
                    size: 32,
                    color: Color(0xFFD64545),
                    shadows: [Shadow(blurRadius: 4, color: Colors.black38)],
                  ),
                ),
              ),
            // MapTiler's terms require visible attribution for OpenStreetMap
            // data. This is not decoration — it is a licence condition.
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                color: Colors.white70,
                child: const Text(
                  '© MapTiler © OpenStreetMap',
                  style: TextStyle(fontSize: 8, color: Colors.black87),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(String message) => Container(
        width: width,
        height: height,
        alignment: Alignment.center,
        color: AppColors.splashBackground,
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      );

  /// Rounds a fractional zoom to something the tile server serves.
  static int clampZoom(num zoom) => math.max(0, math.min(20, zoom.round()));
}
