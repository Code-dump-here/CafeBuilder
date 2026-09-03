import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:cafe_builder/models/place_location.dart';
import 'package:cafe_builder/pages/location_picker_page.dart';
import 'package:cafe_builder/services/places_service.dart';
import 'package:cafe_builder/services/poi_cache.dart';
import 'package:cafe_builder/services/poi_tiles.dart';
import 'package:cafe_builder/widgets/interactive_map_picker.dart';

/// Run with the map key defined, or every assertion here fails:
///
///   flutter test --dart-define=GOOGLE_MAPS_API_KEY=`key`
///
/// `PlacesService.isConfigured` is a compile-time constant, so without it the
/// map builds to a `SizedBox.shrink()` and there is nothing to find.
///
/// The picker opens over Ho Chi Minh City when it is given no pin, so the
/// fixtures are laid out from there.
const double _metresPerDegree = 111194.93;

/// A place [metres] due east of where the picker opens.
MapPoi _placeEast(String name, double metres) {
  const lat = PlacesService.defaultProximityLat;
  const lng = PlacesService.defaultProximityLng;
  return MapPoi(
    id: name,
    name: name,
    address: '$name, somewhere',
    category: 'cafe',
    latitude: lat,
    longitude: lng + metres / (_metresPerDegree * math.cos(lat * math.pi / 180)),
  );
}

Finder _dotOf(String name) => find.byWidgetPredicate(
      (w) => w is Tooltip && (w.message ?? '').startsWith('$name ·'),
    );

/// Which tile the pin currently sits in.
///
/// Read off the picker's own props, which the page rewrites on every frame of
/// a drag — so this is where the pin actually is, not where it started.
TileKey _pinTile(WidgetTester tester) {
  final picker =
      tester.widget<InteractiveMapPicker>(find.byType(InteractiveMapPicker));
  return PoiTiles.tileFor(picker.initialLatitude, picker.initialLongitude);
}

/// Fills the cache as if the tile the picker opens on had already been
/// fetched and decoded.
void _cacheHolds(List<MapPoi> places) => PoiCache.instance.recordTile(
      PoiTiles.tileFor(
        PlacesService.defaultProximityLat,
        PlacesService.defaultProximityLng,
      ),
      places,
    );

