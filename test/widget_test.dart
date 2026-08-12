import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/app/app.dart';

void main() {
  testWidgets('RiskPulse app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const RiskPulseApp());

    expect(find.text('RiskPulse'), findsOneWidget);
  });
}