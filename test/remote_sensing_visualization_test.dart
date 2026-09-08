import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/domain/gis/raster_data.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/gis/remote_sensing_band.dart';
import 'package:riskpulse/domain/gis/multispectral_product.dart';
import 'package:riskpulse/data/services/raster_visualization_service.dart';
import 'package:riskpulse/data/services/cartographic_service.dart';

void main() {
  group('Remote Sensing Visualization Foundation 4K.8.5 Tests', () {
    final visService = RasterVisualizationService();
    final cartoService = CartographicService();

    final testExtent = MapExtent(
      southWest: const GeoLocation(latitude: 31.0, longitude: 77.0),
      northEast: const GeoLocation(latitude: 31.05, longitude: 77.05),
    );

    // Band B2 (Blue)
    final blueRaster = RasterData(
      width: 2,
      height: 2,
      cellWidth: 0.01,
      cellHeight: 0.01,
      origin: const GeoLocation(latitude: 31.05, longitude: 77.0),
      crs: CoordinateReferenceSystem.wgs84,
      values: const [500.0, 500.0, 500.0, -9999.0],
      noDataValue: -9999.0,
    );

    // Band B3 (Green)
    final greenRaster = RasterData(
      width: 2,
      height: 2,
      cellWidth: 0.01,
      cellHeight: 0.01,
      origin: const GeoLocation(latitude: 31.05, longitude: 77.0),
      crs: CoordinateReferenceSystem.wgs84,
      values: const [800.0, 3000.0, 1000.0, 1000.0],
      noDataValue: -9999.0,
    );

    // Band B4 (Red)
    final redRaster = RasterData(
      width: 2,
      height: 2,
      cellWidth: 0.01,
      cellHeight: 0.01,
      origin: const GeoLocation(latitude: 31.05, longitude: 77.0),
      crs: CoordinateReferenceSystem.wgs84,
      values: const [1000.0, 1000.0, 500.0, 1000.0],
      noDataValue: -9999.0,
    );

    // Band B8 (NIR)
    final nirRaster = RasterData(
      width: 2,
      height: 2,
      cellWidth: 0.01,
      cellHeight: 0.01,
      origin: const GeoLocation(latitude: 31.05, longitude: 77.0),
      crs: CoordinateReferenceSystem.wgs84,
      values: const [4000.0, 500.0, 1500.0, 2000.0],
      noDataValue: -9999.0,
    );

    final sampleProduct = MultispectralProduct(
      productId: 's2-vis-01',
      providerId: 'gee',
      datasetId: 'COPERNICUS/S2_SR_HARMONIZED',
      acquisitionDate: DateTime(2026, 8, 20),
      crs: CoordinateReferenceSystem.wgs84,
      extent: testExtent,
      bands: const [
        RemoteSensingBand.sentinel2B2,
        RemoteSensingBand.sentinel2B3,
        RemoteSensingBand.sentinel2B4,
        RemoteSensingBand.sentinel2B8,
      ],
      bandRasters: {
        'B2': blueRaster,
        'B3': greenRaster,
        'B4': redRaster,
        'B8': nirRaster,
      },
    );

    test('1. True-Color RGB composite assignment (B4, B3, B2) produces valid normalized pixel matrix', () {
      final composite = visService.composeRgbComposite(
        product: sampleProduct,
        redBandId: 'B4',
        greenBandId: 'B3',
        blueBandId: 'B2',
      );

      expect(composite['width'], 2);
      expect(composite['height'], 2);
      expect(composite['compositeType'], 'B4/B3/B2');

      final hexList = composite['hexPixels'] as List<String>;
      expect(hexList.length, 4);
      expect(hexList[0], startsWith('#')); // Valid Hex color
      expect(hexList[3], equals('transparent')); // NoData cell in B2 is transparent
    });

    test('2. False-Color composite assignment (B8, B4, B3) produces valid NIR vegetation composite', () {
      final composite = visService.composeRgbComposite(
        product: sampleProduct,
        redBandId: 'B8',
        greenBandId: 'B4',
        blueBandId: 'B3',
      );

      expect(composite['compositeType'], 'B8/B4/B3');
      final hexList = composite['hexPixels'] as List<String>;
      expect(hexList[0], startsWith('#'));
    });

    test('3. Dimension mismatch across RGB bands throws ArgumentError', () {
      final mismatchRaster = RasterData(
        width: 3, // 3x2 vs 2x2
        height: 2,
        cellWidth: 0.01,
        cellHeight: 0.01,
        origin: const GeoLocation(latitude: 31.05, longitude: 77.0),
        crs: CoordinateReferenceSystem.wgs84,
        values: const [1, 2, 3, 4, 5, 6],
      );

      final badProduct = MultispectralProduct(
        productId: 'bad-01',
        providerId: 'gee',
        datasetId: 'COPERNICUS/S2_SR_HARMONIZED',
        acquisitionDate: DateTime.now(),
        crs: CoordinateReferenceSystem.wgs84,
        extent: testExtent,
        bands: const [RemoteSensingBand.sentinel2B2, RemoteSensingBand.sentinel2B3, RemoteSensingBand.sentinel2B4],
        bandRasters: {'B2': mismatchRaster, 'B3': greenRaster, 'B4': redRaster},
      );

      expect(
        () => visService.composeRgbComposite(product: badProduct, redBandId: 'B4', greenBandId: 'B3', blueBandId: 'B2'),
        throwsArgumentError,
      );
    });

    test('4. NDVI value mapping uses continuous vegetation ramp and keeps NoData transparent', () {
      expect(visService.mapNdviValueToColor(0.8, false), equals('#006400')); // Dense Canopy
      expect(visService.mapNdviValueToColor(0.5, false), equals('#32CD32')); // Healthy Greenery
      expect(visService.mapNdviValueToColor(0.1, false), equals('#F4A460')); // Sparse Veg
      expect(visService.mapNdviValueToColor(-0.2, false), equals('#8B4513')); // Water / Bare soil
      expect(visService.mapNdviValueToColor(0.5, true), equals('transparent')); // NoData
    });

    test('5. NDWI value mapping uses continuous water index ramp and keeps NoData transparent', () {
      expect(visService.mapNdwiValueToColor(0.6, false), equals('#00008B')); // Deep Water
      expect(visService.mapNdwiValueToColor(0.3, false), equals('#4169E1')); // Water Body
      expect(visService.mapNdwiValueToColor(-0.2, false), equals('#D3D3D3')); // Dry Land
      expect(visService.mapNdwiValueToColor(0.4, true), equals('transparent')); // NoData
    });

    test('6. Authoritative RasterData values remain 100% immutable during visualization composition', () {
      final val0Before = blueRaster.values[0];

      visService.composeRgbComposite(
        product: sampleProduct,
        redBandId: 'B4',
        greenBandId: 'B3',
        blueBandId: 'B2',
      );

      expect(blueRaster.values[0], equals(val0Before));
    });

    test('7. GisLayer creation attaches remote sensing metadata and stable identity', () {
      final layer = visService.createRemoteSensingLayer(
        id: 'layer-s2-truecolor',
        name: 'Sentinel-2 True Color',
        compositeType: 'B4/B3/B2',
        metadata: {'datasetId': 'COPERNICUS/S2_SR_HARMONIZED'},
      );

      expect(layer.id, 'layer-s2-truecolor');
      expect(layer.name, 'Sentinel-2 True Color');
      expect(layer.isRaster, isTrue);
      expect(layer.metadata['compositeType'], 'B4/B3/B2');
    });

    test('8. CartographicService generates band combination legend for True-Color and False-Color layers', () {
      final trueColorLayer = visService.createRemoteSensingLayer(
        id: 'tc-1',
        name: 'Sentinel-2 True Color',
        compositeType: 'B4/B3/B2',
        metadata: {},
      );

      final legend = cartoService.generateLegend(trueColorLayer);

      expect(legend.title, 'Sentinel-2 True Color');
      expect(legend.entries.length, 3); // 3 bands
      expect(legend.entries[0].label, contains('Red Band: B4'));
      expect(legend.entries[1].label, contains('Green Band: B3'));
      expect(legend.entries[2].label, contains('Blue Band: B2'));
    });
  });
}
