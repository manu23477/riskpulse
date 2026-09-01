import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:riskpulse/data/providers/research_workspace_provider.dart';
import 'package:riskpulse/data/services/state_service.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/screens/research_gis/research_gis_screen.dart';
import 'package:riskpulse/screens/research_gis/widgets/cartography/scale_bar_widget.dart';
import 'package:riskpulse/screens/research_gis/widgets/cartography/north_arrow_widget.dart';

void main() {
  Widget createTestWidget({ResearchWorkspaceProvider? provider}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => provider ?? ResearchWorkspaceProvider()),
        ChangeNotifierProvider.value(value: StateService()),
      ],
      child: const MaterialApp(
        home: ResearchGisScreen(),
      ),
    );
  }

  testWidgets('ResearchGisScreen should initialize and show title (Desktop)', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(createTestWidget());
    expect(find.text('Research GIS Workspace'), findsOneWidget);
    expect(find.byType(Checkbox), findsWidgets);

    addTearDown(tester.view.resetPhysicalSize);
  });

  testWidgets('ResearchGisScreen should show cartographic overlays when active', (tester) async {
    final provider = ResearchWorkspaceProvider();
    final extent = MapExtent(
      southWest: GeoLocation(latitude: 30, longitude: 70),
      northEast: GeoLocation(latitude: 35, longitude: 80),
    );
    provider.initializeSession('Test Map', extent);

    await tester.pumpWidget(createTestWidget(provider: provider));
    // Wait for map to layout and trigger the onMapEvent or just second frame
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Scale bar and North arrow should be visible by default in MapComposition
    expect(find.byType(ScaleBarWidget), findsOneWidget);
    expect(find.byType(NorthArrowWidget), findsOneWidget);
  });

  testWidgets('ResearchGisScreen should show empty state in info panel', (tester) async {
    await tester.pumpWidget(createTestWidget());
    expect(find.text('No Active Analysis'), findsOneWidget);
  });
}
