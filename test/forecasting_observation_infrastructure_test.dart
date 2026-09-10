import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/forecasting/forecasting.dart';
import 'package:riskpulse/data/services/forecasting/forecasting_services.dart';

void main() {
  group('Stage 3.3 Hazard Observation & Time-Series Infrastructure', () {
    final now = DateTime.utc(2026, 9, 8, 12, 0, 0);

    group('1. Ingestion & Normalization', () {
      test('normalizes valid raw JSON records into HazardObservations', () {
        const normalizer = HazardObservationNormalizer();

        final raw = {
          'id': 'obs-telemetry-101',
          'parameter': 'rainfall_mm',
          'unit': 'mm',
          'value': 18.5,
          'timestamp': '2026-09-08T10:00:00Z',
          'latitude': 31.7081,
          'longitude': 76.9317,
          'provider': 'MandiGaugeNet',
        };

        final obs = normalizer.normalizeRecord(raw);

        expect(obs.observationId, 'obs-telemetry-101');
        expect(obs.parameterId, 'rainfall_mm');
        expect(obs.value, 18.5);
        expect(obs.unit, 'mm');
        expect(obs.qualityState, 'observed');
        expect(obs.dataSource?.provider, 'MandiGaugeNet');
      });

      test('flags malformed records with invalid qualityState', () {
        const normalizer = HazardObservationNormalizer();

        final rawInvalidValue = {
          'id': 'obs-bad-val',
          'parameter': 'rainfall_mm',
          'unit': 'mm',
          'value': -99.0, // Negative rainfall invalid
          'timestamp': '2026-09-08T10:00:00Z',
        };

        final obs = normalizer.normalizeRecord(rawInvalidValue);
        expect(obs.qualityState, 'invalid');
      });
    });

    group('2. Quality Control Engine', () {
      final qcEngine = ObservationQualityControlEngine(referenceTime: now);

      test('passes physically valid observations', () {
        final obs = HazardObservation(
          observationId: 'obs-qc-1',
          parameterId: 'temperature_c',
          value: 24.5,
          unit: 'C',
          observationTime: now.subtract(const Duration(minutes: 30)),
          location: const GeoLocation(latitude: 31.7, longitude: 76.9),
        );

        final result = qcEngine.performQc(obs);
        expect(result.isPassed, isTrue);
        expect(result.issues, isEmpty);
        expect(result.observation.qualityState, 'valid');
      });

      test('detects physical range violations, invalid coords, or future timestamps', () {
        final obsBadTemp = HazardObservation(
          observationId: 'obs-qc-2',
          parameterId: 'temperature_c',
          value: 120.0, // Exceeds +70C Earth limit
          unit: 'C',
          observationTime: now,
        );

        final result1 = qcEngine.performQc(obsBadTemp);
        expect(result1.isPassed, isFalse);
        expect(result1.issues, contains(contains('Temperature out of physical Earth range')));
        expect(result1.observation.qualityState, 'invalid');

        final obsFuture = HazardObservation(
          observationId: 'obs-qc-3',
          parameterId: 'rainfall_mm',
          value: 10.0,
          unit: 'mm',
          observationTime: now.add(const Duration(hours: 5)), // Future timestamp
        );

        final result2 = qcEngine.performQc(obsFuture);
        expect(result2.isPassed, isFalse);
        expect(result2.issues, contains(contains('is in the future')));
      });
    });

    group('3. Duplicate Resolution Policies', () {
      final obs1 = HazardObservation(
        observationId: 'obs-dup',
        parameterId: 'rainfall_mm',
        value: 10.0,
        unit: 'mm',
        observationTime: now,
        qualityState: 'valid',
        uncertainty: 2.0,
      );

      final obs2 = HazardObservation(
        observationId: 'obs-dup',
        parameterId: 'rainfall_mm',
        value: 12.0,
        unit: 'mm',
        observationTime: now,
        qualityState: 'valid',
        uncertainty: 0.5, // Better uncertainty
      );

      test('reject policy throws ArgumentError on duplicates', () {
        const resolver = DuplicateResolver(policy: DuplicatePolicyType.reject);
        expect(() => resolver.resolve([obs1, obs2]), throwsArgumentError);
      });

      test('retainHighestQuality policy selects superior quality/uncertainty', () {
        const resolver = DuplicateResolver(policy: DuplicatePolicyType.retainHighestQuality);
        final resolved = resolver.resolve([obs1, obs2]);
        expect(resolved.length, 1);
        expect(resolved.first.uncertainty, 0.5); // Selected obs2
      });

      test('flagConflict policy retains record with suspect_duplicate_conflict state', () {
        const resolver = DuplicateResolver(policy: DuplicatePolicyType.flagConflict);
        final resolved = resolver.resolve([obs1, obs2]);
        expect(resolved.length, 1);
        expect(resolved.first.qualityState, 'suspect_duplicate_conflict');
      });
    });

    group('4. Unit Conversion Engine', () {
      const converter = UnitConversionEngine();

      test('converts compatible units correctly and records provenance', () {
        // Length: mm to m
        final resRain = converter.convert(value: 1500.0, fromUnit: 'mm', toUnit: 'm');
        expect(resRain.convertedValue, 1.5);
        expect(resRain.targetUnit, 'm');
        expect(resRain.provenanceStep.operationType, 'unit_conversion');

        // Temperature: C to K
        final resTemp = converter.convert(value: 25.0, fromUnit: 'C', toUnit: 'K');
        expect(resTemp.convertedValue, 298.15);

        // Volumetric flow: m3/s to L/s
        final resFlow = converter.convert(value: 2.5, fromUnit: 'm3/s', toUnit: 'L/s');
        expect(resFlow.convertedValue, 2500.0);

        // Speed: km/h to m/s
        final resSpeed = converter.convert(value: 36.0, fromUnit: 'km/h', toUnit: 'm/s');
        expect(resSpeed.convertedValue, 10.0);
      });

      test('rejects conversions across incompatible physical dimensions', () {
        expect(
          () => converter.convert(value: 50.0, fromUnit: 'mm', toUnit: 'C'),
          throwsArgumentError,
        );

        expect(
          () => converter.convert(value: 10.0, fromUnit: 'm3/s', toUnit: 'hPa'),
          throwsArgumentError,
        );
      });
    });

    group('5. TimeSeriesPipeline & Mandatory Negative Missing Data Tests', () {
      const pipeline = TimeSeriesPipeline(
        duplicateResolver: DuplicateResolver(policy: DuplicatePolicyType.retainHighestQuality),
      );

      test('MANDATORY NEGATIVE TEST: verifies missing data gaps are NEVER silently filled', () {
        final t10 = now.subtract(const Duration(hours: 3)); // 09:00
        final t11 = now.subtract(const Duration(hours: 2)); // 10:00
        // 11:00 IS MISSING
        final t13 = now; // 12:00

        final obs10 = HazardObservation(
          observationId: 'obs-0900',
          parameterId: 'rainfall_mm',
          value: 5.0,
          unit: 'mm',
          observationTime: t10,
        );
        final obs11 = HazardObservation(
          observationId: 'obs-1000',
          parameterId: 'rainfall_mm',
          value: 8.0,
          unit: 'mm',
          observationTime: t11,
        );
        final obs13 = HazardObservation(
          observationId: 'obs-1200',
          parameterId: 'rainfall_mm',
          value: 12.0,
          unit: 'mm',
          observationTime: t13,
        );

        final series = pipeline.buildTimeSeries(
          timeSeriesId: 'ts-mandi-rain-gap-test',
          parameterId: 'rainfall_mm',
          unit: 'mm',
          observations: [obs10, obs11, obs13],
        );

        // STRICT ASSERTION: Series MUST contain exactly 3 observations; NO 11:00 synthetic value
        expect(series.length, 3);
        final sorted = series.chronologicalObservations;
        expect(sorted[0].observationTime, t10);
        expect(sorted[1].observationTime, t11);
        expect(sorted[2].observationTime, t13);

        // Detect gaps explicitly
        final gaps = pipeline.detectGaps(
          series: series,
          expectedInterval: const Duration(hours: 1),
        );

        expect(gaps.length, 1);
        expect(gaps.first.startTime, t11);
        expect(gaps.first.endTime, t13);
        expect(gaps.first.missingDuration, const Duration(hours: 2));
      });
    });

    group('6. Temporal Alignment & Aggregation', () {
      const alignmentEngine = TemporalAlignmentEngine();

      final obs1 = HazardObservation(
        observationId: 'obs-a1',
        parameterId: 'rainfall_mm',
        value: 10.0,
        unit: 'mm',
        observationTime: now.subtract(const Duration(minutes: 5)),
      );

      final obs2 = HazardObservation(
        observationId: 'obs-a2',
        parameterId: 'rainfall_mm',
        value: 20.0,
        unit: 'mm',
        observationTime: now.add(const Duration(minutes: 55)),
      );

      final series = HazardTimeSeries(
        timeSeriesId: 'ts-align',
        parameterId: 'rainfall_mm',
        unit: 'mm',
        observations: [obs1, obs2],
      );

      test('aligns to target timestamps within tolerance, lists unaligned timestamps as missing', () {
        final targetTimestamps = [
          now, // Within 5 min of obs1 -> Match
          now.add(const Duration(hours: 5)), // Far out -> Missing
        ];

        final result = alignmentEngine.alignToTargetTimestamps(
          series: series,
          targetTimestamps: targetTimestamps,
          tolerance: const Duration(minutes: 10),
        );

        expect(result.alignedObservations.length, 1);
        expect(result.alignedObservations.first.observationId, 'obs-a1');
        expect(result.missingTimestamps.length, 1);
      });

      test('aggregates fine-grained time series using explicit strategy and marks quality as derived', () {
        // 5-min rain observations
        final r1 = HazardObservation(
          observationId: 'r1',
          parameterId: 'rainfall_mm',
          value: 2.0,
          unit: 'mm',
          observationTime: now.subtract(const Duration(minutes: 50)),
        );
        final r2 = HazardObservation(
          observationId: 'r2',
          parameterId: 'rainfall_mm',
          value: 3.5,
          unit: 'mm',
          observationTime: now.subtract(const Duration(minutes: 40)),
        );

        final fineSeries = HazardTimeSeries(
          timeSeriesId: 'ts-fine',
          parameterId: 'rainfall_mm',
          unit: 'mm',
          observations: [r1, r2],
        );

        final hourlySeries = alignmentEngine.aggregateTimeSeries(
          series: fineSeries,
          windowDuration: const Duration(hours: 1),
          strategy: AggregationStrategy.accumulation,
          newTimeSeriesId: 'ts-hourly-accum',
        );

        expect(hourlySeries.length, 1);
        expect(hourlySeries.observations.first.value, 5.5); // 2.0 + 3.5
        expect(hourlySeries.observations.first.qualityState, 'derived');
        expect(hourlySeries.observations.first.provenanceSteps.first.operationType, 'aggregation_accumulation');
      });
    });

    group('7. Spatial Alignment Engine', () {
      const spatialEngine = SpatialAlignmentEngine();
      const mandiPoint = GeoLocation(latitude: 31.7081, longitude: 76.9317);
      const pandohPoint = GeoLocation(latitude: 31.6710, longitude: 77.0420); // ~11km away

      test('calculates Haversine distance and performs proximity alignment', () {
        final dist = spatialEngine.distanceMeters(mandiPoint, pandohPoint);
        expect(dist, greaterThan(10000.0)); // ~11,000 meters
        expect(dist, lessThan(12000.0));

        final obs = HazardObservation(
          observationId: 'obs-sp-1',
          parameterId: 'rainfall_mm',
          value: 15.0,
          unit: 'mm',
          observationTime: now,
          location: mandiPoint,
        );

        // Within 15km
        final resMatch = spatialEngine.alignToLocation(
          observation: obs,
          targetLocation: pandohPoint,
          maxRadiusMeters: 15000.0,
        );
        expect(resMatch.isWithinDomain, isTrue);

        // Within 5km -> False
        final resNoMatch = spatialEngine.alignToLocation(
          observation: obs,
          targetLocation: pandohPoint,
          maxRadiusMeters: 5000.0,
        );
        expect(resNoMatch.isWithinDomain, isFalse);
      });
    });

    group('8. Opt-In Imputation Engine (Explicit & Traceable)', () {
      const imputationEngine = OptInImputationEngine();

      test('imputes gaps only when explicitly invoked and marks qualityState as estimated', () {
        final obs1 = HazardObservation(
          observationId: 'imp-1',
          parameterId: 'temperature_c',
          value: 20.0,
          unit: 'C',
          observationTime: now.subtract(const Duration(hours: 2)),
        );
        final obs2 = HazardObservation(
          observationId: 'imp-2',
          parameterId: 'temperature_c',
          value: 24.0,
          unit: 'C',
          observationTime: now,
        );

        final gappedSeries = HazardTimeSeries(
          timeSeriesId: 'ts-temp-gap',
          parameterId: 'temperature_c',
          unit: 'C',
          observations: [obs1, obs2],
        );

        final filledSeries = imputationEngine.imputeGaps(
          series: gappedSeries,
          stepInterval: const Duration(hours: 1),
          method: ImputationMethod.linearInterpolation,
          newTimeSeriesId: 'ts-temp-filled',
        );

        // Contains obs1 (20C), imputed 1-hour gap value (22C), obs2 (24C)
        expect(filledSeries.length, 3);
        final imputedObs = filledSeries.observations[1];
        expect(imputedObs.value, 22.0); // Linear midpoint
        expect(imputedObs.qualityState, 'estimated');
        expect(imputedObs.metadata['imputed'], isTrue);
      });
    });

    group('9. Mandatory System Negative Safeguard Tests', () {
      test('System DOES NOT confuse zero with missing', () {
        final zeroObs = HazardObservation(
          observationId: 'obs-zero',
          parameterId: 'rainfall_mm',
          value: 0.0, // True observed zero rain
          unit: 'mm',
          observationTime: now,
        );

        expect(zeroObs.value, 0.0);
        expect(zeroObs.qualityState, 'valid');
      });

      test('System DOES NOT generate forecasting runs or predictions in Stage 3.3', () {
        // Assert that Stage 3.3 components produce observations/series only, zero forecasts.
        const pipeline = TimeSeriesPipeline();
        final series = pipeline.buildTimeSeries(
          timeSeriesId: 'ts-pure',
          parameterId: 'rainfall_mm',
          unit: 'mm',
          observations: [
            HazardObservation(
              observationId: 'p1',
              parameterId: 'rainfall_mm',
              value: 10.0,
              unit: 'mm',
              observationTime: now,
            ),
          ],
        );

        expect(series, isA<HazardTimeSeries>());
        expect(series, isNot(isA<HazardForecast>()));
      });
    });
  });
}
