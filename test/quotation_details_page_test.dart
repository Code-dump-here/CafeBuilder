import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:cafe_builder/models/responses/quotation_payment_responses.dart';
import 'package:cafe_builder/pages/quotation_details_page.dart';
import 'package:cafe_builder/utils/quotation_scope.dart';

/// The page renders from `initialQuotation` on its first frame and only then
/// refetches, so nothing here needs the network — the refetch fails under the
/// test harness and is swallowed, which is the behaviour being relied on.
Map<String, dynamic> _quotationJson({
  String status = 'sent',
  int? freeRevisionCount,
  num? extraRevisionFee,
  int? estimatedDurationDays,
  List<Map<String, dynamic>> paymentTerms = const [],
}) =>
    {
      'id': 'q1',
      'version': 1,
      'title': 'Half build',
      'totalAmount': 51000,
      'status': status,
      'isLocked': false,
      'estimatedDurationDays': estimatedDurationDays,
      'freeRevisionCount': freeRevisionCount,
      'extraRevisionFee': extraRevisionFee,
      'items': const [],
      'paymentTerms': paymentTerms,
      'attachments': const [],
      'createdAt': '2026-09-01T00:00:00Z',
      'updatedAt': '2026-09-01T00:00:00Z',
    };

Future<void> _open(
  WidgetTester tester, {
  String? scope,
  Map<String, dynamic>? json,
  Size size = const Size(360, 780),
  double textScale = 1.0,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  // A test that opens the page twice would otherwise get the first one back:
  // the widget type matches, so the element is reused, initState does not run
  // again and `_quotation` keeps the previous bid. Tearing the tree down first
  // makes each open a genuinely fresh page.
  await tester.pumpWidget(const SizedBox.shrink());

  await tester.pumpWidget(MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: QuotationDetailsPage(
        quotationId: 'q1',
        initialQuotation: QuotationResponse.fromJson(json ?? _quotationJson()),
        scope: scope,
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

  group('quotationScopeFrom', () {
    test('reads the server vocabulary, and both counts as design', () {
      expect(quotationScopeFrom('construction'), QuotationScope.construction);
      expect(quotationScopeFrom('design'), QuotationScope.design);
      // A turnkey engagement really does carry a design phase, and the server
      // enforces the revision quota against it.
      expect(quotationScopeFrom('both'), QuotationScope.design);
      expect(quotationScopeFrom('Design'), QuotationScope.design);
      expect(quotationScopeFrom(' CONSTRUCTION '), QuotationScope.construction);
    });

    test('anything it cannot name is unknown, and unknown shows everything', () {
      expect(quotationScopeFrom(null), QuotationScope.unknown);
      expect(quotationScopeFrom(''), QuotationScope.unknown);
      expect(quotationScopeFrom('renovation'), QuotationScope.unknown);

      // Fail open: hiding a term the provider actually published is worse than
      // showing one that does not apply, because the owner cannot tell it is
      // missing.
      expect(QuotationScope.unknown.showsDesignTerms, isTrue);
      expect(QuotationScope.unknown.showsConstructionTerms, isTrue);
      expect(QuotationScope.construction.showsDesignTerms, isFalse);
      expect(QuotationScope.design.showsConstructionTerms, isFalse);
    });
  });

  group('design terms are scoped to design work', () {
    testWidgets('a construction bid does not show revision terms', (tester) async {
      await _open(
        tester,
        scope: 'construction',
        json: _quotationJson(freeRevisionCount: 2, extraRevisionFee: 2000),
      );

      // The provider filled these in — the construction editor has no inputs
      // for them, but older bids carry values and nothing on the construction
      // path will ever charge or honour them.
      expect(find.text('Revision Terms'), findsNothing);
      expect(find.text('Included Revisions'), findsNothing);
      expect(find.text('Extra Revision Fee'), findsNothing);
    });

    testWidgets('a design bid still shows them', (tester) async {
      await _open(
        tester,
        scope: 'design',
        json: _quotationJson(freeRevisionCount: 2, extraRevisionFee: 2000),
      );

      expect(find.text('Revision Terms'), findsOneWidget);
      expect(find.text('Included Revisions'), findsOneWidget);
    });

    testWidgets('so does a turnkey bid, which has a design phase', (tester) async {
      await _open(
        tester,
        scope: 'both',
        json: _quotationJson(freeRevisionCount: 2),
      );

      expect(find.text('Revision Terms'), findsOneWidget);
    });

    testWidgets('an unnamed scope shows them rather than hiding a real term',
        (tester) async {
      await _open(
        tester,
        scope: null,
        json: _quotationJson(freeRevisionCount: 2, extraRevisionFee: 2000),
      );

      expect(find.text('Revision Terms'), findsOneWidget,
          reason: 'the caller could not say what this prices, and a published '
              'quota the owner never sees is worse than one shown in vain');
    });

    testWidgets('a design bid with nothing to say drops the block', (tester) async {
      await _open(tester, scope: 'design', json: _quotationJson());

      expect(find.text('Revision Terms'), findsNothing,
          reason: 'both fields null rendered as "Not stated" twice — a section '
              'that asks to be read and then says nothing');
    });
  });

  group('header', () {
    testWidgets('names which kind of quotation this is', (tester) async {
      await _open(tester, scope: 'construction');
      expect(find.text('Construction quotation'), findsOneWidget);

      await _open(tester, scope: 'design');
      expect(find.text('Design quotation'), findsOneWidget);
    });

    testWidgets('says nothing rather than guessing when the scope is unknown',
        (tester) async {
      await _open(tester, scope: null);
      expect(find.text('Design quotation'), findsNothing);
      expect(find.text('Construction quotation'), findsNothing);
    });

    testWidgets('the status badge lines up under the amount, not mid-row',
        (tester) async {
      await _open(tester, scope: 'construction');

      final amount = tester.getRect(find.text('51,000 VND'));
      final badge = tester.getRect(find.text('Awaiting your decision'));

      // Both values are flushed to the same right edge. Before this, the badge
      // started immediately after the "Status:" label and stopped wherever its
      // own text ended, which is what put it in the middle of the row.
      expect((amount.right - badge.right).abs(), lessThan(12.0),
          reason: 'amount right=${amount.right}, badge right=${badge.right}');
    });

    testWidgets('shows the duration the comparison screen promises', (tester) async {
      await _open(tester, json: _quotationJson(estimatedDurationDays: 90));

      expect(find.text('Estimated Duration'), findsOneWidget);
      expect(find.text('90 days'), findsOneWidget);
    });
  });

  group('the three decisions', () {
    testWidgets('are offered only while the bid is awaiting one', (tester) async {
      await _open(tester, json: _quotationJson(status: 'accepted'));
      expect(find.text('Reject'), findsNothing);

      await _open(tester, json: _quotationJson(status: 'sent'));
      expect(find.text('Reject'), findsOneWidget);
    });

    testWidgets('rank the commitment above the two reversible answers',
        (tester) async {
      await _open(tester);

      final accept = tester.getRect(find.text('Accept & choose provider'));
      final revise = tester.getRect(find.text('Request changes'));
      final reject = tester.getRect(find.text('Reject'));

      // Accept sits on its own row above the other two...
      expect(accept.bottom, lessThan(revise.top));
      expect(accept.bottom, lessThan(reject.top));
      // ...and the two reversible ones share a row.
      expect((revise.center.dy - reject.center.dy).abs(), lessThan(2.0));
    });

    testWidgets('survive a narrow phone at double text size', (tester) async {
      await _open(
        tester,
        size: const Size(320, 780),
        textScale: 2.0,
        json: _quotationJson(
          estimatedDurationDays: 90,
          paymentTerms: const [
            {
              'id': 't1',
              'sortOrder': 0,
              'name': 'first',
              'percentage': 10,
              'amount': 5100,
              'condition': 'on signing the contract',
            },
          ],
        ),
      );

      // Three buttons across 320dp left about 85dp each, which "Reject" does
      // not fit inside its own padding — and the payment-term tile overflowed
      // its ListTile by 11px at this scale.
      expect(tester.takeException(), isNull);
    });
  });
}
