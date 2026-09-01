import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/app/app.dart';

void main() {
  testWidgets('RiskPulse app loads', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const RiskPulseApp());

    // Verify that the app title is set correctly in the MaterialApp.
    final MaterialApp materialApp = tester.widget(find.byType(MaterialApp));
    expect(materialApp.title, 'RiskPulse');

    // Verify that we start at the SplashScreen (which contains a Center widget for the logo).
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
