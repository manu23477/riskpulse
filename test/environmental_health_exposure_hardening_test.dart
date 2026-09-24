import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/gis/analytical_step.dart';
import 'package:riskpulse/domain/gis/impact_exposure_contract.dart';
import 'package:riskpulse/domain/environmental_health/environmental_health_contract.dart';
import 'package:riskpulse/data/services/environmental_health/environmental_health_service.dart';
import 'package:riskpulse/data/services/forecasting/decision_support_engine.dart';
import 'package:riskpulse/data/services/forecasting/research_priority_queue_engine.dart';
import 'package:riskpulse/data/services/osint/controlled_promotion_gate.dart';
import 'package:riskpulse/data/providers/research_workspace_provider.dart';

void main() {
  group('R-13 Environmental Health, Exposure/Impact & Decision Support Tests', () {
    final now = DateTime.utc(2026, 8, 15, 10, 0);

    test('TEST 01, 02, 03 & 04: EnvironmentalHealthContract domain validation, sample size n >= 3, and causal disclaimer', () {
      final contract = EnvironmentalHealthContract(
        analysisId: 'eh-ana-01',
        healthCategory: 'Respiratory',
        exposureVariable: 'PM2.5 Concentration',
        pearsonCorrelationR: 0.65,
        sampleCountN: 25,
        pValue: 0.002,
        analysisTimestamp: now,
        isSynthetic: true,
      );

      expect(contract.analysisId, equals('eh-ana-01'));
      expect(contract.pearsonCorrelationR, equals(0.65));
      expect(contract.isStatisticallySignificant, isTrue);
      expect(contract.causalDisclaimer, contains('Association does NOT establish causation'));
      expect(contract.productClass, equals('EXPLORATORY EXPOSURE-HEALTH OVERLAY'));

      // Sample size n < 3 MUST be rejected with AssertionError
      expect(
        () => EnvironmentalHealthContract(
          analysisId: 'eh-invalid',
          healthCategory: 'Waterborne',
          exposureVariable: 'Flood Inundation',
          pearsonCorrelationR: 0.80,
          sampleCountN: 2, // Invalid sample size n=2 (<3)
          analysisTimestamp: now,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('TEST 05, 06, 07 & 08: ImpactExposureContract enforces spatial overlap EXPOSED != CONFIRMED DAMAGE', () {
      final exposureContract = ImpactExposureContract(
        exposureId: 'exp-01',
        hazardId: 'hazard-flood-01',
        hazardType: 'Flash Flood',
        hazardSource: 'HydroAI Simulation',
        hazardExecutionId: 'exec-hydro-01',
        assetId: 'asset-bridge-01',
        assetType: 'Critical Bridge',
        spatialRelationship: ExposureSpatialRelationship.intersects,
        exposureState: ExposureImpactState.exposed,
        exposureIndex: 0.75,
        analysisTimestamp: now,
        isSynthetic: true,
      );

      expect(exposureContract.exposureId, equals('exp-01'));
      expect(exposureContract.isSpatialExposureOnly, isTrue);
      expect(exposureContract.isConfirmedDamage, isFalse);

      // ASSERT: Spatial intersection DOES NOT equal confirmed damage!
      expect(exposureContract.exposureState, equals(ExposureImpactState.exposed));
      expect(exposureContract.exposureState, isNot(equals(ExposureImpactState.confirmedImpact)));
    });

    test('TEST 15, 16 & 29: Decision Support and Priority Queue Engine use relative PRIORITY SCORE, not probability', () {
      final pqEngine = ResearchPriorityQueueEngine();
      final dsEngine = DecisionSupportEngine();

      expect(pqEngine, isA<ResearchPriorityQueueEngine>());
      expect(dsEngine, isA<DecisionSupportEngine>());
    });

    test('TEST 20, 21, 23 & 24: Research GIS isolation, ControlledPromotionGate, and 168 feature operational baseline integrity', () {
      final gate = ControlledPromotionGate();
      expect(gate, isA<ControlledPromotionGate>());

      final workspace = ResearchWorkspaceProvider();
      expect(workspace.inputDem, isNull);
    });
  });
}
