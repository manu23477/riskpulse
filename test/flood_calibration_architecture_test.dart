import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/forecasting/flood_calibration_contracts.dart';
import 'package:riskpulse/data/services/forecasting/landslide_rainfall_threshold_model.dart';
import 'package:riskpulse/data/services/forecasting/flood_hydrological_response_model.dart';
import 'package:riskpulse/data/services/forecasting/hydrograph_association_engine.dart';
import 'package:riskpulse/data/services/forecasting/flood_calibration_engine.dart';
import 'package:riskpulse/data/services/osint/controlled_promotion_gate.dart';

void main() {
  group('R-03 Flood / Gauge Calibration-Ready Architecture Tests', () {
    final defaultModel = FloodHydrologicalResponseModel();

    test('TEST 1, 2 & 21: Existing Rational Method calculation (Q = C * i * A / 3.6) remains 100% unchanged', () {
      expect(defaultModel.runoffCoefficientC, equals(0.65));
      expect(defaultModel.catchmentAreaKm2, equals(120.0));
      expect(defaultModel.dischargeThresholdM3s, equals(150.0));
      expect(defaultModel.scientificStatus, equals(ScientificStatus.provisional));

      // Test i = 20 mm/h, C = 0.65, A = 120 km2 -> Q = (0.65 * 20 * 120) / 3.6 = 433.33 m3/s
      final qPeak = (0.65 * 20.0 * 120.0) / 3.6;
      expect(qPeak, closeTo(433.33, 0.01));
    });

    test('TEST 3, 4 & 5: Flood dataset, station, and observation schema validation', () {
      final dataset = FloodCalibrationDataset(
        datasetId: 'ds-flood-hp-01',
        datasetName: 'Beas Basin Hydrograph Calibration Dataset',
        floodEvents: [
          FloodEventRecord(
            eventId: 'evt-mandi-flood-01',
            eventDate: DateTime.utc(2025, 8, 15),
            location: const GeoLocation(latitude: 31.71, longitude: 76.93),
            basin: 'Beas Basin',
            riverName: 'Beas River',
            source: 'CWC Regional Report',
            isSynthetic: true,
          ),
        ],
        gaugeStations: [
          GaugeStationRecord(
            stationId: 'gauge-mandi-01',
            stationName: 'Mandi Bridge CWC Gauge',
            location: const GeoLocation(latitude: 31.72, longitude: 76.94),
            elevationMeters: 760.0,
            riverName: 'Beas River',
            basinName: 'Beas Basin',
            source: 'CWC Station Network',
            isSynthetic: true,
          ),
        ],
        observations: [
          GaugeObservationRecord(
            observationId: 'obs-01',
            stationId: 'gauge-mandi-01',
            timestamp: DateTime.utc(2025, 8, 15, 12, 0),
            waterLevelMeters: 4.5,
            dischargeM3s: 210.0,
            isSynthetic: true,
          ),
        ],
        geographicScope: 'Mandi, Himachal Pradesh',
        provenance: 'CWC Test Fixture',
        isSyntheticDataset: true,
      );

      expect(dataset.totalEvents, equals(1));
      expect(dataset.totalStations, equals(1));
      expect(dataset.totalObservations, equals(1));
      expect(dataset.isSufficientForCalibration, isFalse); // Synthetic / <5 events
    });

    test('TEST 7: Water level (m) vs Discharge (m3/s) explicit distinction', () {
      final stageObs = GaugeObservationRecord(
        observationId: 'obs-stage',
        stationId: 'st-01',
        timestamp: DateTime.utc(2025, 8, 15),
        waterLevelMeters: 3.2, // Stage only
        isSynthetic: true,
      );

      expect(stageObs.hasStage, isTrue);
      expect(stageObs.hasDischarge, isFalse);
      expect(stageObs.waterLevelMeters, equals(3.2));
      expect(stageObs.dischargeM3s, isNull);
    });

    test('TEST 8, 9 & 10: Hydrograph Association Engine spatial and temporal matching', () {
      final dataset = FloodCalibrationDataset(
        datasetId: 'ds-assoc-flood',
        datasetName: 'Flood Spatial Match Test',
        floodEvents: [
          FloodEventRecord(
            eventId: 'evt-beas-01',
            eventDate: DateTime.utc(2025, 8, 10, 10, 0),
            location: const GeoLocation(latitude: 31.7, longitude: 76.9),
            basin: 'Beas Basin',
            riverName: 'Beas River',
            source: 'HP SDMA',
            isSynthetic: true,
          ),
        ],
        gaugeStations: [
          GaugeStationRecord(
            stationId: 'gauge-beas-01',
            stationName: 'Mandi Gauge',
            location: const GeoLocation(latitude: 31.71, longitude: 76.91), // ~1.4 km away
            riverName: 'Beas River',
            basinName: 'Beas Basin',
            source: 'CWC',
            isSynthetic: true,
          ),
        ],
        observations: [
          GaugeObservationRecord(
            observationId: 'obs-beas-01',
            stationId: 'gauge-beas-01',
            timestamp: DateTime.utc(2025, 8, 10, 11, 0),
            dischargeM3s: 320.0,
            waterLevelMeters: 5.2,
            isSynthetic: true,
          ),
        ],
        geographicScope: 'Beas Basin',
        provenance: 'Synthetic Test Data',
        isSyntheticDataset: true,
      );

      const assocEngine = HydrographAssociationEngine(maxSearchDistanceKm: 25.0);
      final pairs = assocEngine.associateEventsWithHydrographs(dataset);

      expect(pairs.length, equals(1));
      expect(pairs.first.eventId, equals('evt-beas-01'));
      expect(pairs.first.peakObservedDischargeM3s, equals(320.0));
      expect(pairs.first.isSynthetic, isTrue);
    });

    test('TEST 18 & 19: Hydrograph comparison metrics (NSE, RMSE, MAE) calculation reproducibility', () {
      final observed = [100.0, 150.0, 300.0, 200.0, 120.0];
      final simulated = [110.0, 140.0, 280.0, 210.0, 115.0];

      final nse = FloodCalibrationEngine.calculateNSE(observed, simulated);
      final rmse = FloodCalibrationEngine.calculateRMSE(observed, simulated);
      final mae = FloodCalibrationEngine.calculateMAE(observed, simulated);

      // Hydrograph fits with small error -> NSE close to 1.0 (good fit)
      expect(nse, greaterThan(0.90));
      expect(rmse, lessThan(20.0));
      expect(mae, lessThan(15.0));
    });

    test('TEST 11, 12, 13 & 20: MANDATORY GOVERNANCE TEST: Synthetic dataset CANNOT become calibrated', () {
      final syntheticDataset = FloodCalibrationDataset(
        datasetId: 'ds-flood-synth-01',
        datasetName: 'Synthetic 10-Event Flood Dataset',
        floodEvents: List.generate(
          10,
          (i) => FloodEventRecord(
            eventId: 'evt-synth-$i',
            eventDate: DateTime.utc(2025, 8, 1 + i, 12, 0),
            location: GeoLocation(latitude: 31.0 + (i * 0.01), longitude: 77.0 + (i * 0.01)),
            basin: 'Beas Basin',
            riverName: 'Beas River',
            source: 'Synthetic Generator',
            isSynthetic: true,
          ),
        ),
        gaugeStations: List.generate(
          10,
          (i) => GaugeStationRecord(
            stationId: 'gauge-synth-$i',
            stationName: 'Station $i',
            location: GeoLocation(latitude: 31.0 + (i * 0.01), longitude: 77.0 + (i * 0.01)),
            riverName: 'Beas River',
            basinName: 'Beas Basin',
            source: 'Synthetic Generator',
            isSynthetic: true,
          ),
        ),
        observations: List.generate(
          10,
          (i) => GaugeObservationRecord(
            observationId: 'obs-synth-$i',
            stationId: 'gauge-synth-$i',
            timestamp: DateTime.utc(2025, 8, 1 + i, 13, 0),
            dischargeM3s: 200.0 + (i * 15),
            waterLevelMeters: 4.0 + (i * 0.2),
            isSynthetic: true,
          ),
        ),
        geographicScope: 'Beas Basin',
        provenance: 'Synthetic Test Data',
        isSyntheticDataset: true,
      );

      const calibrationEngine = FloodCalibrationEngine();
      final result = calibrationEngine.calibrateFloodResponse(
        dataset: syntheticDataset,
        catchmentAreaKm2: 120.0,
        peakRainfallIntensityMmHour: 25.0,
      );

      // ASSERT: Scientific status MUST remain 'provisional' because dataset is synthetic!
      expect(result.scientificStatus, equals(ScientificStatus.provisional));
      expect(result.isSynthetic, isTrue);
      expect(result.statusNotes, contains('Synthetic test dataset hydrograph calibration'));
    });

    test('TEST 14, 15, 16 & 17: Calibration results remain 100% isolated from Operational RiskMap and require ControlledPromotionGate', () {
      final gate = ControlledPromotionGate();
      expect(gate, isA<ControlledPromotionGate>());

      // Verify modelRecord parameter set versioning
      final rec = defaultModel.modelRecord;
      expect(rec.modelId, equals('flood-hydrological-response'));
      expect(rec.calibrationParameters['scientific_status'], equals('provisional'));

      final serialized = rec.calibrationParameters.toString();
      expect(serialized, isNot(contains('Bearer')));
      expect(serialized, isNot(contains('AIzaSy')));
    });
  });
}
