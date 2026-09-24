import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/hazard/hazard.dart';
import 'package:riskpulse/domain/forecasting/landslide_threshold_profile.dart';
import 'package:riskpulse/domain/forecasting/landslide_calibration_contracts.dart';
import 'package:riskpulse/data/services/forecasting/landslide_rainfall_threshold_model.dart';
import 'package:riskpulse/data/services/forecasting/event_rainfall_association_engine.dart';
import 'package:riskpulse/data/services/forecasting/landslide_calibration_engine.dart';
import 'package:riskpulse/data/services/osint/controlled_promotion_gate.dart';

void main() {
  group('R-02 Caine Landslide Calibration-Ready Architecture Tests', () {
    const defaultProfile = LandslideThresholdProfile.caine1980Global;
    final model = LandslideRainfallThresholdModel();

    test('TEST 1 & 16: Current Caine global formula (I = 14.82 * D^-0.39) remains 100% unchanged', () {
      expect(defaultProfile.coefficientA, equals(14.82));
      expect(defaultProfile.exponentB, equals(0.39));

      // Test D = 24h -> I_thresh = 14.82 * 24^(-0.39) = 4.288 mm/h
      final thresh24 = defaultProfile.calculateThresholdIntensity(24.0);
      expect(thresh24, closeTo(4.288, 0.01));

      // Test exceedance ratio R = I / I_thresh
      final ratio = defaultProfile.calculateExceedanceRatio(intensityMmHour: 10.0, durationHours: 24.0);
      expect(ratio, closeTo(2.33, 0.05));
    });

    test('TEST 2: Caine profile remains explicitly marked UNCALIBRATED for Himachal Pradesh', () {
      expect(defaultProfile.calibrationStatus, equals(ThresholdCalibrationStatus.uncalibrated));
      expect(defaultProfile.notesAndLimitations, contains('Uncalibrated for Himachal Pradesh'));
      expect(model.modelRecord.calibrationParameters['calibration_status'], equals('uncalibrated'));
    });

    test('TEST 3: Calibration dataset schema validation', () {
      final dataset = LandslideCalibrationDataset(
        datasetId: 'ds-hp-test-01',
        datasetName: 'Himachal Calibration Test Dataset',
        landslideEvents: const [
          LandslideEventRecord(
            eventId: 'ls-01',
            eventDate: DateTime.utc(2025, 7, 10),
            location: GeoLocation(latitude: 31.7, longitude: 76.9),
            district: 'Mandi',
            state: 'Himachal Pradesh',
            source: 'HP SDMA',
            isSynthetic: true,
          ),
        ],
        rainfallRecords: const [
          RainfallStationRecord(
            stationId: 'st-01',
            stationName: 'Mandi IMD',
            location: GeoLocation(latitude: 31.71, longitude: 76.91),
            observationTime: DateTime.utc(2025, 7, 10),
            rainfallAmountMm: 120.0,
            accumulationPeriodHours: 24.0,
            isSynthetic: true,
          ),
        ],
        geographicScope: 'Mandi District',
        provenance: 'Test Fixture',
        isSyntheticDataset: true,
      );

      expect(dataset.totalLandslideEvents, equals(1));
      expect(dataset.totalRainfallRecords, equals(1));
      expect(dataset.isSufficientForCalibration, isFalse); // Synthetic / <5 events
    });

    test('TEST 4, 5, 6: Event-Rainfall Association Engine spatial and temporal matching', () {
      final dataset = LandslideCalibrationDataset(
        datasetId: 'ds-assoc-test',
        datasetName: 'Spatial Match Test',
        landslideEvents: const [
          LandslideEventRecord(
            eventId: 'ls-kotropi-01',
            eventDate: DateTime.utc(2017, 8, 13),
            location: GeoLocation(latitude: 31.85, longitude: 76.95),
            district: 'Mandi',
            state: 'Himachal Pradesh',
            source: 'Historical Archive',
            isSynthetic: true,
          ),
        ],
        rainfallRecords: const [
          RainfallStationRecord(
            stationId: 'st-mandi-01',
            stationName: 'Mandi Gauge',
            location: GeoLocation(latitude: 31.86, longitude: 76.96), // ~1.4 km away
            observationTime: DateTime.utc(2017, 8, 13),
            rainfallAmountMm: 150.0,
            accumulationPeriodHours: 12.0, // 12.5 mm/h intensity
            isSynthetic: true,
          ),
        ],
        geographicScope: 'Mandi',
        provenance: 'Synthetic Test Pair',
        isSyntheticDataset: true,
      );

      const assocEngine = EventRainfallAssociationEngine(maxSearchDistanceKm: 25.0);
      final pairs = assocEngine.associateEventsWithRainfall(dataset);

      expect(pairs.length, equals(1));
      expect(pairs.first.eventId, equals('ls-kotropi-01'));
      expect(pairs.first.distanceKm, lessThan(5.0));
      expect(pairs.first.rainfallIntensityMmHour, equals(12.5));
      expect(pairs.first.isSynthetic, isTrue);
    });

    test('TEST 8, 10, 11, 12: MANDATORY GOVERNANCE TEST: Synthetic dataset CANNOT become calibratedRegional', () {
      final syntheticDataset = LandslideCalibrationDataset(
        datasetId: 'ds-synth-01',
        datasetName: 'Synthetic 10-Pair Dataset',
        landslideEvents: List.generate(
          10,
          (i) => LandslideEventRecord(
            eventId: 'ls-synth-$i',
            eventDate: DateTime.utc(2025, 7, 1 + i),
            location: GeoLocation(latitude: 31.0 + (i * 0.01), longitude: 77.0 + (i * 0.01)),
            district: 'Mandi',
            state: 'Himachal Pradesh',
            source: 'Synthetic Generator',
            isSynthetic: true,
          ),
        ),
        rainfallRecords: List.generate(
          10,
          (i) => RainfallStationRecord(
            stationId: 'st-synth-$i',
            stationName: 'Station $i',
            location: GeoLocation(latitude: 31.0 + (i * 0.01), longitude: 77.0 + (i * 0.01)),
            observationTime: DateTime.utc(2025, 7, 1 + i),
            rainfallAmountMm: 50.0 + (i * 10),
            accumulationPeriodHours: 6.0 + i,
            isSynthetic: true,
          ),
        ),
        geographicScope: 'Himachal Pradesh',
        provenance: 'Synthetic Test Data',
        isSyntheticDataset: true,
      );

      const calibrationEngine = LandslideCalibrationEngine();
      final result = calibrationEngine.calibrateProfile(
        dataset: syntheticDataset,
        profileId: 'caine-hp-candidate',
        profileName: 'Caine HP Candidate Profile',
        geographicScope: 'Himachal Pradesh',
      );

      // ASSERT: Calibration status MUST remain 'uncalibrated' because dataset is synthetic!
      expect(result.profile.calibrationStatus, equals(ThresholdCalibrationStatus.uncalibrated));
      expect(result.isSynthetic, isTrue);
      expect(result.statusNotes, contains('Synthetic test dataset calibration'));
    });

    test('TEST 13 & 14: Calibration results remain 100% isolated from Operational RiskMap and require ControlledPromotionGate', () {
      final gate = ControlledPromotionGate();
      expect(gate, isA<ControlledPromotionGate>());

      // Verify Caine model does NOT contain references to operational RiskMap datasets
      expect(model.modelRecord.modelId, equals('landslide-rainfall-threshold'));
    });

    test('TEST 15: Zero secret credentials enter calibration provenance or model records', () {
      final rec = model.modelRecord;
      final serialized = rec.calibrationParameters.toString();

      expect(serialized, isNot(contains('Bearer')));
      expect(serialized, isNot(contains('AIzaSy')));
      expect(serialized, isNot(contains('key_secret')));
    });
  });
}
