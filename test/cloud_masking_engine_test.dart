import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/domain/gis/raster_data.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/gis/quality_mask.dart';
import 'package:riskpulse/domain/gis/remote_sensing_band.dart';
import 'package:riskpulse/domain/gis/multispectral_product.dart';
import 'package:riskpulse/domain/gis/temporal_observation.dart';
import 'package:riskpulse/domain/gis/temporal_observation_stack.dart';
import 'package:riskpulse/data/services/cloud_masking_engine.dart';
import 'package:riskpulse/data/services/spectral_index_engine.dart';

void main() {
  group('Sentinel-2 Cloud & Quality Masking Stage 1B.8 Scientific Integration Tests', () {
    final maskEngine = CloudMaskingEngine();
    final indexEngine = SpectralIndexEngine();

    final testExtent = MapExtent(
      southWest: const GeoLocation(latitude: 31.0, longitude: 77.0),
      northEast: const GeoLocation(latitude: 31.05, longitude: 77.05),
    );

    // 10m Target Band (Red B4) - 4x4 cells
    final red10mRaster = RasterData(
      width: 4,
      height: 4,
      cellWidth: 0.005,
      cellHeight: 0.005,
      origin: const GeoLocation(latitude: 31.05, longitude: 77.0),
      crs: CoordinateReferenceSystem.wgs84,
      values: List<double>.filled(16, 1000.0), // 0.10 reflectance everywhere
      noDataValue: -9999.0,
    );

    // 10m Target Band (NIR B8) - 4x4 cells
    final nir10mRaster = RasterData(
      width: 4,
      height: 4,
      cellWidth: 0.005,
      cellHeight: 0.005,
      origin: const GeoLocation(latitude: 31.05, longitude: 77.0),
      crs: CoordinateReferenceSystem.wgs84,
      values: List<double>.filled(16, 4000.0), // 0.40 reflectance everywhere
      noDataValue: -9999.0,
    );

    // 20m SCL Band - 2x2 cells (Class 4=Veg (Valid), 8=Cloud Med (Invalid), 3=Shadow (Invalid), 5=Bare Soil (Valid))
    final scl20mRaster = RasterData(
      width: 2,
      height: 2,
      cellWidth: 0.01,
      cellHeight: 0.01,
      origin: const GeoLocation(latitude: 31.05, longitude: 77.0),
      crs: CoordinateReferenceSystem.wgs84,
      values: const [4.0, 8.0, 3.0, 5.0],
      noDataValue: -9999.0,
    );

    // QA60 Band - 2x2 cells (Unrelated bits set: 0x0001 bit 0 should remain VALID; bit 10 1024=Opaque Cloud; bit 11 2048=Cirrus)
    final qa60Raster = RasterData(
      width: 2,
      height: 2,
      cellWidth: 0.01,
      cellHeight: 0.01,
      origin: const GeoLocation(latitude: 31.05, longitude: 77.0),
      crs: CoordinateReferenceSystem.wgs84,
      values: const [1.0, 1024.0, 2048.0, -9999.0],
      noDataValue: -9999.0,
    );

    test('1. QA60 bit decoding explicitly checks bits 10/11 and ignores unrelated bits (bit 0)', () {
      final mask = maskEngine.buildMaskFromQA60(qa60Raster);

      expect(mask.isValid(0), isTrue); // Value 1.0 (bit 0) is VALID
      expect(mask.maskStates[1], QualityPixelState.cloud); // Value 1024 (bit 10) is CLOUD
      expect(mask.maskStates[2], QualityPixelState.cirrus); // Value 2048 (bit 11) is CIRRUS
      expect(mask.maskStates[3], QualityPixelState.noData); // NoData cell
    });

    test('2. SCL classification correctly categorizes valid (4,5) vs invalid (8,3) classes', () {
      final mask = maskEngine.buildMaskFromSCL(scl20mRaster);

      expect(mask.isValid(0), isTrue); // SCL 4 = Veg (Valid)
      expect(mask.maskStates[1], QualityPixelState.cloud); // SCL 8 = Cloud
      expect(mask.maskStates[2], QualityPixelState.cloudShadow); // SCL 3 = Shadow
      expect(mask.isValid(3), isTrue); // SCL 5 = Bare soil (Valid)
    });

    test('3. Primary Gate Validation: Nearest-neighbour categorical resampling resamples 20m SCL mask to 10m target grid safely', () {
      final scl20mMask = maskEngine.buildMaskFromSCL(scl20mRaster);
      expect(scl20mMask.width, 2);

      // Apply 20m mask to 10m target band (4x4 cells)
      final maskedRed = maskEngine.applyMask(sourceRaster: red10mRaster, mask: scl20mMask);

      expect(maskedRed.width, 4);
      expect(maskedRed.height, 4);
      expect(maskedRed.metadata['resampling_policy'], contains('Nearest-Neighbour Categorical Resampling'));

      // Top-Left quadrant (4x4 sub-grid x=0..1, y=0..1) maps to 20m SCL cell (0,0) [Valid]
      expect(maskedRed.values[0], equals(1000.0));
      expect(maskedRed.values[1], equals(1000.0));
      expect(maskedRed.values[4], equals(1000.0));
      expect(maskedRed.values[5], equals(1000.0));

      // Top-Right quadrant (x=2..3, y=0..1) maps to 20m SCL cell (1,0) [Cloud] -> Masked
      expect(maskedRed.values[2], equals(-9999.0));
      expect(maskedRed.values[3], equals(-9999.0));
      expect(maskedRed.values[6], equals(-9999.0));
      expect(maskedRed.values[7], equals(-9999.0));
    });

    test('4. CRS mismatch between source raster and quality mask throws ArgumentError', () {
      final mismatchCrsRaster = RasterData(
        width: 2,
        height: 2,
        cellWidth: 0.01,
        cellHeight: 0.01,
        origin: const GeoLocation(latitude: 31.05, longitude: 77.0),
        crs: const CoordinateReferenceSystem(code: 'EPSG:32644', name: 'UTM Zone 44N'),
        values: const [1000, 1000, 500, -9999],
      );

      final mask = maskEngine.buildMaskFromSCL(scl20mRaster);

      expect(() => maskEngine.applyMask(sourceRaster: mismatchCrsRaster, mask: mask), throwsArgumentError);
    });

    test('5. Source RasterData values array remains 100% immutable after masking and resampling', () {
      final red0Before = red10mRaster.values[0];
      final red2Before = red10mRaster.values[2];

      final mask = maskEngine.buildMaskFromSCL(scl20mRaster);
      maskEngine.applyMask(sourceRaster: red10mRaster, mask: mask);

      expect(red10mRaster.values[0], equals(red0Before));
      expect(red10mRaster.values[2], equals(red2Before));
    });

    test('6. Quality-masked 10m rasters calculate valid NDVI on clear cells and NoData on cloudy cells', () {
      final sclMask = maskEngine.buildMaskFromSCL(scl20mRaster);

      final maskedRed = maskEngine.applyMask(sourceRaster: red10mRaster, mask: sclMask);
      final maskedNir = maskEngine.applyMask(sourceRaster: nir10mRaster, mask: sclMask);

      final ndvi = indexEngine.calculateNdvi(nir: maskedNir, red: maskedRed);

      // Top-Left clear quadrant: NIR=0.40, RED=0.10 => (0.40-0.10)/(0.40+0.10) = 0.60
      expect(ndvi.values[0], closeTo(0.60, 1e-4));
      expect(ndvi.values[1], closeTo(0.60, 1e-4));

      // Top-Right cloudy quadrant: Masked out -> NoData
      expect(ndvi.values[2], equals(-9999.0));
      expect(ndvi.values[3], equals(-9999.0));
    });

    test('7. Temporal quality isolation: January mask and February mask remain date-specific without cross-leak', () {
      final janProduct = MultispectralProduct(
        productId: 's2-jan',
        providerId: 'gee',
        datasetId: 'COPERNICUS/S2_SR_HARMONIZED',
        acquisitionDate: DateTime(2026, 1, 15),
        crs: CoordinateReferenceSystem.wgs84,
        extent: testExtent,
        bands: const [RemoteSensingBand.sentinel2B4, RemoteSensingBand.sentinel2B8],
        bandRasters: {'B4': red10mRaster, 'B8': nir10mRaster},
      );

      final febProduct = MultispectralProduct(
        productId: 's2-feb',
        providerId: 'gee',
        datasetId: 'COPERNICUS/S2_SR_HARMONIZED',
        acquisitionDate: DateTime(2026, 2, 15),
        crs: CoordinateReferenceSystem.wgs84,
        extent: testExtent,
        bands: const [RemoteSensingBand.sentinel2B4, RemoteSensingBand.sentinel2B8],
        bandRasters: {'B4': red10mRaster, 'B8': nir10mRaster},
      );

      final janMask = maskEngine.buildMaskFromQA60(RasterData(
        width: 4, height: 4, cellWidth: 0.005, cellHeight: 0.005,
        origin: const GeoLocation(latitude: 31.05, longitude: 77.0),
        crs: CoordinateReferenceSystem.wgs84,
        values: List<double>.filled(16, 0.0), // January 100% Clear
      ));

      final febMask = maskEngine.buildMaskFromQA60(RasterData(
        width: 4, height: 4, cellWidth: 0.005, cellHeight: 0.005,
        origin: const GeoLocation(latitude: 31.05, longitude: 77.0),
        crs: CoordinateReferenceSystem.wgs84,
        values: List<double>.filled(16, 1024.0), // February 100% Opaque Cloud
      ));

      final janObs = TemporalObservation(
        observationId: 'obs-jan',
        product: maskEngine.applyMaskToProduct(product: janProduct, mask: janMask),
        qualityMask: janMask,
      );

      final febObs = TemporalObservation(
        observationId: 'obs-feb',
        product: maskEngine.applyMaskToProduct(product: febProduct, mask: febMask),
        qualityMask: febMask,
      );

      final stack = TemporalObservationStack().add(janObs).add(febObs);

      expect(stack.byId('obs-jan')!.validPercentage, equals(100.0));
      expect(stack.byId('obs-feb')!.validPercentage, equals(0.0));
      expect(stack.byId('obs-jan')!.product.getBandRaster('B4')!.values[0], equals(1000.0));
      expect(stack.byId('obs-feb')!.product.getBandRaster('B4')!.values[0], equals(-9999.0));
    });
  });
}
