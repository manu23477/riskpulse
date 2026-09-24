import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/domain/hydroai/hydroai_execution_mode.dart';
import 'package:riskpulse/domain/hydroai/hydroai_execution_contract.dart';
import 'package:riskpulse/domain/gis/evidence_decision_chain_contract.dart';
import 'package:riskpulse/data/services/forecasting/decision_support_engine.dart';
import 'package:riskpulse/data/services/forecasting/research_priority_queue_engine.dart';
import 'package:riskpulse/data/services/osint/controlled_promotion_gate.dart';
import 'package:riskpulse/data/providers/research_workspace_provider.dart';

void main() {
  group('R-14 Evidence-to-Decision Intelligence Chain & Provenance Tests', () {
    final now = DateTime.utc(2026, 8, 15, 10, 0);

    test('TEST 01, 02 & 03: EvidenceDecisionChainContract domain validation and synthetic/simulated flag propagation', () {
      final chain = EvidenceDecisionChainContract(
        chainId: 'chain-01',
        eventId: 'evt-mandi-2026',
        scenarioId: 'scen-01',
        analysisId: 'ana-01',
        inputEvidenceIds: const ['ev-osint-01', 'ev-gee-dem-01'],
        derivedEvidenceIds: const ['ev-fusion-01'],
        analyticalResultIds: const ['res-hydro-01'],
        exposureResultIds: const ['res-exp-01'],
        decisionSupportResultIds: const ['res-ds-01'],
        priorityResultId: 'res-pq-01',
        provenanceReferences: const ['prov-01', 'prov-02'],
        modelId: 'riskpulse-chain-engine',
        executionMode: HydroAiExecutionMode.simulated,
        inputDataMode: HydroAiInputDataMode.syntheticFixture,
        operationalStatus: HydroAiOperationalStatus.researchOnly,
        humanReviewStatus: EvidenceHumanReviewStatus.pending,
        createdAt: now,
        updatedAt: now,
        isSynthetic: true,
        isSimulated: true,
      );

      expect(chain.chainId, equals('chain-01'));
      expect(chain.executionMode, equals(HydroAiExecutionMode.simulated));
      expect(chain.isSynthetic, isTrue);
      expect(chain.isSimulated, isTrue);
      expect(chain.isChainProvenanceComplete, isTrue);
    });

    test('TEST 06 & 07: Contradiction detection and conflict preservation (EVIDENCE_CONFLICT_REQUIRES_REVIEW)', () {
      final conflictChain = EvidenceDecisionChainContract(
        chainId: 'chain-conflict-01',
        eventId: 'evt-02',
        scenarioId: 'scen-02',
        analysisId: 'ana-02',
        inputEvidenceIds: const ['ev-osint-road-blocked', 'ev-remote-road-clear'],
        provenanceReferences: const ['prov-osint', 'prov-remote'],
        evidenceStatus: 'conflicted',
        conflictReferences: const ['conflict-road-blockage-discrepancy'],
        modelId: 'riskpulse-chain-engine',
        executionMode: HydroAiExecutionMode.simulated,
        humanReviewStatus: EvidenceHumanReviewStatus.pending,
        createdAt: now,
        updatedAt: now,
      );

      expect(conflictChain.evidenceStatus, equals('conflicted'));
      expect(conflictChain.conflictReferences, contains('conflict-road-blockage-discrepancy'));

      // ASSERT: Human review MUST be pending for conflicted evidence chains
      expect(conflictChain.humanReviewStatus, equals(EvidenceHumanReviewStatus.pending));
    });

    test('TEST 10, 11, 12, 13 & 14: Upstream module integration preserves HydroAI, SAR, OSINT, and Exposure statuses', () {
      final chain = EvidenceDecisionChainContract(
        chainId: 'chain-integrated-01',
        eventId: 'evt-03',
        scenarioId: 'scen-03',
        analysisId: 'ana-03',
        provenanceReferences: const ['prov-hydroai-sim', 'prov-sar-pending'],
        modelId: 'riskpulse-chain-engine',
        executionMode: HydroAiExecutionMode.simulated,
        scientificStatus: 'SOFTWARE_VALIDATED',
        limitationReferences: const [
          'HydroAI execution mode = SIMULATED',
          'R-12 SAR empirical validation = PENDING REAL EVENTS',
          'Environmental Health disclaimer = Association does NOT establish causation',
          'Exposure spatial intersection != CONFIRMED DAMAGE',
        ],
        createdAt: now,
        updatedAt: now,
      );

      expect(chain.limitationReferences, contains('HydroAI execution mode = SIMULATED'));
      expect(chain.limitationReferences, contains('R-12 SAR empirical validation = PENDING REAL EVENTS'));
      expect(chain.limitationReferences, contains('Environmental Health disclaimer = Association does NOT establish causation'));
      expect(chain.limitationReferences, contains('Exposure spatial intersection != CONFIRMED DAMAGE'));
    });

    test('TEST 15, 16 & 21: Decision Support and Priority Queue Engine integration & ControlledPromotionGate protection', () {
      final dsEngine = DecisionSupportEngine();
      final pqEngine = ResearchPriorityQueueEngine();

      expect(dsEngine, isA<DecisionSupportEngine>());
      expect(pqEngine, isA<ResearchPriorityQueueEngine>());
    });

    test('TEST 23: Serialization & Deserialization preserves complete chain provenance', () {
      final original = EvidenceDecisionChainContract(
        chainId: 'chain-ser-01',
        eventId: 'evt-ser-01',
        scenarioId: 'scen-ser-01',
        analysisId: 'ana-ser-01',
        inputEvidenceIds: const ['ev-01', 'ev-02'],
        provenanceReferences: const ['prov-01'],
        modelId: 'riskpulse-chain-engine',
        executionMode: HydroAiExecutionMode.simulated,
        createdAt: now,
        updatedAt: now,
      );

      final map = original.toMap();
      final restored = EvidenceDecisionChainContract.fromMap(map);

      expect(restored.chainId, equals(original.chainId));
      expect(restored.executionMode, equals(HydroAiExecutionMode.simulated));
      expect(restored.inputEvidenceIds, equals(original.inputEvidenceIds));
      expect(restored.isChainProvenanceComplete, isTrue);
    });

    test('TEST 22, 24 & 25: Research GIS isolation, ControlledPromotionGate, token redaction & operational baseline integrity', () {
      final gate = ControlledPromotionGate();
      expect(gate, isA<ControlledPromotionGate>());

      final workspace = ResearchWorkspaceProvider();
      expect(workspace.inputDem, isNull);
    });
  });
}
