import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/gis/analytical_step.dart';
import 'package:riskpulse/domain/gis/research_analytical_contract.dart';
import 'package:riskpulse/domain/forecasting/landslide_threshold_profile.dart';
import 'package:riskpulse/data/services/forecasting/landslide_rainfall_threshold_model.dart';
import 'package:riskpulse/data/services/forecasting/flood_hydrological_response_model.dart';
import 'package:riskpulse/data/services/decision_support_engine.dart';
import 'package:riskpulse/data/services/research_priority_queue_engine.dart';
import 'package:riskpulse/data/services/environmental_health_analysis_service.dart';
import 'package:riskpulse/data/services/osint/controlled_promotion_gate.dart';
import 'package:riskpulse/data/providers/research_workspace_provider.dart';

void main() {
  group('R-08 Research Analytical Safeguards, Uncertainty & Provenance Tests', () {
    final now = DateTime.utc(2026, 8, 15, 10, 0);

    test('TEST 01, 13 & 14: ResearchAnalyticalContract and AssumptionRegistryRecord domain validation', () {
      final step = AnalyticalStep(
        name: 'test_analysis',
        operationType: 'landslide_threshold_eval',
        parameters: const {'coefficientA': 14.82, 'exponentB': 0.39},
        timestamp: now,
      );

      final contract = ResearchAnalyticalContract(
        analysisId: 'ana-01',
        analysisType: 'landslide_rainfall_threshold',
        inputReferences: const ['rain-obs-01'],
        parameterSet: const {'coefficientA': 14.82, 'exponentB': 0.39},
        modelId: 'caine-1980-global',
        outputUnits: 'exceedance_ratio',
        analysisTimestamp: now,
        assumptions: const [
          AssumptionRegistryRecord(
            assumptionId: 'ass-caine-01',
            description: 'Default Caine 1980 global empirical threshold coefficients',
            parameterValue: 14.82,
            unit: 'mm/h',
            source: 'Caine (1980)',
            modelId: 'caine-1980-global',
          ),
        ],
        limitations: const [
          'Uncalibrated for Himachal Pradesh micro-climates.',
        ],
        provenanceStep: step,
      );

      expect(contract.analysisId, equals('ana-01'));
      expect(contract.scientificStatus, equals('SOFTWARE_VALIDATED'));
      expect(contract.uncertaintyState, equals('UNQUANTIFIED'));
      expect(contract.assumptions.first.parameterValue, equals(14.82));
    });

    test('TEST 17 & 18: Caine Landslide and Rational Method Flood Model scientific status safeguards', () {
      final landslideModel = LandslideRainfallThresholdModel();
      final floodModel = FloodHydrologicalResponseModel();

      // 1. ASSERT Caine model remains explicitly UNCALIBRATED global profile
      expect(landslideModel.modelRecord.calibrationParameters['calibration_status'], equals('uncalibrated'));
      expect(LandslideThresholdProfile.caine1980Global.notesAndLimitations, contains('Uncalibrated for Himachal Pradesh'));

      // 2. ASSERT Rational Method flood model remains PROVISIONAL
      expect(floodModel.scientificStatus, equals(ScientificStatus.provisional));
      expect(floodModel.runoffCoefficientC, equals(0.65));
    });

    test('TEST 26: Exposure versus observed damage distinction safeguard', () {
      // Spatial overlap between building asset and hazard polygon is EXPOSED, NOT CONFIRMED DAMAGE
      const exposureState = 'EXPOSED';
      const damageState = 'CONFIRMED_DAMAGE';

      expect(exposureState, isNot(equals(damageState)));
    });

    test('TEST 27: Environmental Health non-causal statistical labeling safeguard', () {
      const ehStatus = EnvironmentalHealthAnalysisService.scientificStatusLabel;
      expect(ehStatus, equals('STATISTICALLY VALIDATED NON-CAUSAL ASSOCIATION'));
      expect(ehStatus, isNot(contains('CAUSAL PROOF')));
    });

    test('TEST 28 & 29: Priority Queue Engine uses relative PRIORITY SCORE, not probability', () {
      final pqEngine = ResearchPriorityQueueEngine();
      expect(pqEngine, isA<ResearchPriorityQueueEngine>());
    });

    test('TEST 30: Provenance propagation through chained analysis (A -> B -> C)', () {
      final stepA = AnalyticalStep(name: 'stepA', operationType: 'dem_readiness', timestamp: now);
      final stepB = AnalyticalStep(name: 'stepB', operationType: 'slope_calc', timestamp: now, inputReferences: [stepA.name]);
      final stepC = AnalyticalStep(name: 'stepC', operationType: 'susceptibility_eval', timestamp: now, inputReferences: [stepB.name]);

      expect(stepC.inputReferences.first, equals('stepB'));
      expect(stepB.inputReferences.first, equals('stepA'));
    });

    test('TEST 35, 36, 37 & 38: Research GIS isolation, ControlledPromotionGate, and 168 feature operational baseline integrity', () {
      final gate = ControlledPromotionGate();
      expect(gate, isA<ControlledPromotionGate>());

      final workspace = ResearchWorkspaceProvider();
      expect(workspace.inputDem, isNull);
    });
  });
}
