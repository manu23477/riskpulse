import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/data/services/drainage_analysis_service.dart';
import 'package:riskpulse/data/services/hydrological_analysis_service.dart';
import 'package:riskpulse/data/services/metadata_factory.dart';
import 'package:riskpulse/data/services/morphometric_analysis_service.dart';
import 'package:riskpulse/data/services/research_workflow_orchestrator.dart';
import 'package:riskpulse/data/services/terrain_analysis_service.dart';
import 'package:riskpulse/data/services/watershed_analysis_service.dart';
import 'package:riskpulse/domain/gis/data_source_record.dart';
import 'package:riskpulse/domain/gis/map_composition.dart';
import 'package:riskpulse/domain/gis/raster_data.dart';
import 'package:riskpulse/domain/gis/research_metadata_record.dart';
import 'package:riskpulse/domain/gis/research_session.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/location/geo_location.dart';

void main() {
  group('Live Hydro Research Summary Provenance Propagation Tests', () {
    late ResearchWorkflowOrchestrator orchestrator;
    late MetadataFactory metadataFactory;

    setUp(() {
      orchestrator = ResearchWorkflowOrchestrator(
        terrainService: TerrainAnalysisService(),
        hydroService: HydrologicalAnalysisService(),
        drainageService: DrainageAnalysisService(),
        watershedService: WatershedAnalysisService(),
        morphoService: MorphometricAnalysisService(),
      );
      metadataFactory = MetadataFactory();
    });

    final testExtent = MapExtent(
      southWest: const GeoLocation(latitude: 31.0, longitude: 77.0),
      northEast: const GeoLocation(latitude: 31.2, longitude: 77.2),
    );

    final testDem = RasterData(
      width: 10,
      height: 10,
      cellWidth: 30.0,
      cellHeight: 30.0,
      origin: const GeoLocation(latitude: 31.0, longitude: 77.0),
      crs: CoordinateReferenceSystem.wgs84,
      values: List.generate(100, (i) => 1000.0 + i),
      metadata: const {
        'provider': 'Google Earth Engine REST API',
        'providerId': 'gee',
        'datasetId': 'COPERNICUS/DEM/GLO30',
        'datasetName': 'Copernicus DEM GLO-30 / Digital Surface Model',
        'acquisitionDate': '2024-01-15T10:00:00Z',
        'resolutionMeters': 30.0,
      },
    );

    test('8a..8e. GLO-30 DEM metadata is propagated into ResearchSession.dataSources with preserved provider, datasetId, datasetName, and acquisitionDate', () async {
      final session = ResearchSession(
        id: 'session-001',
        title: 'Himalayan Study',
        extent: testExtent,
        createdAt: DateTime.now(),
      );

      final updatedSession = await orchestrator.runAnalysis(
        session: session,
        dem: testDem,
        pourPoint: const GeoLocation(latitude: 31.05, longitude: 77.05),
      );

      expect(updatedSession.dataSources, isNotEmpty);
      final demSource = updatedSession.dataSources.first;

      expect(demSource.provider, equals('Google Earth Engine REST API'));
      expect(demSource.datasetId, equals('COPERNICUS/DEM/GLO30'));
      expect(demSource.datasetName, equals('Copernicus DEM GLO-30 / Digital Surface Model'));
      expect(demSource.acquisitionDate, equals(DateTime.parse('2024-01-15T10:00:00Z')));
      expect(demSource.resolution, equals('30.0m'));
    });

    test('8f. Missing acquisitionDate in DEM metadata is NOT replaced with DateTime.now()', () async {
      final demWithoutAcq = RasterData(
        width: 10,
        height: 10,
        cellWidth: 30.0,
        cellHeight: 30.0,
        origin: const GeoLocation(latitude: 31.0, longitude: 77.0),
        crs: CoordinateReferenceSystem.wgs84,
        values: List.generate(100, (i) => 1000.0 + i),
        metadata: const {
          'provider': 'Local GeoTIFF',
          'datasetId': 'LOCAL_DEM_01',
          'datasetName': 'Local Himalayan DEM',
          // acquisitionDate is intentionally ABSENT!
        },
      );

      final session = ResearchSession(
        id: 'session-002',
        title: 'Local Study',
        extent: testExtent,
        createdAt: DateTime.now(),
      );

      final updatedSession = await orchestrator.runAnalysis(
        session: session,
        dem: demWithoutAcq,
        pourPoint: const GeoLocation(latitude: 31.05, longitude: 77.05),
      );

      final demSource = updatedSession.dataSources.first;
      expect(demSource.acquisitionDate, isNull); // Must NOT be fabricated!
    });

    test('8g. Existing data sources in session are preserved during analysis run', () async {
      final existingSource = const DataSourceRecord(
        provider: 'GSI',
        datasetName: 'GSI Landslide Inventory',
        datasetId: 'GSI_LS_2023',
      );

      final session = ResearchSession(
        id: 'session-003',
        title: 'Preservation Study',
        extent: testExtent,
        dataSources: [existingSource],
        createdAt: DateTime.now(),
      );

      final updatedSession = await orchestrator.runAnalysis(
        session: session,
        dem: testDem,
        pourPoint: const GeoLocation(latitude: 31.05, longitude: 77.05),
      );

      expect(updatedSession.dataSources.length, equals(2));
      expect(updatedSession.dataSources.first.datasetName, equals('GSI Landslide Inventory'));
      expect(updatedSession.dataSources.last.datasetName, equals('Copernicus DEM GLO-30 / Digital Surface Model'));
    });

    test('8h. Repeated analysis does not create duplicate DEM source records', () async {
      final session = ResearchSession(
        id: 'session-004',
        title: 'Repeated Analysis Study',
        extent: testExtent,
        createdAt: DateTime.now(),
      );

      // Run 1
      final session1 = await orchestrator.runAnalysis(
        session: session,
        dem: testDem,
        pourPoint: const GeoLocation(latitude: 31.05, longitude: 77.05),
      );

      // Run 2 (Repeated on same session)
      final session2 = await orchestrator.runAnalysis(
        session: session1,
        dem: testDem,
        pourPoint: const GeoLocation(latitude: 31.05, longitude: 77.05),
      );

      expect(session2.dataSources.length, equals(1)); // No duplicate DEM records!
    });

    test('8i. Provenance becomes 100% (COMPLETE) ONLY when data sources, workflow steps, and CRS are present', () async {
      final session = ResearchSession(
        id: 'session-005',
        title: 'Full Provenance Study',
        extent: testExtent,
        createdAt: DateTime.now(),
      );

      final updatedSession = await orchestrator.runAnalysis(
        session: session,
        dem: testDem,
        pourPoint: const GeoLocation(latitude: 31.05, longitude: 77.05),
      );

      final composition = MapComposition(
        id: 'comp-005',
        title: updatedSession.title,
        extent: updatedSession.extent,
        layers: updatedSession.layers,
      );

      final record = metadataFactory.createRecord(session: updatedSession, composition: composition);

      expect(record.assessment.score, equals(1.0)); // 100%! (0.4 dataSources + 0.4 workflow + 0.2 CRS)
      expect(record.assessment.completeness, equals(CompletenessLevel.complete));
      expect(record.warnings, isNot(contains('Missing data source records.')));
    });
  });
}
