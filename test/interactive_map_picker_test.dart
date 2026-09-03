import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:cafe_builder/models/place_location.dart';
import 'package:cafe_builder/services/places_service.dart';
import 'package:cafe_builder/widgets/interactive_map_picker.dart';

/// Run with the map key defined, or every assertion here fails:
///
///   flutter test --dart-define=GOOGLE_MAPS_API_KEY=`key`
///
/// `PlacesService.isConfigured` is a compile-time constant, so without it the
/// map builds to a `SizedBox.shrink()` and there is nothing to find.
///
/// The picker opens at this zoom, and the fixtures below are built with the
/// same projection the widget uses, so a pixel offset here means what it means
/// on screen.
const int _zoom = 17;
const double _boxWidth = 360;
const double _boxHeight = 240;

const double _centreLat = 10.7769;
const double _centreLng = 106.7009;

/// A POI [dxPixels] east of the centre at [_zoom].
///
/// Kept well inside the box: the picker culls anything more than a dot-box
/// outside it, and a culled POI has neither a dot nor a label to assert on.
MapPoi _poiEastOfCentre(String name, double dxPixels) {
  final centre = PlacesService.worldPixel(_centreLat, _centreLng, _zoom);
  final at = PlacesService.latLngFromWorldPixel(centre.x + dxPixels, centre.y, _zoom);
  return MapPoi(
    id: name,
    name: name,
    address: '$name, somewhere',
    category: 'cafe',
    latitude: at.latitude,
    longitude: at.longitude,
  );
}

Finder _dotOf(String name) => find.byWidgetPredicate(
      (w) => w is Tooltip && (w.message ?? '').startsWith('$name ·'),
    );

double _scaleOf(WidgetTester tester, String name) => tester
    .widget<AnimatedScale>(
      find.ancestor(of: _dotOf(name), matching: find.byType(AnimatedScale)).first,
    )
    .scale;

double _opacityOf(WidgetTester tester, String name) => tester
    .widget<AnimatedOpacity>(
      find.ancestor(of: _dotOf(name), matching: find.byType(AnimatedOpacity)).first,
    )
    .opacity;

/// The name chip, which only the nearest place gets. Matched on the chip's own
/// single-line Text, rather than the tooltip that every dot carries.
String? _labelText(WidgetTester tester) {
  final chips = tester.widgetList<Text>(find.byType(Text)).where(
        (t) => (t.data ?? '').contains(' · ') && t.maxLines == 1,
      );
  return chips.isEmpty ? null : chips.first.data;
}

/// The metres off the end of the chip: "Name · 128 m" -> 128.
int _labelMetres(WidgetTester tester) {
  final parts = _labelText(tester)!.split(' ');
  return int.parse(parts[parts.length - 2]);
}

/// The locate button, which is the only thing on the map carrying this label.
final _locateButton = find.byTooltip('Move the pin to where I am');

Future<void> _pumpPicker(
  WidgetTester tester,
  List<MapPoi> pois, {
  void Function(double latitude, double longitude)? onPoisNeeded,
  void Function(double latitude, double longitude)? onChanged,
  VoidCallback? onLocateMe,
  bool locating = false,
}) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: _boxWidth,
          child: InteractiveMapPicker(
            initialLatitude: _centreLat,
            initialLongitude: _centreLng,
            height: _boxHeight,
            onChanged: onChanged ?? (_, _) {},
            pois: pois,
            onPoisNeeded: onPoisNeeded,
            onLocateMe: onLocateMe,
            locating: locating,
          ),
        ),
      ),
    ),
  ));
  await tester.pump();
}

