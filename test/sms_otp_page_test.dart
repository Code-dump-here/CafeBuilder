import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cafe_builder/pages/sms_otp_page.dart';

/// The password-reset code screen.
///
/// It used to draw four boxes while the backend e-mailed a six-digit TOTP
/// (`OtpService`, `Otp:Length` defaulting to 6), so the code never fitted and
/// the short one was still posted to `/auth/reset-password`, which counts a
/// failed attempt and disables the request after five of them.
Future<void> _open(
  WidgetTester tester, {
  Size size = const Size(360, 780),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(MaterialApp(
    // The page reads the e-mail from its route arguments and bounces back to
    // the forgot-password screen without them.
    onGenerateRoute: (settings) => MaterialPageRoute(
      builder: (_) => const SmsOtpPage(),
      settings: const RouteSettings(arguments: {'email': 'owner@example.com'}),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('asks for six digits', (tester) async {
    await _open(tester);

    expect(find.byType(TextField), findsNWidgets(6));
  });

  testWidgets('the boxes fit on a small phone', (tester) async {
    await _open(tester, size: const Size(320, 700));

    // A row of fixed-width boxes overflowed here once there were six of them.
    expect(tester.takeException(), isNull);
  });

  testWidgets('an incomplete code is refused', (tester) async {
    await _open(tester);

    final boxes = find.byType(TextField);
    for (var i = 0; i < 5; i++) {
      await tester.enterText(boxes.at(i), '1');
    }
    await tester.tap(find.text('Verify'));
    await tester.pump();

    expect(find.text('Enter the full code.'), findsOneWidget);
  });
}
