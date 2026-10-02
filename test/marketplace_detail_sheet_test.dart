import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:cafe_builder/models/marketplace_state.dart';
import 'package:cafe_builder/pages/marketplace_page.dart';

/// The detail sheet a post opens on the Market page.
///
/// Every heading in it used to be 9pt in the placeholder grey and every value
/// 13pt in the secondary grey, so a heading carried no more weight than the
/// sentence under it and the sheet read as one wash of grey. This pins the
/// hierarchy that replaced it.

const _description =
    'A bakery counter with an open kitchen and seating upstairs. Families and '
    'students, weekends and afternoons.';

BroadcastProject _post() => BroadcastProject(
      id: 'p1',
      title: 'Bếp Mây Bakery & Coffee',
      location: 'Thủ Đức, Hồ Chí Minh',
      style: 'Warm minimal',
      budgetTier: '520 triệu VND',
      description: _description,
      requirements: const ['Interior design', 'Fit-out'],
      date: '01/03/2026',
      proposalsCount: 0,
      commentsCount: 0,
      status: 'open',
      imageUrl: 'https://example.invalid/cafe.png',
    );

/// The page renders `Image.network`; without this every test logs a failed
/// request. Answers with a 1×1 transparent PNG instead of reaching the network.
class _OfflineImages extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _FakeClient();
}

class _FakeClient implements HttpClient {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw const SocketException("offline");
}

void main() {
  setUpAll(() {
    HttpOverrides.global = _OfflineImages();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('the sheet sets its headings apart from its text', (tester) async {
    MarketplaceState.broadcasts
      ..clear()
      ..add(_post());
    addTearDown(MarketplaceState.broadcasts.clear);

    tester.view.physicalSize = const Size(430, 940);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: MarketplacePage()));
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('View Detail'));
    await tester.pump(const Duration(milliseconds: 500));

    // The card behind the sheet repeats the description, so every lookup is
    // scoped to the sheet itself.
    TextStyle styleOf(String data) => tester
        .widget<Text>(find.descendant(
          of: find.byType(BottomSheet),
          matching: find.text(data),
        ))
        .style!;

    final heading = styleOf('PROJECT DESCRIPTION');
    final body = styleOf(_description);

    expect(heading.fontWeight, FontWeight.bold);
    expect(heading.color, isNot(body.color));
    expect(body.fontSize! > heading.fontSize!, isTrue,
        reason: 'the sentence should read larger than the label above it');
    expect(body.height, greaterThanOrEqualTo(1.5),
        reason: 'body copy needs line spacing a label does not');

    // The offline image client throws by design; drain it so the failure of a
    // real assertion is what this test reports.
    while (tester.takeException() != null) {}
  });

  testWidgets('the post list fits a narrow phone', (tester) async {
    MarketplaceState.broadcasts
      ..clear()
      ..add(_post());
    addTearDown(MarketplaceState.broadcasts.clear);

    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: MarketplacePage()));
    await tester.pump(const Duration(milliseconds: 300));

    // Image failures are expected offline; an overflow is not.
    final overflows = <String>[];
    for (Object? error = tester.takeException();
        error != null;
        error = tester.takeException()) {
      final text = error.toString();
      if (text.contains('overflowed')) overflows.add(text.substring(0, 80));
    }
    expect(overflows, isEmpty, reason: overflows.join(' | '));
  });
}
