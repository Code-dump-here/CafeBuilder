import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/place_location.dart';
import 'local_store.dart';
import 'places_service.dart';

/// Addresses the geocoder has already given for a point on the map.
///
/// The other half of the picker's request budget, and until now the uncached
/// half: every time a drag settles, the pin's coordinates go back to MapTiler
/// to be turned into a street address. That is one request per settle, and a
/// settle happens every time the user pauses — including when they nudge the
/// pin and immediately drag it back, which is most of what "adjusting a pin"
/// actually is.
///
/// Deliberately much tighter than [PoiCache]. A place is a thing that exists
/// somewhere; an address is a property of a specific spot, and the house
/// number changes from doorway to doorway. [_sameSpotMetres] is set to about
/// the width of a building frontage, so a real re-aim always gets a real
/// answer and only a return to somewhere already asked about is free.
///
/// Only successes are filed. [PlacesService.reverseGeocode] returns null both
/// when it fails and when nothing matches, and neither is worth remembering as
/// an answer.
class AddressCache {
  static final AddressCache instance = AddressCache();

  /// The clock, so a test can ask what this looks like next week. Nothing else
  /// should touch it.
  @visibleForTesting
  static DateTime Function() now = DateTime.now;

  static const String _storeKey = 'address_cache.v1';
  static const int _formatVersion = 1;

  /// Close enough to be the same doorway.
  ///
  /// Fifteen metres is roughly one building frontage. Wider and the picker
  /// would confidently label a shop with its neighbour's house number; much
  /// narrower and it would never hit, because a settle rarely lands on the
  /// exact coordinate of a previous one.
  static const double _sameSpotMetres = 15;

  /// Addresses change — a lane is renamed, a building is renumbered — and
  /// unlike places there is no completeness property to prune against, so this
  /// leans on expiry alone and expires sooner than [PoiCache] does.
  static const Duration _ttl = Duration(days: 3);

  static const int _maxEntries = 200;

  final List<_KnownAddress> _entries = [];

  LocalStore? _store;
  Timer? _saveTimer;
  bool _restored = false;

  Future<void> restore(LocalStore store) async {
    if (_restored) return;
    _restored = true;
    _store = store;

    final raw = await store.read(_storeKey);
    if (raw == null) return;

    try {
      final body = jsonDecode(raw) as Map<String, dynamic>;
      if (body['version'] != _formatVersion) {
        await store.remove(_storeKey);
        return;
      }
      for (final entry in (body['entries'] as List<dynamic>? ?? const [])) {
        final known = _KnownAddress.fromJson(entry as Map<String, dynamic>);
        if (known != null) _entries.add(known);
      }
      _prune();
    } catch (_) {
      _entries.clear();
      await store.remove(_storeKey);
    }
  }

  /// The address already known for this spot, or null to go and ask.
  PickedLocation? lookup(double latitude, double longitude) {
    final cutoff = now().subtract(_ttl);

    _KnownAddress? best;
    var bestMetres = double.infinity;
    for (final entry in _entries) {
      if (entry.at.isBefore(cutoff)) continue;
      final metres = PlacesService.metresBetween(
          latitude, longitude, entry.latitude, entry.longitude);
      if (metres <= _sameSpotMetres && metres < bestMetres) {
        bestMetres = metres;
        best = entry;
      }
    }
    if (best == null) return null;

    // The caller's own coordinates, not the ones the answer was filed under.
    // The pin is where the user put it; only the words are being reused.
    return PickedLocation(
      address: best.address,
      latitude: latitude,
      longitude: longitude,
    );
  }

  void record(double latitude, double longitude, String address) {
    if (address.trim().isEmpty) return;

    // A spot already known is refreshed in place rather than added again,
    // which is what stops a session of nudging one pin from filling the list
    // with two hundred copies of the same doorway.
    _entries.removeWhere((entry) =>
        PlacesService.metresBetween(
            latitude, longitude, entry.latitude, entry.longitude) <=
        _sameSpotMetres);

    _entries.add(_KnownAddress(
      latitude: latitude,
      longitude: longitude,
      address: address,
      at: now(),
    ));

    _prune();
    _scheduleSave();
  }

  void clear() {
    _saveTimer?.cancel();
    _saveTimer = null;
    _entries.clear();
    _restored = false;
    final store = _store;
    _store = null;
    if (store != null) unawaited(store.remove(_storeKey));
  }

  Future<void> flush() async {
    _saveTimer?.cancel();
    _saveTimer = null;
    final store = _store;
    if (store == null) return;
    await store.write(
      _storeKey,
      jsonEncode({
        'version': _formatVersion,
        'entries': [for (final entry in _entries) entry.toJson()],
      }),
    );
  }

  int get entryCount => _entries.length;

  void _prune() {
    final cutoff = now().subtract(_ttl);
    _entries.removeWhere((entry) => entry.at.isBefore(cutoff));
    if (_entries.length > _maxEntries) {
      _entries.removeRange(0, _entries.length - _maxEntries);
    }
  }

  void _scheduleSave() {
    if (_store == null) return;
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 3), () {
      _saveTimer = null;
      unawaited(flush());
    });
  }
}

class _KnownAddress {
  final double latitude;
  final double longitude;
  final String address;
  final DateTime at;

  const _KnownAddress({
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.at,
  });

  Map<String, dynamic> toJson() => {
        'y': latitude,
        'x': longitude,
        'a': address,
        't': at.millisecondsSinceEpoch,
      };

  static _KnownAddress? fromJson(Map<String, dynamic> json) {
    final latitude = (json['y'] as num?)?.toDouble();
    final longitude = (json['x'] as num?)?.toDouble();
    final address = json['a'] as String?;
    final at = json['t'] as int?;
    if (latitude == null || longitude == null || address == null || at == null) {
      return null;
    }
    return _KnownAddress(
      latitude: latitude,
      longitude: longitude,
      address: address,
      at: DateTime.fromMillisecondsSinceEpoch(at),
    );
  }
}
