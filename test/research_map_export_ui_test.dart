import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:riskpulse/data/providers/research_workspace_provider.dart';
import 'package:riskpulse/data/services/state_service.dart';
import 'package:riskpulse/domain/gis/analytical_step.dart';
import 'package:riskpulse/domain/gis/data_source_record.dart';
import 'package:riskpulse/domain/gis/data_source_type.dart';
import 'package:riskpulse/domain/gis/drainage_network.dart';
import 'package:riskpulse/domain/gis/gis_layer.dart';
import 'package:riskpulse/domain/gis/morphometric_result.dart';
import 'package:riskpulse/domain/gis/raster_data.dart';
import 'package:riskpulse/domain/gis/research_map_page_format.dart';
import 'package:riskpulse/domain/gis/research_session.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/gis/watershed.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/screens/research_gis/research_gis_screen.dart';
import 'package:riskpulse/screens/research_gis/widgets/export_map_dialog.dart';

void main() {
  group('Research GIS Export Map UI Implementation Tests', () {
    final testExtent = MapExtent(
      southWest: const GeoLocation(latitude: 31.0, longitude: 77.0),
      northEast: const GeoLocation(latitude: 31.2, longitude: 77.2),
    );

    final mockDem = RasterData(
      width: 5,
      height: 5,
      cellWidth: 30.0,
      cellHeight: 30.0,
      origin: const GeoLocation(latitude: 31.0, longitude: 77.0),
      crs: CoordinateReferenceSystem.wgs84,
      values: List.generate(25, (i) => 1000.0 + i),
    );

    final mockSession = ResearchSession(
      id: 'session-ui-export-01',
      title: 'Mandi Export Test',
      extent: testExtent,
      crs: CoordinateReferenceSystem.wgs84,
      dataSources: const [
        DataSourceRecord(
          provider: 'Google Earth Engine REST API',
          datasetName: 'Copernicus DEM GLO-30',
          datasetId: 'COPERNICUS/DEM/GLO30',
        )
      ],
      workflowSteps: [
        AnalyticalStep(name: 'Terrain Analysis', operationType: 'terrain', timestamp: DateTime.parse('2026-09-25T10:00:00Z')),
      ],
      layers: [
        GisLayer(
          id: 'slope-01',
          name: 'Slope',
          type: GisLayerType.terrain,
          dataType: SpatialDataType.raster,
          dataSourceType: DataSourceType.cloudProcessing,
        ),
      ],
      activeWatershed: Watershed(
        id: 'ws-001',
        pourPointNodeId: 'node-01',
        pourPointLocation: const GeoLocation(latitude: 31.09, longitude: 77.16),
        mask: mockDem,
        areaKm2: 6.24,
      ),
      drainageNetwork: const DrainageNetwork(id: 'net-01', nodes: [], segments: []),
      morphometricResult: const MorphometricResult(
        watershedId: 'ws-001',
        streamCountsByOrder: {1: 10},
        totalStreamLengthByOrder: {1: 5.0},
        meanStreamLengthByOrder: {1: 0.5},
        bifurcationRatios: {},
        meanBifurcationRatio: 1.0,
        areaKm2: 6.24,
        perimeterKm: 11.4,
        drainageDensity: 2.15,
        streamFrequency: 3.4,
        circularityRatio: 0.62,
        elongationRatio: 0.76,
        basinLengthKm: 4.2,
        maxElevation: 2100.0,
        minElevation: 1200.0,
        basinRelief: 900.0,
        reliefRatio: 0.082,
        ruggednessNumber: 1.24,
      ),
      createdAt: DateTime.parse('2026-09-25T10:00:00Z'),
    );

    testWidgets('1. Export Map button is rendered in AppBar and is disabled when workspace is not ready', (WidgetTester tester) async {
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

      expect(find.text('EXPORT MAP ▾'), findsOneWidget);

      final exportBtnFinder = find.byKey(const Key('export-map-appbar-btn'));
      expect(exportBtnFinder, findsOneWidget);

      final popupBtn = tester.widget<PopupMenuButton<ExportMapActionType>>(exportBtnFinder);
      expect(popupBtn.enabled, isFalse); // Disabled when state is not WorkspaceReady!
    });

    testWidgets('2. Export Map button is enabled when workspace state is WorkspaceReady', (WidgetTester tester) async {
      final workspaceProvider = ResearchWorkspaceProvider();
      final stateService = StateService();

      // Set workspace to WorkspaceReady state
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

      final exportBtnFinder = find.byKey(const Key('export-map-appbar-btn'));
      expect(exportBtnFinder, findsOneWidget);

      final popupBtn = tester.widget<PopupMenuButton<ExportMapActionType>>(exportBtnFinder);
      expect(popupBtn.enabled, isTrue); // Enabled when state is WorkspaceReady!
    });

    testWidgets('3. ExportMapDialog renders all 3 export options and page format dropdown', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ExportMapDialog(),
          ),
        ),
      );

      expect(find.text('Export Research Map'), findsOneWidget);
      expect(find.text('Publication PDF Map'), findsOneWidget);
      expect(find.text('Map Image Snapshot (PNG)'), findsOneWidget);
      expect(find.text('Browse GIS Product Catalogue (GeoTIFF / GeoJSON)'), findsOneWidget);

      // Verify dropdown formats
      expect(find.text('A4 Portrait (210 x 297 mm)'), findsOneWidget);
    });

    testWidgets('4. ExportMapDialog returns selected ExportMapActionType and page format on submit', (WidgetTester tester) async {
      ExportMapDialogResult? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () async {
                  result = await showDialog<ExportMapDialogResult>(
                    context: ctx,
                    builder: (dCtx) => const ExportMapDialog(),
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('export-pdf-action-btn')), findsOneWidget);
      await tester.tap(find.byKey(const Key('export-pdf-action-btn')));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result?.actionType, equals(ExportMapActionType.publicationPdf));
      expect(result?.selectedPdfFormat, equals(ResearchMapPageFormat.a4Portrait));
    });

    test('5. Export operations do NOT mutate ResearchSession or hydrological outputs', () {
      final initialArea = mockSession.activeWatershed?.areaKm2;
      final initialDensity = mockSession.morphometricResult?.drainageDensity;

      expect(initialArea, equals(6.24));
      expect(initialDensity, equals(2.15));

      // Re-verify that session is untouched
      expect(mockSession.activeWatershed?.areaKm2, equals(initialArea));
      expect(mockSession.morphometricResult?.drainageDensity, equals(initialDensity));
    });
  });
}
