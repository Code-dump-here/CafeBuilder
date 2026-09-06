import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../models/place_location.dart';
import 'local_store.dart';
import 'places_service.dart';
import 'poi_tiles.dart';

/// The map tiles whose places the picker has already decoded, held between
/// drags and between runs of the app.
///
/// Keyed by tile rather than by point, which is the whole difference. The
/// geocoding path this replaced could only ever say "the ten nearest to here",
/// so coverage had to be guessed at with radii; a tile is a rectangle, and
/// holding one means holding *all* of it. Three consequences, all free:
///
///  1. **Coverage is exact.** [covers] is a lookup, not a distance heuristic.
///  2. **Refreshing heals.** [recordTile] replaces a tile's places wholesale,
///     so anything that has closed is simply absent from the new one. No
///     reasoning about which cached places a reply implicitly denies.
///  3. **A drag is usually free.** A zoom-14 tile is 2.4km across and a
///     session placing one pin rarely leaves it.
///
/// Kept honest over days by two horizons: [_refreshAfter] decides when a tile
/// stops being trusted and gets re-fetched — that is what gives (2) its
/// chance — while [_keepFor] decides when an unrefreshed tile stops being
/// worth drawing at all. The gap between them is deliberate: the morning after,
/// the dots come straight up from disk *and* a refresh goes out, rather than
/// the map sitting blank waiting for one.
class PoiCache {
  /// Shared by the whole app on purpose. Outliving the picker page is most of
  /// the value: an owner who edits a project's address, backs out and opens it
  /// again is looking at the same tile.
  static final PoiCache instance = PoiCache();

  /// The clock, so a test can ask what this looks like next week without
  /// waiting a week. Nothing else should touch it.
  @visibleForTesting
  static DateTime Function() now = DateTime.now;

  static const String _storeKey = 'poi_tiles.v1';
  static const int _formatVersion = 1;

  /// Insertion-ordered, and [recordTile] re-inserts, so the front is the least
  /// recently fetched — which is what eviction drops.
  final Map<String, _CachedTile> _tiles = {};

  LocalStore? _store;
  Timer? _saveTimer;
  bool _restored = false;

  /// Three tiles is about 17 km² — a district and its neighbours, which is
  /// more than any one pin-placing session covers. In memory that is a few
  /// thousand places; the bounding-box reject in [around] is what keeps
  /// scanning them cheap.
  static const int _maxTiles = 3;

  /// But only the two most recent are written to disk. A dense city tile is
  /// about 132 KB of JSON, and shared preferences is a small store that is
  /// read whole at startup — two is a whole district and a sane thing to keep
  /// there.
  static const int _maxPersistedTiles = 2;

  /// When a tile stops being trusted and is worth asking for again.
  static const Duration _refreshAfter = Duration(hours: 12);

  /// When an unrefreshed tile stops being worth drawing.
  static const Duration _keepFor = Duration(days: 7);

  /// Default reach for [around] when the caller has no view to measure
  /// against. Callers that know how much ground is on screen should say so.
  static const double _defaultServeMetres = 2000;

  static const double _metresPerDegree = 111194.93;

  /// Read whatever was saved last time, and keep saving from now on.
  ///
  /// Idempotent and safe to call from anywhere. Failure is not an error: the
  /// cache starts empty, which is where it started before any of this.
  Future<void> restore(LocalStore store) async {
    if (_restored) return;
    _restored = true;
    _store = store;

    final raw = await store.read(_storeKey);
    if (raw == null) return;

    try {
      final body = jsonDecode(raw) as Map<String, dynamic>;
      // A format change means the saved shape is not the shape being read.
      // Throwing it away costs a request; guessing costs correctness.
      if (body['version'] != _formatVersion) {
        await store.remove(_storeKey);
        return;
      }
      for (final entry in (body['tiles'] as List<dynamic>? ?? const [])) {
        final tile = _CachedTile.fromJson(entry as Map<String, dynamic>);
        if (tile != null) _tiles[tile.key] = tile;
      }
      _prune();
    } catch (_) {
      _tiles.clear();
      await store.remove(_storeKey);
    }
  }

  /// The places nearest a point, nearest first, at most [limit] of them and no
  /// further out than [withinMetres].
  List<MapPoi> around(
    double latitude,
    double longitude, {
    int limit = 12,
    double withinMetres = _defaultServeMetres,
  }) {
    if (_tiles.isEmpty || limit <= 0) return const [];

    final cutoff = now().subtract(_keepFor);

    // A rectangle first. Three city tiles is several thousand places and this
    // runs several times a second during a drag, so the cheap reject goes
    // before the great-circle distance and throws out all but a handful.
    final dLat = withinMetres / _metresPerDegree;
    final dLng =
        withinMetres / (_metresPerDegree * math.cos(latitude * math.pi / 180));

    final seen = <String>{};
    final near = <({MapPoi place, double metres})>[];
    for (final tile in _tiles.values) {
      if (tile.fetchedAt.isBefore(cutoff)) continue;
      for (final place in tile.places) {
        if ((place.latitude - latitude).abs() > dLat) continue;
        if ((place.longitude - longitude).abs() > dLng) continue;
        // Tiles are buffered — a place near a boundary is carried by both
        // neighbours — so the same shop really does turn up twice.
        if (!seen.add(place.id)) continue;
        final metres = PlacesService.metresBetween(
            latitude, longitude, place.latitude, place.longitude);
        if (metres <= withinMetres) near.add((place: place, metres: metres));
      }
    }

    near.sort((a, b) => a.metres.compareTo(b.metres));
    return [for (final entry in near.take(limit)) entry.place];
  }

