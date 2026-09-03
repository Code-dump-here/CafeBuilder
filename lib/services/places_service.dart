import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:math' as math;

import 'package:http/http.dart' as http;

import '../models/place_location.dart';

/// Address search and map tiles, backed by **MapTiler Cloud**.
///
/// Replaced Google Maps Platform, which refused every request on this account:
/// Maps Platform requires a billing account with a payment method, and the
/// project's linked account never satisfied that check. MapTiler's free tier
/// needs no card and covers everything here.
///
/// What the free tier does and does not include, verified against the live API:
///   - Geocoding + reverse geocoding  ✅
///   - Raster map tiles (incl. @2x)   ✅
///   - Static Maps API                ❌ 403, paid plan only
///
/// That last one is why map previews are composed from tiles ([tileUrl],
/// [worldPixel]) rather than fetched as a single image.
class PlacesService {
  /// Supplied at build time, never committed:
  ///
  ///   flutter run --dart-define=GOOGLE_MAPS_API_KEY=`your-maptiler-key`
  ///
  /// The define keeps its original name so `dev.cmd`, the CI args and every
  /// existing checkout keep working — renaming it would break the launcher for
  /// a cosmetic gain. It is simply "the map provider key".
  static const String apiKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');

  /// False when no key was supplied. Callers fall back to plain text entry
  /// rather than showing a map that can only fail.
  static bool get isConfigured => apiKey.isNotEmpty;

  static const String _host = 'api.maptiler.com';

  /// Results are restricted to Vietnam and labelled in Vietnamese. Every
  /// project in this app is a cafe being built in Vietnam.
  static const String _country = 'vn';
  static const String _language = 'vi';

  /// Tile style. `streets-v2` carries street names and POIs, which is what
  /// makes a preview legible as a *place* rather than a coloured rectangle.
  static const String _style = 'streets-v2';

  /// `@2x` tiles are 512px, not 256. Everything downstream depends on this,
  /// so it is stated once here instead of being hardcoded per call site.
  static const int tileSize = 512;

  /// Where to bias search when nothing better is known.
  ///
  /// Not cosmetic — MapTiler's ranking is poor without it. Verified against
  /// the live API: "123 Nguyen Hue Quan 1" with no bias returns *Nguyễn Hữu
  /// Cầu*, a different street; adding more of the address makes it worse, not
  /// better. With this bias the same query resolves to Đại lộ Nguyễn Huệ.
  ///
  /// Ho Chi Minh City because that is where the projects are. Callers pass the
  /// current pin instead once there is one, so a Hanoi user stops being
  /// measured against Saigon after their first pick.
  static const double defaultProximityLat = 10.7769;
  static const double defaultProximityLng = 106.7009;

  // ── Search ──────────────────────────────────────────────────────────────────

  /// Address suggestions for a partial query.
  ///
  /// Unlike the Google implementation this replaced, each suggestion already
  /// carries its coordinates — MapTiler returns them inline, so choosing one
  /// costs no second request. That removed a whole round trip, the billing
  /// session-token machinery, and the "resolved but failed" state the picker
  /// used to have to handle.
  ///
  /// Returns an empty list — never throws — when the key is missing, the query
  /// is too short, or the request fails. A picker that explodes mid-typing is
  /// worse than one that shows nothing: the user can still type the address by
  /// hand, which is what they did before this existed.
  static Future<List<PlaceSuggestion>> autocomplete(
    String input, {
    double? proximityLat,
    double? proximityLng,
  }) async {
    final query = input.trim();
    if (!isConfigured || query.length < 2) return const [];

    try {
      final lat = proximityLat ?? defaultProximityLat;
      final lng = proximityLng ?? defaultProximityLng;

      final response = await http.get(
        Uri.https(_host, '/geocoding/${Uri.encodeComponent(query)}.json', {
          'key': apiKey,
          'country': _country,
          'language': _language,
          'autocomplete': 'true',
          'limit': '6',
          // MapTiler is GeoJSON throughout: longitude first, everywhere.
          'proximity': '$lng,$lat',
        }),
      );

      if (response.statusCode != 200) {
        _logFailure('autocomplete', response.statusCode, response.body);
        return const [];
      }

      final body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final features = body['features'] as List<dynamic>? ?? const [];

      return features
          .whereType<Map<String, dynamic>>()
          .map(_suggestionFrom)
          .whereType<PlaceSuggestion>()
          .toList();
    } catch (e) {
      dev.log('[PlacesService] autocomplete failed: $e', name: 'PlacesService');
      return const [];
    }
  }

