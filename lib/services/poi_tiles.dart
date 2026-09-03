import 'dart:developer' as dev;
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:vector_tile/vector_tile.dart';

import '../models/place_location.dart';
import 'places_service.dart';

/// One tile of the map, by its position in the world grid.
typedef TileKey = ({int z, int x, int y});

/// Named places, taken from the map's own vector tiles instead of the
/// geocoding API.
///
/// The geocoder answers "the ten nearest places to this point", which is a
/// question you have to keep re-asking as the pin moves — measured against the
/// live API, about fourteen requests per kilometre downtown. A vector tile
/// answers "every place in this rectangle", once.
///
/// Measured on the live tileset, one zoom-14 tile over central Ho Chi Minh
/// City: 233 KB on the wire, 5.8 km² of ground, 3,516 features, 2,341 of them
/// named — against ten per geocoding request. Out at Bình Chánh the same tile
/// is 48 KB and 74 places, because the size tracks the density.
///
/// Two things fall out of that beyond the request count:
///
///   * **Coverage becomes exact.** A tile is a known rectangle, so "do we have
///     this ground" is a lookup rather than the distance heuristic the
///     geocoding path needed. Holding a tile means holding *all* of it.
///   * **Refreshing is self-healing by construction.** Re-fetching replaces a
///     tile's places wholesale, so anything that has closed simply is not in
///     the new one.
///
/// What is lost is the composed address line — the tile gives a place its name
/// and its kind, not "123 Lê Lợi, Bến Nghé, Quận 1". The picker resolves that
/// with a single reverse geocode when the user actually latches onto
/// something, which is the one moment it is needed.
class PoiTiles {
  /// The `poi` layer exists from zoom 14 up, and 14 is the coarsest — so one
  /// tile there covers the most ground for one request. Fetching at the
  /// coarsest zoom that carries the data is the whole trick.
  static const int zoom = 14;

  /// How far out tiles are considered, however much ground is on screen.
  ///
  /// Without a cap, a viewport zoomed out to the whole province would ask for
  /// hundreds of tiles. Dots at that zoom are decoration anyway — the pin is
  /// placed at street level.
  static const double _maxSelectionMetres = 3600;

  /// Metres in a degree of latitude, on the sphere [PlacesService.metresBetween]
  /// measures against.
  static const double _metresPerDegree = 111194.93;

  /// Street furniture. A bus stop or a rubbish bin is a named point on the map
  /// and a terrible thing to label a construction site with — "Bus stop 42" is
  /// worse than the bare street. Dropped rather than shown and ignored,
  /// because a dot the pin can latch onto is a dot the pin *will* latch onto.
  ///
  /// A denylist rather than an allowlist so an unfamiliar kind of place still
  /// shows up. Costs about 12% of the named features in a city tile.
  static const Set<String> deniedClasses = {
    'bus',
    'gate',
    'atm',
    'bench',
    'waste_basket',
    'toilets',
    'drinking_water',
    'bicycle_parking',
    'shelter',
    'picnic_site',
    'tram_stop',
    'railway',
  };

  /// The tile a coordinate falls in.
  static TileKey tileFor(double latitude, double longitude) {
    final scale = 1 << zoom;
    final lat = latitude.clamp(-85.05112878, 85.05112878);
    final latRad = lat * math.pi / 180.0;

    final x = ((longitude + 180.0) / 360.0 * scale).floor().clamp(0, scale - 1);
    final y = ((1.0 -
                math.log(math.tan(latRad) + 1.0 / math.cos(latRad)) / math.pi) /
            2.0 *
            scale)
        .floor()
        .clamp(0, scale - 1);

    return (z: zoom, x: x, y: y);
  }

  /// The middle of a tile, used to rank tiles by how close they are to the pin.
  static ({double latitude, double longitude}) centreOf(TileKey key) {
    final scale = 1 << key.z;
    final longitude = (key.x + 0.5) / scale * 360.0 - 180.0;
    final n = math.pi * (1.0 - 2.0 * (key.y + 0.5) / scale);
    final latitude =
        math.atan((math.exp(n) - math.exp(-n)) / 2.0) * 180.0 / math.pi;
    return (latitude: latitude, longitude: longitude);
  }

  /// The tiles worth having for a pin at this point, nearest first.
  ///
  /// Usually one — a tile is 2.4km across and a picker session rarely leaves
  /// it. Two or four when the pin sits near an edge or a corner, which is the
  /// case that would otherwise leave the map bare on the side the user is
  /// dragging towards.
  static List<TileKey> tilesNear(
    double latitude,
    double longitude,
    double radiusMetres, {
    int limit = 4,
  }) {
    final reach = math.min(radiusMetres, _maxSelectionMetres);
    final dLat = reach / _metresPerDegree;
    final dLng =
        reach / (_metresPerDegree * math.cos(latitude * math.pi / 180.0));

    final keys = <TileKey>{};
    for (final la in [latitude - dLat, latitude, latitude + dLat]) {
      for (final lo in [longitude - dLng, longitude, longitude + dLng]) {
        keys.add(tileFor(la, lo));
      }
    }

    final ranked = keys.toList()
      ..sort((a, b) {
        final ca = centreOf(a);
        final cb = centreOf(b);
        return PlacesService.metresBetween(
                latitude, longitude, ca.latitude, ca.longitude)
            .compareTo(PlacesService.metresBetween(
                latitude, longitude, cb.latitude, cb.longitude));
      });
    return ranked.take(limit).toList();
  }

