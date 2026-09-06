import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';

import 'package:cafe_builder/services/address_cache.dart';
import 'package:cafe_builder/services/local_store.dart';

const double _lat = 10.7769;
const double _lng = 106.7009;
const double _metresPerDegree = 111194.93;

({double lat, double lng}) _east(double metres) => (
      lat: _lat,
      lng: _lng + metres / (_metresPerDegree * math.cos(_lat * math.pi / 180)),
    );

class _FakeStore implements LocalStore {
  final Map<String, String> saved = {};

  @override
  Future<String?> read(String key) async => saved[key];

  @override
  Future<void> write(String key, String value) async => saved[key] = value;

  @override
  Future<void> remove(String key) async => saved.remove(key);
}

void main() {
  final cache = AddressCache.instance;
  setUp(cache.clear);
  tearDown(() {
    cache.clear();
    AddressCache.now = DateTime.now;
  });

  test('an empty cache sends every settle to the geocoder', () {
    expect(cache.lookup(_lat, _lng), isNull);
    expect(cache.entryCount, 0);
  });

  test('coming back to a spot already asked about is free', () {
    cache.record(_lat, _lng, '123 Lê Lợi, Bến Nghé, Quận 1');

    // The nudge-and-drag-back that adjusting a pin actually consists of. Under
    // ten metres is the same doorway.
    final nudged = _east(8);
    final hit = cache.lookup(nudged.lat, nudged.lng);
    expect(hit?.address, '123 Lê Lợi, Bến Nghé, Quận 1');

    // And it answers for where the pin actually is, not where the address was
    // filed. The words are being reused; the coordinates are the user's.
    expect(hit!.latitude, nudged.lat);
    expect(hit.longitude, nudged.lng);
  });

  test('a real re-aim gets a real answer', () {
    cache.record(_lat, _lng, '123 Lê Lợi');

    // Twenty-five metres is the next building along, and it has its own house
    // number. Confidently labelling it with the neighbour's would be worse
    // than spending the request.
    final along = _east(25);
    expect(cache.lookup(along.lat, along.lng), isNull);
  });

  test('nudging one pin does not fill the cache with copies of it', () {
    for (var i = 0; i < 40; i++) {
      final at = _east(i % 10.0);
      cache.record(at.lat, at.lng, 'somewhere');
    }
    expect(cache.entryCount, 1,
        reason: 'forty settles inside one doorway is one address');
  });

  test('an address is not trusted forever', () {
    var clock = DateTime(2026, 9, 2, 9);
    AddressCache.now = () => clock;

    cache.record(_lat, _lng, '123 Lê Lợi');
    expect(cache.lookup(_lat, _lng), isNotNull);

    // Still good the next day - this is the whole point of persisting it.
    clock = clock.add(const Duration(days: 1));
    expect(cache.lookup(_lat, _lng), isNotNull);

    // But lanes get renamed and buildings renumbered, and unlike places there
    // is no way to prove an address is still right short of asking again.
    clock = clock.add(const Duration(days: 3));
    expect(cache.lookup(_lat, _lng), isNull);
  });

  test('what one session learned, the next one opens with', () async {
    final store = _FakeStore();
    await cache.restore(store);
    cache.record(_lat, _lng, '123 Lê Lợi');
    await cache.flush();

    final onDisk = Map<String, String>.from(store.saved);
    cache.clear();
    expect(cache.lookup(_lat, _lng), isNull);

    await cache.restore(_FakeStore()..saved.addAll(onDisk));
    expect(cache.lookup(_lat, _lng)?.address, '123 Lê Lợi');
  });

  test('a corrupt or unfamiliar saved cache is discarded, never guessed at',
      () async {
    for (final blob in [
      'not json at all',
      '{"version":99,"entries":[]}',
      '{"version":1,"entries":[{"a":"no coordinates"}]}',
    ]) {
      cache.clear();
      await cache.restore(_FakeStore()..saved['address_cache.v1'] = blob);
      expect(cache.entryCount, 0, reason: blob);
    }
  });

  test('an empty address is never filed as an answer', () {
    cache.record(_lat, _lng, '   ');
    expect(cache.entryCount, 0);
    expect(cache.lookup(_lat, _lng), isNull);
  });
}
