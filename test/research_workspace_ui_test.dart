import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:riskpulse/data/providers/research_workspace_provider.dart';
import 'package:riskpulse/data/services/state_service.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/gis/research_session.dart';
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

    // In Initial state, it should show the empty layers message
    expect(find.textContaining('No research layers available'), findsOneWidget);

    addTearDown(tester.view.resetPhysicalSize);
  });

  testWidgets('ResearchGisScreen should show cartographic overlays when active', (tester) async {
    final provider = ResearchWorkspaceProvider();
    final extent = MapExtent(
      southWest: const GeoLocation(latitude: 30, longitude: 70),
      northEast: const GeoLocation(latitude: 35, longitude: 80),
    );
    
    // Put provider in Ready state to show overlays
    final session = ResearchSession(
      id: 's1', title: 'Test Map', extent: extent, createdAt: DateTime.now(),
    );
    provider.completeAnalysis(session);
    
    await tester.pumpWidget(createTestWidget(provider: provider));
    await tester.pumpAndSettle();
    
    expect(find.byType(ScaleBarWidget), findsOneWidget);
    expect(find.byType(NorthArrowWidget), findsOneWidget);
  });

  testWidgets('ResearchGisScreen should render Research Summary and Metadata', (tester) async {
    final provider = ResearchWorkspaceProvider();
    final extent = MapExtent(
      southWest: const GeoLocation(latitude: 30, longitude: 70),
      northEast: const GeoLocation(latitude: 35, longitude: 80),
    );
    
    final session = ResearchSession(
      id: 's1', title: 'Himalayan Research', extent: extent, createdAt: DateTime.now(),
    );
    provider.completeAnalysis(session);

    await tester.pumpWidget(createTestWidget(provider: provider));
    await tester.pumpAndSettle();

    expect(find.text('Research Summary'), findsOneWidget);
    expect(find.textContaining('Himalayan Research'), findsWidgets);
    expect(find.text('Analytical Workflow'), findsOneWidget);
  });

  testWidgets('ResearchGisScreen should allow AOI capture and require genuine DEM and Pour Point for analysis', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;

    final provider = ResearchWorkspaceProvider();
    await tester.pumpWidget(createTestWidget(provider: provider));

    // 1. Initial state: SET AOI button present
    expect(find.text('SET AOI'), findsOneWidget);

    // 2. Click SET AOI -> state becomes WorkspaceConfigured
    await tester.tap(find.text('SET AOI'));
    await tester.pumpAndSettle();

    // 3. Verify AOI SET indicator appears and DEM / POUR POINT REQ. button label is shown
    expect(find.text('AOI SET'), findsOneWidget);
    expect(find.text('DEM / POUR POINT REQ.'), findsOneWidget);

    addTearDown(tester.view.resetPhysicalSize);
  });

  testWidgets('ResearchGisScreen should show empty state in info panel', (tester) async {
    await tester.pumpWidget(createTestWidget());
    expect(find.text('No Active Analysis'), findsOneWidget);
  });
}