void main() {
  setUpAll(() {
    // Otherwise every test tries to download a font it is never going to get.
    GoogleFonts.config.allowRuntimeFetching = false;
  });
  setUp(PoiCache.instance.clear);
  tearDown(() {
    PoiCache.instance.clear();
    PoiTiles.fetcher = PoiTiles.fetchOverHttp;
  });

  // Nothing here reaches the network: the test harness refuses HTTP, and every
  // assertion below is about what the page can answer without it. That is the
  // point — these are the paths that used to need a round trip.

  testWidgets('opens with the dots the cache already holds', (tester) async {
    _cacheHolds([_placeEast('Corner', 30), _placeEast('Kiosk', 90)]);

    await tester.pumpWidget(const MaterialApp(home: LocationPickerPage()));

    // First frame. Nothing has been awaited, and the map is already furnished
    // — reopening the picker on a neighbourhood already looked at no longer
    // starts blank.
    expect(_dotOf('Corner'), findsOneWidget);
    expect(_dotOf('Kiosk'), findsOneWidget);
  });

  testWidgets('opens bare when the cache has nothing to say about the area',
      (tester) async {
    _cacheHolds([_placeEast('Elsewhere', 40000)]);

    await tester.pumpWidget(const MaterialApp(home: LocationPickerPage()));

    expect(_dotOf('Elsewhere'), findsNothing,
        reason: 'a place 40km away is not a latch target, and drawing it '
            'would put another city on this map');
  });

  testWidgets('a fix that cannot be taken still leaves a way forward',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LocationPickerPage()));

    await tester.tap(find.byTooltip('Move the pin to where I am'));
    await tester.pump();

    // A test binding answers no platform channel at all, so this is the wedged
    // case: without the bound on those calls the button would spin here for as
    // long as the picker stayed open.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
    await tester.pump();

    // The user is told what happened and pointed back at the map, rather than
    // being left with a dead button.
    expect(find.textContaining('cannot report its location'), findsOneWidget);
    expect(find.byType(InteractiveMapPicker), findsOneWidget,
        reason: 'the map is still there to place the pin by hand');

    // Let the snack bar run out so no timer outlives the test.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  // ── Which tiles the picker actually asks for ────────────────────────────

  /// Records every tile asked for, and answers with one place in the middle of
  /// it so the picker has something to draw.
  List<TileKey> _recordFetches({bool succeed = true}) {
    final asked = <TileKey>[];
    PoiTiles.fetcher = (key) async {
      asked.add(key);
      if (!succeed) return null;
      final centre = PoiTiles.centreOf(key);
      return [
        MapPoi(
          id: 'in-${key.x}-${key.y}',
          name: 'Tile ${key.x}',
          address: 'Tile ${key.x}',
          category: 'cafe',
          latitude: centre.latitude,
          longitude: centre.longitude,
        ),
      ];
    };
    return asked;
  }

  /// A picker opened on a pin in the middle of a tile.
  ///
  /// The middle matters: the app's default proximity point sits 186m from its
  /// tile's western edge, so a 500m reach from there legitimately spans two
  /// tiles and the counts below would be measuring the geometry of one
  /// arbitrary coordinate rather than the policy.
  Widget _pickerAtTileCentre() {
    final centre = PoiTiles.centreOf(PoiTiles.tileFor(
      PlacesService.defaultProximityLat,
      PlacesService.defaultProximityLng,
    ));
    return MaterialApp(
      home: LocationPickerPage(
        initial: PickedLocation(
          address: 'somewhere',
          latitude: centre.latitude,
          longitude: centre.longitude,
        ),
      ),
    );
  }

  testWidgets('opening the picker costs one tile', (tester) async {
    final asked = _recordFetches();

    await tester.pumpWidget(_pickerAtTileCentre());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(asked, hasLength(1),
        reason: 'a tile is 2.4km across, so opening on a pin needs exactly '
            'one — where the geocoding path this replaced spent one every '
            'forty-odd metres of dragging');

    // Let the cache's debounced save run out, so no timer outlives the test.
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });

  testWidgets('and a second open costs nothing at all', (tester) async {
    final asked = _recordFetches();

    await tester.pumpWidget(_pickerAtTileCentre());
    await tester.pump(const Duration(milliseconds: 50));
    expect(asked, hasLength(1));

    // Back out and in again — a fresh page, the same neighbourhood.
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await tester.pumpWidget(_pickerAtTileCentre());
    await tester.pump(const Duration(milliseconds: 50));

    expect(asked, hasLength(1), reason: 'the tile is already held');

    // Let the cache's debounced save run out, so no timer outlives the test.
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });

  testWidgets('a tile that could not be fetched is not remembered as empty',
      (tester) async {
    final asked = _recordFetches(succeed: false);

    await tester.pumpWidget(_pickerAtTileCentre());
    await tester.pump(const Duration(milliseconds: 50));
    expect(asked, hasLength(1));

    expect(PoiCache.instance.tileCount, 0,
        reason: 'a request that failed is not evidence that a 2.4km rectangle '
            'is empty — and the cache survives restarts, so it would keep '
            'claiming so tomorrow');

    // Let the cache's debounced save run out, so no timer outlives the test.
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });

  testWidgets('a drag towards the next tile fetches it before the pin arrives',
      (tester) async {
    final asked = _recordFetches();
    final home = PoiTiles.tileFor(
      PlacesService.defaultProximityLat,
      PlacesService.defaultProximityLng,
    );
    final eastward = (z: home.z, x: home.x + 1, y: home.y);

    // No initial pin, so the map is live and draggable.
    await tester.pumpWidget(const MaterialApp(home: LocationPickerPage()));
    await tester.pump(const Duration(milliseconds: 50));

    // Drag west in real steps rather than one jump, so the picker sees a
    // velocity it can extrapolate from. Six frames of 380px is about 1.3km of
    // ground — well short of the boundary 2.2km east.
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(InteractiveMapPicker)),
    );
    for (var step = 0; step < 6; step++) {
      await gesture.moveBy(const Offset(-380, 0));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await tester.pump(const Duration(milliseconds: 50));

    // The pin is still in the tile it started in...
    expect(_pinTile(tester), home,
        reason: 'the drag has not actually crossed the boundary yet');
    // ...and the tile beyond it has already been asked for, on the strength of
    // where the drag is going. Not an extra request — the same one, aimed.
    expect(asked, contains(eastward));

    await gesture.up();
    // Let the cache's debounced save run out, so no timer outlives the test.
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });

  testWidgets('the dots follow the pin mid-drag, over ground already cached',
      (tester) async {
    // A street of shops running east, more of them than the map draws at once.
    _cacheHolds([for (var i = 1; i <= 16; i++) _placeEast('Shop$i', i * 40.0)]);

    await tester.pumpWidget(const MaterialApp(home: LocationPickerPage()));

    // Only the nearest twelve are given to the map, so the far end of the
    // street is not on it yet.
    expect(_dotOf('Shop1'), findsOneWidget);
    expect(_dotOf('Shop16'), findsNothing);

    // Walk east, finger down. About 440m at this zoom.
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(InteractiveMapPicker)),
    );
    await gesture.moveBy(const Offset(-750, 0));
    await tester.pump();

    // The far end has arrived and the near end has dropped off, without the
    // finger coming up and without anything being fetched. Under the old
    // arrangement the map carried whatever the last reply contained until a
    // new one landed, so this swap could not happen at all.
    expect(_dotOf('Shop16'), findsOneWidget);
    expect(_dotOf('Shop1'), findsNothing);

    await gesture.up();
    // Let the settle debouncer run out, so no timer outlives the test.
    await tester.pumpAndSettle(const Duration(milliseconds: 600));
  });
}
