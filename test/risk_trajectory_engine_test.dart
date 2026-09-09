import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/hazard/hazard.dart';
import 'package:riskpulse/domain/forecasting/forecasting.dart';
import 'package:riskpulse/data/services/forecasting/forecasting_services.dart';

void main() {
  group('Stage 3.9.3 Risk Trajectory Engine', () {
    final t1 = DateTime.utc(2026, 9, 8, 12, 0, 0);
    final t2 = DateTime.utc(2026, 9, 8, 18, 0, 0); // +6 hours (21600 seconds)

    final mandiLocation = const GeoLocation(latitude: 31.7081, longitude: 76.9317);

    final timeSpan = ForecastHorizon(
      validFrom: t1,
      validTo: t2,
    );

    const engine = RiskTrajectoryEngine();

    group('1. RiskTrajectory Domain Contract Invariants', () {
      test('instantiates valid RiskTrajectory and validates non-empty IDs', () {
        final trajectory = RiskTrajectory(
          trajectoryId: 'traj-101',
          targetEntityId: 'ls-model-mandi',
          entityCategory: 'Landslide',
          stateVariable: 'rainfall_threshold_exceedance',
          direction: RiskTrajectoryDirection.rising,
          initialValue: 0.50,
          finalValue: 1.20,
          absoluteDelta: 0.70,
          relativeDelta: 1.40,
          velocityPerSecond: 0.70 / 21600.0,
          timeSpan: timeSpan,
          location: mandiLocation,
          uncertainty: ForecastUncertainty(),
        );

        expect(trajectory.trajectoryId, 'traj-101');
        expect(trajectory.direction, RiskTrajectoryDirection.rising);
        expect(trajectory.isRising, isTrue);
        expect(trajectory.isUnknown, isFalse);
        expect(trajectory.absoluteDelta, 0.70);
      });

      test('rejects empty IDs or NaN state values', () {
        expect(
          () => RiskTrajectory(
            trajectoryId: '',
            targetEntityId: 'model-1',
            entityCategory: 'Landslide',
            stateVariable: 'ratio',
            direction: RiskTrajectoryDirection.unknown,
            timeSpan: timeSpan,
            location: mandiLocation,
            uncertainty: ForecastUncertainty(),
          ),
          throwsArgumentError,
        );

        expect(
          () => RiskTrajectory(
            trajectoryId: 'traj-1',
            targetEntityId: 'model-1',
            entityCategory: 'Landslide',
            stateVariable: 'ratio',
            direction: RiskTrajectoryDirection.rising,
            initialValue: double.nan, // NaN value -> MUST REJECT!
            timeSpan: timeSpan,
            location: mandiLocation,
            uncertainty: ForecastUncertainty(),
          ),
          throwsArgumentError,
        );
      });
    });

    group('2. Value-Based Trajectory Classification Rules', () {
      test('classifies rising trajectory when relative delta exceeds 5% threshold', () {
        final result = engine.evaluateTrajectoryFromValues(
          trajectoryId: 'traj-eval-1',
          targetEntityId: 'landslide-model',
          entityCategory: 'Landslide',
          stateVariable: 'exceedance_ratio',
          initialValue: 0.80,
          finalValue: 1.20, // +50% increase > +5% threshold
          timeSpan: timeSpan,
          location: mandiLocation,
          uncertainty: ForecastUncertainty(),
        );

        expect(result.direction, RiskTrajectoryDirection.rising);
        expect(result.isRising, isTrue);
        expect(result.absoluteDelta, closeTo(0.40, 1e-5));
        expect(result.relativeDelta, closeTo(0.50, 1e-5));
        expect(result.velocityPerSecond, greaterThan(0.0));
      });

      test('classifies stable trajectory when change is within 5% threshold', () {
        final result = engine.evaluateTrajectoryFromValues(
          trajectoryId: 'traj-eval-2',
          targetEntityId: 'landslide-model',
          entityCategory: 'Landslide',
          stateVariable: 'exceedance_ratio',
          initialValue: 1.00,
          finalValue: 1.02, // +2% change < 5% threshold
          timeSpan: timeSpan,
          location: mandiLocation,
          uncertainty: ForecastUncertainty(),
        );

        expect(result.direction, RiskTrajectoryDirection.stable);
        expect(result.isStable, isTrue);
      });

      test('classifies declining trajectory when relative delta is below -5% threshold', () {
        final result = engine.evaluateTrajectoryFromValues(
          trajectoryId: 'traj-eval-3',
          targetEntityId: 'landslide-model',
          entityCategory: 'Landslide',
          stateVariable: 'exceedance_ratio',
          initialValue: 1.20,
          finalValue: 0.60, // -50% change < -5% threshold
          timeSpan: timeSpan,
          location: mandiLocation,
          uncertainty: ForecastUncertainty(),
        );

        expect(result.direction, RiskTrajectoryDirection.declining);
        expect(result.isDeclining, isTrue);
        expect(result.velocityPerSecond, lessThan(0.0));
      });

      test('returns UNKNOWN trajectory when values are null or NaN', () {
        final result = engine.evaluateTrajectoryFromValues(
          trajectoryId: 'traj-eval-null',
          targetEntityId: 'model-1',
          entityCategory: 'Landslide',
          stateVariable: 'exceedance_ratio',
          initialValue: null, // Null value -> MUST RETURN UNKNOWN!
          finalValue: 1.20,
          timeSpan: timeSpan,
          location: mandiLocation,
          uncertainty: ForecastUncertainty(),
        );

        expect(result.direction, RiskTrajectoryDirection.unknown);
        expect(result.isUnknown, isTrue);
      });

      test('returns UNKNOWN trajectory when time window is inverted or duration <= 0', () {
        final invalidHorizon = ForecastHorizon(
          validFrom: t2,
          validTo: t1, // Inverted!
        );

        final result = engine.evaluateTrajectoryFromValues(
          trajectoryId: 'traj-eval-time-fail',
          targetEntityId: 'model-1',
          entityCategory: 'Landslide',
          stateVariable: 'exceedance_ratio',
          initialValue: 0.50,
          finalValue: 1.20,
          timeSpan: invalidHorizon,
          location: mandiLocation,
          uncertainty: ForecastUncertainty(),
        );

        expect(result.direction, RiskTrajectoryDirection.unknown);
        expect(result.isUnknown, isTrue);
      });

      test('handles zero initial baseline correctly (0 -> 5.0 is rising)', () {
        final result = engine.evaluateTrajectoryFromValues(
          trajectoryId: 'traj-eval-zero-base',
          targetEntityId: 'flood-model',
          entityCategory: 'Flood',
          stateVariable: 'discharge_m3s',
          initialValue: 0.0,
          finalValue: 5.0,
          timeSpan: timeSpan,
          location: mandiLocation,
          uncertainty: ForecastUncertainty(),
        );

        expect(result.direction, RiskTrajectoryDirection.rising);
        expect(result.absoluteDelta, 5.0);
      });
    });

    group('3. Impact Trajectory & Unknown Vulnerability Safeguard', () {
      test('MANDATORY UNKNOWN VULNERABILITY SAFEGUARD TEST: when vulnerability is unknown, impact trajectory returns UNKNOWN', () {
        final initialImpact = ImpactAssessment(
          assessmentId: 'impact-t1',
          hazardId: 'ls-mandi-1',
          hazardCategory: 'Landslide',
          exposureCategory: ExposureCategory.population,
          exposureDatasetId: 'pop-ds-1',
          totalExposedQuantity: 2500.0,
          quantityUnit: 'persons',
          horizon: ForecastHorizon(validFrom: t1, validTo: t1.add(const Duration(hours: 1))),
          location: mandiLocation,
          uncertainty: ForecastUncertainty(),
          vulnerabilityProfile: null, // Vulnerability is UNKNOWN
        );

        final finalImpact = ImpactAssessment(
          assessmentId: 'impact-t2',
          hazardId: 'ls-mandi-1',
          hazardCategory: 'Landslide',
          exposureCategory: ExposureCategory.population,
          exposureDatasetId: 'pop-ds-1',
          totalExposedQuantity: 2500.0,
          quantityUnit: 'persons',
          horizon: ForecastHorizon(validFrom: t2, validTo: t2.add(const Duration(hours: 1))),
          location: mandiLocation,
          uncertainty: ForecastUncertainty(),
          vulnerabilityProfile: null, // Vulnerability is UNKNOWN
        );

        final result = engine.evaluateImpactTrajectory(
          trajectoryId: 'impact-traj-101',
          initialImpact: initialImpact,
          finalImpact: finalImpact,
        );

        // ASSERT: Trajectory direction MUST be UNKNOWN!
        expect(result.direction, RiskTrajectoryDirection.unknown);
        expect(result.isUnknown, isTrue);
        expect(result.scientificStatus, ScientificValidationStatus.notValidatedDataUnavailable);
        expect(result.metadata['reason'], contains('Vulnerability is UNKNOWN'));

        // ASSERT: Valid exposure quantity remains preserved in metadata
        expect(result.metadata['initialExposedQuantity'], 2500.0);
      });
    });

    group('4. Mandatory Governance Safeguard Tests', () {
      test('MANDATORY GOVERNANCE TEST: RiskTrajectory DOES NOT mutate RiskMap or create operational hazards', () {
        final result = engine.evaluateTrajectoryFromValues(
          trajectoryId: 'traj-gov-1',
          targetEntityId: 'mandi-sector',
          entityCategory: 'Landslide',
          stateVariable: 'exceedance_ratio',
          initialValue: 0.50,
          finalValue: 1.50,
          timeSpan: timeSpan,
          location: mandiLocation,
          uncertainty: ForecastUncertainty(),
        );

        expect(result, isA<RiskTrajectory>());
        expect(result, isNot(isA<Hazard>()));
      });
    });
  });
}
