import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:riskpulse/data/providers/research_workspace_provider.dart';
import 'package:riskpulse/data/services/administrative_boundary_service.dart';
import 'package:riskpulse/data/services/state_service.dart';
import 'package:riskpulse/domain/administrative/administrative_level.dart';
import 'package:riskpulse/domain/administrative/administrative_unit.dart';
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
  group('Research GIS Administrative Boundary Activation & 8-State Visibility Matrix Tests', () {
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
      style: const VectorStyle(useStrahlerWidth: true, strokeColor: '#3B82F6'),
      metadata: const {'hydrology_product': 'drainageNetwork'},
    );

    final watershedLayer = GisLayer(
      id: 'layer-watershed-boundary-01',
      name: 'Watershed Boundary',
      type: GisLayerType.research,
      dataType: SpatialDataType.vector,
      dataSourceType: DataSourceType.cloudProcessing,
      isVisible: true,
      style: const VectorStyle(strokeColor: '#4682B4', strokeWidth: 2.5),
      metadata: const {'hydrology_product': 'watershedBoundary'},
    );

    final adminLayer = GisLayer(
      id: 'layer-district-boundaries-01',
      name: 'District Boundaries',
      type: GisLayerType.boundary,
      dataType: SpatialDataType.vector,
      dataSourceType: DataSourceType.local,
      isVisible: true,
      style: const VectorStyle(strokeColor: '#6B7280', strokeWidth: 1.8),
      metadata: const {
        'hydrology_product': 'districtBoundaries',
        'administrative_level': 'DISTRICT',
        'sourceName': 'LGD / Survey of India',
      },
    );

    final mockSession = ResearchSession(
      id: 'session-admin-vis-01',
      title: 'Mandi Administrative Boundary Study',
      extent: testExtent,
      crs: CoordinateReferenceSystem.wgs84,
      layers: [drainageLayer, watershedLayer, adminLayer],
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

    test('1. AdministrativeBoundaryService loads authoritative GeoJSON district units with provenance', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final adminService = AdministrativeBoundaryService();
      final hpUnits = await adminService.loadDistrictBoundaries(stateCode: 'HP');

      expect(hpUnits.length, equals(12));
      expect(hpUnits.first.level, equals(AdministrativeLevel.district));
      expect(hpUnits.first.sourceName, equals('LGD / Survey of India'));
      expect(hpUnits.first.geometry, isNotNull);
      final names = hpUnits.map((u) => u.name).toSet();
      expect(hpUnits.length, equals(12));
      expect(names, contains('Chamba'));
      expect(names, contains('Kangra'));
      expect(names, contains('Mandi'));
      expect(names, contains('Shimla'));
      expect(names.any((n) => n.contains('Spiti')), isTrue);
    });

    testWidgets('2. 8-State Visibility Matrix Tests (Admin ON/OFF x Watershed ON/OFF x Drainage ON/OFF)', (WidgetTester tester) async {
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

      // State 1: Admin ON / Watershed ON / Drainage ON
      expect(workspaceProvider.activeComposition?.layers.firstWhere((l) => l.name == 'District Boundaries').isVisible, isTrue);
      expect(workspaceProvider.activeComposition?.layers.firstWhere((l) => l.name == 'Watershed Boundary').isVisible, isTrue);
      expect(workspaceProvider.activeComposition?.layers.firstWhere((l) => l.name == 'Drainage Network').isVisible, isTrue);

      // State 2: Admin ON / Watershed ON / Drainage OFF
      workspaceProvider.toggleLayerVisibility('layer-drainage-net-01');
      await tester.pumpAndSettle();
      expect(workspaceProvider.activeComposition?.layers.firstWhere((l) => l.name == 'District Boundaries').isVisible, isTrue);
      expect(workspaceProvider.activeComposition?.layers.firstWhere((l) => l.name == 'Watershed Boundary').isVisible, isTrue);
      expect(workspaceProvider.activeComposition?.layers.firstWhere((l) => l.name == 'Drainage Network').isVisible, isFalse);

      // State 3: Admin ON / Watershed OFF / Drainage ON
      workspaceProvider.toggleLayerVisibility('layer-drainage-net-01');
      workspaceProvider.toggleLayerVisibility('layer-watershed-boundary-01');
      await tester.pumpAndSettle();
      expect(workspaceProvider.activeComposition?.layers.firstWhere((l) => l.name == 'District Boundaries').isVisible, isTrue);
      expect(workspaceProvider.activeComposition?.layers.firstWhere((l) => l.name == 'Watershed Boundary').isVisible, isFalse);
      expect(workspaceProvider.activeComposition?.layers.firstWhere((l) => l.name == 'Drainage Network').isVisible, isTrue);

      // State 4: Admin ON / Watershed OFF / Drainage OFF
      workspaceProvider.toggleLayerVisibility('layer-drainage-net-01');
      await tester.pumpAndSettle();
      expect(workspaceProvider.activeComposition?.layers.firstWhere((l) => l.name == 'District Boundaries').isVisible, isTrue);
      expect(workspaceProvider.activeComposition?.layers.firstWhere((l) => l.name == 'Watershed Boundary').isVisible, isFalse);
      expect(workspaceProvider.activeComposition?.layers.firstWhere((l) => l.name == 'Drainage Network').isVisible, isFalse);

      // State 5: Admin OFF / Watershed ON / Drainage ON
      workspaceProvider.toggleLayerVisibility('layer-district-boundaries-01');
      workspaceProvider.toggleLayerVisibility('layer-watershed-boundary-01');
      workspaceProvider.toggleLayerVisibility('layer-drainage-net-01');
      await tester.pumpAndSettle();
      expect(workspaceProvider.activeComposition?.layers.firstWhere((l) => l.name == 'District Boundaries').isVisible, isFalse);
      expect(workspaceProvider.activeComposition?.layers.firstWhere((l) => l.name == 'Watershed Boundary').isVisible, isTrue);
      expect(workspaceProvider.activeComposition?.layers.firstWhere((l) => l.name == 'Drainage Network').isVisible, isTrue);

      // State 6: Admin OFF / Watershed ON / Drainage OFF
      workspaceProvider.toggleLayerVisibility('layer-drainage-net-01');
      await tester.pumpAndSettle();
      expect(workspaceProvider.activeComposition?.layers.firstWhere((l) => l.name == 'District Boundaries').isVisible, isFalse);
      expect(workspaceProvider.activeComposition?.layers.firstWhere((l) => l.name == 'Watershed Boundary').isVisible, isTrue);
      expect(workspaceProvider.activeComposition?.layers.firstWhere((l) => l.name == 'Drainage Network').isVisible, isFalse);

      // State 7: Admin OFF / Watershed OFF / Drainage ON
      workspaceProvider.toggleLayerVisibility('layer-watershed-boundary-01');
      workspaceProvider.toggleLayerVisibility('layer-drainage-net-01');
      await tester.pumpAndSettle();
      expect(workspaceProvider.activeComposition?.layers.firstWhere((l) => l.name == 'District Boundaries').isVisible, isFalse);
      expect(workspaceProvider.activeComposition?.layers.firstWhere((l) => l.name == 'Watershed Boundary').isVisible, isFalse);
      expect(workspaceProvider.activeComposition?.layers.firstWhere((l) => l.name == 'Drainage Network').isVisible, isTrue);

      // State 8: Admin OFF / Watershed OFF / Drainage OFF
      workspaceProvider.toggleLayerVisibility('layer-drainage-net-01');
      await tester.pumpAndSettle();
      expect(workspaceProvider.activeComposition?.layers.firstWhere((l) => l.name == 'District Boundaries').isVisible, isFalse);
      expect(workspaceProvider.activeComposition?.layers.firstWhere((l) => l.name == 'Watershed Boundary').isVisible, isFalse);
      expect(workspaceProvider.activeComposition?.layers.firstWhere((l) => l.name == 'Drainage Network').isVisible, isFalse);
    });

    testWidgets('3. Pour Point and Identify point markers remain independent when all 3 vector layers are OFF', (WidgetTester tester) async {
      final workspaceProvider = ResearchWorkspaceProvider();
      final stateService = StateService();

      workspaceProvider.completeAnalysis(mockSession);
      workspaceProvider.setPourPoint(pourPoint);

      // Turn ALL 3 vector layers OFF
      workspaceProvider.toggleLayerVisibility('layer-district-boundaries-01');
      workspaceProvider.toggleLayerVisibility('layer-watershed-boundary-01');
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

      expect(workspaceProvider.activePourPoint, equals(pourPoint));
    });

    test('4. Toggling Administrative Boundaries does NOT mutate ResearchSession or hydrological calculations', () {
      final workspaceProvider = ResearchWorkspaceProvider();
      workspaceProvider.completeAnalysis(mockSession);

      final initialNodesCount = mockSession.drainageNetwork?.nodes.length;
      final initialArea = mockSession.activeWatershed?.areaKm2;

      workspaceProvider.toggleLayerVisibility('layer-district-boundaries-01');

      expect(mockSession.drainageNetwork?.nodes.length, equals(initialNodesCount));
      expect(mockSession.activeWatershed?.areaKm2, equals(initialArea));
    });
  });
}
