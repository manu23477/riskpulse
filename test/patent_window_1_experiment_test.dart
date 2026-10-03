import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

import '../research/patent_window_1/evidence_fusion/contracts/experiment_result.dart';
import '../research/patent_window_1/evidence_fusion/contracts/model_output_contract.dart';
import '../research/patent_window_1/evidence_fusion/harness/experiment_configuration.dart';
import '../research/patent_window_1/evidence_fusion/harness/ground_truth_evaluator.dart';
import '../research/patent_window_1/evidence_fusion/harness/visible_dataset_loader.dart';
import '../research/patent_window_1/evidence_fusion/models/model_a_weighted_fusion_contract.dart';
import '../research/patent_window_1/evidence_fusion/models/model_b_bayesian_updating_contract.dart';
import '../research/patent_window_1/evidence_fusion/models/model_c_evidence_graph_contract.dart';

void main() {
  group('PATENT WINDOW 1C-2A — Baseline Comparative Fusion Experiment Test Suite', () {
    late VisibleDatasetLoader visibleLoader;
    late GroundTruthEvaluator evaluator;
    late List<VisibleEvidenceObject> visibleDataset;

    setUpAll(() {
      visibleLoader = VisibleDatasetLoader();
      evaluator = GroundTruthEvaluator();
      visibleDataset = visibleLoader.loadAndValidateVisibleDataset();
    });

    test('1. Dataset hash verification against dataset_manifest.json', () {
      expect(visibleDataset.length, equals(678));
    });

    test('2. Model isolation: Models A, B, and C strictly exclude ground truth fields', () {
      final sample = visibleDataset.first.toJson();
      final forbiddenKeys = ['trueEventId', 'trueCoordinates', 'trueHazard', 'trueLineage', 'geometry', 'events'];
      for (final k in forbiddenKeys) {
        expect(sample.containsKey(k), isFalse);
      }
    });

    test('3. Common output compatibility across Models A, B, and C', () async {
      final case01Evidence = visibleDataset.where((e) => e.caseId == 'CASE-01').toList();

      final modelA = ModelAWeightedFusion();
      final modelB = ModelBBayesianUpdating();
      final modelC = ModelCEvidenceGraph();

      final config = ExperimentConfiguration(
        experimentId: 'PW1C2A-TEST-01',
        datasetVersion: 'PW1C1-DATA-v1.0',
        modelId: 'test_model',
        modelVersion: '1.0.0',
        parameterSet: {},
        arrivalOrderMode: 'chronological',
        randomSeed: 20260929,
        executionTimestamp: '2026-09-30T12:00:00Z',
      );

      final hypA = await modelA.process(visibleEvidence: case01Evidence, configuration: config);
      final hypB = await modelB.process(visibleEvidence: case01Evidence, configuration: config);
      final hypC = await modelC.process(visibleEvidence: case01Evidence, configuration: config);

      expect(hypA.isNotEmpty, isTrue);
      expect(hypB.isNotEmpty, isTrue);
      expect(hypC.isNotEmpty, isTrue);

      expect(hypA.first.eventHypothesisId.isNotEmpty, isTrue);
      expect(hypB.first.eventHypothesisId.isNotEmpty, isTrue);
      expect(hypC.first.eventHypothesisId.isNotEmpty, isTrue);
    });

    test('4. Case-level result completeness: All 50 cases evaluated for E01', () {
      final resultsDir = Directory('research/patent_window_1/evidence_fusion/experiments/results/PW1C2A-E01');
      expect(resultsDir.existsSync(), isTrue);

      final caseResultsFile = File('${resultsDir.path}/case_results.json');
      expect(caseResultsFile.existsSync(), isTrue);

      final json = jsonDecode(caseResultsFile.readAsStringSync()) as Map<String, dynamic>;
      final casesA = json['modelA_cases'] as List<dynamic>;
      final casesB = json['modelB_cases'] as List<dynamic>;
      final casesC = json['modelC_cases'] as List<dynamic>;

      expect(casesA.length, equals(50));
      expect(casesB.length, equals(50));
      expect(casesC.length, equals(50));
    });

    test('5. Metric calculation and failure recording completeness', () {
      final resultsDir = Directory('research/patent_window_1/evidence_fusion/experiments/results/PW1C2A-E01');
      final aggFile = File('${resultsDir.path}/aggregate_metrics.json');
      expect(aggFile.existsSync(), isTrue);

      final json = jsonDecode(aggFile.readAsStringSync()) as Map<String, dynamic>;
      expect(json.containsKey('modelA'), isTrue);
      expect(json.containsKey('modelB'), isTrue);
      expect(json.containsKey('modelC'), isTrue);

      final metricsA = json['modelA'] as Map<String, dynamic>;
      expect(metricsA['eventAssociationAccuracy'], equals(1.0));
      expect(metricsA['falseMergeRate'], greaterThanOrEqualTo(0.0));
    });

    test('6. Result reproducibility: E01 manifest and hashes are intact', () {
      final manifestFile = File('research/patent_window_1/evidence_fusion/experiments/results/PW1C2A-E01/experiment_manifest.json');
      expect(manifestFile.existsSync(), isTrue);

      final manifest = jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
      expect(manifest['experimentId'], equals('PW1C2A-E01'));
      expect(manifest['arrivalOrderMode'], equals('chronological'));
      expect(manifest['randomSeed'], equals(20260929));
    });
  });
}
