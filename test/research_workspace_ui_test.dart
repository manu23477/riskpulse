import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:riskpulse/data/providers/research_workspace_provider.dart';
import 'package:riskpulse/data/services/state_service.dart';
import 'package:riskpulse/screens/research_gis/research_gis_screen.dart';

void main() {
  Widget createTestWidget() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ResearchWorkspaceProvider()),
        // StateService is a singleton in this project.
        // Using .value to avoid disposal errors between tests.
        ChangeNotifierProvider.value(value: StateService()),
      ],
      child: const MaterialApp(
        home: ResearchGisScreen(),
      ),
    );
  }

  testWidgets('ResearchGisScreen should initialize and show title (Desktop)', (tester) async {
    // Set desktop size
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(createTestWidget());
    expect(find.text('Research GIS Workspace'), findsOneWidget);
    expect(find.byType(Checkbox), findsWidgets); // Layer manager should be visible on desktop

    // Reset size
    addTearDown(tester.view.resetPhysicalSize);
  });

  testWidgets('ResearchGisScreen should show empty state in info panel', (tester) async {
    await tester.pumpWidget(createTestWidget());
    expect(find.text('No Active Analysis'), findsOneWidget);
  });
}