  static String urlFor(TileKey key) =>
      'https://api.maptiler.com/tiles/v3/${key.z}/${key.x}/${key.y}.pbf'
      '?key=${PlacesService.apiKey}';

  /// How a tile is actually obtained.
  ///
  /// Swappable so a test can drive the picker's tile logic — which tile it
  /// asks for, when it prefetches the next one, what it does with a failure —
  /// without a network and without the live key. Nothing but a test should
  /// assign to it.
  @visibleForTesting
  static Future<List<MapPoi>?> Function(TileKey key) fetcher = fetchOverHttp;

  /// Every named place in a tile, or null if the tile could not be had.
  static Future<List<MapPoi>?> fetch(TileKey key) => fetcher(key);

  /// Null rather than an empty list on failure, for the same reason the
  /// geocoding path draws that distinction: an empty tile is a real answer
  /// about a real rectangle and gets cached, while a failed request is not an
  /// answer at all and must not be.
  static Future<List<MapPoi>?> fetchOverHttp(TileKey key) async {
    if (!PlacesService.isConfigured) return null;

    try {
      final response = await http.get(Uri.parse(urlFor(key)));
      if (response.statusCode != 200) {
        dev.log(
          '[PoiTiles] ${key.z}/${key.x}/${key.y} HTTP ${response.statusCode}',
          name: 'PoiTiles',
        );
        return null;
      }
      // Off the main isolate: a city tile is a few thousand features, and
      // decoding it inline drops frames in the middle of a drag. On web there
      // are no isolates and compute() runs inline, so this is once-per-tile
      // jank there rather than none — still better than the same work
      // fourteen times a kilometre.
      return await compute(
        decodeTile,
        (bytes: response.bodyBytes, z: key.z, x: key.x, y: key.y),
      );
    } catch (e) {
      dev.log('[PoiTiles] ${key.z}/${key.x}/${key.y} failed: $e',
          name: 'PoiTiles');
      return null;
    }
  }
}

/// Pulls the named places out of one encoded tile.
///
/// Top-level and self-contained because it runs in another isolate. Public
/// only so a test can hand it real bytes without going near the network.
@visibleForTesting
List<MapPoi> decodeTile(
    ({Uint8List bytes, int z, int x, int y}) input) {
  final VectorTile tile;
  try {
    tile = VectorTile.fromBytes(bytes: input.bytes);
  } catch (_) {
    // A truncated or unexpected tile is not worth an exception on a background
    // isolate; it is worth no dots for a moment.
    return const [];
  }

  VectorTileLayer? poi;
  for (final layer in tile.layers) {
    if (layer.name == 'poi') {
      poi = layer;
      break;
    }
  }
  if (poi == null) return const [];

  final places = <MapPoi>[];
  for (final feature in poi.features) {
    if (feature.type != VectorTileGeomType.POINT) continue;

    final geo = feature.toGeoJson<GeoJsonPoint>(
      x: input.x,
      y: input.y,
      z: input.z,
    );
    final coordinates = geo?.geometry?.coordinates;
    if (coordinates == null || coordinates.length < 2) continue;

    final properties = feature.properties;
    // The Vietnamese rendering when the data carries one, the default name
    // otherwise — which for a Vietnamese place is already Vietnamese.
    final name = (_text(properties, 'name:vi') ?? _text(properties, 'name'))?.trim();
    // An unnamed feature is a dot that would label a site with nothing.
    if (name == null || name.isEmpty || name == '-') continue;

    final kind = _text(properties, 'class');
    if (kind != null && PoiTiles.deniedClasses.contains(kind)) continue;

    // GeoJSON order: longitude first.
    final longitude = coordinates[0];
    final latitude = coordinates[1];

    final id = feature.id.toString();
    places.add(MapPoi(
      id: id != '0'
          ? 'omt:$id'
          // Every named feature in the tiles measured carried an id, but a
          // coordinate is a stable fallback: the same place is at the same
          // point in every fetch of the same tile.
          : 'at:${latitude.toStringAsFixed(6)},${longitude.toStringAsFixed(6)}',
      name: name,
      // The tile has no composed address. The picker resolves one the moment
      // the pin actually latches on, which is when it is needed; until then
      // the name is the honest answer.
      address: name,
      category: _text(properties, 'subclass') ?? kind,
      latitude: latitude,
      longitude: longitude,
    ));
  }
  return places;
}

String? _text(Map<String, VectorTileValue>? properties, String key) {
  final value = properties?[key]?.value;
  return value is String ? value : null;
}
