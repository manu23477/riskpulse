import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/data/services/research_map_print_service.dart';
import 'package:riskpulse/domain/gis/analytical_step.dart';
import 'package:riskpulse/domain/gis/data_source_record.dart';
import 'package:riskpulse/domain/gis/data_source_type.dart';
import 'package:riskpulse/domain/gis/drainage_network.dart';
import 'package:riskpulse/domain/gis/gis_layer.dart';
import 'package:riskpulse/domain/gis/map_composition.dart';
import 'package:riskpulse/domain/gis/morphometric_result.dart';
import 'package:riskpulse/domain/gis/raster_data.dart';
import 'package:riskpulse/domain/gis/research_map_page_format.dart';
import 'package:riskpulse/domain/gis/research_session.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/gis/watershed.dart';
import 'package:riskpulse/domain/location/geo_location.dart';

void main() {
  group('Research GIS Printable Map & Publication Export Tests', () {
    late ResearchMapPrintService printService;

    final testExtent = MapExtent(
      southWest: const GeoLocation(latitude: 31.0, longitude: 77.0),
      northEast: const GeoLocation(latitude: 31.2, longitude: 77.2),
    );

    final pourPoint = const GeoLocation(latitude: 31.0900, longitude: 77.1600);

    final mockDem = RasterData(
      width: 10,
      height: 10,
      cellWidth: 30.0,
      cellHeight: 30.0,
      origin: const GeoLocation(latitude: 31.0, longitude: 77.0),
      crs: CoordinateReferenceSystem.wgs84,
      values: List.generate(100, (i) => 1000.0 + i),
    );

    final mockWatershed = Watershed(
      id: 'ws-001',
      pourPointNodeId: 'node-001',
      pourPointLocation: pourPoint,
      mask: mockDem,
      areaKm2: 6.24,
    );

    final mockMorphoResult = MorphometricResult(
      watershedId: 'ws-001',
      streamCountsByOrder: const {1: 14, 2: 4},
      totalStreamLengthByOrder: const {1: 8.5, 2: 4.9},
      meanStreamLengthByOrder: const {1: 0.61, 2: 1.225},
      bifurcationRatios: const {1: 3.5},
      meanBifurcationRatio: 3.5,
      areaKm2: 6.24,
      perimeterKm: 11.4,
      drainageDensity: 2.15,
      streamFrequency: 3.40,
      circularityRatio: 0.62,
      elongationRatio: 0.76,
      basinLengthKm: 4.2,
      maxElevation: 2100.0,
      minElevation: 1200.0,
      basinRelief: 900.0,
      reliefRatio: 0.082,
      ruggednessNumber: 1.24,
    );

    final mockDataSource = const DataSourceRecord(
      provider: 'Google Earth Engine REST API',
      datasetName: 'Copernicus DEM GLO-30 / Digital Surface Model',
      datasetId: 'COPERNICUS/DEM/GLO30',
      resolution: '30.0m',
      acquisitionDate: null, // Intentionally null to test zero-fabrication!
    );

    final mockSession = ResearchSession(
      id: 'session-print-001',
      title: 'Mandi Himachali Himalayan Benchmark',
      extent: testExtent,
      crs: CoordinateReferenceSystem.wgs84,
      dataSources: [mockDataSource],
      workflowSteps: [
        AnalyticalStep(name: 'Terrain Analysis', operationType: 'terrain', timestamp: DateTime.parse('2026-09-25T10:00:00Z')),
        AnalyticalStep(name: 'Hydrological Conditioning', operationType: 'sink_filling', timestamp: DateTime.parse('2026-09-25T10:01:00Z')),
        AnalyticalStep(name: 'Watershed Delineation', operationType: 'watershed', timestamp: DateTime.parse('2026-09-25T10:05:00Z')),
      ],
      layers: [
        GisLayer(
          id: 'slope-01',
          name: 'Slope',
          type: GisLayerType.terrain,
          dataType: SpatialDataType.raster,
          dataSourceType: DataSourceType.cloudProcessing,
        ),
        GisLayer(
          id: 'stream-01',
          name: 'Stream Raster',
          type: GisLayerType.research,
          dataType: SpatialDataType.raster,
          dataSourceType: DataSourceType.cloudProcessing,
        ),
      ],
      activeWatershed: mockWatershed,
      drainageNetwork: const DrainageNetwork(id: 'net-001', nodes: [], segments: []),
      morphometricResult: mockMorphoResult,
      createdAt: DateTime.parse('2026-09-25T10:00:00Z'),
    );

    final mockComposition = MapComposition(
      id: 'comp-print-001',
      title: 'Mandi Hydrological Publication Map',
      extent: testExtent,
      layers: mockSession.layers,
    );

    setUp(() {
      printService = ResearchMapPrintService();
    });

    test('1. Completed Hydro ResearchSession produces a valid PrintableResearchMapModel', () {
      final model = printService.buildMapModel(
        session: mockSession,
        composition: mockComposition,
      );

      expect(model.mapTitle, 'Mandi Hydrological Publication Map');
      expect(model.studyName, 'Mandi Himachali Himalayan Benchmark');
      expect(model.hasAoiWatershedBoundary, isTrue);
      expect(model.hasDrainageNetwork, isTrue);
      expect(model.hasStreamRaster, isTrue);
      expect(model.hasPourPoint, isTrue);
      expect(model.pourPointLocation?.latitude, 31.0900);
    });

    test('2 & 3. Generated layers appear in the publication legend; non-generated layers are omitted', () {
      final model = printService.buildMapModel(
        session: mockSession,
        composition: mockComposition,
      );

      final labels = model.publicationLegendEntries.map((e) => e.label).toList();
      expect(labels, contains('Flat'));
      expect(labels, contains('Stream Channel'));
      // Non-generated layer (e.g. Shreve Magnitude) is omitted!
      expect(model.hasShreveMagnitude, isFalse);
    });

    test('4. "No Data" or diagnostic status text is NEVER printed in the publication legend', () {
      final model = printService.buildMapModel(
        session: mockSession,
        composition: mockComposition,
      );

      for (final entry in model.publicationLegendEntries) {
        expect(entry.label.toLowerCase(), isNot(contains('no data')));
        expect(entry.label.toLowerCase(), isNot(contains('not generated')));
      }
    });

    test('5. Data provenance is transferred correctly from ResearchSession.dataSources', () {
      final model = printService.buildMapModel(
        session: mockSession,
        composition: mockComposition,
      );

      expect(model.dataSources.length, equals(1));
      expect(model.dataSources.first.provider, 'Google Earth Engine REST API');
      expect(model.dataSources.first.datasetId, 'COPERNICUS/DEM/GLO30');
    });

    test('6. Analytical workflow is transferred correctly from ResearchSession.workflowSteps', () {
      final model = printService.buildMapModel(
        session: mockSession,
        composition: mockComposition,
      );

      expect(model.workflowSummary.length, equals(3));
      expect(model.workflowSummary, contains('Terrain Analysis'));
      expect(model.workflowSummary, contains('Hydrological Conditioning'));
      expect(model.workflowSummary, contains('Watershed Delineation'));
    });

    test('7. Morphometric values are transferred unchanged from MorphometricResult', () {
      final model = printService.buildMapModel(
        session: mockSession,
        composition: mockComposition,
      );

      expect(model.morphometricSummary['Watershed Area'], '6.24 km²');
      expect(model.morphometricSummary['Drainage Density'], '2.15 km/km²');
    });

    test('8. Missing provenance fields (acquisitionDate = null) remain null rather than fabricated', () {
      final model = printService.buildMapModel(
        session: mockSession,
        composition: mockComposition,
      );

      final src = model.dataSources.first;
      expect(src.acquisitionDate, isNull); // Must NOT be replaced with DateTime.now()!
    });

    test('9. A4 and A3 portrait and landscape page format models support exact dimensions', () {
      expect(ResearchMapPageFormat.a4Portrait.widthPoints, closeTo(595.28, 0.1));
      expect(ResearchMapPageFormat.a4Portrait.heightPoints, closeTo(841.89, 0.1));

      expect(ResearchMapPageFormat.a4Landscape.widthPoints, closeTo(841.89, 0.1));
      expect(ResearchMapPageFormat.a4Landscape.heightPoints, closeTo(595.28, 0.1));

      expect(ResearchMapPageFormat.a3Portrait.isA3, isTrue);
      expect(ResearchMapPageFormat.a3Landscape.isA3, isTrue);
      expect(ResearchMapPageFormat.a3Landscape.isLandscape, isTrue);
    });

    test('10. Compiles printable map into binary PDF document without altering hydrological outputs', () {
      final pdfBytes = printService.generatePdfBinary(
        session: mockSession,
        composition: mockComposition,
        pageFormat: ResearchMapPageFormat.a4Landscape,
      );

      expect(pdfBytes, isNotEmpty);
      expect(pdfBytes.length, greaterThan(100));

      // Verify PDF 1.4 header bytes (%PDF-1.4)
      final headerStr = String.fromCharCodes(pdfBytes.sublist(0, 8));
      expect(headerStr, startsWith('%PDF-1.4'));

      // Verify original session models remain unchanged
      expect(mockSession.activeWatershed?.areaKm2, equals(6.24));
      expect(mockSession.morphometricResult?.drainageDensity, equals(2.15));
    });
  });
}
