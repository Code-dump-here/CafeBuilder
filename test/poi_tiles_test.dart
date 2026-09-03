import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:cafe_builder/models/place_location.dart';
import 'package:cafe_builder/services/places_service.dart';
import 'package:cafe_builder/services/poi_tiles.dart';

/// A real zoom-14 tile pulled from MapTiler, covering Bình Chánh on the
/// south-west edge of Ho Chi Minh City.
///
/// Real bytes rather than a hand-built fixture, because every interesting thing
/// about this decoder — the geometry projection, the property tables, which
/// features carry an id, what a Vietnamese name looks like in the data — is a
/// fact about the live tileset that a synthetic tile would only assert back at
/// itself.
const _tileKey = (z: 14, x: 13042, y: 7701);

Uint8List _fixture() =>
    File('test/fixtures/poi_tile_z14.pbf').readAsBytesSync();

List<MapPoi> _decoded() => decodeTile((
      bytes: _fixture(),
      z: _tileKey.z,
      x: _tileKey.x,
      y: _tileKey.y,
    ));

void main() {
  test('a real tile decodes to named places', () {
    final places = _decoded();

    // Checked against an independent decode of the same bytes: the poi layer
    // holds 74 point features, 59 of them named, 44 of those bus stops, gates
    // and shelters. Fifteen places is what is left worth pointing at — and
    // still more than the ten a geocoding request returns, from a rectangle
    // 2.4km across rather than a point.
    expect(places, hasLength(15));

    for (final place in places) {
      expect(place.name.trim(), isNotEmpty);
      expect(place.name, isNot('-'));
      expect(place.id, isNotEmpty);
    }
  });

  test('places land where they belong on the ground', () {
    final places = _decoded();
    final centre = PoiTiles.centreOf(_tileKey);

    // A zoom-14 tile is 2.4km across, so its half-diagonal is about 1.7km —
    // but tiles are *buffered*, and this one carries features from -599 to
    // 5118 in a 0..4096 extent, roughly 600m of overhang past each edge. So
    // the honest bound is the half-diagonal plus the buffer, and the point of
    // the check is to catch a projection that is wrong by kilometres: reading
    // tile-local units as degrees, or swapping the GeoJSON longitude-first
    // order.
    for (final place in places) {
      final metres = PlacesService.metresBetween(
          centre.latitude, centre.longitude, place.latitude, place.longitude);
      expect(metres, lessThan(3000), reason: '${place.name} at $metres m');
    }

    // And they really are in Ho Chi Minh City, not off the coast of Africa
    // where a longitude/latitude swap would put them.
    final first = places.first;
    expect(first.latitude, inInclusiveRange(10.0, 11.5));
    expect(first.longitude, inInclusiveRange(106.0, 107.5));
  });

  test('the tile knows what kind of place each one is', () {
    final places = _decoded();
    final kinds = places.map((p) => p.category).whereType<String>().toSet();

    expect(kinds, isNotEmpty,
        reason: 'the category picks the icon on the map');
    // Whatever else is in there, a tile over a Vietnamese suburb has schools
    // and places of worship in it.
    expect(kinds.any((k) => k.contains('school') || k.contains('worship')),
        isTrue,
        reason: 'kinds found: $kinds');
  });

  test('street furniture is left out', () {
    final places = _decoded();

    // This tile has 43 bus stops, 6 gates and 4 shelters in its poi layer.
    // None of them is a thing to name a construction site after, and a dot the
    // pin can latch onto is a dot the pin will latch onto.
    for (final place in places) {
      expect(PoiTiles.deniedClasses.contains(place.category), isFalse,
          reason: '${place.name} (${place.category})');
    }
  });

  test('the same tile decodes to the same ids every time', () {
    // Ids have to be stable across fetches or the cache would treat every
    // refresh as a tile full of new places.
    final first = _decoded().map((p) => p.id).toList();
    final second = _decoded().map((p) => p.id).toList();
    expect(second, first);
    expect(first.toSet().length, first.length, reason: 'and no duplicates');
  });

  test('a tile that is not a tile decodes to nothing rather than throwing', () {
    expect(
      decodeTile((bytes: Uint8List.fromList([1, 2, 3, 4, 5]), z: 14, x: 1, y: 1)),
      isEmpty,
    );
    expect(decodeTile((bytes: Uint8List(0), z: 14, x: 1, y: 1)), isEmpty);
  });

  // ── Which tiles to ask for ──────────────────────────────────────────────

  test('a coordinate maps to the tile it sits in', () {
    // The tile the fixture came from, derived from the coordinate it covers.
    expect(PoiTiles.tileFor(10.72, 106.58), _tileKey);

    // And back again: the middle of a tile is inside that tile.
    final centre = PoiTiles.centreOf(_tileKey);
    expect(PoiTiles.tileFor(centre.latitude, centre.longitude), _tileKey);
  });

  test('a pin in the middle of a tile needs only that tile', () {
    final centre = PoiTiles.centreOf(_tileKey);
    final needed = PoiTiles.tilesNear(centre.latitude, centre.longitude, 500);

    expect(needed, [_tileKey],
        reason: 'a tile is 2.4km across, so a 500m reach from the middle of '
            'one never leaves it — which is why a picker session is usually a '
            'single request');
  });

  test('a pin near an edge also wants the tile it is about to cross into', () {
    final centre = PoiTiles.centreOf(_tileKey);
    // A little over a kilometre east: past the halfway line, so the reach
    // spills over the boundary.
    const eastwards = 0.011;
    final needed = PoiTiles.tilesNear(
        centre.latitude, centre.longitude + eastwards, 800);

    expect(needed.length, greaterThan(1));
    expect(needed.first, isNot(equals(needed.last)));
    expect(needed, contains((z: 14, x: _tileKey.x + 1, y: _tileKey.y)));
  });

  test('a zoomed-out viewport does not ask for the province', () {
    final centre = PoiTiles.centreOf(_tileKey);
    // 54km of reach, which is what the serve radius works out to around zoom
    // 10. Left uncapped this would be hundreds of tiles.
    final needed =
        PoiTiles.tilesNear(centre.latitude, centre.longitude, 54000);

    expect(needed.length, lessThanOrEqualTo(4));
    expect(needed.first, _tileKey,
        reason: 'and the one the pin is actually in comes first');
  });
}
