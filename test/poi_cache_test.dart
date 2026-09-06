import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';

import 'package:cafe_builder/models/place_location.dart';
import 'package:cafe_builder/services/local_store.dart';
import 'package:cafe_builder/services/places_service.dart';
import 'package:cafe_builder/services/poi_cache.dart';
import 'package:cafe_builder/services/poi_tiles.dart';

/// A real zoom-14 tile over central Ho Chi Minh City, and its eastern
/// neighbour.
const TileKey _tile = (z: 14, x: 13048, y: 7698);
const TileKey _neighbour = (z: 14, x: 13049, y: 7698);

const double _metresPerDegree = 111194.93;

/// A coordinate [metres] due east of the middle of [_tile].
({double lat, double lng}) _east(double metres) {
  final centre = PoiTiles.centreOf(_tile);
  return (
    lat: centre.latitude,
    lng: centre.longitude +
        metres / (_metresPerDegree * math.cos(centre.latitude * math.pi / 180)),
  );
}

MapPoi _placeEastOf(String id, double metres) {
  final at = _east(metres);
  return MapPoi(
    id: id,
    name: id,
    address: id,
    category: 'cafe',
    latitude: at.lat,
    longitude: at.lng,
  );
}

/// A [LocalStore] that keeps one string in memory, so persistence can be
/// tested without a device and without waiting days.
class _FakeStore implements LocalStore {
  final Map<String, String> saved = {};
  int writes = 0;

  @override
  Future<String?> read(String key) async => saved[key];

  @override
  Future<void> write(String key, String value) async {
    writes++;
    saved[key] = value;
  }

  @override
  Future<void> remove(String key) async => saved.remove(key);
}

