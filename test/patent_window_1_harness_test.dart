import 'package:flutter_test/flutter_test.dart';

import '../research/patent_window_1/evidence_fusion/contracts/experiment_model_contract.dart';
import '../research/patent_window_1/evidence_fusion/contracts/experiment_result.dart';
import '../research/patent_window_1/evidence_fusion/contracts/metric_contract.dart';
import '../research/patent_window_1/evidence_fusion/contracts/model_output_contract.dart';
import '../research/patent_window_1/evidence_fusion/harness/experiment_configuration.dart';
import '../research/patent_window_1/evidence_fusion/harness/ground_truth_evaluator.dart';
import '../research/patent_window_1/evidence_fusion/harness/visible_dataset_loader.dart';
import '../research/patent_window_1/evidence_fusion/models/model_a_weighted_fusion_contract.dart';
import '../research/patent_window_1/evidence_fusion/models/model_b_bayesian_updating_contract.dart';
import '../research/patent_window_1/evidence_fusion/models/model_c_evidence_graph_contract.dart';

void main() {
  group('PATENT WINDOW 1C-1B — Experimental Fusion Harness Contract Suite', () {
    late VisibleDatasetLoader visibleLoader;
    late GroundTruthEvaluator evaluator;
    late List<VisibleEvidenceObject> visibleDataset;

    setUpAll(() {
      visibleLoader = VisibleDatasetLoader();
      evaluator = GroundTruthEvaluator();
      visibleDataset = visibleLoader.loadAndValidateVisibleDataset();
    });

    test('1. Visible dataset loading and SHA-256 manifest verification', () {
      expect(visibleDataset.length, equals(678));
      expect(visibleDataset.first.caseId, equals('CASE-01'));
      expect(visibleDataset.first.evidenceId, equals('EVID-0001'));
    });

    test('2. Ground-truth isolation: VisibleDatasetLoader excludes ground truth', () {
      final sample = visibleDataset.first.toJson();
      final forbiddenKeys = [
        'trueEventId',
        'trueCoordinates',
        'trueHazard',
        'trueLineage',
        'trueRelationship',
        'trueEventTime',
        'trueEventState',
        'geometry',
        'events'
      ];

      for (final forbidden in forbiddenKeys) {
        expect(sample.containsKey(forbidden), isFalse, reason: 'Visible object must not contain ground truth key $forbidden');
      }
    });

    test('3. Common model interface conformance across Models A, B, and C', () {
      final models = <ExperimentModel>[
        ModelAWeightedFusion(),
        ModelBBayesianUpdating(),
        ModelCEvidenceGraph(),
      ];

      for (final model in models) {
        expect(model.modelId.isNotEmpty, isTrue);
        expect(model.modelVersion, equals('1.0.0'));
        expect(model.parameterSet.isNotEmpty, isTrue);
      }
    });

    test('4. Common output contract ExperimentEventHypothesis format', () async {
      final modelA = ModelAWeightedFusion();
      final config = ExperimentConfiguration(
        experimentId: 'EXP-TEST-01',
        datasetVersion: 'PW1C1-DATA-v1.0',
        modelId: modelA.modelId,
        modelVersion: modelA.modelVersion,
        parameterSet: modelA.parameterSet,
        arrivalOrderMode: 'chronological',
        randomSeed: 20260929,
        executionTimestamp: '2026-09-29T13:00:00Z',
      );

      final case01Evidence = visibleDataset.where((e) => e.caseId == 'CASE-01').toList();
      final hypotheses = await modelA.process(visibleEvidence: case01Evidence, configuration: config);

      expect(hypotheses.isNotEmpty, isTrue);
      final hyp = hypotheses.first;

      expect(hyp.eventHypothesisId, equals('HYP-MODA-CASE-01-01'));
      expect(hyp.hazardType, equals('landslide'));
      expect(hyp.candidateGeometry.containsKey('type'), isTrue);
      expect(hyp.supportingEvidenceIds.length, equals(case01Evidence.length));
      expect(hyp.confidenceComponents.sourceReliabilityScore, greaterThan(0.0));
      expect(hyp.overallConfidence, greaterThan(0.0));
    });

    test('5. Model A contract: Conventional weighted fusion baseline parameters', () {
      final modelA = ModelAWeightedFusion(
        sourceReliabilityWeight: 0.30,
        semanticAgreementWeight: 0.30,
        spatialAgreementWeight: 0.20,
        temporalAgreementWeight: 0.20,
      );

      expect(modelA.parameterSet['sourceReliabilityWeight'], equals(0.30));
      expect(modelA.parameterSet['semanticAgreementWeight'], equals(0.30));
      expect(modelA.parameterSet['spatialAgreementWeight'], equals(0.20));
      expect(modelA.parameterSet['temporalAgreementWeight'], equals(0.20));
    });

    test('6. Model B contract: Bayesian updating baseline parameters', () {
      final modelB = ModelBBayesianUpdating(
        priorProbability: 0.40,
        likelihoodRatioCorroborating: 3.0,
        likelihoodRatioContradicting: 0.20,
      );

      expect(modelB.parameterSet['priorProbability'], equals(0.40));
      expect(modelB.parameterSet['likelihoodRatioCorroborating'], equals(3.0));
      expect(modelB.parameterSet['likelihoodRatioContradicting'], equals(0.20));
    });

    test('7. Model C contract: Evidence-state graph model parameters', () {
      final modelC = ModelCEvidenceGraph(
        enableEchoCancellation: true,
        enableLineagePruning: true,
        contradictionWeightPenalty: 0.50,
      );

      expect(modelC.parameterSet['enableEchoCancellation'], isTrue);
      expect(modelC.parameterSet['enableLineagePruning'], isTrue);
      expect(modelC.parameterSet['contradictionWeightPenalty'], equals(0.50));
    });

    test('8. Ground-truth evaluator case metrics evaluation', () async {
      final modelA = ModelAWeightedFusion();
      final config = ExperimentConfiguration(
        experimentId: 'EXP-TEST-02',
        datasetVersion: 'PW1C1-DATA-v1.0',
        modelId: modelA.modelId,
        modelVersion: modelA.modelVersion,
        parameterSet: modelA.parameterSet,
        arrivalOrderMode: 'chronological',
        randomSeed: 20260929,
        executionTimestamp: '2026-09-29T13:00:00Z',
      );

      final case01Evidence = visibleDataset.where((e) => e.caseId == 'CASE-01').toList();
      final hypotheses = await modelA.process(visibleEvidence: case01Evidence, configuration: config);

      final caseResult = evaluator.evaluateCase(caseId: 'CASE-01', hypotheses: hypotheses);

      expect(caseResult.caseId, equals('CASE-01'));
      expect(caseResult.metrics.eventAssociationAccuracy, greaterThan(0.0));
      expect(caseResult.metrics.lineageAccuracy, greaterThan(0.0));
    });

    test('9. Arrival-order permutation modes support', () {
      final perms = evaluator.getArrivalOrderPermutations('CASE-40');
      expect(perms, isNotNull);
      expect(perms!.containsKey('sequenceA_chronological'), isTrue);
      expect(perms.containsKey('sequenceB_shuffled'), isTrue);
      expect(perms.containsKey('sequenceC_reverse'), isTrue);
    });

    test('10. Metric contract: All 12 neutral metric fields represented', () {
      const metrics = ExperimentMetrics(
        eventAssociationAccuracy: 0.95,
        falseMergeRate: 0.02,
        falseSplitRate: 0.01,
        lineageAccuracy: 0.92,
        spatialErrorMeters: 45.0,
        spatialPrecisionInflationRatio: 1.05,
        temporalErrorSeconds: 120.0,
        temporalPrecisionInflationRatio: 1.02,
        contradictionRetentionRate: 0.98,
        provenanceCompletenessRatio: 1.0,
        stateReconstructionAccuracy: 0.96,
        arrivalOrderRobustness: 0.99,
      );

      final json = metrics.toJson();
      expect(json.keys.length, greaterThanOrEqualTo(12));
    });

    test('11. Failure recording: Inspectable FailureRecord representation', () {
      const failure = FailureRecord(
        failureType: 'false_merge',
        description: 'Merged 2 distinct events',
        relevantEvidenceIds: ['EVID-0001', 'EVID-0002'],
      );

      expect(failure.failureType, equals('false_merge'));
      expect(failure.relevantEvidenceIds.length, equals(2));
    });

    test('12. Reproducibility metadata in ExperimentConfiguration', () {
      final config = ExperimentConfiguration(
        experimentId: 'EXP-DETERMINISTIC-01',
        datasetVersion: 'PW1C1-DATA-v1.0',
        modelId: 'model_a_weighted_fusion',
        modelVersion: '1.0.0',
        parameterSet: {'weight': 0.5},
        arrivalOrderMode: 'chronological',
        randomSeed: 20260929,
        executionTimestamp: '2026-09-29T13:00:00Z',
      );

      expect(config.randomSeed, equals(20260929));
      expect(config.datasetVersion, equals('PW1C1-DATA-v1.0'));
    });
  });
}