  static PlaceSuggestion? _suggestionFrom(Map<String, dynamic> feature) {
    // `center` is [longitude, latitude] — GeoJSON order. Reading these the
    // other way round silently drops the pin in the Indian Ocean, which is why
    // the tests assert on a known Ho Chi Minh City fixture.
    final center = feature['center'] as List<dynamic>?;
    if (center == null || center.length < 2) return null;
    final lng = (center[0] as num?)?.toDouble();
    final lat = (center[1] as num?)?.toDouble();
    if (lat == null || lng == null) return null;

    // Prefer the Vietnamese rendering: it carries the ward ("Phường …") that
    // a local address is normally written with, and the English one drops it.
    final full = (feature['place_name_vi'] ?? feature['place_name']) as String?;
    if (full == null || full.isEmpty) return null;

    final name = feature['text_vi'] as String? ?? feature['text'] as String? ?? full;
    // Everything after the name, so the row reads "Lê Lợi" / "Phường Bến Nghé, …".
    final secondary = full.startsWith('$name, ')
        ? full.substring(name.length + 2)
        : (full == name ? '' : full);

    return PlaceSuggestion(
      fullText: full,
      mainText: name,
      secondaryText: secondary,
      latitude: lat,
      longitude: lng,
    );
  }

  /// Coordinates for a typed address — used to pin the map when the picker
  /// opens on a project that only ever had text. Null when nothing matches.
  static Future<PickedLocation?> geocode(String address) async {
    final results = await autocomplete(address);
    if (results.isEmpty) return null;
    final first = results.first;
    return PickedLocation(
      address: first.fullText,
      latitude: first.latitude,
      longitude: first.longitude,
    );
  }

  /// The address at a point, for when a pin is placed on the map directly.
  /// Returns null on failure — the caller keeps the coordinates rather than
  /// losing the user's pin over a failed lookup.
  static Future<PickedLocation?> reverseGeocode(double latitude, double longitude) async {
    if (!isConfigured) return null;

    try {
      final response = await http.get(
        // Longitude first — see the note in [_suggestionFrom].
        Uri.https(_host, '/geocoding/$longitude,$latitude.json', {
          'key': apiKey,
          'language': _language,
        }),
      );

      if (response.statusCode != 200) {
        _logFailure('reverseGeocode', response.statusCode, response.body);
        return null;
      }

      final body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final features = body['features'] as List<dynamic>? ?? const [];
      if (features.isEmpty) return null;

      final first = features.first as Map<String, dynamic>;
      final address = (first['place_name_vi'] ?? first['place_name']) as String?;
      if (address == null) return null;

      return PickedLocation(address: address, latitude: latitude, longitude: longitude);
    } catch (e) {
      dev.log('[PlacesService] reverseGeocode failed: $e', name: 'PlacesService');
      return null;
    }
  }

  // ── Tiles ───────────────────────────────────────────────────────────────────

  /// URL of one raster map tile.
  static String tileUrl(int zoom, int x, int y) =>
      'https://$_host/maps/$_style/$zoom/$x/$y@2x.png?key=$apiKey';

  /// Web Mercator projection: a coordinate to its position in the world pixel
  /// grid at [zoom], where the world is `tileSize * 2^zoom` pixels square.
  ///
  /// This is what lets a preview be composed from tiles now that the Static
  /// Maps API is behind a paid plan. Verified against the live tile server:
  /// Ho Chi Minh City and Hanoi both land on dense ~150KB city tiles, while a
  /// point in the open ocean lands on a 222-byte empty one.
  static ({double x, double y}) worldPixel(double latitude, double longitude, int zoom) {
    final scale = tileSize * math.pow(2, zoom).toDouble();
    final x = (longitude + 180.0) / 360.0 * scale;

    // Clamped just short of the poles: the projection is undefined at ±90°,
    // where tan() runs to infinity and the arithmetic produces NaN.
    final lat = latitude.clamp(-85.05112878, 85.05112878);
    final latRad = lat * math.pi / 180.0;
    final y = (1.0 - math.log(math.tan(latRad) + 1.0 / math.cos(latRad)) / math.pi) / 2.0 * scale;

    return (x: x, y: y);
  }

  /// How much ground one screen pixel covers, in metres.
  ///
  /// The conversion between the two units this file deals in, and the thing
  /// that makes a threshold mean the same to a user at every zoom. A rule
  /// written in metres alone is a different rule at every zoom level: 40m is
  /// most of the screen at zoom 19 and four pixels at zoom 13.
  ///
  /// Mercator stretches east-west with latitude, hence the cosine. In Ho Chi
  /// Minh City at zoom 17 this is 0.587 m/px, so the picker's 240px-tall box
  /// shows about 141m of ground.
  static double metresPerPixel(int zoom, double latitude) {
    // Equatorial circumference. The projection is a sphere here, matching
    // [metresBetween] — the ellipsoidal difference is under 0.3%, well inside
    // the tolerance of anything measured in screen pixels.
    const equatorMetres = 40075016.686;
    final lat = latitude.clamp(-85.05112878, 85.05112878);
    return equatorMetres *
        math.cos(lat * math.pi / 180.0) /
        (tileSize * math.pow(2, zoom));
  }

