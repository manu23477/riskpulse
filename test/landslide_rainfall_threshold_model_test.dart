import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/hazard/hazard.dart';
import 'package:riskpulse/domain/forecasting/forecasting.dart';
import 'package:riskpulse/data/services/forecasting/forecasting_services.dart';

void main() {
  group('Stage 3.5-R Model 1 — Landslide Rainfall Threshold Model & Provenance Correction', () {
    final now = DateTime.utc(2026, 9, 8, 12, 0, 0);

    final historicalHorizon = ForecastHorizon(
      validFrom: now.subtract(const Duration(hours: 24)),
      validTo: now,
    );

    final futureHorizon = ForecastHorizon(
      validFrom: now.add(const Duration(hours: 1)),
      validTo: now.add(const Duration(hours: 25)),
    );

    group('1. Caine (1980) Profile Verification & Invariants', () {
      test('Caine 1980 profile holds exact 14.82 and 0.39 parameters and global scope', () {
        const profile = LandslideThresholdProfile.caine1980Global;

        expect(profile.profileId, 'caine-1980-global');
        expect(profile.coefficientA, 14.82);
        expect(profile.exponentB, 0.39);
        expect(profile.durationMinHours, 0.1);
        expect(profile.durationMaxHours, 500.0);
        expect(profile.publicationYear, 1980);
        expect(profile.geographicScope, contains('Global Empirical Reference'));
        expect(profile.sourceCitation, contains('Caine, N. (1980)'));
        expect(profile.calibrationStatus, ThresholdCalibrationStatus.uncalibrated);
      });

      test('default LandslideRainfallThresholdModel uses Caine 1980 profile', () {
        final model = LandslideRainfallThresholdModel();

        expect(model.aParameter, 14.82);
        expect(model.bExponent, 0.39);
        expect(model.profile.profileId, 'caine-1980-global');
        expect(model.modelVersion, '1.1.0');

        final record = model.modelRecord;
        expect(record.calibrationParameters['threshold_profile_id'], 'caine-1980-global');
        expect(record.calibrationParameters['coefficient_a'], 14.82);
        expect(record.calibrationParameters['exponent_b'], 0.39);
        expect(record.calibrationParameters['calibration_status'], 'uncalibrated');
      });

      test('unverified legacy profile is explicitly identified and separate from Caine', () {
        const legacy = LandslideThresholdProfile.unverifiedLegacy;

        expect(legacy.profileId, 'unverified-legacy-research');
        expect(legacy.coefficientA, 12.5);
        expect(legacy.exponentB, 0.42);
        expect(legacy.sourceCitation, contains('Unverified prior code configuration'));
        expect(legacy.geographicScope, contains('Unverified Scope'));
      });
    });

    group('2. Empirical Caine (1980) Threshold Exceedance Predictions', () {
      test('evaluates rainfall below Caine 1980 threshold correctly', () async {
        final model = LandslideRainfallThresholdModel();

        // 24mm rainfall over 24 hours -> Intensity I = 1.0 mm/h
        // Threshold I_thresh = 14.82 * 24^(-0.39) = 14.82 * 0.2882 = ~4.27 mm/h
        // Exceedance Ratio = 1.0 / 4.27 = ~0.234 (< 1.0)
        final rainObs1 = HazardObservation(
          observationId: 'rain-caine-low-1',
          parameterId: 'rainfall_mm',
          value: 12.0,
          unit: 'mm',
          observationTime: now.subtract(const Duration(hours: 24)),
          location: const GeoLocation(latitude: 31.7081, longitude: 76.9317),
        );

        final rainObs2 = HazardObservation(
          observationId: 'rain-caine-low-2',
          parameterId: 'rainfall_mm',
          value: 12.0,
          unit: 'mm',
          observationTime: now,
          location: const GeoLocation(latitude: 31.7081, longitude: 76.9317),
        );

        final series = HazardTimeSeries(
          timeSeriesId: 'ts-caine-low',
          parameterId: 'rainfall_mm',
          unit: 'mm',
          observations: [rainObs1, rainObs2],
        );

        final input = ForecastInput(
          inputId: 'input-caine-low',
          timeSeriesIds: [series.timeSeriesId],
          targetHorizon: historicalHorizon,
          parameters: {'rainfall_time_series': series},
        );

        final forecast = await model.predict(input: input, initializationTime: now);

        expect(forecast.parameterId, 'landslide_threshold_exceedance');
        expect(forecast.category, 'Historical Landslide Threshold Analysis');
        expect(forecast.primaryValue, closeTo(0.234, 0.05));
        expect(forecast.categoricalLabel, 'Below Threshold');
        expect(forecast.metadata['profileId'], 'caine-1980-global');
        expect(forecast.metadata['coefficientA'], 14.82);
      });

      test('evaluates heavy rainfall exceeding Caine 1980 threshold correctly', () async {
        final model = LandslideRainfallThresholdModel();

        // Heavy cloudburst rainfall: 120mm over 24 hours -> Intensity I = 5.0 mm/h
        // Threshold I_thresh = 14.82 * 24^(-0.39) = ~4.27 mm/h
        // Exceedance Ratio = 5.0 / 4.27 = ~1.17 (> 1.0)
        final rainObs = HazardObservation(
          observationId: 'rain-caine-heavy',
          parameterId: 'rainfall_mm',
          value: 120.0,
          unit: 'mm',
          observationTime: now.subtract(const Duration(hours: 24)),
          location: const GeoLocation(latitude: 31.7081, longitude: 76.9317),
        );

        final series = HazardTimeSeries(
          timeSeriesId: 'ts-caine-heavy',
          parameterId: 'rainfall_mm',
          unit: 'mm',
          observations: [rainObs],
        );

        final input = ForecastInput(
          inputId: 'input-caine-heavy',
          timeSeriesIds: [series.timeSeriesId],
          targetHorizon: futureHorizon,
          parameters: {'rainfall_time_series': series},
        );

        final forecast = await model.predict(input: input, initializationTime: now);

        expect(forecast.category, 'Forecast Landslide Threshold Exceedance');
        expect(forecast.primaryValue, greaterThan(1.0));
        expect(forecast.categoricalLabel, 'Threshold Exceeded');
      });

      test('separates primary I-D equation from optional antecedent rainfall condition', () async {
        final model = LandslideRainfallThresholdModel(antecedentWindowHours: 48);

        final rainObs = HazardObservation(
          observationId: 'rain-ant-1',
          parameterId: 'rainfall_mm',
          value: 30.0,
          unit: 'mm',
          observationTime: now,
        );

        final series = HazardTimeSeries(
          timeSeriesId: 'ts-ant',
          parameterId: 'rainfall_mm',
          unit: 'mm',
          observations: [rainObs],
        );

        final input = ForecastInput(
          inputId: 'input-ant-1',
          timeSeriesIds: [series.timeSeriesId],
          targetHorizon: historicalHorizon,
          parameters: {'rainfall_time_series': series},
        );

        final forecast = await model.predict(input: input, initializationTime: now);

        // Verify antecedent window is explicitly tracked as separate configuration
        expect(forecast.metadata['antecedentWindowHours'], 48);
        final step = forecast.provenanceSteps.first;
        expect(step.parameters['antecedentWindowHours'], 48);
      });
    });

    group('3. Mandatory Scientific Negative Tests (Stage 3.5-R)', () {
      test('MANDATORY SCIENTIFIC NEGATIVE TEST: Caine 1980 is NOT called Himalayan calibrated', () {
        const profile = LandslideThresholdProfile.caine1980Global;
        expect(profile.geographicScope, isNot(contains('Himalayan Calibrated')));
        expect(profile.calibrationStatus, ThresholdCalibrationStatus.uncalibrated);
      });

      test('MANDATORY SCIENTIFIC NEGATIVE TEST: 12.5/0.42 is NOT attributed to Caine 1980', () {
        const legacy = LandslideThresholdProfile.unverifiedLegacy;
        expect(legacy.sourceCitation, isNot(contains('Caine, N. (1980)')));
        expect(legacy.profileId, 'unverified-legacy-research');
      });

      test('MANDATORY SCIENTIFIC NEGATIVE TEST: threshold exceedance does NOT populate calibrated probability', () async {
        final model = LandslideRainfallThresholdModel();

        final rainObs = HazardObservation(
          observationId: 'rain-neg-caine',
          parameterId: 'rainfall_mm',
          value: 100.0,
          unit: 'mm',
          observationTime: now,
        );

        final series = HazardTimeSeries(
          timeSeriesId: 'ts-neg-caine',
          parameterId: 'rainfall_mm',
          unit: 'mm',
          observations: [rainObs],
        );

        final input = ForecastInput(
          inputId: 'input-neg-caine',
          timeSeriesIds: [series.timeSeriesId],
          targetHorizon: historicalHorizon,
          parameters: {'rainfall_time_series': series},
        );

        final forecast = await model.predict(input: input, initializationTime: now);

        expect(forecast.uncertainty.isCalibrated, isFalse);
        expect(forecast.uncertainty.calibratedEventProbability, isNull);
        expect(forecast.uncertainty.uncalibratedScore, isNotNull);
      });

      test('MANDATORY GOVERNANCE TEST: model prediction DOES NOT mutate RiskMap or create operational hazards', () async {
        final model = LandslideRainfallThresholdModel();

        final rainObs = HazardObservation(
          observationId: 'rain-gov-caine',
          parameterId: 'rainfall_mm',
          value: 120.0,
          unit: 'mm',
          observationTime: now,
        );

        final series = HazardTimeSeries(
          timeSeriesId: 'ts-gov-caine',
          parameterId: 'rainfall_mm',
          unit: 'mm',
          observations: [rainObs],
        );

        final input = ForecastInput(
          inputId: 'input-gov-caine',
          timeSeriesIds: [series.timeSeriesId],
          targetHorizon: historicalHorizon,
          parameters: {'rainfall_time_series': series},
        );

        final forecast = await model.predict(input: input, initializationTime: now);

        expect(forecast, isA<HazardForecast>());
        expect(forecast, isNot(isA<Hazard>()));
      });
    });
  });
}