  /// Whether this tile is held and still trusted.
  bool covers(TileKey key) {
    final tile = _tiles[_keyOf(key)];
    if (tile == null) return false;
    return !tile.fetchedAt.isBefore(now().subtract(_refreshAfter));
  }

  /// File a decoded tile, replacing whatever was held for it.
  ///
  /// Replacement rather than merging is the point: the tile is the complete
  /// answer for its rectangle, so a place that has closed is gone simply by
  /// not being in the new one. Never call this with the null
  /// [PoiTiles.fetch] returns for a request that failed — recording a failure
  /// as an empty tile would claim a rectangle nobody has seen.
  void recordTile(TileKey key, List<MapPoi> places) {
    final id = _keyOf(key);
    // Removed before inserting so a refreshed tile moves to the back of the
    // insertion order and eviction drops the least recently fetched.
    _tiles.remove(id);
    _tiles[id] = _CachedTile(key: id, places: places, fetchedAt: now());
    _prune();
    _scheduleSave();
  }

  /// Forget everything, on disk as well as in memory.
  void clear() {
    _saveTimer?.cancel();
    _saveTimer = null;
    _tiles.clear();
    _restored = false;
    final store = _store;
    _store = null;
    if (store != null) unawaited(store.remove(_storeKey));
  }

  /// Write now rather than in a few seconds. For leaving a screen, and for
  /// tests that would otherwise end with a timer still pending.
  Future<void> flush() async {
    _saveTimer?.cancel();
    _saveTimer = null;
    final store = _store;
    if (store == null) return;

    // Only the most recent few reach disk; the rest stay a session's luxury.
    final persisted = _tiles.values.toList();
    final keep = persisted.length > _maxPersistedTiles
        ? persisted.sublist(persisted.length - _maxPersistedTiles)
        : persisted;

    await store.write(
      _storeKey,
      jsonEncode({
        'version': _formatVersion,
        'tiles': [for (final tile in keep) tile.toJson()],
      }),
    );
  }

  int get tileCount => _tiles.length;
  int get placeCount =>
      _tiles.values.fold(0, (sum, tile) => sum + tile.places.length);

  static String _keyOf(TileKey key) => '${key.z}/${key.x}/${key.y}';

  void _prune() {
    final cutoff = now().subtract(_keepFor);
    _tiles.removeWhere((_, tile) => tile.fetchedAt.isBefore(cutoff));
    while (_tiles.length > _maxTiles) {
      _tiles.remove(_tiles.keys.first);
    }
  }

  void _scheduleSave() {
    if (_store == null) return;
    // Debounced: crossing a couple of tile boundaries during one drag should
    // be one write, not three of a few hundred kilobytes each.
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 3), () {
      _saveTimer = null;
      unawaited(flush());
    });
  }
}

/// One tile's worth of places, and when it was decoded.
class _CachedTile {
  final String key;
  final List<MapPoi> places;
  final DateTime fetchedAt;

  const _CachedTile({
    required this.key,
    required this.places,
    required this.fetchedAt,
  });

  Map<String, dynamic> toJson() => {
        'k': key,
        't': fetchedAt.millisecondsSinceEpoch,
        // Positional and short: a dense tile is a couple of thousand of these,
        // and the field names would outweigh the data.
        'p': [
          for (final place in places)
            [place.id, place.name, place.category ?? '', place.latitude, place.longitude],
        ],
      };

  static _CachedTile? fromJson(Map<String, dynamic> json) {
    final key = json['k'] as String?;
    final at = json['t'] as int?;
    final rows = json['p'] as List<dynamic>?;
    if (key == null || at == null || rows == null) return null;

    final places = <MapPoi>[];
    for (final row in rows) {
      if (row is! List || row.length < 5) return null;
      final id = row[0] as String?;
      final name = row[1] as String?;
      final category = row[2] as String?;
      final latitude = (row[3] as num?)?.toDouble();
      final longitude = (row[4] as num?)?.toDouble();
      if (id == null || name == null || latitude == null || longitude == null) {
        return null;
      }
      places.add(MapPoi(
        id: id,
        name: name,
        // Tiles carry no composed address; the name is what is known until the
        // pin actually latches on and one is resolved.
        address: name,
        category: category == null || category.isEmpty ? null : category,
        latitude: latitude,
        longitude: longitude,
      ));
    }

    return _CachedTile(
      key: key,
      places: places,
      fetchedAt: DateTime.fromMillisecondsSinceEpoch(at),
    );
  }
}
