import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/domain/gis/raster_data.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/gis/remote_sensing_band.dart';
import 'package:riskpulse/domain/gis/multispectral_product.dart';
import 'package:riskpulse/domain/gis/temporal_observation.dart';
import 'package:riskpulse/domain/gis/temporal_observation_stack.dart';
import 'package:riskpulse/data/services/spectral_index_engine.dart';
import 'package:riskpulse/data/services/cloud_masking_engine.dart';

void main() {
  group('Spectral Index Engine Stage 1B.9 Scientific Validation Tests', () {
    final engine = SpectralIndexEngine();
    final cloudEngine = CloudMaskingEngine();

    final testExtent = MapExtent(
      southWest: const GeoLocation(latitude: 31.0, longitude: 77.0),
      northEast: const GeoLocation(latitude: 31.05, longitude: 77.05),
    );

    // Band B4 (Red) - 10m res, scale 0.0001
    final redRaster = RasterData(
      width: 2,
      height: 2,
      cellWidth: 0.01,
      cellHeight: 0.01,
      origin: const GeoLocation(latitude: 31.05, longitude: 77.0),
      crs: CoordinateReferenceSystem.wgs84,
      values: const [
        1000.0,
        1000.0,
        500.0,
        -9999.0,
      ], // Dense vegetation, Water, Land, NoData
      noDataValue: -9999.0,
      metadata: const {
        'datasetId': 'COPERNICUS/S2_SR_HARMONIZED',
        'nominalResolutionMeters': 10.0,
      },
    );

    // Band B8 (NIR) - 10m res, scale 0.0001
    final nirRaster = RasterData(
      width: 2,
      height: 2,
      cellWidth: 0.01,
      cellHeight: 0.01,
      origin: const GeoLocation(latitude: 31.05, longitude: 77.0),
      crs: CoordinateReferenceSystem.wgs84,
      values: const [
        4000.0,
        500.0,
        1500.0,
        2000.0,
      ], // Dense vegetation, Water, Land, Valid
      noDataValue: -9999.0,
      metadata: const {
        'datasetId': 'COPERNICUS/S2_SR_HARMONIZED',
        'nominalResolutionMeters': 10.0,
      },
    );

    // Band B3 (Green) - 10m res, scale 0.0001
    final greenRaster = RasterData(
      width: 2,
      height: 2,
      cellWidth: 0.01,
      cellHeight: 0.01,
      origin: const GeoLocation(latitude: 31.05, longitude: 77.0),
      crs: CoordinateReferenceSystem.wgs84,
      values: const [800.0, 3000.0, 1200.0, 1000.0],
      noDataValue: -9999.0,
      metadata: const {
        'datasetId': 'COPERNICUS/S2_SR_HARMONIZED',
        'nominalResolutionMeters': 10.0,
      },
    );

    test(
      '1. NDVI numerical calculation executes correctly: (NIR - RED) / (NIR + RED)',
      () {
        final ndvi = engine.calculateNdvi(nir: nirRaster, red: redRaster);

        expect(ndvi.width, 2);
        expect(ndvi.height, 2);

        // Cell 0 (Dense vegetation): NIR=0.40, RED=0.10 => (0.40-0.10)/(0.40+0.10) = 0.30/0.50 = 0.60
        expect(ndvi.values[0], closeTo(0.60, 1e-4));

        // Cell 1 (Water): NIR=0.05, RED=0.10 => (0.05-0.10)/(0.05+0.10) = -0.05/0.15 = -0.3333
        expect(ndvi.values[1], closeTo(-0.3333, 1e-3));

        // Cell 2 (Land): NIR=0.15, RED=0.05 => (0.15-0.05)/(0.15+0.05) = 0.10/0.20 = 0.50
        expect(ndvi.values[2], closeTo(0.50, 1e-4));

        // Cell 3 (NoData in RED band): NoData propagation
        expect(ndvi.values[3], equals(-9999.0));
        expect(ndvi.isNoData(ndvi.values[3]), isTrue);
      },
    );

    test('2. Case 2: NIR = RED yields exact 0.0 NDVI value', () {
      final equalRaster = RasterData(
        width: 1,
        height: 1,
        cellWidth: 0.01,
        cellHeight: 0.01,
        origin: const GeoLocation(latitude: 0, longitude: 0),
        crs: CoordinateReferenceSystem.wgs84,
        values: const [2000.0], // 0.20 reflectance
      );

      final ndvi = engine.calculateNdvi(nir: equalRaster, red: equalRaster);
      expect(ndvi.values[0], equals(0.0));
    });

    test(
      '3. Reflectance scaling verification: Stored 1000 * 0.0001 scale = 0.10 physical reflectance',
      () {
        const stored = 1000.0;
        const scale = 0.0001;
        expect(stored * scale, closeTo(0.10, 1e-6));
      },
    );

    test('4. NaN and Infinity inputs propagate as NoData without throwing', () {
      final nanRaster = RasterData(
        width: 2,
        height: 2,
        cellWidth: 0.01,
        cellHeight: 0.01,
        origin: const GeoLocation(latitude: 31.05, longitude: 77.0),
        crs: CoordinateReferenceSystem.wgs84,
        values: const [double.nan, 1000.0, 1000.0, 1000.0],
      );

      final infRaster = RasterData(
        width: 2,
        height: 2,
        cellWidth: 0.01,
        cellHeight: 0.01,
        origin: const GeoLocation(latitude: 31.05, longitude: 77.0),
        crs: CoordinateReferenceSystem.wgs84,
        values: const [1000.0, double.infinity, 1000.0, 1000.0],
      );

      final ndvi1 = engine.calculateNdvi(nir: nanRaster, red: redRaster);
      final ndvi2 = engine.calculateNdvi(nir: nirRaster, red: infRaster);

      expect(ndvi1.values[0], equals(-9999.0));
      expect(ndvi2.values[1], equals(-9999.0));
    });

    test(
      '5. Zero denominator (0 + 0) propagation sets NoData cleanly without NaN',
      () {
        final zeroNIR = RasterData(
          width: 1,
          height: 1,
          cellWidth: 0.01,
          cellHeight: 0.01,
          origin: const GeoLocation(latitude: 0, longitude: 0),
          crs: CoordinateReferenceSystem.wgs84,
          values: const [0.0],
        );

        final zeroRED = RasterData(
          width: 1,
          height: 1,
          cellWidth: 0.01,
          cellHeight: 0.01,
          origin: const GeoLocation(latitude: 0, longitude: 0),
          crs: CoordinateReferenceSystem.wgs84,
          values: const [0.0],
        );

        final ndvi = engine.calculateNdvi(nir: zeroNIR, red: zeroRED);

        expect(ndvi.values[0], equals(-9999.0));
        expect(ndvi.values[0].isNaN, isFalse);
      },
    );

    test('6. Dimension mismatch throws ArgumentError', () {
      final mismatchNIR = RasterData(
        width: 3, // 3x2 vs 2x2
        height: 2,
        cellWidth: 0.01,
        cellHeight: 0.01,
        origin: const GeoLocation(latitude: 31.05, longitude: 77.0),
        crs: CoordinateReferenceSystem.wgs84,
        values: const [1, 2, 3, 4, 5, 6],
      );

      expect(
        () => engine.calculateNdvi(nir: mismatchNIR, red: redRaster),
        throwsArgumentError,
      );
    });

    test('7. CRS mismatch throws ArgumentError', () {
      final mismatchCrsNIR = RasterData(
        width: 2,
        height: 2,
        cellWidth: 0.01,
        cellHeight: 0.01,
        origin: const GeoLocation(latitude: 31.05, longitude: 77.0),
        crs: const CoordinateReferenceSystem(
          code: 'EPSG:32644',
          name: 'UTM Zone 44N',
        ),
        values: const [4000, 500, 1500, 2000],
      );

      expect(
        () => engine.calculateNdvi(nir: mismatchCrsNIR, red: redRaster),
        throwsArgumentError,
      );
    });

    test('8. NDVI and NDWI from MultispectralProduct operates cleanly', () {
      final product = MultispectralProduct(
        productId: 's2-test-01',
        providerId: 'gee',
        datasetId: 'COPERNICUS/S2_SR_HARMONIZED',
        acquisitionDate: DateTime.now(),
        crs: CoordinateReferenceSystem.wgs84,
        extent: testExtent,
        bands: const [
          RemoteSensingBand.sentinel2B3,
          RemoteSensingBand.sentinel2B4,
          RemoteSensingBand.sentinel2B8,
        ],
        bandRasters: {'B3': greenRaster, 'B4': redRaster, 'B8': nirRaster},
      );

      final ndvi = engine.calculateNdviFromProduct(product);
      final ndwi = engine.calculateNdwiFromProduct(product);

      expect(ndvi.metadata['analysis_type'], 'NDVI');
      expect(ndvi.metadata['units'], 'index (-1 to +1)');
      expect(ndwi.metadata['analysis_type'], 'NDWI');
      expect(ndwi.metadata['units'], 'index (-1 to +1)');
    });

    test(
      '9. Stage 1B.9: Band association proves NDVI uses B8/B4 and NDWI uses B3/B8 exclusively',
      () {
        final product = MultispectralProduct(
          productId: 's2-band-assoc',
          providerId: 'gee',
          datasetId: 'COPERNICUS/S2_SR_HARMONIZED',
          acquisitionDate: DateTime.now(),
          crs: CoordinateReferenceSystem.wgs84,
          extent: testExtent,
          bands: const [
            RemoteSensingBand.sentinel2B3,
            RemoteSensingBand.sentinel2B4,
            RemoteSensingBand.sentinel2B8,
          ],
          bandRasters: {
            'B3': greenRaster, // cell 0: 800.0 (0.08)
            'B4': redRaster, // cell 0: 1000.0 (0.10)
            'B8': nirRaster, // cell 0: 4000.0 (0.40)
          },
        );

        final ndvi = engine.calculateNdviFromProduct(product);
        final ndwi = engine.calculateNdwiFromProduct(product);

        // NDVI cell 0: (0.40 - 0.10)/(0.40 + 0.10) = 0.60
        expect(ndvi.values[0], closeTo(0.60, 1e-4));

        // NDWI cell 0: (0.08 - 0.40)/(0.08 + 0.40) = -0.32 / 0.48 = -0.6667
        expect(ndwi.values[0], closeTo(-0.6667, 1e-3));
        expect(ndvi.values[0], isNot(equals(ndwi.values[0])));
      },
    );

    test(
      '10. Stage 1B.9: Quality mask integration outputs NoData for cloud cells and valid index for clear cells',
      () {
        final qa60Raster = RasterData(
          width: 2,
          height: 2,
          cellWidth: 0.01,
          cellHeight: 0.01,
          origin: const GeoLocation(latitude: 31.05, longitude: 77.0),
          crs: CoordinateReferenceSystem.wgs84,
          values: const [
            0.0,
            1024.0,
            0.0,
            -9999.0,
          ], // Clear, Opaque Cloud, Clear, NoData
        );

        final mask = cloudEngine.buildMaskFromQA60(qa60Raster);
        final maskedRed = cloudEngine.applyMask(
          sourceRaster: redRaster,
          mask: mask,
        );
        final maskedNir = cloudEngine.applyMask(
          sourceRaster: nirRaster,
          mask: mask,
        );

        final ndvi = engine.calculateNdvi(nir: maskedNir, red: maskedRed);

        expect(ndvi.values[0], closeTo(0.60, 1e-4)); // Clear cell 0: valid NDVI
        expect(ndvi.values[1], equals(-9999.0)); // Cloud cell 1: NoData
        expect(ndvi.values[2], closeTo(0.50, 1e-4)); // Clear cell 2: valid NDVI
        expect(ndvi.values[3], equals(-9999.0)); // Source NoData cell 3: NoData
      },
    );

    test(
      '11. Stage 1B.9: Temporal spectral index sequence proves no cross-date mixing',
      () {
        final janProduct = MultispectralProduct(
          productId: 'jan-p',
          providerId: 'gee',
          datasetId: 'COPERNICUS/S2_SR_HARMONIZED',
          acquisitionDate: DateTime(2026, 1, 15),
          crs: CoordinateReferenceSystem.wgs84,
          extent: testExtent,
          bands: const [
            RemoteSensingBand.sentinel2B4,
            RemoteSensingBand.sentinel2B8,
          ],
          bandRasters: {
            'B4': redRaster,
            'B8': nirRaster,
          }, // NIR=0.40, RED=0.10 => NDVI=0.60
        );

        final febProduct = MultispectralProduct(
          productId: 'feb-p',
          providerId: 'gee',
          datasetId: 'COPERNICUS/S2_SR_HARMONIZED',
          acquisitionDate: DateTime(2026, 2, 15),
          crs: CoordinateReferenceSystem.wgs84,
          extent: testExtent,
          bands: const [
            RemoteSensingBand.sentinel2B4,
            RemoteSensingBand.sentinel2B8,
          ],
          bandRasters: {
            'B4': RasterData(
              width: 2,
              height: 2,
              cellWidth: 0.01,
              cellHeight: 0.01,
              origin: const GeoLocation(latitude: 31.05, longitude: 77.0),
              crs: CoordinateReferenceSystem.wgs84,
              values: const [2000, 2000, 2000, 2000],
            ),
            'B8': RasterData(
              width: 2,
              height: 2,
              cellWidth: 0.01,
              cellHeight: 0.01,
              origin: const GeoLocation(latitude: 31.05, longitude: 77.0),
              crs: CoordinateReferenceSystem.wgs84,
              values: const [3000, 3000, 3000, 3000],
            ),
          }, // NIR=0.30, RED=0.20 => NDVI=(0.30-0.20)/(0.30+0.20) = 0.20
        );

        final marProduct = MultispectralProduct(
          productId: 'mar-p',
          providerId: 'gee',
          datasetId: 'COPERNICUS/S2_SR_HARMONIZED',
          acquisitionDate: DateTime(2026, 3, 15),
          crs: CoordinateReferenceSystem.wgs84,
          extent: testExtent,
          bands: const [
            RemoteSensingBand.sentinel2B4,
            RemoteSensingBand.sentinel2B8,
          ],
          bandRasters: {
            'B4': RasterData(
              width: 2,
              height: 2,
              cellWidth: 0.01,
              cellHeight: 0.01,
              origin: const GeoLocation(latitude: 31.05, longitude: 77.0),
              crs: CoordinateReferenceSystem.wgs84,
              values: const [3000, 3000, 3000, 3000],
            ),
            'B8': RasterData(
              width: 2,
              height: 2,
              cellWidth: 0.01,
              cellHeight: 0.01,
              origin: const GeoLocation(latitude: 31.05, longitude: 77.0),
              crs: CoordinateReferenceSystem.wgs84,
              values: const [1000, 1000, 1000, 1000],
            ),
          }, // NIR=0.10, RED=0.30 => NDVI=(0.10-0.30)/(0.10+0.30) = -0.50
        );

        final janNdvi = engine.calculateNdviFromProduct(janProduct);
        final febNdvi = engine.calculateNdviFromProduct(febProduct);
        final marNdvi = engine.calculateNdviFromProduct(marProduct);

        final janObs = TemporalObservation(
          observationId: 'jan-obs',
          product: janProduct,
        );
        final febObs = TemporalObservation(
          observationId: 'feb-obs',
          product: febProduct,
        );
        final marObs = TemporalObservation(
          observationId: 'mar-obs',
          product: marProduct,
        );

        final stack = TemporalObservationStack()
            .add(janObs)
            .add(febObs)
            .add(marObs);

        expect(janNdvi.values[0], closeTo(0.60, 1e-4));
        expect(febNdvi.values[0], closeTo(0.20, 1e-4));
        expect(marNdvi.values[0], closeTo(-0.50, 1e-4));

        expect(
          stack.byId('jan-obs')!.product.acquisitionDate,
          equals(DateTime(2026, 1, 15)),
        );
        expect(
          stack.byId('feb-obs')!.product.acquisitionDate,
          equals(DateTime(2026, 2, 15)),
        );
        expect(
          stack.byId('mar-obs')!.product.acquisitionDate,
          equals(DateTime(2026, 3, 15)),
        );
      },
    );

    test(
      '12. Stage 1B.9: Source bands and product remain 100% immutable after index calculation',
      () {
        final red0Before = redRaster.values[0];
        final nir0Before = nirRaster.values[0];

        engine.calculateNdvi(nir: nirRaster, red: redRaster);

        expect(redRaster.values[0], equals(red0Before));
        expect(nirRaster.values[0], equals(nir0Before));
      },
    );
  });
}
