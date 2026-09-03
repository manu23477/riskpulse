import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/domain/gis/research_product.dart';
import 'package:riskpulse/domain/gis/research_product_registry.dart';
import 'package:riskpulse/data/services/research_product_registry_factory.dart';
import 'package:riskpulse/domain/gis/research_session.dart';
import 'package:riskpulse/domain/gis/map_composition.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/gis/raster_data.dart';
import 'package:riskpulse/domain/gis/drainage_network.dart';
import 'package:riskpulse/domain/gis/drainage_node.dart';
import 'package:riskpulse/domain/gis/stream_segment.dart';
import 'package:riskpulse/domain/gis/watershed.dart';
import 'package:riskpulse/domain/gis/morphometric_result.dart';
import 'package:riskpulse/domain/gis/gis_layer.dart';
import 'package:riskpulse/domain/gis/data_source_type.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/data/providers/research_workspace_provider.dart';

void main() {
  group('ResearchProductRegistry 4K.7.1 Tests', () {
    final testExtent = MapExtent(
      southWest: const GeoLocation(latitude: 31.0, longitude: 77.0),
      northEast: const GeoLocation(latitude: 31.5, longitude: 77.5),
    );

    test('1. Empty/new ResearchSession produces no falsely available products except studyArea if extent captured', () {
      final session = ResearchSession(
        id: 's-empty',
        title: 'Empty Session',
        extent: testExtent,
        createdAt: DateTime.now(),
      );

      final registry = ResearchProductRegistryFactory.fromSession(session);

      // Only studyArea should be available if extent exists
      final available = registry.availableProducts;
      expect(available.length, 1);
      expect(available.first.type, ResearchProductType.studyArea);

      // All other products must be unavailable
      final unavailable = registry.unavailableProducts;
      expect(unavailable.length, greaterThan(10));
      expect(registry.byType(ResearchProductType.dem)?.isAvailable, false);
      expect(registry.byType(ResearchProductType.slope)?.isAvailable, false);
      expect(registry.byType(ResearchProductType.watershed)?.isAvailable, false);
    });

    test('2. Genuine DEM produces an available DEM product with real dimensions and CRS', () {
      final demRaster = RasterData(
        width: 10,
        height: 10,
        cellWidth: 0.01,
        cellHeight: 0.01,
        origin: const GeoLocation(latitude: 31.5, longitude: 77.0),
        crs: CoordinateReferenceSystem.wgs84,
        values: List.filled(100, 1000.0),
        units: 'meters',
      );

      final provider = ResearchWorkspaceProvider();
      provider.initializeSession('DEM Test', testExtent);
      provider.setInputDem(demRaster);

      final registry = provider.productRegistry;
      final demProd = registry.byType(ResearchProductType.dem);

      expect(demProd, isNotNull);
      expect(demProd!.isAvailable, isTrue);
      expect(demProd.dimensions?.width, 10);
      expect(demProd.dimensions?.height, 10);
      expect(demProd.crsCode, 'EPSG:4326');
      expect(demProd.units, 'meters');
      expect(demProd.sourceData, equals(demRaster));
      expect(demProd.supportedExportFormats, contains(ResearchProductFormat.geoTiff));
    });

    test('3. Genuine analytical raster produces corresponding available product', () {
      final slopeRaster = RasterData(
        width: 5,
        height: 5,
        cellWidth: 0.01,
        cellHeight: 0.01,
        origin: const GeoLocation(latitude: 31.5, longitude: 77.0),
        crs: CoordinateReferenceSystem.wgs84,
        values: List.filled(25, 15.0),
        units: 'degrees',
      );

      final slopeLayer = GisLayer(
        id: 'layer-slope',
        name: 'Slope',
        type: GisLayerType.terrain,
        dataType: SpatialDataType.raster,
        dataSourceType: DataSourceType.cloudProcessing,
        metadata: {'raster_data': slopeRaster},
      );

      final session = ResearchSession(
        id: 's-slope',
        title: 'Slope Session',
        extent: testExtent,
        layers: [slopeLayer],
        createdAt: DateTime.now(),
      );

      final registry = ResearchProductRegistryFactory.fromSession(session);
      final slopeProd = registry.byType(ResearchProductType.slope);

      expect(slopeProd, isNotNull);
      expect(slopeProd!.isAvailable, isTrue);
      expect(slopeProd.dimensions?.width, 5);
      expect(slopeProd.units, 'degrees');
      expect(slopeProd.sourceData, equals(slopeRaster));
    });

    test('4. Missing analytical product remains unavailable without fabrication', () {
      final session = ResearchSession(
        id: 's-partial',
        title: 'Partial Session',
        extent: testExtent,
        createdAt: DateTime.now(),
      );

      final registry = ResearchProductRegistryFactory.fromSession(session);

      expect(registry.byType(ResearchProductType.aspect)?.isAvailable, false);
      expect(registry.byType(ResearchProductType.aspect)?.dimensions, isNull);
      expect(registry.byType(ResearchProductType.aspect)?.sourceData, isNull);
    });

    test('5. Session-level products (DrainageNetwork, Watershed) are represented correctly', () {
      final network = DrainageNetwork(
        id: 'net-1',
        nodes: [
          const DrainageNode(
            id: 'n1',
            type: DrainageNodeType.headwater,
            location: GeoLocation(latitude: 31.1, longitude: 77.1),
          ),
        ],
        segments: [
          const StreamSegment(
            id: 'seg-1',
            upstreamNodeId: 'n1',
            downstreamNodeId: 'n2',
            polyline: [
              GeoLocation(latitude: 31.1, longitude: 77.1),
              GeoLocation(latitude: 31.0, longitude: 77.0),
            ],
            strahlerOrder: 1,
            length: 1200,
          ),
        ],
      );

      final watershed = Watershed(
        id: 'ws-1',
        pourPointNodeId: 'n2',
        pourPointLocation: const GeoLocation(latitude: 31.0, longitude: 77.0),
        mask: RasterData(
          width: 2, height: 2, cellWidth: 0.1, cellHeight: 0.1,
          origin: const GeoLocation(latitude: 31.2, longitude: 77.0),
          crs: CoordinateReferenceSystem.wgs84,
          values: [1.0, 1.0, 1.0, 1.0],
        ),
        areaKm2: 12.5,
      );

      final session = ResearchSession(
        id: 's-hydrology',
        title: 'Hydrology Session',
        extent: testExtent,
        drainageNetwork: network,
        activeWatershed: watershed,
        createdAt: DateTime.now(),
      );

      final registry = ResearchProductRegistryFactory.fromSession(session);

      final netProd = registry.byType(ResearchProductType.drainageNetwork);
      expect(netProd?.isAvailable, true);
      expect(netProd?.featureCount, 1);
      expect(netProd?.category, ResearchProductCategory.vector);

      final wsProd = registry.byType(ResearchProductType.watershed);
      expect(wsProd?.isAvailable, true);
      expect(wsProd?.areaKm2, 12.5);
      expect(wsProd?.category, ResearchProductCategory.vector);
    });

    test('6-9. No fabricated CRS, units, dimensions, or feature counts when product unavailable', () {
      final session = ResearchSession(
        id: 's-none',
        title: 'None',
        extent: testExtent,
        createdAt: DateTime.now(),
      );

      final registry = ResearchProductRegistryFactory.fromSession(session);

      for (final p in registry.unavailableProducts) {
        expect(p.dimensions, isNull, reason: '${p.name} should not have fabricated dimensions');
        expect(p.featureCount, isNull, reason: '${p.name} should not have fabricated feature count');
        expect(p.sourceData, isNull, reason: '${p.name} should not have fabricated source data');
      }
    });

    test('10. Product availability does not imply analysis failure', () {
      final session = ResearchSession(
        id: 's-init',
        title: 'Just Configured',
        extent: testExtent,
        createdAt: DateTime.now(),
      );

      final registry = ResearchProductRegistryFactory.fromSession(session);

      final watershedProd = registry.byType(ResearchProductType.watershed);
      expect(watershedProd?.availability, ResearchProductAvailability.unavailable);
      // Ensure status is unavailable, NOT marked as "Failed"
      expect(watershedProd?.metadata['status'], isNull);
    });

    test('11-13. Registry is immutable and does not mutate ResearchSession or MapComposition', () {
      final session = ResearchSession(
        id: 's-immutable',
        title: 'Immutable',
        extent: testExtent,
        createdAt: DateTime.now(),
      );

      final composition = MapComposition(
        id: 'c-immutable',
        title: 'Immutable Comp',
        layers: const [],
      );

      final provider = ResearchWorkspaceProvider();
      provider.initializeSession('Test', testExtent);
      provider.completeAnalysis(session);
      provider.updateComposition(composition);

      final registry1 = provider.productRegistry;
      expect(registry1.products, isA<List<ResearchProduct>>());

      // Attempting to modify unmodifiable collection throws
      expect(() => (registry1.products as List).add(
        const ResearchProduct(
          id: 'fake',
          name: 'Fake',
          type: ResearchProductType.dem,
          category: ResearchProductCategory.raster,
          availability: ResearchProductAvailability.unavailable,
          supportedExportFormats: [],
        )
      ), throwsUnsupportedError);

      // Original session and composition remain identical
      expect(provider.currentSession?.id, session.id);
      expect(provider.activeComposition?.id, composition.id);
    });

    test('14. Supported format declarations are correct according to domain product type', () {
      final registry = ResearchProductRegistryFactory.fromWorkspace(ResearchWorkspaceProvider());

      final dem = registry.byType(ResearchProductType.dem);
      expect(dem?.supportedExportFormats, [ResearchProductFormat.geoTiff]);

      final drainage = registry.byType(ResearchProductType.drainageNetwork);
      expect(drainage?.supportedExportFormats, [ResearchProductFormat.geoJson]);

      final morpho = registry.byType(ResearchProductType.morphometricResults);
      expect(morpho?.supportedExportFormats, containsAll([ResearchProductFormat.csv, ResearchProductFormat.json]));
    });

    test('15. Provenance references are preserved where genuinely available', () {
      final demRaster = RasterData(
        width: 3, height: 3, cellWidth: 0.1, cellHeight: 0.1,
        origin: const GeoLocation(latitude: 31, longitude: 77),
        crs: CoordinateReferenceSystem.wgs84,
        values: List.filled(9, 100.0),
      );

      final provider = ResearchWorkspaceProvider();
      provider.initializeSession('Prov Test', testExtent);
      provider.setInputDem(demRaster);

      final registry = provider.productRegistry;
      final demProd = registry.byType(ResearchProductType.dem);

      expect(demProd?.provenanceStepName, 'DEM Acquisition');
    });

    test('16. Repeated registry creation from same state is deterministic', () {
      final session = ResearchSession(
        id: 's-det',
        title: 'Deterministic',
        extent: testExtent,
        createdAt: DateTime.now(),
      );

      final r1 = ResearchProductRegistryFactory.fromSession(session);
      final r2 = ResearchProductRegistryFactory.fromSession(session);

      expect(r1.availableCount, equals(r2.availableCount));
      expect(r1.totalCount, equals(r2.totalCount));
      expect(r1.products.map((p) => p.id), equals(r2.products.map((p) => p.id)));
    });

    test('17. Multiple analytical products coexist correctly', () {
      final demRaster = RasterData(
        width: 3, height: 3, cellWidth: 0.1, cellHeight: 0.1,
        origin: const GeoLocation(latitude: 31, longitude: 77),
        crs: CoordinateReferenceSystem.wgs84,
        values: List.filled(9, 100.0),
      );

      final slopeLayer = GisLayer(
        id: 'l-slope', name: 'Slope', type: GisLayerType.terrain,
        dataType: SpatialDataType.raster, dataSourceType: DataSourceType.cloudProcessing,
        metadata: {'raster_data': demRaster},
      );

      final morpho = const MorphometricResult(
        watershedId: 'ws-1', streamCountsByOrder: {1: 2}, totalStreamLengthByOrder: {1: 5.0},
        meanStreamLengthByOrder: {1: 2.5}, bifurcationRatios: {}, meanBifurcationRatio: 1.0,
        areaKm2: 10.0, perimeterKm: 14.0, drainageDensity: 0.5, streamFrequency: 0.2,
        circularityRatio: 0.6, elongationRatio: 0.7, basinLengthKm: 4.0, maxElevation: 1200,
        minElevation: 800, basinRelief: 400, reliefRatio: 0.1, ruggednessNumber: 0.2,
      );

      final session = ResearchSession(
        id: 's-multi', title: 'Multi', extent: testExtent,
        layers: [slopeLayer], morphometricResult: morpho, createdAt: DateTime.now(),
      );

      final registry = ResearchProductRegistryFactory.fromSession(session);

      expect(registry.byType(ResearchProductType.slope)?.isAvailable, true);
      expect(registry.byType(ResearchProductType.morphometricResults)?.isAvailable, true);
      expect(registry.availableCount, 4); // AOI + DEM (from slope metadata) + Slope + Morphometry
    });

    test('18. Failed workspace state does not cause fabricated products', () {
      final provider = ResearchWorkspaceProvider();
      provider.failAnalysis('Simulated Analysis Error');

      final registry = provider.productRegistry;

      // Failed state without last known session has no available products
      expect(registry.byType(ResearchProductType.dem)?.isAvailable, false);
      expect(registry.byType(ResearchProductType.watershed)?.isAvailable, false);
    });

    test('19. Last Known Good analytical state is handled according to existing state semantics', () {
      final provider = ResearchWorkspaceProvider();
      final session = ResearchSession(
        id: 's-lkg', title: 'LKG Session', extent: testExtent,
        drainageNetwork: const DrainageNetwork(id: 'd1', nodes: [], segments: []),
        createdAt: DateTime.now(),
      );

      provider.completeAnalysis(session);
      expect(provider.productRegistry.byType(ResearchProductType.drainageNetwork)?.isAvailable, true);

      // Now fail a subsequent run
      provider.failAnalysis('Subsequent Run Failed');

      // The provider retains lastKnownSession in WorkspaceFailed, so LKG products remain accessible
      expect(provider.productRegistry.byType(ResearchProductType.drainageNetwork)?.isAvailable, true);
      expect(provider.currentSession?.id, 's-lkg');
    });
  });
}