void main() {
  setUpAll(() {
    // Otherwise every test tries to download a font it is never going to get.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  test('metresBetween measures real ground distance', () {
    // One degree of latitude on a 6371km sphere.
    expect(
      PlacesService.metresBetween(10.0, 106.0, 11.0, 106.0),
      closeTo(111194.9, 1.0),
    );
    expect(PlacesService.metresBetween(10.7769, 106.7009, 10.7769, 106.7009), 0.0);
    // Ho Chi Minh City to Hanoi, about 1140km.
    expect(
      PlacesService.metresBetween(10.7769, 106.7009, 21.0278, 105.8342) / 1000,
      closeTo(1140, 20),
    );
  });

  testWidgets('nearest place is named, and the far one is smaller and fainter',
      (tester) async {
    await _pumpPicker(tester, [
      _poiEastOfCentre('Near', 30),
      _poiEastOfCentre('Far', 170),
    ]);

    expect(_labelText(tester), startsWith('Near ·'));
    expect(_scaleOf(tester, 'Near'), greaterThan(_scaleOf(tester, 'Far')));
    expect(_opacityOf(tester, 'Near'), greaterThan(_opacityOf(tester, 'Far')));

    // The nearest of a batch is drawn at full prominence, the furthest at the
    // floor.
    expect(_scaleOf(tester, 'Near'), closeTo(1.0, 0.001));
    expect(_opacityOf(tester, 'Near'), closeTo(1.0, 0.001));
    expect(_scaleOf(tester, 'Far'), closeTo(0.62, 0.001));
    expect(_opacityOf(tester, 'Far'), closeTo(0.34, 0.001));
  });

  testWidgets('emphasis tracks the pin live, without waiting for the drag to end',
      (tester) async {
    await _pumpPicker(tester, [
      _poiEastOfCentre('Near', 30),
      _poiEastOfCentre('Far', 170),
    ]);

    expect(_labelText(tester), startsWith('Near ·'));
    expect(_scaleOf(tester, 'Near'), greaterThan(_scaleOf(tester, 'Far')));

    // Drag the map west, which walks the pin east past 'Far'. Finger stays
    // down throughout — nothing below is allowed to depend on releasing it.
    final gesture =
        await tester.startGesture(tester.getCenter(find.byType(InteractiveMapPicker)));
    await gesture.moveBy(const Offset(-200, 0));
    await tester.pump();

    // Mid-drag, with the pin now closer to 'Far', the gradient has already
    // swapped and the label already names the new nearest place.
    expect(_scaleOf(tester, 'Far'), greaterThan(_scaleOf(tester, 'Near')));
    expect(_opacityOf(tester, 'Far'), greaterThan(_opacityOf(tester, 'Near')));
    expect(_labelText(tester), startsWith('Far ·'));

    // And it keeps tracking: drag back and it swaps straight back, still
    // without the finger coming up.
    await gesture.moveBy(const Offset(200, 0));
    await tester.pump();
    expect(_scaleOf(tester, 'Near'), greaterThan(_scaleOf(tester, 'Far')));
    expect(_labelText(tester), startsWith('Near ·'));

    // Releasing changes nothing, because nothing was being held back.
    await gesture.up();
    await tester.pump();
    expect(_labelText(tester), startsWith('Near ·'));
    expect(_scaleOf(tester, 'Near'), greaterThan(_scaleOf(tester, 'Far')));
  });

  testWidgets('the distance on the label counts down as the pin approaches',
      (tester) async {
    await _pumpPicker(tester, [_poiEastOfCentre('Target', 170)]);

    final before = _labelMetres(tester);
    final gesture =
        await tester.startGesture(tester.getCenter(find.byType(InteractiveMapPicker)));
    await gesture.moveBy(const Offset(-120, 0));
    await tester.pump();

    final during = _labelMetres(tester);
    expect(during, lessThan(before),
        reason: 'the label should be reading the live distance, not the one '
            'the pin had when the drag started');
    await gesture.up();
  });

  testWidgets('asks for a new batch once the drag empties the map',
      (tester) async {
    final asks = <List<double>>[];
    var pinLat = 0.0, pinLng = 0.0;

    await _pumpPicker(
      tester,
      [
        _poiEastOfCentre('A', 8),
        _poiEastOfCentre('B', 16),
        _poiEastOfCentre('C', 28),
      ],
      onChanged: (lat, lng) { pinLat = lat; pinLng = lng; },
      onPoisNeeded: (lat, lng) => asks.add([lat, lng]),
    );

    final gesture =
        await tester.startGesture(tester.getCenter(find.byType(InteractiveMapPicker)));

    // A nudge that leaves the dots on screen asks for nothing.
    await gesture.moveBy(const Offset(-20, 0));
    await tester.pump();
    expect(asks, isEmpty);

    // Dragging the batch clean off the box does ask - and does it during the
    // drag, without waiting for the finger to come up.
    await gesture.moveBy(const Offset(-500, 0));
    await tester.pump();
    expect(asks, hasLength(1));
    expect(asks.first[0], closeTo(pinLat, 1e-9));
    expect(asks.first[1], closeTo(pinLng, 1e-9));

    // Still empty, still dragging, and the throttle keeps a fling costing a
    // handful of asks rather than one per frame. Eight more frames of it is
    // two and a half kilometres of map, and it is still a handful.
    for (var frame = 0; frame < 8; frame++) {
      await gesture.moveBy(const Offset(-500, 0));
      await tester.pump();
    }
    expect(asks.length, lessThan(4),
        reason: 'eight frames of fling should not be eight asks');

    await gesture.up();
  });

  testWidgets('asks sooner than the dots take to go stale, because the '
      'parent answers most asks from its cache', (tester) async {
    final asks = <List<double>>[];
    await _pumpPicker(
      tester,
      [
        _poiEastOfCentre('A', 8),
        _poiEastOfCentre('B', 16),
        _poiEastOfCentre('C', 28),
      ],
      onPoisNeeded: (lat, lng) => asks.add([lat, lng]),
    );

    final gesture =
        await tester.startGesture(tester.getCenter(find.byType(InteractiveMapPicker)));

    // 40px is about 23m: half of what a refill used to need, and barely more
    // than the width of the cluster itself. It asks anyway. Over ground the
    // cache already holds, the answer costs nothing and buys a re-rank against
    // places the last reply never contained; over new ground the parent is the
    // one that decides whether to spend a request.
    await gesture.moveBy(const Offset(-40, 0));
    await tester.pump();
    expect(asks, hasLength(1));

    await gesture.up();
  });

  testWidgets('refills on ground distance, before the dots have left the box',
      (tester) async {
    final asks = <List<double>>[];
    // A dense batch: everything within 28px, which is about 16m at this zoom.
    // Its reach is short, so it goes stale after a short walk.
    await _pumpPicker(
      tester,
      [
        _poiEastOfCentre('A', 8),
        _poiEastOfCentre('B', 16),
        _poiEastOfCentre('C', 28),
      ],
      onPoisNeeded: (lat, lng) => asks.add([lat, lng]),
    );

    final gesture =
        await tester.startGesture(tester.getCenter(find.byType(InteractiveMapPicker)));
    await gesture.moveBy(const Offset(-100, 0));
    await tester.pump();

    // Every dot is still on screen - 100px of a 360px box - and it has asked
    // anyway, because the pin has walked past the batch's reach.
    for (final name in ['A', 'B', 'C']) {
      expect(_dotOf(name), findsOneWidget, reason: name);
    }
    expect(asks, hasLength(1));

    // And the trigger really is ground distance: 100px at zoom 17 in Ho Chi
    // Minh City is about 59m, which is what it travelled before asking.
    final travelled = PlacesService.metresBetween(
      _centreLat,
      _centreLng,
      asks.first[0],
      asks.first[1],
    );
    expect(travelled, closeTo(59, 4));

    await gesture.up();
  });

  testWidgets('a batch that reaches further is carried further, but never past '
      'half a screen', (tester) async {
    final asks = <List<double>>[];
    // Same three places, but spread out to about 200m - what the geocoder
    // returns away from the centre of town.
    await _pumpPicker(
      tester,
      [
        _poiEastOfCentre('A', 8),
        _poiEastOfCentre('B', 200),
        _poiEastOfCentre('C', 340),
      ],
      onPoisNeeded: (lat, lng) => asks.add([lat, lng]),
    );

    final gesture =
        await tester.startGesture(tester.getCenter(find.byType(InteractiveMapPicker)));

    // 60px is about 35m. The dense batch above is stale after 17m, so this one
    // is being carried more than twice as far on the strength of its own reach.
    await gesture.moveBy(const Offset(-60, 0));
    await tester.pump();
    expect(asks, isEmpty);

    // Only up to a point, though. Its 200m reach would once have carried it
    // 110m; the box shows 141m of ground across its short side, and half of
    // that is as stale as the dots are allowed to get however far the batch
    // reaches. 140px is about 82m.
    await gesture.moveBy(const Offset(-80, 0));
    await tester.pump();
    expect(asks, hasLength(1));

    final travelled = PlacesService.metresBetween(
      _centreLat,
      _centreLng,
      asks.first[0],
      asks.first[1],
    );
    expect(travelled, closeTo(82, 5),
        reason: 'capped by half the screen, not by the 110m its reach alone '
            'would have allowed');

    await gesture.up();
  });

  testWidgets('the refresh distance is a share of the screen, not a fixed '
      'number of metres', (tester) async {
    // How far the pin had travelled, in metres, the first time the map asked.
    Future<double> metresBeforeFirstAsk({required int zoomOutSteps}) async {
      final asks = <List<double>>[];
      await _pumpPicker(
        tester,
        [
          _poiEastOfCentre('A', 8),
          _poiEastOfCentre('B', 16),
          _poiEastOfCentre('C', 28),
        ],
        onPoisNeeded: (lat, lng) => asks.add([lat, lng]),
      );

      for (var step = 0; step < zoomOutSteps; step++) {
        await tester.tap(find.byTooltip('Zoom out'));
        await tester.pump();
      }
      // A zoom step can empty the box and ask on its own account; only the
      // drag below is being measured.
      asks.clear();

      final gesture = await tester
          .startGesture(tester.getCenter(find.byType(InteractiveMapPicker)));
      // 40px, comfortably past the ~29px the floor works out to at any zoom.
      await gesture.moveBy(const Offset(-40, 0));
      await tester.pump();
      await gesture.up();
      // Tear the picker down so the next call gets a fresh State rather than
      // one carrying the last run's anchor and throttle.
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));

      expect(asks, hasLength(1), reason: 'zoomOutSteps=$zoomOutSteps');
      return PlacesService.metresBetween(
          _centreLat, _centreLng, asks.first[0], asks.first[1]);
    }

    final atStreetLevel = await metresBeforeFirstAsk(zoomOutSteps: 0);
    final zoomedOut = await metresBeforeFirstAsk(zoomOutSteps: 4);

    // The same gesture, the same batch, the same fraction of the screen
    // crossed - and sixteen times the ground, because that is what four zoom
    // steps mean. A threshold fixed in metres could only ever have been right
    // at one of these two.
    expect(atStreetLevel, closeTo(23, 3));
    expect(zoomedOut / atStreetLevel, closeTo(16, 1),
        reason: 'four zoom steps is a factor of 2^4');
  });

  testWidgets('asks for nothing when no one is listening', (tester) async {
    // The callback is optional, and a picker without one must still drag.
    await _pumpPicker(tester, [_poiEastOfCentre('A', 8)]);
    final gesture =
        await tester.startGesture(tester.getCenter(find.byType(InteractiveMapPicker)));
    await gesture.moveBy(const Offset(-600, 0));
    await tester.pump();
    await gesture.up();
    expect(tester.takeException(), isNull);
  });

  testWidgets('a tight cluster stays bunched instead of being stretched out',
      (tester) async {
    // Three places within ~12m of each other, which is what the geocoder
    // returns downtown. None of them should be faded away.
    await _pumpPicker(tester, [
      _poiEastOfCentre('A', 8),
      _poiEastOfCentre('B', 16),
      _poiEastOfCentre('C', 28),
    ]);

    for (final name in ['A', 'B', 'C']) {
      expect(_scaleOf(tester, name), greaterThan(0.9), reason: name);
      expect(_opacityOf(tester, name), greaterThan(0.85), reason: name);
    }
  });

  testWidgets('no locate button when nobody can answer it', (tester) async {
    // Zoom is always there; locate is not, because taking a fix needs
    // permissions and a way to report failure, which the map does not have.
    await _pumpPicker(tester, const []);
    expect(find.byTooltip('Zoom in'), findsOneWidget);
    expect(_locateButton, findsNothing);
  });

  testWidgets('the locate button asks the parent for a fix', (tester) async {
    var asked = 0;
    await _pumpPicker(tester, const [], onLocateMe: () => asked++);

    expect(_locateButton, findsOneWidget);
    await tester.tap(_locateButton);
    await tester.pump();
    expect(asked, 1);
  });

  testWidgets('while a fix is being taken the button spins and stops asking',
      (tester) async {
    var asked = 0;
    await _pumpPicker(
      tester,
      const [],
      onLocateMe: () => asked++,
      locating: true,
    );

    // A cold GPS start takes seconds. The spinner is what stops the button
    // reading as broken, and it sits in the same box so nothing shifts.
    expect(
      find.descendant(
        of: _locateButton,
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.my_location), findsNothing);

    await tester.tap(_locateButton);
    await tester.pump();
    expect(asked, 0, reason: 'a second tap must not start a second fix');
  });

  testWidgets('the label spells out the real distance, not the relative rank',
      (tester) async {
    final lonely = _poiEastOfCentre('Lonely', 170);
    await _pumpPicker(tester, [lonely]);

    final expected = PlacesService.metresBetween(
      _centreLat,
      _centreLng,
      lonely.latitude,
      lonely.longitude,
    ).round();
    // 170px east at zoom 17 in Ho Chi Minh City is about 100m of ground.
    expect(expected, inInclusiveRange(85, 115));
    expect(_labelText(tester), 'Lonely · $expected m');
  });
}
