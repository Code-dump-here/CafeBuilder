import 'package:flutter_test/flutter_test.dart';

import 'package:cafe_builder/utils/money.dart';

/// These pin the exact strings, not the shape of them. The bug this file
/// guards against was never "the formatter is broken" — every one of the six
/// formatters it replaced worked. It was that they disagreed, and the
/// disagreement was only visible by opening two screens and comparing.
void main() {
  group('formatVnd', () {
    test('groups thousands with commas and suffixes the currency', () {
      expect(formatVnd(1500000), '1,500,000 VND');
      expect(formatVnd(1000000000), '1,000,000,000 VND');
      expect(formatVnd(999), '999 VND');
      expect(formatVnd(1000), '1,000 VND');
    });

    test('rounds to whole dong', () {
      // Percentage splits come off the wire as doubles that do not divide
      // cleanly; the fractional dong is an artefact, not an amount.
      expect(formatVnd(1500000.4), '1,500,000 VND');
      expect(formatVnd(1500000.6), '1,500,001 VND');
    });

    test('keeps the sign outside the grouping', () {
      // The old hand-rolled grouper counted the minus as a digit and pushed
      // every separator one place across.
      expect(formatVnd(-1500000), '-1,500,000 VND');
    });

    test('zero is an amount, not a blank', () {
      expect(formatVnd(0), '0 VND');
    });
  });

  group('formatVndCompact', () {
    test('abbreviates by magnitude', () {
      expect(formatVndCompact(1500000000), '1.5B VND');
      expect(formatVndCompact(1500000), '1.5M VND');
      expect(formatVndCompact(250000), '250k VND');
      expect(formatVndCompact(999), '999 VND');
    });

    test('a billion-dong budget does not collapse into a four-digit M', () {
      // Regression: without the billions tier this read "1500.0M VND".
      expect(formatVndCompact(1500000000), isNot(contains('M')));
    });
  });

  test('compact and full agree on the same amount', () {
    // Both are shown for the same budget on the project detail page, one under
    // the other. They have to be two renderings of one number.
    expect(formatVndCompact(1500000), '1.5M VND');
    expect(formatVnd(1500000), '1,500,000 VND');
  });

  group('formatPercent', () {
    test('drops a trailing zero', () {
      expect(formatPercent(30), '30');
      expect(formatPercent(30.0), '30');
      expect(formatPercent(12.5), '12.5');
    });
  });

  group('formatQuantity', () {
    test('keeps fractions, because half a square metre is a real line item',
        () {
      expect(formatQuantity(12.5), '12.5');
      expect(formatQuantity(12), '12');
      expect(formatQuantity(1200), '1,200');
      expect(formatQuantity(1200.75), '1,200.75');
    });
  });
}