  /// The tiles needed to fill a [width] x [height] box centred on a coordinate,
  /// each with the offset it should be drawn at inside that box.
  ///
  /// Shared by the static preview and the draggable picker so both compose the
  /// map identically — a second implementation is a second chance to get the
  /// centring wrong.
  static List<({String url, double left, double top})> tileGrid({
    required double latitude,
    required double longitude,
    required int zoom,
    required double width,
    required double height,
  }) {
    final maxIndex = (1 << zoom) - 1;
    final centre = worldPixel(latitude, longitude, zoom);
    final originX = centre.x - width / 2;
    final originY = centre.y - height / 2;

    final firstX = (originX / tileSize).floor();
    final firstY = (originY / tileSize).floor();
    // How far into the first tile the box's corner falls. Shifting the grid by
    // this remainder is what centres the point instead of snapping it to a
    // tile boundary.
    final offsetX = firstX * tileSize - originX;
    final offsetY = firstY * tileSize - originY;

    final columns = ((width - offsetX) / tileSize).ceil();
    final rows = ((height - offsetY) / tileSize).ceil();

    final tiles = <({String url, double left, double top})>[];
    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < columns; col++) {
        final tileY = firstY + row;
        // Latitude does not wrap — there is no tile above the north pole, and
        // asking for one returns an error image. Longitude does, so x wraps.
        if (tileY < 0 || tileY > maxIndex) continue;
        final tileX = ((firstX + col) % (maxIndex + 1) + maxIndex + 1) % (maxIndex + 1);

        tiles.add((
          url: tileUrl(zoom, tileX, tileY),
          left: offsetX + col * tileSize,
          top: offsetY + row * tileSize,
        ));
      }
    }
    return tiles;
  }

  /// The inverse of [worldPixel]: a position in the world pixel grid back to a
  /// coordinate. This is what makes the map draggable — a pan is measured in
  /// pixels, and the pin's new location has to be read back out of them.
  ///
  /// Longitude wraps rather than clamping, so dragging past the date line
  /// continues rather than sticking. Latitude clamps at the Mercator limit,
  /// which is where the projection itself stops being defined.
  static ({double latitude, double longitude}) latLngFromWorldPixel(
    double x,
    double y,
    int zoom,
  ) {
    final scale = tileSize * math.pow(2, zoom).toDouble();

    var lon = x / scale * 360.0 - 180.0;
    lon = (lon + 180.0) % 360.0;
    if (lon < 0) lon += 360.0;
    lon -= 180.0;

    final n = math.pi * (1.0 - 2.0 * (y / scale).clamp(0.0, 1.0));
    // Mercator's inverse uses the hyperbolic sine; Dart has no sinh, so it is
    // written out as (e^n - e^-n) / 2.
    final lat = math.atan((math.exp(n) - math.exp(-n)) / 2.0) * 180.0 / math.pi;

    return (latitude: lat, longitude: lon);
  }

  /// Great-circle distance between two coordinates, in metres.
  ///
  /// Metres rather than screen pixels because this ranks latch targets by how
  /// close they really are: a shop 20m from the pin is 20m from the pin at
  /// every zoom level, so the ranking survives a zoom instead of reshuffling
  /// under it.
  static double metresBetween(
    double aLatitude,
    double aLongitude,
    double bLatitude,
    double bLongitude,
  ) {
    const earthRadius = 6371000.0;
    const toRadians = math.pi / 180.0;

    final dLat = (bLatitude - aLatitude) * toRadians;
    final dLng = (bLongitude - aLongitude) * toRadians;
    final h = math.pow(math.sin(dLat / 2), 2) +
        math.cos(aLatitude * toRadians) *
            math.cos(bLatitude * toRadians) *
            math.pow(math.sin(dLng / 2), 2);

    // Clamped before asin: rounding can push h a hair past 1 for antipodal
    // points, where asin is then outside its domain and returns NaN.
    return 2 * earthRadius * math.asin(math.min(1.0, math.sqrt(h)));
  }

  /// Opens the point in whatever map app the device has.
  static String directionsUrl(double latitude, double longitude) =>
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';

  static void _logFailure(String call, int statusCode, String body) {
    final snippet = body.length > 300 ? '${body.substring(0, 300)}…' : body;
    dev.log('[PlacesService] $call HTTP $statusCode — $snippet', name: 'PlacesService');
  }
}
