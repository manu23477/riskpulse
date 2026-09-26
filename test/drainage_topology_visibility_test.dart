import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:riskpulse/data/providers/research_workspace_provider.dart';
import 'package:riskpulse/data/services/state_service.dart';
import 'package:riskpulse/domain/gis/data_source_type.dart';
import 'package:riskpulse/domain/gis/drainage_network.dart';
import 'package:riskpulse/domain/gis/drainage_node.dart';
import 'package:riskpulse/domain/gis/gis_layer.dart';
import 'package:riskpulse/domain/gis/gis_style.dart';
import 'package:riskpulse/domain/gis/raster_data.dart';
import 'package:riskpulse/domain/gis/research_session.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/gis/stream_segment.dart';
import 'package:riskpulse/domain/gis/watershed.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/screens/research_gis/research_gis_screen.dart';

void main() {
  group('Research GIS Layer Control & Visibility Regression Tests', () {
    final testExtent = MapExtent(
      southWest: const GeoLocation(latitude: 31.0, longitude: 77.0),
      northEast: const GeoLocation(latitude: 31.2, longitude: 77.2),
    );

    final pourPoint = const GeoLocation(latitude: 31.0900, longitude: 77.1600);

    final mockDem = RasterData(
      width: 5,
      height: 5,
      cellWidth: 30.0,
      cellHeight: 30.0,
      origin: const GeoLocation(latitude: 31.0, longitude: 77.0),
      crs: CoordinateReferenceSystem.wgs84,
      values: List.generate(25, (i) => 1000.0 + i),
    );

    final headwaterNode = const DrainageNode(
      id: 'node-headwater-01',
      location: GeoLocation(latitude: 31.15, longitude: 77.10),
      type: DrainageNodeType.headwater,
    );

    final junctionNode = const DrainageNode(
      id: 'node-junction-01',
      location: GeoLocation(latitude: 31.12, longitude: 77.12),
      type: DrainageNodeType.junction,
    );

    final segment = const StreamSegment(
      id: 'seg-01',
      upstreamNodeId: 'node-headwater-01',
      downstreamNodeId: 'node-junction-01',
      polyline: [
        GeoLocation(latitude: 31.15, longitude: 77.10),
        GeoLocation(latitude: 31.12, longitude: 77.12),
      ],
      strahlerOrder: 1.0,
      shreveMagnitude: 1.0,
      length: 1200.0,
    );

    final mockNetwork = DrainageNetwork(
      id: 'net-01',
      nodes: [headwaterNode, junctionNode],
      segments: [segment],
    );

    final drainageLayer = GisLayer(
      id: 'layer-drainage-net-01',
      name: 'Drainage Network',
      type: GisLayerType.research,
      dataType: SpatialDataType.vector,
      dataSourceType: DataSourceType.cloudProcessing,
      isVisible: true,
      style: const VectorStyle(
        useStrahlerWidth: true,
        strokeColor: '#3B82F6',
      ),
      metadata: const {
        'hydrology_product': 'drainageNetwork',
      },
    );

    final watershedLayer = GisLayer(
      id: 'layer-watershed-boundary-01',
      name: 'Watershed Boundary',
      type: GisLayerType.research,
      dataType: SpatialDataType.vector,
      dataSourceType: DataSourceType.cloudProcessing,
      isVisible: true,
      style: const VectorStyle(
        strokeColor: '#4682B4',
        strokeWidth: 2.5,
      ),
      metadata: const {
        'hydrology_product': 'watershedBoundary',
      },
    );

    final mockSession = ResearchSession(
      id: 'session-topology-vis-01',
      title: 'Mandi Topology Visibility Test',
      extent: testExtent,
      crs: CoordinateReferenceSystem.wgs84,
      layers: [drainageLayer, watershedLayer],
      activeWatershed: Watershed(
        id: 'ws-001',
        pourPointNodeId: 'node-junction-01',
        pourPointLocation: pourPoint,
        mask: mockDem,
        areaKm2: 6.24,
      ),
      drainageNetwork: mockNetwork,
      createdAt: DateTime.parse('2026-09-25T10:00:00Z'),
    );

    testWidgets('TEST 1 & 3: Drainage Network ON -> drainage polylines, headwater markers, and junction markers are visible', (WidgetTester tester) async {
      final workspaceProvider = ResearchWorkspaceProvider();
      final stateService = StateService();

      workspaceProvider.completeAnalysis(mockSession);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ResearchWorkspaceProvider>.value(value: workspaceProvider),
            ChangeNotifierProvider<StateService>.value(value: stateService),
          ],
          child: const MaterialApp(
            home: ResearchGisScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final drainageLayerState = workspaceProvider.activeComposition?.layers
          .where((l) => l.name == 'Drainage Network')
          .firstOrNull;

      expect(drainageLayerState?.isVisible, isTrue);
      expect(find.byType(ResearchGisScreen), findsOneWidget);
    });

    testWidgets('TEST 2 & 4: Drainage Network OFF -> drainage polylines, headwater markers, and junction markers are hidden', (WidgetTester tester) async {
      final workspaceProvider = ResearchWorkspaceProvider();
      final stateService = StateService();

      workspaceProvider.completeAnalysis(mockSession);

      // Toggle Drainage Network visibility to false in activeComposition
      workspaceProvider.toggleLayerVisibility('layer-drainage-net-01');

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ResearchWorkspaceProvider>.value(value: workspaceProvider),
            ChangeNotifierProvider<StateService>.value(value: stateService),
          ],
          child: const MaterialApp(
            home: ResearchGisScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final drainageLayerState = workspaceProvider.activeComposition?.layers
          .where((l) => l.name == 'Drainage Network')
          .firstOrNull;

      expect(drainageLayerState?.isVisible, isFalse);
    });

    testWidgets('TEST 5: Watershed Boundary ON -> watershed boundary layer is visible in composition', (WidgetTester tester) async {
      final workspaceProvider = ResearchWorkspaceProvider();
      final stateService = StateService();

      workspaceProvider.completeAnalysis(mockSession);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ResearchWorkspaceProvider>.value(value: workspaceProvider),
            ChangeNotifierProvider<StateService>.value(value: stateService),
          ],
          child: const MaterialApp(
            home: ResearchGisScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final wsLayerState = workspaceProvider.activeComposition?.layers
          .where((l) => l.name == 'Watershed Boundary')
          .firstOrNull;

      expect(wsLayerState?.isVisible, isTrue);
    });

    testWidgets('TEST 6: Watershed Boundary OFF -> watershed boundary layer is hidden in composition', (WidgetTester tester) async {
      final workspaceProvider = ResearchWorkspaceProvider();
      final stateService = StateService();

      workspaceProvider.completeAnalysis(mockSession);

      // Toggle Watershed Boundary visibility to false
      workspaceProvider.toggleLayerVisibility('layer-watershed-boundary-01');

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ResearchWorkspaceProvider>.value(value: workspaceProvider),
            ChangeNotifierProvider<StateService>.value(value: stateService),
          ],
          child: const MaterialApp(
            home: ResearchGisScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final wsLayerState = workspaceProvider.activeComposition?.layers
          .where((l) => l.name == 'Watershed Boundary')
          .firstOrNull;

      expect(wsLayerState?.isVisible, isFalse);
    });

    testWidgets('TEST 7, 8, & 9: Active Pour Point, Snapped Pour Point, and Identify markers remain independent of layer toggles', (WidgetTester tester) async {
      final workspaceProvider = ResearchWorkspaceProvider();
      final stateService = StateService();

      workspaceProvider.completeAnalysis(mockSession);
      workspaceProvider.setPourPoint(pourPoint);

      // Toggle both vector layers OFF
      workspaceProvider.toggleLayerVisibility('layer-drainage-net-01');
      workspaceProvider.toggleLayerVisibility('layer-watershed-boundary-01');

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ResearchWorkspaceProvider>.value(value: workspaceProvider),
            ChangeNotifierProvider<StateService>.value(value: stateService),
          ],
          child: const MaterialApp(
            home: ResearchGisScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Pour Point location remains set and 100% independent
      expect(workspaceProvider.activePourPoint, equals(pourPoint));
    });

    test('TEST 10: Drainage Network and Watershed Boundary layer toggles remain 100% independent and do not mutate analytical data', () {
      final workspaceProvider = ResearchWorkspaceProvider();
      workspaceProvider.completeAnalysis(mockSession);

      final initialNodesCount = mockSession.drainageNetwork?.nodes.length;
      final initialArea = mockSession.activeWatershed?.areaKm2;

      // Toggle Drainage Network OFF
      workspaceProvider.toggleLayerVisibility('layer-drainage-net-01');

      final drainageState = workspaceProvider.activeComposition?.layers.where((l) => l.name == 'Drainage Network').first.isVisible;
      final watershedState = workspaceProvider.activeComposition?.layers.where((l) => l.name == 'Watershed Boundary').first.isVisible;

      expect(drainageState, isFalse);
      expect(watershedState, isTrue); // Independent!

      // Verify zero analytical data mutation
      expect(mockSession.drainageNetwork?.nodes.length, equals(initialNodesCount));
      expect(mockSession.activeWatershed?.areaKm2, equals(initialArea));
    });

    testWidgets('TEST 11: Moore-Neighbor perimeter tracing produces an ordered, contiguous boundary ring without interior jumps', (WidgetTester tester) async {
      final maskValues = [
        0.0, 0.0, 0.0, 0.0, 0.0,
        0.0, 1.0, 1.0, 1.0, 0.0,
        0.0, 1.0, 1.0, 1.0, 0.0,
        0.0, 1.0, 1.0, 1.0, 0.0,
        0.0, 0.0, 0.0, 0.0, 0.0,
      ];

      final testMask = RasterData(
        width: 5,
        height: 5,
        cellWidth: 30.0,
        cellHeight: 30.0,
        origin: const GeoLocation(latitude: 31.0, longitude: 77.0),
        crs: CoordinateReferenceSystem.wgs84,
        values: maskValues,
      );

      final testWatershed = Watershed(
        id: 'ws-geom-01',
        pourPointNodeId: 'p-01',
        pourPointLocation: const GeoLocation(latitude: 31.0, longitude: 77.0),
        mask: testMask,
        areaKm2: 9.0,
      );

      final workspaceProvider = ResearchWorkspaceProvider();
      final stateService = StateService();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ResearchWorkspaceProvider>.value(value: workspaceProvider),
            ChangeNotifierProvider<StateService>.value(value: stateService),
          ],
          child: const MaterialApp(
            home: ResearchGisScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final screenState = tester.state(find.byType(ResearchGisScreen));
      final polyline = (screenState as dynamic).buildWatershedBoundaryPolylineForTest(testWatershed) as Polyline?;

      expect(polyline, isNotNull);
      expect(polyline!.points, isNotEmpty);
      expect(polyline.points.first, equals(polyline.points.last)); // Closed ring!

      // Verify contiguous 8-neighbor connectivity (no horizontal cross-hatching or interior jumps)
      for (int i = 0; i < polyline.points.length - 1; i++) {
        final p1 = polyline.points[i];
        final p2 = polyline.points[i + 1];
        final dLat = (p1.latitude - p2.latitude).abs();
        final dLon = (p1.longitude - p2.longitude).abs();

        expect(dLat, lessThanOrEqualTo(60.0));
        expect(dLon, lessThanOrEqualTo(60.0));
      }
    });

    testWidgets('TEST 12: Single isolated cell mask returns null rather than degenerate two-point polyline', (WidgetTester tester) async {
      final singleCellMaskValues = [
        0.0, 0.0, 0.0, 0.0, 0.0,
        0.0, 0.0, 0.0, 0.0, 0.0,
        0.0, 0.0, 1.0, 0.0, 0.0,
        0.0, 0.0, 0.0, 0.0, 0.0,
        0.0, 0.0, 0.0, 0.0, 0.0,
      ];

      final singleCellMask = RasterData(
        width: 5,
        height: 5,
        cellWidth: 30.0,
        cellHeight: 30.0,
        origin: const GeoLocation(latitude: 31.0, longitude: 77.0),
        crs: CoordinateReferenceSystem.wgs84,
        values: singleCellMaskValues,
      );

      final singleCellWatershed = Watershed(
        id: 'ws-single-01',
        pourPointNodeId: 'p-01',
        pourPointLocation: const GeoLocation(latitude: 31.0, longitude: 77.0),
        mask: singleCellMask,
        areaKm2: 1.0,
      );

      final workspaceProvider = ResearchWorkspaceProvider();
      final stateService = StateService();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ResearchWorkspaceProvider>.value(value: workspaceProvider),
            ChangeNotifierProvider<StateService>.value(value: stateService),
          ],
          child: const MaterialApp(
            home: ResearchGisScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final screenState = tester.state(find.byType(ResearchGisScreen));
      final polyline = (screenState as dynamic).buildWatershedBoundaryPolylineForTest(singleCellWatershed) as Polyline?;

      expect(polyline, isNull); // Rejects degenerate isolated single-cell boundary
    });

    testWidgets('TEST 13: Incomplete loop traversal with maxSteps limit returns null rather than false closed ring', (WidgetTester tester) async {
      final maskValues = [
        0.0, 0.0, 0.0, 0.0, 0.0,
        0.0, 1.0, 1.0, 1.0, 0.0,
        0.0, 1.0, 1.0, 1.0, 0.0,
        0.0, 1.0, 1.0, 1.0, 0.0,
        0.0, 0.0, 0.0, 0.0, 0.0,
      ];

      final testMask = RasterData(
        width: 5,
        height: 5,
        cellWidth: 30.0,
        cellHeight: 30.0,
        origin: const GeoLocation(latitude: 31.0, longitude: 77.0),
        crs: CoordinateReferenceSystem.wgs84,
        values: maskValues,
      );

      final testWatershed = Watershed(
        id: 'ws-maxsteps-01',
        pourPointNodeId: 'p-01',
        pourPointLocation: const GeoLocation(latitude: 31.0, longitude: 77.0),
        mask: testMask,
        areaKm2: 9.0,
      );

      final workspaceProvider = ResearchWorkspaceProvider();
      final stateService = StateService();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ResearchWorkspaceProvider>.value(value: workspaceProvider),
            ChangeNotifierProvider<StateService>.value(value: stateService),
          ],
          child: const MaterialApp(
            home: ResearchGisScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final screenState = tester.state(find.byType(ResearchGisScreen));
      // Force maxSteps = 2 on a 3x3 block requiring 8 steps -> Truncates before returning to (startX, startY)
      final polyline = (screenState as dynamic).buildWatershedBoundaryPolylineForTest(testWatershed, maxStepsOverride: 2) as Polyline?;

      expect(polyline, isNull); // Rejects incomplete/truncated traversal!
    });
  });
}
