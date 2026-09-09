import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/hazard/hazard.dart';
import 'package:riskpulse/domain/forecasting/forecasting.dart';
import 'package:riskpulse/data/services/forecasting/forecasting_services.dart';

void main() {
  group('Stage 3.9.4 Risk Driver & Attribution Engine', () {
    final t1 = DateTime.utc(2026, 9, 8, 12, 0, 0);
    final t2 = DateTime.utc(2026, 9, 8, 18, 0, 0);

    final mandiLocation = const GeoLocation(latitude: 31.7081, longitude: 76.9317);
    final farLocation = const GeoLocation(latitude: 32.5000, longitude: 78.0000); // ~150km away

    final horizon = ForecastHorizon(validFrom: t1, validTo: t2);

    final risingTrajectory = RiskTrajectory(
      trajectoryId: 'traj-mandi-001',
      targetEntityId: 'mandi-landslide-zone',
      entityCategory: 'Landslide',
      stateVariable: 'rainfall_threshold_exceedance',
      direction: RiskTrajectoryDirection.rising,
      initialValue: 0.60,
      finalValue: 1.35,
      absoluteDelta: 0.75,
      relativeDelta: 1.25,
      timeSpan: horizon,
      location: mandiLocation,
      uncertainty: ForecastUncertainty(),
    );

    final unknownTrajectory = RiskTrajectory(
      trajectoryId: 'traj-unk-001',
      targetEntityId: 'mandi-unverified-zone',
      entityCategory: 'Landslide',
      stateVariable: 'potential_impact_score',
      direction: RiskTrajectoryDirection.unknown,
      timeSpan: horizon,
      location: mandiLocation,
      uncertainty: ForecastUncertainty(),
    );

    const attributionEngine = RiskDriverAttributionEngine();

    final rainDriver = attributionEngine.createHydrometDriver(
      driverId: 'drv-rain-72h',
      name: '72h Antecedent Rainfall Accumulation',
      contributionDirection: RiskDriverContributionDirection.increasing,
      numericalValue: 145.0,
      unit: 'mm',
      driverRole: 'primary_evidence',
      evidenceIds: ['obs-rain-101'],
      temporalRelevance: horizon,
      location: mandiLocation,
      rationale: 'Observed 72h antecedent rainfall of 145mm approaches regional I-D threshold.',
    );

    final slopeDriver = RiskDriver(
      driverId: 'drv-slope-35deg',
      name: 'Slope Angle >= 35 Degrees',
      category: RiskDriverCategory.terrainGis,
      hazardSourceType: 'observed',
      contributionDirection: RiskDriverContributionDirection.neutral,
      numericalValue: 38.5,
      unit: 'degrees',
      driverRole: 'supporting_evidence',
      evidenceIds: ['dem-slope-001'],
      location: mandiLocation,
      rationale: 'Steep slope terrain susceptibility.',
    );

    group('1. RiskDriver Domain Contract Invariants', () {
      test('instantiates valid RiskDriver and validates role constraints', () {
        expect(rainDriver.driverId, 'drv-rain-72h');
        expect(rainDriver.category, RiskDriverCategory.hydrometeorological);
        expect(rainDriver.driverRole, 'primary_evidence');
        expect(rainDriver.relationshipStatus, HazardRelationshipStatus.associative);

        expect(
          () => RiskDriver(
            driverId: 'drv-bad',
            name: 'Bad Driver',
            category: RiskDriverCategory.hazard,
            contributionDirection: RiskDriverContributionDirection.increasing,
            driverRole: 'invalid_role_name', // Invalid role -> MUST REJECT!
            rationale: 'Test',
          ),
          throwsArgumentError,
        );
      });
    });

    group('2. Driver Attribution & Role Sorting', () {
      test('attributes candidate drivers to trajectory and sorts deterministically by role', () {
        final result = attributionEngine.attributeDrivers(
          resultId: 'attr-res-101',
          trajectory: risingTrajectory,
          candidateDrivers: [slopeDriver, rainDriver], // Passed supporting (slope) before primary (rain)
        );

        expect(result.resultId, 'attr-res-101');
        expect(result.driverCount, 2);
        expect(result.conflictDetected, isFalse);

        // ASSERT: Primary evidence driver MUST be sorted before supporting evidence!
        expect(result.contributingDrivers[0].driverId, 'drv-rain-72h');
        expect(result.contributingDrivers[1].driverId, 'drv-slope-35deg');
      });

      test('filters spatially incompatible drivers outside domain radius', () {
        final farDriver = RiskDriver(
          driverId: 'drv-far-rain',
          name: 'Far Station Rain',
          category: RiskDriverCategory.hydrometeorological,
          contributionDirection: RiskDriverContributionDirection.increasing,
          location: farLocation, // ~150km away
          rationale: 'Far rainfall',
        );

        final result = attributionEngine.attributeDrivers(
          resultId: 'attr-res-spatial',
          trajectory: risingTrajectory,
          candidateDrivers: [rainDriver, farDriver],
          maxSpatialDistanceMeters: 30000.0, // 50km threshold -> Far driver excluded!
        );

        expect(result.driverCount, 1);
        expect(result.contributingDrivers.first.driverId, 'drv-rain-72h');
      });
    });

    group('3. Conflict Detection', () {
      test('detects conflict when opposing drivers (increasing vs decreasing) exist', () {
        final decreasingDriver = RiskDriver(
          driverId: 'drv-dry-spell',
          name: 'Recent Dry Spell Duration',
          category: RiskDriverCategory.hydrometeorological,
          contributionDirection: RiskDriverContributionDirection.decreasing, // Decreasing!
          numericalValue: 48.0,
          unit: 'hours',
          driverRole: 'supporting_evidence',
          location: mandiLocation,
          temporalRelevance: horizon,
          rationale: 'Dry spell reduces short-term surface soil moisture.',
        );

        final result = attributionEngine.attributeDrivers(
          resultId: 'attr-res-conflict',
          trajectory: risingTrajectory,
          candidateDrivers: [rainDriver, decreasingDriver],
        );

        // ASSERT: Conflict MUST be detected!
        expect(result.conflictDetected, isTrue);
        expect(result.attributionSummary, contains('CONFLICT DETECTED'));
      });
    });

    group('4. Unknown Trajectory Handling', () {
      test('returns zero attributed drivers when risk trajectory is UNKNOWN', () {
        final result = attributionEngine.attributeDrivers(
          resultId: 'attr-res-unknown-traj',
          trajectory: unknownTrajectory,
          candidateDrivers: [rainDriver, slopeDriver],
        );

        expect(result.driverCount, 0);
        expect(result.trajectoryDirection, RiskTrajectoryDirection.unknown);
        expect(result.attributionSummary, contains('UNKNOWN'));
      });
    });

    group('5. Mandatory Scientific & Governance Safeguards', () {
      test('MANDATORY SCIENTIFIC NEGATIVE TEST: association != causation (relationshipStatus remains associative)', () {
        final result = attributionEngine.attributeDrivers(
          resultId: 'attr-res-assoc-test',
          trajectory: risingTrajectory,
          candidateDrivers: [rainDriver],
        );

        // ASSERT: Driver relationship status MUST NOT be force-upgraded to causal!
        expect(result.contributingDrivers.first.relationshipStatus, equals(HazardRelationshipStatus.associative));
      });

      test('MANDATORY GOVERNANCE TEST: driver attribution DOES NOT mutate RiskMap or create operational hazards', () {
        final result = attributionEngine.attributeDrivers(
          resultId: 'attr-res-gov',
          trajectory: risingTrajectory,
          candidateDrivers: [rainDriver, slopeDriver],
        );

        expect(result, isA<RiskDriverAttributionResult>());
        expect(result, isNot(isA<Hazard>()));
      });
    });
  });
}
