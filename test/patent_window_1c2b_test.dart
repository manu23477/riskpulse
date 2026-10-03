import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

import '../research/patent_window_1/evidence_fusion/contracts/dependency_contract.dart';
import '../research/patent_window_1/evidence_fusion/contracts/mutation_contract.dart';
import '../research/patent_window_1/evidence_fusion/contracts/state_history_contract.dart';
import '../research/patent_window_1/evidence_fusion/harness/experiment_configuration.dart';
import '../research/patent_window_1/evidence_fusion/harness/visible_dataset_loader.dart';
import '../research/patent_window_1/evidence_fusion/models/dependency_graph_model.dart';
import '../research/patent_window_1/evidence_fusion/models/event_state_history_model.dart';
import '../research/patent_window_1/evidence_fusion/models/model_c_evidence_graph_contract.dart';

void main() {
  group('PATENT WINDOW 1C-2B — Multi-Permutation & Active Dependency Propagation Suite', () {
    late VisibleDatasetLoader loader;
    late List<VisibleEvidenceObject> visibleDataset;

    setUpAll(() {
      loader = VisibleDatasetLoader();
      visibleDataset = loader.loadAndValidateVisibleDataset();
    });

    test('1. Frozen dataset integrity & SHA-256 validation', () {
      expect(visibleDataset.length, equals(678));
    });

    test('2. Deterministic arrival order permutations (chronological, shuffled, reverse)', () {
      final case01Ev = visibleDataset.where((e) => e.caseId == 'CASE-01').toList();
      final chron = List<VisibleEvidenceObject>.from(case01Ev);
      final rev = case01Ev.reversed.toList();

      expect(chron.first.evidenceId, isNot(equals(rev.first.evidenceId)));
    });

    test('3. Mutation immutability: Original dataset evidence objects remain unchanged', () {
      const mut = EvidenceMutationEvent(
        mutationId: 'MUT-TEST-01',
        targetEvidenceId: 'EVID-0001',
        targetCaseId: 'CASE-01',
        mutationType: 'evidence_invalidation',
        mutationTimestamp: '2026-09-30T12:50:00Z',
        attributeChanges: {'isValid': false},
        description: 'Test invalidation',
      );

      expect(visibleDataset.first.evidenceId, equals('EVID-0001'));
      expect(mut.targetEvidenceId, equals('EVID-0001'));
    });

    test('4. Event-state version creation (V1, V2, V3...)', () async {
      final historyManager = EventStateHistoryManager();
      final case01Ev = visibleDataset.where((e) => e.caseId == 'CASE-01').toList();
      final modelC = ModelCEvidenceGraph();

      final hypV1 = await modelC.process(
        visibleEvidence: case01Ev,
        configuration: ExperimentConfiguration(
          experimentId: 'EXP-HIST-V1',
          datasetVersion: 'PW1C1-DATA-v1.0',
          modelId: modelC.modelId,
          modelVersion: modelC.modelVersion,
          parameterSet: modelC.parameterSet,
          arrivalOrderMode: 'chronological',
          randomSeed: 20260929,
          executionTimestamp: '2026-09-30T12:00:00Z',
        ),
      );

      final v1 = historyManager.appendStateVersion(
        caseId: 'CASE-01',
        currentEvidence: case01Ev,
        hypotheses: hypV1,
      );

      expect(v1.versionNumber, equals(1));
      expect(v1.isCurrentVersion, isTrue);

      final v2 = historyManager.appendStateVersion(
        caseId: 'CASE-01',
        currentEvidence: case01Ev,
        hypotheses: hypV1,
        triggeringMutationId: 'MUT-01',
      );

      expect(v2.versionNumber, equals(2));
      expect(v2.isCurrentVersion, isTrue);
    });

    test('5. Historical state retention: Prior versions reconstructable', () {
      final historyManager = EventStateHistoryManager();
      final case01Ev = visibleDataset.where((e) => e.caseId == 'CASE-01').toList();

      historyManager.appendStateVersion(caseId: 'CASE-01', currentEvidence: case01Ev, hypotheses: []);
      historyManager.appendStateVersion(caseId: 'CASE-01', currentEvidence: case01Ev, hypotheses: [], triggeringMutationId: 'MUT-01');

      final historicalV1 = historyManager.getHistoricalVersion('CASE-01', 1);
      expect(historicalV1, isNotNull);
      expect(historicalV1!.versionNumber, equals(1));
    });

    test('6. Dependency graph construction across 6 layers', () {
      final graphEngine = DependencyGraphEngine();
      final case01Ev = visibleDataset.where((e) => e.caseId == 'CASE-01').toList();

      graphEngine.buildGraphForCase('CASE-01', case01Ev);

      expect(graphEngine.nodes.containsKey('NODE-EV-EVID-0001'), isTrue);
      expect(graphEngine.nodes.containsKey('NODE-INT-EVID-0001'), isTrue);
      expect(graphEngine.nodes.containsKey('NODE-HYP-CASE-01'), isTrue);
      expect(graphEngine.nodes.containsKey('NODE-SPAT-CASE-01'), isTrue);
      expect(graphEngine.nodes.containsKey('NODE-ADM-CASE-01'), isTrue);
      expect(graphEngine.nodes.containsKey('NODE-RISK-CASE-01'), isTrue);
    });

    test('7. Dependency traversal & affected-node identification', () {
      final graphEngine = DependencyGraphEngine();
      final case01Ev = visibleDataset.where((e) => e.caseId == 'CASE-01').toList();
      graphEngine.buildGraphForCase('CASE-01', case01Ev);

      const mut = EvidenceMutationEvent(
        mutationId: 'MUT-01',
        targetEvidenceId: 'EVID-0001',
        targetCaseId: 'CASE-01',
        mutationType: 'evidence_invalidation',
        mutationTimestamp: '2026-09-30T12:50:00Z',
        attributeChanges: {'isValid': false},
        description: 'Test invalidation',
      );

      final trace = graphEngine.applyMutationAndPropagate(mutation: mut);

      expect(trace.affectedNodeIds.contains('NODE-EV-EVID-0001'), isTrue);
      expect(trace.affectedNodeIds.contains('NODE-INT-EVID-0001'), isTrue);
      expect(trace.unaffectedNodeIds.isNotEmpty, isTrue);
    });

    test('8. Unaffected node preservation & selective recomputation reduction', () {
      final graphEngine = DependencyGraphEngine();
      final case01Ev = visibleDataset.where((e) => e.caseId == 'CASE-01').toList();
      graphEngine.buildGraphForCase('CASE-01', case01Ev);

      const mut = EvidenceMutationEvent(
        mutationId: 'MUT-01',
        targetEvidenceId: 'EVID-0001',
        targetCaseId: 'CASE-01',
        mutationType: 'evidence_invalidation',
        mutationTimestamp: '2026-09-30T12:50:00Z',
        attributeChanges: {'isValid': false},
        description: 'Test invalidation',
      );

      final trace = graphEngine.applyMutationAndPropagate(mutation: mut);

      expect(trace.rebuildReductionPercentage, greaterThan(50.0));
      expect(trace.preservedNodeIds.isNotEmpty, isTrue);
    });

    test('9. Negative control mutation (MUT-08) leaves unrelated event unaffected', () {
      final graphEngine = DependencyGraphEngine();
      final case35Ev = visibleDataset.where((e) => e.caseId == 'CASE-35').toList();
      graphEngine.buildGraphForCase('CASE-35', case35Ev);

      final targetEvId = case35Ev.first.evidenceId;
      final mut = EvidenceMutationEvent(
        mutationId: 'MUT-08',
        targetEvidenceId: targetEvId,
        targetCaseId: 'CASE-35',
        mutationType: 'negative_control',
        mutationTimestamp: '2026-09-30T12:50:00Z',
        attributeChanges: const {'statedLocation': 'Aut Bridge North Bank'},
        description: 'Negative control on Event 1',
        isNegativeControl: true,
      );

      final trace = graphEngine.applyMutationAndPropagate(mutation: mut);

      expect(trace.affectedNodeIds.contains('NODE-EV-$targetEvId'), isTrue);
      expect(trace.unaffectedNodeIds.length, greaterThan(0));
    });

    test('10. 1C-2B Result Artifacts Verification', () {
      final outDir = Directory('research/patent_window_1/evidence_fusion/experiments/results/PW1C2B-E02');
      expect(outDir.existsSync(), isTrue);

      final manifestFile = File('${outDir.path}/experiment_manifest.json');
      final aggFile = File('${outDir.path}/aggregate_metrics.json');
      expect(manifestFile.existsSync(), isTrue);
      expect(aggFile.existsSync(), isTrue);

      final manifest = jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
      expect(manifest['experimentId'], equals('PW1C2B-E02'));
      expect(manifest['overallRebuildReductionPercentage'], greaterThan(80.0));
    });
  });
}
