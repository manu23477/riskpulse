import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/domain/gis/raster_data.dart';
import 'package:riskpulse/domain/gis/research_product.dart';
import 'package:riskpulse/domain/gis/research_product_registry.dart';
import 'package:riskpulse/data/services/research_product_registry_factory.dart';
import 'package:riskpulse/domain/gis/research_session.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/gis/gis_layer.dart';
import 'package:riskpulse/domain/gis/data_source_type.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/gis/raster_export_contract.dart';
import 'package:riskpulse/data/services/raster_export_service.dart';

void main() {
  group('Raster Export Contract 4K.7.2.1 Tests', () {
    final testExtent = MapExtent(
      southWest: const GeoLocation(latitude: 31.0, longitude: 77.0),
      northEast: const GeoLocation(latitude: 31.5, longitude: 77.5),
    );

    final testDemRaster = RasterData(
      width: 4,
      height: 4,
      cellWidth: 0.01,
      cellHeight: 0.01,
      origin: const GeoLocation(latitude: 31.5, longitude: 77.0),
      crs: CoordinateReferenceSystem.wgs84,
      values: [
        100.0, 105.0, 110.0, 115.0,
        102.0, 107.0, 112.0, 117.0,
        104.0, 109.0, 114.0, 119.0,
        106.0, 111.0, 116.0, 121.0,
      ],
      noDataValue: -9999.0,
      units: 'meters',
    );

    final availableDemProduct = ResearchProduct(
      id: 'prod-dem-01',
      name: 'Digital Elevation Model',
      type: ResearchProductType.dem,
      category: ResearchProductCategory.raster,
      availability: ResearchProductAvailability.available,
      supportedExportFormats: const [ResearchProductFormat.geoTiff],
      crsCode: 'EPSG:4326',
      units: 'meters',
      dimensions: (width: 4, height: 4),
      sourceData: testDemRaster,
      provenanceStepName: 'DEM Acquisition',
    );

    final unavailableProduct = ResearchProduct(
      id: 'prod-slope-01',
      name: 'Slope',
      type: ResearchProductType.slope,
      category: ResearchProductCategory.raster,
      availability: ResearchProductAvailability.unavailable,
      supportedExportFormats: const [ResearchProductFormat.geoTiff],
      sourceData: null,
      provenanceStepName: 'Terrain Analysis',
    );

    final vectorProduct = ResearchProduct(
      id: 'prod-drainage-01',
      name: 'Drainage Network',
      type: ResearchProductType.drainageNetwork,
      category: ResearchProductCategory.vector,
      availability: ResearchProductAvailability.available,
      supportedExportFormats: const [ResearchProductFormat.geoJson],
      sourceData: Object(),
      provenanceStepName: 'Drainage Network Generation',
    );

    final service = RasterExportService();

    test('1. Valid export request can reference an available raster product', () {
      final request = RasterExportRequest(
        product: availableDemProduct,
        requestedAt: DateTime.now(),
      );

      final result = service.validateRequest(request);

      expect(result.isSuccess, isTrue);
      expect(result.request.product.id, 'prod-dem-01');
      expect(result.error, isNull);
    });

    test('2. Unavailable raster product is rejected/represented correctly', () {
      final request = RasterExportRequest(
        product: unavailableProduct,
        requestedAt: DateTime.now(),
      );

      final result = service.validateRequest(request);

      expect(result.isSuccess, isFalse);
      expect(result.error?.type, RasterExportErrorType.productUnavailable);
      expect(result.error?.productId, 'prod-slope-01');
    });

    test('3. Invalid request (non-raster product) is represented correctly', () {
      final request = RasterExportRequest(
        product: vectorProduct,
        requestedAt: DateTime.now(),
      );

      final result = service.validateRequest(request);

      expect(result.isSuccess, isFalse);
      expect(result.error?.type, RasterExportErrorType.invalidRequest);
      expect(result.error?.productId, 'prod-drainage-01');
    });

    test('4. GeoTIFF is represented as a supported future format', () {
      final request = RasterExportRequest(
        product: availableDemProduct,
        format: RasterExportFormat.geoTiff,
        requestedAt: DateTime.now(),
      );

      expect(request.format, RasterExportFormat.geoTiff);
      final result = service.validateRequest(request);
      expect(result.isSuccess, isTrue);
    });

    test('5. No synthetic RasterData is created', () {
      final request = RasterExportRequest(
        product: unavailableProduct,
        requestedAt: DateTime.now(),
      );

      expect(request.authoritativeRaster, isNull);
    });

    test('6. The request does not duplicate raster values', () {
      final request = RasterExportRequest(
        product: availableDemProduct,
        requestedAt: DateTime.now(),
      );

      expect(identical(request.authoritativeRaster?.values, testDemRaster.values), isTrue);
    });

    test('7. Authoritative RasterData reference remains intact', () {
      final request = RasterExportRequest(
        product: availableDemProduct,
        requestedAt: DateTime.now(),
      );

      expect(request.authoritativeRaster, equals(testDemRaster));
      expect(request.authoritativeRaster?.width, 4);
      expect(request.authoritativeRaster?.height, 4);
    });

    test('8. CRS is not fabricated', () {
      final request = RasterExportRequest(
        product: availableDemProduct,
        requestedAt: DateTime.now(),
      );

      expect(request.crs, equals(CoordinateReferenceSystem.wgs84));
      expect(request.crs?.code, 'EPSG:4326');
    });

    test('9. NoData is not fabricated', () {
      final request = RasterExportRequest(
        product: availableDemProduct,
        requestedAt: DateTime.now(),
      );

      expect(request.noDataValue, -9999.0);
    });

    test('10. Numeric policy is explicit if represented', () {
      final reqDefault = RasterExportRequest(
        product: availableDemProduct,
        requestedAt: DateTime.now(),
      );
      final reqFloat32 = RasterExportRequest(
        product: availableDemProduct,
        numericPolicy: NumericExportPolicy.float32,
        requestedAt: DateTime.now(),
      );

      expect(reqDefault.numericPolicy, NumericExportPolicy.preserveSource);
      expect(reqFloat32.numericPolicy, NumericExportPolicy.float32);
    });

    test('11. Product identity is preserved', () {
      final request = RasterExportRequest(
        product: availableDemProduct,
        requestedAt: DateTime.now(),
      );

      expect(request.productId, 'prod-dem-01');
      expect(request.product.name, 'Digital Elevation Model');
    });

    test('12. Provenance reference is preserved where available', () {
      final request = RasterExportRequest(
        product: availableDemProduct,
        requestedAt: DateTime.now(),
      );

      expect(request.provenanceStepName, 'DEM Acquisition');
    });

    test('13. Result success/failure semantics are deterministic', () {
      final request = RasterExportRequest(
        product: availableDemProduct,
        requestedAt: DateTime.now(),
      );

      final res1 = service.validateRequest(request);
      final res2 = service.validateRequest(request);

      expect(res1.isSuccess, isTrue);
      expect(res2.isSuccess, isTrue);
      expect(res1.request.product.id, res2.request.product.id);
    });

    test('14. Error types distinguish invalid/unavailable/failed states where appropriate', () {
      final reqUnavailable = RasterExportRequest(
        product: unavailableProduct,
        requestedAt: DateTime.now(),
      );
      final reqInvalid = RasterExportRequest(
        product: vectorProduct,
        requestedAt: DateTime.now(),
      );

      final resUnavailable = service.validateRequest(reqUnavailable);
      final resInvalid = service.validateRequest(reqInvalid);

      expect(resUnavailable.error?.type, RasterExportErrorType.productUnavailable);
      expect(resInvalid.error?.type, RasterExportErrorType.invalidRequest);
      expect(resUnavailable.error?.type, isNot(equals(resInvalid.error?.type)));
    });

    test('15. Contract objects are immutable', () {
      final request = RasterExportRequest(
        product: availableDemProduct,
        requestedAt: DateTime.now(),
      );
      final result = service.validateRequest(request);

      expect(request.product, equals(availableDemProduct));
      expect(result.request, equals(request));
    });

    test('16. Creating an export request does not mutate ResearchSession', () {
      final session = ResearchSession(
        id: 's-test',
        title: 'Test Study',
        extent: testExtent,
        createdAt: DateTime.now(),
        layers: [
          GisLayer(
            id: 'l-dem',
            name: 'DEM',
            type: GisLayerType.terrain,
            dataType: SpatialDataType.raster,
            dataSourceType: DataSourceType.cloudProcessing,
            metadata: {'raster_data': testDemRaster},
          ),
        ],
      );

      final registry = ResearchProductRegistryFactory.fromSession(session);
      final demProd = registry.byType(ResearchProductType.dem);
      expect(demProd, isNotNull);

      final initialLayerCount = session.layers.length;
      final request = RasterExportRequest(
        product: demProd!,
        requestedAt: DateTime.now(),
      );
      service.validateRequest(request);

      expect(session.layers.length, initialLayerCount);
    });

    test('17. Creating an export request does not mutate ResearchProductRegistry', () {
      final registry = ResearchProductRegistry(
        sessionId: 's-1',
        sessionTitle: 'Session 1',
        products: [availableDemProduct, unavailableProduct],
        generatedAt: DateTime.now(),
      );

      final initialAvailableCount = registry.availableCount;
      final initialTotalCount = registry.totalCount;

      final request = RasterExportRequest(
        product: availableDemProduct,
        requestedAt: DateTime.now(),
      );
      service.validateRequest(request);

      expect(registry.availableCount, initialAvailableCount);
      expect(registry.totalCount, initialTotalCount);
    });

    test('18. No serialization occurs', () {
      final request = RasterExportRequest(
        product: availableDemProduct,
        requestedAt: DateTime.now(),
      );

      final result = service.validateRequest(request);

      expect(result.bytes, isNull);
    });

    test('19. Repeated creation of the same request is deterministic', () {
      final now = DateTime.now();
      final req1 = RasterExportRequest(product: availableDemProduct, requestedAt: now);
      final req2 = RasterExportRequest(product: availableDemProduct, requestedAt: now);

      expect(req1.productId, req2.productId);
      expect(req1.authoritativeRaster, req2.authoritativeRaster);
      expect(req1.numericPolicy, req2.numericPolicy);
      expect(req1.format, req2.format);
    });
  });
}