void main() {
  final cache = PoiCache.instance;
  setUp(cache.clear);
  tearDown(() {
    cache.clear();
    PoiCache.now = DateTime.now;
  });

  test('an empty cache draws nothing and holds no ground', () {
    final at = _east(0);
    expect(cache.around(at.lat, at.lng), isEmpty);
    expect(cache.covers(_tile), isFalse);
    expect(cache.tileCount, 0);
  });

  test('a filed tile is served back, nearest first', () {
    cache.recordTile(_tile, [
      _placeEastOf('far', 300),
      _placeEastOf('near', 20),
      _placeEastOf('middle', 120),
    ]);

    final at = _east(0);
    expect([for (final p in cache.around(at.lat, at.lng)) p.id],
        ['near', 'middle', 'far']);

    // Ordered by the point being asked about, not the tile it came from. This
    // is what lets the dots re-rank while the pin moves, with nothing in
    // flight and no new request.
    final beyond = _east(400);
    expect(cache.around(beyond.lat, beyond.lng).first.id, 'far');
  });

  test('holding a tile means holding all of it', () {
    cache.recordTile(_tile, [_placeEastOf('shop', 20)]);

    // Exact, not a radius guess. The whole 2.4km rectangle is answered for,
    // and nothing outside it is.
    expect(cache.covers(_tile), isTrue);
    expect(cache.covers(_neighbour), isFalse);
  });

  test('a tile that really is empty still counts as held', () {
    // Farmland. The tile answered, and the answer was "nothing here" — which
    // is a fact worth keeping, or a drag across it asks forever.
    cache.recordTile(_tile, const []);

    final at = _east(0);
    expect(cache.around(at.lat, at.lng), isEmpty);
    expect(cache.covers(_tile), isTrue);
  });

  test('neighbouring tiles are drawn together', () {
    cache.recordTile(_tile, [_placeEastOf('here', 20)]);
    cache.recordTile(_neighbour, [_placeEastOf('there', 900)]);

    final at = _east(0);
    expect([for (final p in cache.around(at.lat, at.lng)) p.id],
        ['here', 'there']);
  });

  test('a place carried by two tiles is drawn once', () {
    // Tiles are buffered, so a place near a boundary really is in both. The
    // same shop twice would be two dots on top of each other, and the nearer
    // of the two would win the latch by a rounding error.
    final onTheLine = _placeEastOf('borderShop', 1150);
    cache.recordTile(_tile, [onTheLine, _placeEastOf('inland', 40)]);
    cache.recordTile(_neighbour, [onTheLine]);

    final at = _east(0);
    final drawn = cache.around(at.lat, at.lng);
    expect(drawn.where((p) => p.id == 'borderShop'), hasLength(1));
    expect(drawn, hasLength(2));
  });

  // ── Staying honest ──────────────────────────────────────────────────────

  test('a place that has closed is gone the next time its tile is fetched', () {
    cache.recordTile(_tile, [
      _placeEastOf('stillOpen', 12),
      _placeEastOf('closedDown', 21),
      _placeEastOf('alsoOpen', 30),
    ]);
    expect(cache.placeCount, 3);

    // The same tile, a week later, without it. A tile is the complete answer
    // for its rectangle, so this needs no reasoning about what the new list
    // implicitly denies — replacing it is the whole of the argument.
    cache.recordTile(_tile, [
      _placeEastOf('stillOpen', 12),
      _placeEastOf('alsoOpen', 30),
    ]);

    final at = _east(0);
    expect([for (final p in cache.around(at.lat, at.lng)) p.id],
        ['stillOpen', 'alsoOpen']);
    expect(cache.placeCount, 2);
  });

  test('a tile goes stale long before its dots do', () {
    var clock = DateTime(2026, 9, 2, 9);
    PoiCache.now = () => clock;
    cache.recordTile(_tile, [_placeEastOf('corner', 20)]);

    final at = _east(0);
    expect(cache.covers(_tile), isTrue);

    // Next morning. The tile is due to be fetched again — that is what gives
    // the replacement above its chance — but the dots still come straight up
    // rather than leaving the map blank while it flies.
    clock = clock.add(const Duration(hours: 13));
    expect(cache.covers(_tile), isFalse);
    expect(cache.around(at.lat, at.lng), hasLength(1));

    // A week on, with nothing having refreshed it, a tile nobody has checked
    // stops being worth drawing.
    clock = clock.add(const Duration(days: 8));
    expect(cache.around(at.lat, at.lng), isEmpty);
  });

  test('only a few tiles are kept', () {
    for (var i = 0; i < 8; i++) {
      cache.recordTile((z: 14, x: 13040 + i, y: 7698), [
        _placeEastOf('p$i', 20),
      ]);
    }
    expect(cache.tileCount, lessThanOrEqualTo(3));
    // And what survived is where the user just was, not where they started.
    expect(cache.covers((z: 14, x: 13047, y: 7698)), isTrue);
    expect(cache.covers((z: 14, x: 13040, y: 7698)), isFalse);
  });

  test('places too far away to aim at are not served', () {
    cache.recordTile(_tile, [_placeEastOf('nextDistrict', 9000)]);
    final at = _east(0);

    // Held — it is genuinely in the tile's buffer — but never drawn: a dot
    // that far out is off the box at every zoom the picker opens at.
    expect(cache.placeCount, 1);
    expect(cache.around(at.lat, at.lng), isEmpty);
    expect(cache.around(at.lat, at.lng, withinMetres: 12000), hasLength(1));
  });

  test('the caller gets no more dots than it asked for', () {
    cache.recordTile(_tile, [
      for (var i = 1; i <= 20; i++) _placeEastOf('p$i', i * 10.0),
    ]);
    final at = _east(0);

    expect(cache.around(at.lat, at.lng, limit: 5), hasLength(5));
    expect([for (final p in cache.around(at.lat, at.lng, limit: 3)) p.id],
        ['p1', 'p2', 'p3']);
    expect(cache.around(at.lat, at.lng, limit: 0), isEmpty);
  });

  // ── What it costs ───────────────────────────────────────────────────────

  test('a kilometre of dragging costs one request', () {
    // Exactly what the picker does: at every point it would ask about, work
    // out which tiles it wants and count the ones it has not got.
    var requests = 0;
    void ask(double metres) {
      final at = _east(metres);
      for (final key in PoiTiles.tilesNear(at.lat, at.lng, 500)) {
        if (cache.covers(key)) continue;
        requests++;
        cache.recordTile(key, [_placeEastOf('near-$metres', metres + 10)]);
      }
    }

    // A kilometre, sampled every 18m — the picker's refresh distance at the
    // zoom it opens on.
    for (var metres = 0.0; metres <= 1000; metres += 18) {
      ask(metres);
    }
    // Two: the tile the pin started in, and — once the pin is about 700m out
    // and its 500m reach crosses the boundary — the neighbour holding the dots
    // to the east. The geocoding path this replaced spent fourteen over the
    // same ground.
    expect(requests, 2);

    // And back again, for nothing.
    for (var metres = 1000.0; metres >= 0; metres -= 18) {
      ask(metres);
    }
    expect(requests, 2);
  });

  // ── Surviving a restart ─────────────────────────────────────────────────

  test('what one session learned, the next one opens with', () async {
    final store = _FakeStore();
    await cache.restore(store);
    cache.recordTile(_tile, [
      _placeEastOf('corner', 20),
      _placeEastOf('kiosk', 90),
    ]);
    await cache.flush();

    // A new run of the app: nothing in memory, everything still on disk.
    // Snapshotted before clear(), which is a deliberate "forget everything"
    // and wipes the saved copy too.
    final onDisk = Map<String, String>.from(store.saved);
    cache.clear();
    expect(cache.tileCount, 0);

    await cache.restore(_FakeStore()..saved.addAll(onDisk));
    final at = _east(0);
    expect([for (final p in cache.around(at.lat, at.lng)) p.id],
        ['corner', 'kiosk']);
    expect(cache.covers(_tile), isTrue,
        reason: 'so reopening the picker in the same district costs nothing');
  });

  test('a saved tile too old to trust does not come back', () async {
    var clock = DateTime(2026, 9, 2, 9);
    PoiCache.now = () => clock;

    final store = _FakeStore();
    await cache.restore(store);
    cache.recordTile(_tile, [_placeEastOf('corner', 20)]);
    await cache.flush();

    final onDisk = Map<String, String>.from(store.saved);
    cache.clear();
    // Sanity: the blob really is there, so the emptiness below is expiry doing
    // its job rather than nothing having been saved.
    expect(onDisk, isNotEmpty);

    clock = clock.add(const Duration(days: 9));
    PoiCache.now = () => clock;
    await cache.restore(_FakeStore()..saved.addAll(onDisk));

    expect(cache.tileCount, 0,
        reason: 'nine days of nobody looking is not evidence of anything');
    expect(cache.covers(_tile), isFalse);
  });

  test('a corrupt or unfamiliar saved cache is discarded, never guessed at',
      () async {
    for (final blob in [
      'not json at all',
      '{"version":99,"tiles":[]}',
      '{"version":1,"tiles":[{"k":"14/1/1"}]}', // no timestamp, no places
      '{"version":1,"tiles":[{"k":"14/1/1","t":1,"p":[["id"]]}]}', // short row
    ]) {
      cache.clear();
      await cache.restore(_FakeStore()..saved['poi_tiles.v1'] = blob);
      expect(cache.tileCount, 0, reason: blob);
    }
  });

  test('saving is batched, and only the newest tiles reach disk', () async {
    final store = _FakeStore();
    await cache.restore(store);

    for (var i = 0; i < 5; i++) {
      cache.recordTile((z: 14, x: 13040 + i, y: 7698), [_placeEastOf('p$i', 20)]);
    }
    expect(store.writes, 0, reason: 'nothing written while the drag is going');

    await cache.flush();
    expect(store.writes, 1);

    // A dense city tile is about 132 KB of JSON and shared preferences is read
    // whole at startup, so the disk copy is capped tighter than memory is.
    final onDisk = Map<String, String>.from(store.saved);
    cache.clear();
    await cache.restore(_FakeStore()..saved.addAll(onDisk));
    expect(cache.tileCount, 2,
        reason: 'three tiles in memory, the newest two on disk');
  });

  test('clear empties memory and disk', () async {
    final store = _FakeStore();
    await cache.restore(store);
    cache.recordTile(_tile, [_placeEastOf('a', 20)]);
    await cache.flush();

    cache.clear();
    expect(cache.tileCount, 0);
    expect(store.saved, isEmpty);
  });

  test('metresBetween measures real ground distance', () {
    // Leaned on by every distance above.
    expect(PlacesService.metresBetween(10.0, 106.0, 11.0, 106.0),
        closeTo(111194.9, 1.0));
  });
}
