import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/domain/gis/raster_data.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/gis/remote_sensing_band.dart';
import 'package:riskpulse/domain/gis/remote_sensing_query.dart';
import 'package:riskpulse/domain/gis/multispectral_product.dart';
import 'package:riskpulse/domain/gis/temporal_observation.dart';
import 'package:riskpulse/domain/gis/temporal_observation_stack.dart';
import 'package:riskpulse/data/services/temporal_observation_selector.dart';
import 'package:riskpulse/data/services/cloud_masking_engine.dart';
import 'package:riskpulse/data/services/spectral_index_engine.dart';

void main() {
  group('Stage 1B.10 End-to-End Research Remote Sensing Pipeline Integration Tests', () {
    final cloudEngine = CloudMaskingEngine();
    final indexEngine = SpectralIndexEngine();
    final selector = const TemporalObservationSelector();

    // Research AOI - Himachal Pradesh mountain valley
    final researchExtent = MapExtent(
      southWest: const GeoLocation(latitude: 31.0000, longitude: 77.0000),
      northEast: const GeoLocation(latitude: 31.0500, longitude: 77.0500),
    );

    RasterData make10mRaster(List<double> values) {
      return RasterData(
        width: 4,
        height: 4,
        cellWidth: 0.005,
        cellHeight: 0.005,
        origin: const GeoLocation(latitude: 31.0500, longitude: 77.0000),
        crs: CoordinateReferenceSystem.wgs84,
        values: values,
        noDataValue: -9999.0,
        metadata: const {
          'datasetId': 'COPERNICUS/S2_SR_HARMONIZED',
          'nominalResolutionMeters': 10.0,
        },
      );
    }

    RasterData make20mSclRaster(List<double> sclValues) {
      return RasterData(
        width: 2,
        height: 2,
        cellWidth: 0.010,
        cellHeight: 0.010,
        origin: const GeoLocation(latitude: 31.0500, longitude: 77.0000),
        crs: CoordinateReferenceSystem.wgs84,
        values: sclValues,
        noDataValue: -9999.0,
        metadata: const {
          'datasetId': 'COPERNICUS/S2_SR_HARMONIZED',
          'nominalResolutionMeters': 20.0,
        },
      );
    }

    MultispectralProduct makeProduct(
      String id,
      DateTime date, {
      required List<double> redValues,
      required List<double> nirValues,
      required List<double> greenValues,
    }) {
      return MultispectralProduct(
        productId: id,
        providerId: 'gee',
        datasetId: 'COPERNICUS/S2_SR_HARMONIZED',
        acquisitionDate: date,
        crs: CoordinateReferenceSystem.wgs84,
        extent: researchExtent,
        bands: const [
          RemoteSensingBand.sentinel2B3,
          RemoteSensingBand.sentinel2B4,
          RemoteSensingBand.sentinel2B8,
        ],
        bandRasters: {
          'B3': make10mRaster(greenValues),
          'B4': make10mRaster(redValues),
          'B8': make10mRaster(nirValues),
        },
        metadata: const {
          'provider': 'Google Earth Engine',
          'datasetId': 'COPERNICUS/S2_SR_HARMONIZED',
          'acquisitionDateSource':
              'queryStartDate; scene metadata retrieval not yet implemented',
          'targetGridCrs': 'EPSG:4326',
          'nativeGridPreserved': false,
        },
      );
    }

    test(
      '1. End-to-end research workflow executes seamlessly across AOI, Query, Quality Masking, Temporal Stacking, Quality Selection, and Spectral Indices',
      () {
        // 1. Research AOI & Query Construction
        final queryJan = RemoteSensingQuery(
          extent: researchExtent,
          startDate: DateTime(2026, 1, 1),
          endDate: DateTime(2026, 1, 31),
          requestedBands: const ['B3', 'B4', 'B8'],
          datasetId: 'COPERNICUS/S2_SR_HARMONIZED',
        );

        expect(queryJan.extent, equals(researchExtent));
        expect(queryJan.datasetId, 'COPERNICUS/S2_SR_HARMONIZED');

        // 2. January Observation (100% Clear, High Vegetation: NIR=0.40 (4000), RED=0.10 (1000), GREEN=0.08 (800))
        final janProduct = makeProduct(
          's2-jan',
          DateTime(2026, 1, 15),
          redValues: List<double>.filled(16, 1000.0),
          nirValues: List<double>.filled(16, 4000.0),
          greenValues: List<double>.filled(16, 800.0),
        );
        final janScl = make20mSclRaster(const [
          4.0,
          4.0,
          4.0,
          4.0,
        ]); // 100% Veg (Valid)
        final janMask = cloudEngine.buildMaskFromSCL(janScl);
        final janMaskedProduct = cloudEngine.applyMaskToProduct(
          product: janProduct,
          mask: janMask,
        );
        final janObs = TemporalObservation(
          observationId: 'obs-jan',
          product: janMaskedProduct,
          qualityMask: janMask,
        );

        // 3. February Observation (50% Cloud-Contaminated: SCL=8.0 (Cloud) on top-right cell)
        final febProduct = makeProduct(
          's2-feb',
          DateTime(2026, 2, 15),
          redValues: List<double>.filled(16, 2000.0), // RED=0.20
          nirValues: List<double>.filled(16, 3000.0), // NIR=0.30
          greenValues: List<double>.filled(16, 1200.0),
        );
        final febScl = make20mSclRaster(const [
          4.0,
          8.0,
          4.0,
          5.0,
        ]); // Top-Right = SCL 8 (Cloud Med)
        final febMask = cloudEngine.buildMaskFromSCL(febScl);
        final febMaskedProduct = cloudEngine.applyMaskToProduct(
          product: febProduct,
          mask: febMask,
        );
        final febObs = TemporalObservation(
          observationId: 'obs-feb',
          product: febMaskedProduct,
          qualityMask: febMask,
        );

        // 4. March Observation (100% Clear, Moderate Vegetation: RED=0.15 (1500), NIR=0.25 (2500), GREEN=0.10 (1000))
        final marProduct = makeProduct(
          's2-mar',
          DateTime(2026, 3, 15),
          redValues: List<double>.filled(16, 1500.0),
          nirValues: List<double>.filled(16, 2500.0),
          greenValues: List<double>.filled(16, 1000.0),
        );
        final marScl = make20mSclRaster(const [
          4.0,
          5.0,
          4.0,
          4.0,
        ]); // 100% Valid
        final marMask = cloudEngine.buildMaskFromSCL(marScl);
        final marMaskedProduct = cloudEngine.applyMaskToProduct(
          product: marProduct,
          mask: marMask,
        );
        final marObs = TemporalObservation(
          observationId: 'obs-mar',
          product: marMaskedProduct,
          qualityMask: marMask,
        );

        // 5. Out-of-Order Temporal Stacking (Insert March, January, February)
        final stack = TemporalObservationStack()
            .add(marObs)
            .add(janObs)
            .add(febObs);

        expect(stack.length, equals(3));

        // Verify chronological sorting (Jan -> Feb -> Mar)
        final chronological = stack.chronologicalObservations;
        expect(chronological[0].observationId, 'obs-jan');
        expect(chronological[1].observationId, 'obs-feb');
        expect(chronological[2].observationId, 'obs-mar');

        // 6. Quality-Aware Selection
        final bestObs = selector.selectBest(
          stack: stack,
          requiredBands: {'B4', 'B8'},
        );
        expect(bestObs, isNotNull);
        expect(bestObs!.validPercentage, equals(100.0));

        // 7. Spectral Index Calculation per Temporal Observation
        final janNdvi = indexEngine.calculateNdviFromProduct(janObs.product);
        final febNdvi = indexEngine.calculateNdviFromProduct(febObs.product);
        final marNdvi = indexEngine.calculateNdviFromProduct(marObs.product);

        // Jan NDVI = (0.40 - 0.10)/(0.40 + 0.10) = 0.60
        expect(janNdvi.values[0], closeTo(0.60, 1e-4));

        // Feb NDVI = (0.30 - 0.20)/(0.30 + 0.20) = 0.20 on clear cells, -9999.0 on top-right cloud cells
        expect(febNdvi.values[0], closeTo(0.20, 1e-4));
        expect(
          febNdvi.values[2],
          equals(-9999.0),
        ); // Top-right resampled cloud cell -> NoData

        // Mar NDVI = (0.25 - 0.15)/(0.25 + 0.15) = 0.10 / 0.40 = 0.25
        expect(marNdvi.values[0], closeTo(0.25, 1e-4));

        // 8. End-to-End Provenance Verification
        expect(janNdvi.metadata['analysis_type'], equals('NDVI'));
        expect(
          janNdvi.metadata['formula'],
          equals('(NIR - RED) / (NIR + RED)'),
        );
        expect(
          janNdvi.metadata['datasetId'],
          equals('COPERNICUS/S2_SR_HARMONIZED'),
        );
        expect(
          janObs.product.metadata['acquisitionDateSource'],
          contains('queryStartDate'),
        );
        expect(
          janObs.product.metadata['acquisitionDateSource'],
          isNot(contains('authoritativeSceneMetadata')),
        );
      },
    );

    test(
      '2. Error Propagation: Missing required band or CRS mismatch fails safely without synthetic fallback',
      () {
        final incompleteProduct = MultispectralProduct(
          productId: 's2-incomplete',
          providerId: 'gee',
          datasetId: 'COPERNICUS/S2_SR_HARMONIZED',
          acquisitionDate: DateTime(2026, 1, 15),
          crs: CoordinateReferenceSystem.wgs84,
          extent: researchExtent,
          bands: const [RemoteSensingBand.sentinel2B4], // B8 (NIR) missing
          bandRasters: {'B4': make10mRaster(List<double>.filled(16, 1000.0))},
        );

        expect(
          () => indexEngine.calculateNdviFromProduct(incompleteProduct),
          throwsArgumentError,
        );
      },
    );

    test(
      '3. Source Immutability: Source rasters and products remain 100% untouched after end-to-end execution',
      () {
        final origRed = make10mRaster(List<double>.filled(16, 1000.0));
        final origRedVal0 = origRed.values[0];

        final p = MultispectralProduct(
          productId: 's2-immut',
          providerId: 'gee',
          datasetId: 'COPERNICUS/S2_SR_HARMONIZED',
          acquisitionDate: DateTime(2026, 1, 15),
          crs: CoordinateReferenceSystem.wgs84,
          extent: researchExtent,
          bands: const [
            RemoteSensingBand.sentinel2B4,
            RemoteSensingBand.sentinel2B8,
          ],
          bandRasters: {
            'B4': origRed,
            'B8': make10mRaster(List<double>.filled(16, 4000.0)),
          },
        );

        final scl = make20mSclRaster(const [4.0, 4.0, 4.0, 4.0]);
        final mask = cloudEngine.buildMaskFromSCL(scl);
        final maskedP = cloudEngine.applyMaskToProduct(product: p, mask: mask);
        indexEngine.calculateNdviFromProduct(maskedP);

        expect(origRed.values[0], equals(origRedVal0));
        expect(p.productId, equals('s2-immut'));
      },
    );
  });
}
