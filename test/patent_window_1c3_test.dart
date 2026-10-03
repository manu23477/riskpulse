import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

import '../research/patent_window_1/evidence_fusion/contracts/dependency_contract.dart';
import '../research/patent_window_1/evidence_fusion/contracts/metric_contract.dart';
import '../research/patent_window_1/evidence_fusion/contracts/mutation_contract.dart';
import '../research/patent_window_1/evidence_fusion/contracts/state_history_contract.dart';
import '../research/patent_window_1/evidence_fusion/harness/experiment_configuration.dart';
import '../research/patent_window_1/evidence_fusion/harness/visible_dataset_loader.dart';
import '../research/patent_window_1/evidence_fusion/models/advanced_dependency_graph_model.dart';
import '../research/patent_window_1/evidence_fusion/models/multi_generation_state_history_model.dart';
import '../research/patent_window_1/evidence_fusion/models/model_c_evidence_graph_contract.dart';

void main() {
  group('PATENT WINDOW 1C-3 — Deep Mutation, State Reconstruction & Adversarial Propagation Suite', () {
    late VisibleDatasetLoader loader;
    late List<VisibleEvidenceObject> visibleDataset;

    setUpAll(() {
      loader = VisibleDatasetLoader();
      visibleDataset = loader.loadAndValidateVisibleDataset();
    });

    test('1. Frozen dataset immutability verification', () {
      expect(visibleDataset.length, equals(678));
    });

    test('2. Mutation fixture immutability verification', () {
      final fixtureFile = File('research/patent_window_1/evidence_fusion/fixtures/pw1c3_mutation_scenarios.json');
      expect(fixtureFile.existsSync(), isTrue);

      final scenarios = jsonDecode(fixtureFile.readAsStringSync()) as List<dynamic>;
      expect(scenarios.length, equals(20));
    });

    test('3. 1C-3A: 7-generation cascading state history creation (V1..V7)', () async {
      final historyEngine = MultiGenerationStateHistoryEngine();
      final case01Ev = visibleDataset.where((e) => e.caseId == 'CASE-01').toList();
      final modelC = ModelCEvidenceGraph();

      for (int v = 1; v <= 7; v++) {
        final hyp = await modelC.process(
          visibleEvidence: case01Ev,
          configuration: ExperimentConfiguration(
            experimentId: 'PW1C3-V$v',
            datasetVersion: 'PW1C1-DATA-v1.0',
            modelId: modelC.modelId,
            modelVersion: modelC.modelVersion,
            parameterSet: modelC.parameterSet,
            arrivalOrderMode: 'chronological',
            randomSeed: 20260929,
            executionTimestamp: '2026-09-30T13:00:00Z',
          ),
        );

        historyEngine.appendVersion(
          caseId: 'CASE-01',
          currentEvidence: case01Ev,
          hypotheses: hyp,
          triggeringMutationId: v > 1 ? 'MUT3-01-V$v' : null,
        );
      }

      final history = historyEngine.caseHistories['CASE-01'];
      expect(history, isNotNull);
      expect(history!.versions.length, equals(7));
      expect(history.currentVersion.versionNumber, equals(7));
    });

    test('4. 1C-3C: Non-sequential historical reconstruction (V4, V1, V7, V3, V6, V2, V5)', () async {
      final historyEngine = MultiGenerationStateHistoryEngine();
      final case01Ev = visibleDataset.where((e) => e.caseId == 'CASE-01').toList();
      final modelC = ModelCEvidenceGraph();

      for (int v = 1; v <= 7; v++) {
        final hyp = await modelC.process(
          visibleEvidence: case01Ev,
          configuration: ExperimentConfiguration(
            experimentId: 'PW1C3-V$v',
            datasetVersion: 'PW1C1-DATA-v1.0',
            modelId: modelC.modelId,
            modelVersion: modelC.modelVersion,
            parameterSet: modelC.parameterSet,
            arrivalOrderMode: 'chronological',
            randomSeed: 20260929,
            executionTimestamp: '2026-09-30T13:00:00Z',
          ),
        );

        historyEngine.appendVersion(
          caseId: 'CASE-01',
          currentEvidence: case01Ev,
          hypotheses: hyp,
          triggeringMutationId: v > 1 ? 'MUT3-01-V$v' : null,
        );
      }

      final requestedOrder = [4, 1, 7, 3, 6, 2, 5];
      final reconstructed = historyEngine.reconstructNonSequentialHistory('CASE-01', requestedOrder);

      expect(reconstructed.keys.toList(), equals(requestedOrder));
      expect(reconstructed[4]!.versionNumber, equals(4));
      expect(reconstructed[1]!.versionNumber, equals(1));
      expect(reconstructed[7]!.versionNumber, equals(7));
    });

    test('5. 1C-3C: Historical state immutability audit (V1..V5 unchanged after V6 mutation)', () async {
      final historyEngine = MultiGenerationStateHistoryEngine();
      final case01Ev = visibleDataset.where((e) => e.caseId == 'CASE-01').toList();
      final modelC = ModelCEvidenceGraph();

      final priorVersions = <EventStateVersion>[];
      for (int v = 1; v <= 5; v++) {
        final hyp = await modelC.process(
          visibleEvidence: case01Ev,
          configuration: ExperimentConfiguration(
            experimentId: 'PW1C3-V$v',
            datasetVersion: 'PW1C1-DATA-v1.0',
            modelId: modelC.modelId,
            modelVersion: modelC.modelVersion,
            parameterSet: modelC.parameterSet,
            arrivalOrderMode: 'chronological',
            randomSeed: 20260929,
            executionTimestamp: '2026-09-30T13:00:00Z',
          ),
        );

        final ver = historyEngine.appendVersion(caseId: 'CASE-01', currentEvidence: case01Ev, hypotheses: hyp);
        priorVersions.add(ver);
      }

      // Add V6 mutation
      final hypV6 = await modelC.process(
        visibleEvidence: case01Ev,
        configuration: ExperimentConfiguration(
          experimentId: 'PW1C3-V6',
          datasetVersion: 'PW1C1-DATA-v1.0',
          modelId: modelC.modelId,
          modelVersion: modelC.modelVersion,
          parameterSet: modelC.parameterSet,
          arrivalOrderMode: 'chronological',
          randomSeed: 20260929,
          executionTimestamp: '2026-09-30T13:00:00Z',
        ),
      );
      historyEngine.appendVersion(caseId: 'CASE-01', currentEvidence: case01Ev, hypotheses: hypV6, triggeringMutationId: 'MUT3-01-V6');

      final isImm = historyEngine.verifyHistoricalImmutability('CASE-01', priorVersions);
      expect(isImm, isTrue);
    });

    test('6. 1C-3B: Multi-event shared administrative dependency graph propagation', () {
      final graphEngine = AdvancedDependencyGraphEngine();
      final case35Ev = visibleDataset.where((e) => e.caseId == 'CASE-35').toList();

      graphEngine.buildAdvancedGraphForCase('CASE-35', case35Ev, isMultiEvent: true);

      final targetEvId = case35Ev.first.evidenceId;
      final closure = graphEngine.computeTransitiveClosure('NODE-EV-$targetEvId');

      expect(closure.contains('NODE-EV-$targetEvId'), isTrue);
      expect(closure.contains('NODE-ADM-CASE-35-SHARED'), isTrue);
      expect(closure.contains('NODE-RISK-CASE-35-SHARED'), isTrue);
      expect(closure.contains('NODE-HYP-CASE-35-EVTB'), isFalse, reason: 'Event B hypothesis must remain unpoisoned');
    });

    test('7. 1C-3F: Three-Way Strategy Comparison (Selective vs Full Rebuild vs Naive Global Invalidation)', () {
      final graphEngine = AdvancedDependencyGraphEngine();
      final case01Ev = visibleDataset.where((e) => e.caseId == 'CASE-01').toList();
      graphEngine.buildAdvancedGraphForCase('CASE-01', case01Ev);

      final mut = EvidenceMutationEvent(
        mutationId: 'MUT3-15',
        targetEvidenceId: case01Ev.first.evidenceId,
        targetCaseId: 'CASE-01',
        mutationType: 'three_way_comparison',
        mutationTimestamp: '2026-09-30T13:10:00Z',
        attributeChanges: const {'isValid': false},
        description: 'Strategy comparison test',
      );

      final comparison = graphEngine.evaluateStrategyComparison(mutation: mut);

      expect(comparison.selectivePropagationEvaluations, lessThan(comparison.fullRebuildEvaluations));
      expect(comparison.reductionVsFullRebuildPct, greaterThan(50.0));
      expect(comparison.selectiveEqualsFullRebuild, isTrue);
    });

    test('8. 1C-3 Result Artifacts Verification', () {
      final resultsDir = Directory('research/patent_window_1/evidence_fusion/experiments/results/PW1C3');
      expect(resultsDir.existsSync(), isTrue);

      final manifestFile = File('${resultsDir.path}/experiment_manifest.json');
      final aggFile = File('${resultsDir.path}/aggregate_metrics.json');
      expect(manifestFile.existsSync(), isTrue);
      expect(aggFile.existsSync(), isTrue);

      final manifest = jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
      expect(manifest['experimentId'], equals('PW1C3'));
      expect(manifest['cumulativeRebuildReductionPercentage'], greaterThan(80.0));
    });
  });
}
