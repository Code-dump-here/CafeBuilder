import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:cafe_builder/models/place_location.dart';
import 'package:cafe_builder/services/places_service.dart';
import 'package:cafe_builder/widgets/interactive_map_picker.dart';

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

Future<void> _pumpPicker(
  WidgetTester tester,
  List<MapPoi> pois, {
  void Function(double latitude, double longitude)? onPoisNeeded,
  void Function(double latitude, double longitude)? onChanged,
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

    // Still empty, still dragging, but the throttle holds the next one back
    // rather than firing a request per frame.
    await gesture.moveBy(const Offset(-500, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(-500, 0));
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

  testWidgets('a batch that reaches further is carried further', (tester) async {
    final asks = <List<double>>[];
    // Same three places, but spread out to about 200m - what the geocoder
    // returns away from the centre of town. Nothing has gone stale yet after
    // the walk that emptied the dense batch above.
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
    await gesture.moveBy(const Offset(-150, 0));
    await tester.pump();

    // 150px is about 88m, further than the dense batch tolerated, and still
    // well inside this one's reach.
    expect(asks, isEmpty);

    // Keep going and it does eventually ask.
    await gesture.moveBy(const Offset(-250, 0));
    await tester.pump();
    expect(asks, hasLength(1));

    await gesture.up();
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
