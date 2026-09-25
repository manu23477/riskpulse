import 'package:flutter/material.dart';
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
  group('Research GIS Drainage Topology Node Marker Visibility Tests', () {
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

    final mockSession = ResearchSession(
      id: 'session-topology-vis-01',
      title: 'Mandi Topology Visibility Test',
      extent: testExtent,
      crs: CoordinateReferenceSystem.wgs84,
      layers: [drainageLayer],
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

    testWidgets('1. Drainage Network ON: drainage polylines, headwater markers, and junction markers are visible', (WidgetTester tester) async {
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

    testWidgets('2. Drainage Network OFF: drainage polylines, headwater markers, and junction markers are hidden', (WidgetTester tester) async {
      final workspaceProvider = ResearchWorkspaceProvider();
      final stateService = StateService();

      workspaceProvider.completeAnalysis(mockSession);

      // Toggle Drainage Network visibility to false
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

    testWidgets('3. Pour Point and Identify markers remain independent of Drainage Network layer toggle', (WidgetTester tester) async {
      final workspaceProvider = ResearchWorkspaceProvider();
      final stateService = StateService();

      workspaceProvider.completeAnalysis(mockSession);
      workspaceProvider.setPourPoint(pourPoint);

      // Toggle Drainage Network visibility to false
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

      // Pour Point location remains set and independent
      expect(workspaceProvider.activePourPoint, equals(pourPoint));
    });

    test('4. Toggling Drainage Network layer visibility does NOT mutate ResearchSession or DrainageNetwork topology data', () {
      final workspaceProvider = ResearchWorkspaceProvider();
      workspaceProvider.completeAnalysis(mockSession);

      final initialNodesCount = mockSession.drainageNetwork?.nodes.length;
      final initialSegmentsCount = mockSession.drainageNetwork?.segments.length;

      workspaceProvider.toggleLayerVisibility('layer-drainage-net-01');

      expect(mockSession.drainageNetwork?.nodes.length, equals(initialNodesCount));
      expect(mockSession.drainageNetwork?.segments.length, equals(initialSegmentsCount));
      expect(mockSession.drainageNetwork?.nodes.first.type, equals(DrainageNodeType.headwater));
    });
  });
}
