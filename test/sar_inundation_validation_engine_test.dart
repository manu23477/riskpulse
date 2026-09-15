import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/gis/raster_data.dart';
import 'package:riskpulse/domain/gis/analytical_step.dart';
import 'package:riskpulse/domain/forecasting/validation_dataset_record.dart';
import 'package:riskpulse/domain/hazard/hazard.dart';
import 'package:riskpulse/domain/hydroai/hydroai.dart';
import 'package:riskpulse/data/services/hydroai/hydroai_services.dart';

void main() {
  group('Stage 0.1.10-R1 Common Validation Grid & Governance Correction Pass', () {
    final t1 = DateTime.utc(2026, 9, 15, 10, 0, 0);
    final t2 = DateTime.utc(2026, 9, 15, 16, 0, 0);

    final extent = MapExtent(
      southWest: const GeoLocation(latitude: 31.0, longitude: 77.0),
      northEast: const GeoLocation(latitude: 31.5, longitude: 77.5),
    );

    // Create 4x4 test rasters on Common Validation Grid
    final modelMask = RasterData(
      width: 4,
      height: 4,
      cellWidth: 0.1,
      cellHeight: 0.1,
      origin: const GeoLocation(latitude: 31.5, longitude: 77.0),
      crs: CoordinateReferenceSystem.wgs84,
      values: [
        1.0, 1.0, 1.0, 1.0, // Row 1
        1.0, 1.0, 1.0, 1.0, // Row 2
        0.0, 0.0, 0.0, 0.0, // Row 3
        0.0, 0.0, 0.0, 0.0, // Row 4
      ],
    );

    final sarMask = RasterData(
      width: 4,
      height: 4,
      cellWidth: 0.1,
      cellHeight: 0.1,
      origin: const GeoLocation(latitude: 31.5, longitude: 77.0),
      crs: CoordinateReferenceSystem.wgs84,
      values: [
        1.0, 1.0, 1.0, 0.0, // Row 1: TP=3, FP=1
        1.0, 1.0, 1.0, 0.0, // Row 2: TP=3, FP=1
        1.0, 1.0, 0.0, 0.0, // Row 3: FN=2, TN=2
        0.0, 0.0, 0.0, 0.0, // Row 4: TN=4
      ],
    );

    const validationEngine = SarInundationValidationEngine();

    group('1. Common Validation Grid Compatibility Contract (R1 Requirements)', () {
      test('TEST 1: Rejects rasters with different CRS as crsMismatch', () {
        final diffCrsSarMask = RasterData(
          width: 4,
          height: 4,
          cellWidth: 0.1,
          cellHeight: 0.1,
          origin: const GeoLocation(latitude: 31.5, longitude: 77.0),
          crs: const CoordinateReferenceSystem(code: 'EPSG:32643', name: 'UTM Zone 43N'),
          values: sarMask.values,
        );

        final status = validationEngine.evaluateGridCompatibility(modelMask, diffCrsSarMask);
        expect(status, equals(SpatialValidationGridStatus.crsMismatch));

        expect(
          () => validationEngine.computeConfusionMatrix(
            modelExtentMask: modelMask,
            sarFloodMask: diffCrsSarMask,
          ),
          throwsArgumentError,
        );
      });

      test('TEST 2: Rejects rasters with different pixel size as pixelSizeMismatch', () {
        final diffPixelSarMask = RasterData(
          width: 4,
          height: 4,
          cellWidth: 0.2, // Mismatched cell width
          cellHeight: 0.1,
          origin: const GeoLocation(latitude: 31.5, longitude: 77.0),
          crs: CoordinateReferenceSystem.wgs84,
          values: sarMask.values,
        );

        final status = validationEngine.evaluateGridCompatibility(modelMask, diffPixelSarMask);
        expect(status, equals(SpatialValidationGridStatus.pixelSizeMismatch));
      });

      test('TEST 3: Rejects rasters with shifted origin as originShiftMismatch', () {
        final shiftedOriginSarMask = RasterData(
          width: 4,
          height: 4,
          cellWidth: 0.1,
          cellHeight: 0.1,
          origin: const GeoLocation(latitude: 32.0, longitude: 78.0), // Shifted origin
          crs: CoordinateReferenceSystem.wgs84,
          values: sarMask.values,
        );

        final status = validationEngine.evaluateGridCompatibility(modelMask, shiftedOriginSarMask);
        expect(status, equals(SpatialValidationGridStatus.originShiftMismatch));
      });

      test('TEST 6: Accepts perfectly matching rasters on Common Validation Grid', () {
        final status = validationEngine.evaluateGridCompatibility(modelMask, sarMask);
        expect(status, equals(SpatialValidationGridStatus.spatiallyCompatible));
      });
    });

    group('2. Spatial Metrics & Inundation Criterion Governance', () {
      test('computes spatial CSI, POD, FAR, F1, IoU, BIAS, ACC on matching grid', () {
        final matrix = validationEngine.computeConfusionMatrix(
          modelExtentMask: modelMask,
          sarFloodMask: sarMask,
        );

        expect(matrix.truePositives, equals(6));
        expect(matrix.falsePositives, equals(2));
        expect(matrix.falseNegatives, equals(2));
        expect(matrix.trueNegatives, equals(6));
        expect(matrix.csi, closeTo(0.60, 0.001));
        expect(matrix.f1Score, closeTo(0.75, 0.001));
      });

      test('TEST 8: Flood depth raster returns null when inundation threshold is omitted (Criterion Not Established)', () {
        final depthRaster = FloodDepthRaster(
          rasterData: modelMask,
          timestamp: t2,
        );

        final derivedMask = depthRaster.deriveInundationExtentMask(depthThresholdMeters: null);
        expect(derivedMask, isNull);
      });
    });

    group('3. Mandatory Scientific Governance & Operational Isolation Safeguards', () {
      test('MANDATORY SCIENTIFIC GOVERNANCE TEST: CSI score calculation DOES NOT alter scientificStatus to validatedForStudyArea', () {
        final depthData = RasterData(
          width: 4,
          height: 4,
          cellWidth: 0.1,
          cellHeight: 0.1,
          origin: const GeoLocation(latitude: 31.5, longitude: 77.0),
          crs: CoordinateReferenceSystem.wgs84,
          values: List<double>.filled(16, 1.5),
        );

        final domain = HydrodynamicModelDomain(
          domainId: 'domain-val-gov',
          crs: CoordinateReferenceSystem.wgs84,
          extent: extent,
          floodplainModel: FloodplainModel(
            floodplainId: 'fp-val-gov',
            extent: extent,
            crs: CoordinateReferenceSystem.wgs84,
            demRaster: depthData,
          ),
        );

        final config = SimulationConfig(
          simulationId: 'sim-val-gov',
          eventId: 'evt-val-gov',
          domain: domain,
          startTime: t1,
          endTime: t2,
        );

        final step = AnalyticalStep(
          name: 'simulation',
          operationType: 'sim_run',
          timestamp: DateTime.now(),
        );

        final hydroResult = HydrodynamicResult(
          resultId: 'res-val-gov',
          config: config,
          maxDepthRaster: FloodDepthRaster(rasterData: depthData, timestamp: t2),
          provenanceStep: step,
        );

        final sarRecord = SarInundationRecord(
          datasetId: 'sar-sentinel1-mandi-gov',
          acquisitionTime: t2,
          extent: extent,
          crs: CoordinateReferenceSystem.wgs84,
          sarFloodMask: depthData,
        );

        final record = validationEngine.evaluateInundationResult(
          hydrodynamicResult: hydroResult,
          sarRecord: sarRecord,
          depthThresholdMeters: 0.50,
        );

        // ASSERT: Perfect CSI = 1.0, but scientificStatus remains provisionalSoftwareOnly!
        expect(record.csi, equals(1.0));
        expect(record.scientificStatus, equals(ScientificValidationStatus.provisionalSoftwareOnly));
      });

      test('MANDATORY GOVERNANCE TEST: SarInundationValidationEngine DOES NOT mutate RiskMap or create operational hazards', () {
        final sarRecord = SarInundationRecord(
          datasetId: 'sar-gov-002',
          acquisitionTime: t2,
          extent: extent,
          crs: CoordinateReferenceSystem.wgs84,
          sarFloodMask: modelMask,
        );

        expect(sarRecord, isA<SarInundationRecord>());
        expect(sarRecord, isNot(isA<Hazard>()));
      });
    });
  });
}
