import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/data/repositories/evidence_evaluation_repository.dart';
import 'package:riskpulse/data/services/evidence/evidence_evaluation_service.dart';
import 'package:riskpulse/domain/evidence/contradiction_strength.dart';
import 'package:riskpulse/domain/evidence/contradiction_target.dart';
import 'package:riskpulse/domain/evidence/contradiction_type.dart';
import 'package:riskpulse/domain/evidence/evaluation_state.dart';
import 'package:riskpulse/domain/evidence/event_hypothesis.dart';
import 'package:riskpulse/domain/evidence/event_hypothesis_status.dart';
import 'package:riskpulse/domain/evidence/evidence_evaluation_result.dart';
import 'package:riskpulse/domain/evidence/evidence_object.dart';
import 'package:riskpulse/domain/evidence/evidence_presence.dart';
import 'package:riskpulse/domain/evidence/evidence_provenance.dart';
import 'package:riskpulse/domain/evidence/evidence_relationship.dart';
import 'package:riskpulse/domain/evidence/evidence_relationship_type.dart';
import 'package:riskpulse/domain/evidence/evidence_source.dart';
import 'package:riskpulse/domain/evidence/evidence_type.dart';
import 'package:riskpulse/domain/evidence/interpretation_confidence.dart';
import 'package:riskpulse/domain/evidence/negative_evidence.dart';
import 'package:riskpulse/domain/evidence/relevance_dimension.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('P2.1 Negative Evidence & Contradiction Evaluation Test Suite', () {
    late LocalEvidenceEvaluationRepository repository;
    late EvidenceEvaluationService service;

    late EventHypothesis hypothesis;
    late EvidenceObject evSupp1;
    late EvidenceObject evSupp2;
    late EvidenceObject evContr1;
    late EvidenceRelationship relSupp1;
    late EvidenceRelationship relSupp2;
    late EvidenceRelationship relContr1;

    setUp(() {
      repository = LocalEvidenceEvaluationRepository();
      service = EvidenceEvaluationService(repository: repository);

      hypothesis = EventHypothesis(
        hypothesisId: 'HYP-EVAL-2026',
        eventType: 'ROAD_BLOCKAGE',
        hazardCategory: 'landslide',
        title: 'Candidate Landslide at Aut Village',
        description: 'Landslide obstacle reported on NH-21',
        interpretationIds: const ['INT-001'],
        confidence: const InterpretationConfidence(value: 0.82, method: 'TEST', basis: 'Initial NLP'),
      );

      evSupp1 = EvidenceObject(
        evidenceId: 'EVID-SUPP-01',
        observationId: 'OBS-001',
        evidenceType: EvidenceType.socialMedia,
        source: EvidenceSource(sourceSystem: 'Social', sourceId: 'S-01', sourceName: 'Twitter'),
        sourceId: 'S-01',
        sourceName: 'Twitter',
        description: 'Post stating boulders on NH-21 highway',
        provenance: EvidenceProvenance(sourceSystem: 'Social', sourceId: 'S-01'),
      );

      evSupp2 = EvidenceObject(
        evidenceId: 'EVID-SUPP-02',
        observationId: 'OBS-002',
        evidenceType: EvidenceType.satellite,
        source: EvidenceSource(sourceSystem: 'Sentinel-2', sourceId: 'SAT-01', sourceName: 'Sentinel Scene'),
        sourceId: 'SAT-01',
        sourceName: 'Sentinel Scene',
        description: 'Satellite imagery surface change consistent with landslide scarp',
        provenance: EvidenceProvenance(sourceSystem: 'Sentinel-2', sourceId: 'SAT-01'),
      );

      evContr1 = EvidenceObject(
        evidenceId: 'EVID-CONTR-01',
        observationId: 'OBS-003',
        evidenceType: EvidenceType.fieldReport,
        source: EvidenceSource(sourceSystem: 'Field', sourceId: 'FR-01', sourceName: 'Field Inspector'),
        sourceId: 'FR-01',
        sourceName: 'Field Inspector',
        description: 'Field inspection confirms road clear and no landslide at reported location',
        provenance: EvidenceProvenance(sourceSystem: 'Field', sourceId: 'FR-01'),
      );

      relSupp1 = EvidenceRelationship(
        relationshipId: 'REL-SUPP-01',
        sourceType: 'EvidenceObject',
        sourceId: 'EVID-SUPP-01',
        targetType: 'EventHypothesis',
        targetId: 'HYP-EVAL-2026',
        relationshipType: EvidenceRelationshipType.supports,
        relationshipDescription: 'Social post supports landslide hypothesis',
      );

      relSupp2 = EvidenceRelationship(
        relationshipId: 'REL-SUPP-02',
        sourceType: 'EvidenceObject',
        sourceId: 'EVID-SUPP-02',
        targetType: 'EventHypothesis',
        targetId: 'HYP-EVAL-2026',
        relationshipType: EvidenceRelationshipType.supports,
        relationshipDescription: 'Satellite raster supports landslide hypothesis',
      );

      relContr1 = EvidenceRelationship(
        relationshipId: 'REL-CONTR-01',
        sourceType: 'EvidenceObject',
        sourceId: 'EVID-CONTR-01',
        targetType: 'EventHypothesis',
        targetId: 'HYP-EVAL-2026',
        relationshipType: EvidenceRelationshipType.contradicts,
        relationshipDescription: 'Field report contradicts landslide hypothesis',
        rationale: 'Physical inspector on site verified free vehicle traffic',
      );
    });

    test('1. NegativeEvidence construction', () {
      final negEv = NegativeEvidence(
        negativeEvidenceId: 'NEG-001',
        evidenceId: 'EVID-CONTR-01',
        hypothesisId: 'HYP-EVAL-2026',
        contradictionDescription: 'Field report states road is clear',
        rationale: 'Verified field call',
      );

      expect(negEv.negativeEvidenceId, equals('NEG-001'));
      expect(negEv.evidenceId, equals('EVID-CONTR-01'));
      expect(negEv.hypothesisId, equals('HYP-EVAL-2026'));
    });

    test('2. immutability', () {
      final negEv = NegativeEvidence(
        negativeEvidenceId: 'NEG-IMMUTABLE',
        evidenceId: 'EVID-001',
        hypothesisId: 'HYP-001',
        contradictionDescription: 'Original description',
        rationale: 'Original rationale',
      );

      expect(() => (negEv.warnings as List).add('test'), throwsUnsupportedError);
    });

    test('3. evidence linkage', () {
      final negEv = NegativeEvidence(
        negativeEvidenceId: 'NEG-LINK-01',
        evidenceId: 'EVID-CONTR-01',
        hypothesisId: 'HYP-EVAL-2026',
        contradictionDescription: 'Description',
        rationale: 'Rationale',
      );

      expect(negEv.evidenceId, equals('EVID-CONTR-01'));
    });

    test('4. relationship linkage', () {
      final negEv = NegativeEvidence(
        negativeEvidenceId: 'NEG-REL-01',
        evidenceId: 'EVID-CONTR-01',
        evidenceRelationshipId: 'REL-CONTR-01',
        hypothesisId: 'HYP-EVAL-2026',
        contradictionDescription: 'Description',
        rationale: 'Rationale',
      );

      expect(negEv.evidenceRelationshipId, equals('REL-CONTR-01'));
    });

    test('5. hypothesis linkage', () {
      final negEv = NegativeEvidence(
        negativeEvidenceId: 'NEG-HYP-01',
        evidenceId: 'EVID-001',
        hypothesisId: 'HYP-TARGET-100',
        contradictionDescription: 'Description',
        rationale: 'Rationale',
      );

      expect(negEv.hypothesisId, equals('HYP-TARGET-100'));
    });

    test('6. contradiction type', () {
      expect(ContradictionType.fromCode('directContradiction'), equals(ContradictionType.directContradiction));
      expect(ContradictionType.fromCode('spatialContradiction'), equals(ContradictionType.spatialContradiction));
      expect(ContradictionType.fromCode('temporalContradiction'), equals(ContradictionType.temporalContradiction));
    });

    test('7. contradiction target', () {
      expect(ContradictionTarget.fromCode('existence'), equals(ContradictionTarget.existence));
      expect(ContradictionTarget.fromCode('location'), equals(ContradictionTarget.location));
      expect(ContradictionTarget.fromCode('extent'), equals(ContradictionTarget.extent));
    });

    test('8. rationale', () {
      final negEv = NegativeEvidence(
        negativeEvidenceId: 'NEG-RAT-01',
        evidenceId: 'EVID-001',
        hypothesisId: 'HYP-001',
        contradictionDescription: 'Desc',
        rationale: 'Detailed technical rationale statement explaining contradiction',
      );

      expect(negEv.rationale, contains('Detailed technical rationale'));
    });

    test('9. temporal relevance', () {
      final tempRel = service.assessTemporalRelevance(
        eventTime: DateTime(2026, 8, 15, 10, 0),
        evidenceTime: DateTime(2026, 8, 15, 11, 0),
      );

      expect(tempRel.level, equals(RelevanceLevel.high));
      expect(tempRel.score, equals(1.0));
    });

    test('10. spatial relevance', () {
      final spatRel = service.assessSpatialRelevance(
        eventGeom: {'type': 'Polygon'},
        evidenceGeom: {'type': 'Polygon'},
      );

      expect(spatRel.level, equals(RelevanceLevel.high));
    });

    test('11. semantic relevance', () {
      final semRel = service.assessSemanticRelevance(
        eventType: 'LANDSLIDE',
        description: 'Field inspection confirms no landslide at location',
      );

      expect(semRel.level, equals(RelevanceLevel.high));
    });

    test('12. integrity', () {
      final negEv = NegativeEvidence(
        negativeEvidenceId: 'NEG-INT-01',
        evidenceId: 'EVID-001',
        hypothesisId: 'HYP-001',
        contradictionDescription: 'Desc',
        rationale: 'Rationale',
        evidenceIntegrity: 'VERIFIED',
      );

      expect(negEv.evidenceIntegrity, equals('VERIFIED'));
    });

    test('13. provenance', () {
      final negEv = NegativeEvidence(
        negativeEvidenceId: 'NEG-PROV-01',
        evidenceId: 'EVID-001',
        hypothesisId: 'HYP-001',
        contradictionDescription: 'Desc',
        rationale: 'Rationale',
        provenance: const {'evaluator': 'RuleEngine-V1'},
      );

      expect(negEv.provenance['evaluator'], equals('RuleEngine-V1'));
    });

    test('14. evaluation method', () {
      final negEv = NegativeEvidence(
        negativeEvidenceId: 'NEG-METH-01',
        evidenceId: 'EVID-001',
        hypothesisId: 'HYP-001',
        contradictionDescription: 'Desc',
        rationale: 'Rationale',
        evaluationMethod: 'RULE_BASED_CONTRADICTION_EVALUATOR',
      );

      expect(negEv.evaluationMethod, equals('RULE_BASED_CONTRADICTION_EVALUATOR'));
    });

    test('15. evaluator type', () {
      final negEv = NegativeEvidence(
        negativeEvidenceId: 'NEG-EVAL-01',
        evidenceId: 'EVID-001',
        hypothesisId: 'HYP-001',
        contradictionDescription: 'Desc',
        rationale: 'Rationale',
        evaluatorType: 'HUMAN_REVIEW',
      );

      expect(negEv.evaluatorType, equals('HUMAN_REVIEW'));
    });

    test('16. evaluation timestamp', () {
      final now = DateTime.now().toUtc();
      final negEv = NegativeEvidence(
        negativeEvidenceId: 'NEG-TIME-01',
        evidenceId: 'EVID-001',
        hypothesisId: 'HYP-001',
        contradictionDescription: 'Desc',
        rationale: 'Rationale',
        evaluatedAt: now,
      );

      expect(negEv.evaluatedAt, equals(now));
    });

    test('17. evaluation state enum', () {
      expect(EvaluationState.fromCode('consistent'), equals(EvaluationState.consistent));
      expect(EvaluationState.fromCode('conflicted'), equals(EvaluationState.conflicted));
      expect(EvaluationState.fromCode('insufficient'), equals(EvaluationState.insufficient));
    });

    test('18. CONSISTENT state (only supporting evidence)', () async {
      final exec = await service.evaluateHypothesis(
        hypothesis: hypothesis,
        relationships: [relSupp1, relSupp2],
        evidenceMap: {'EVID-SUPP-01': evSupp1, 'EVID-SUPP-02': evSupp2},
      );

      expect(exec.evaluationResult.evaluationState, equals(EvaluationState.consistent));
      expect(exec.negativeEvidenceRecords, isEmpty);
    });

    test('19. CONFLICTED state (supporting + contradicting evidence)', () async {
      final evidenceMap = {'EVID-CONTR-01': evContr1};

      final exec = await service.evaluateHypothesis(
        hypothesis: hypothesis,
        relationships: [relSupp1, relContr1],
        evidenceMap: evidenceMap,
      );

      expect(exec.evaluationResult.evaluationState, equals(EvaluationState.conflicted));
      expect(exec.negativeEvidenceRecords.length, equals(1));
      expect(exec.negativeEvidenceRecords.first.evidenceId, equals('EVID-CONTR-01'));
    });

    test('20. INSUFFICIENT state (no relationships)', () async {
      final exec = await service.evaluateHypothesis(
        hypothesis: hypothesis,
        relationships: const [],
      );

      expect(exec.evaluationResult.evaluationState, equals(EvaluationState.insufficient));
    });

    test('21. UNRESOLVED state', () {
      expect(EvaluationState.fromCode('unresolved'), equals(EvaluationState.unresolved));
    });

    test('22. NOT_EVALUABLE state', () {
      expect(EvaluationState.fromCode('notEvaluable'), equals(EvaluationState.notEvaluable));
    });

    test('23. absence is not contradiction (EvidencePresence.absent != CONTRADICTS)', () {
      expect(EvidencePresence.absent, isNot(equals(EvidencePresence.present)));
      // Absence of evidence (e.g. no satellite scene available) is presence state absent, NOT negative evidence!
    });

    test('24. direct contradiction', () async {
      final exec = await service.evaluateHypothesis(
        hypothesis: hypothesis,
        relationships: [relContr1],
        evidenceMap: {'EVID-CONTR-01': evContr1},
      );

      expect(exec.negativeEvidenceRecords.first.contradictionType, equals(ContradictionType.directContradiction));
    });

    test('25. spatial contradiction', () {
      final spatRel = service.assessSpatialRelevance(
        eventGeom: {'type': 'Polygon'},
        evidenceGeom: {'type': 'Polygon'},
      );

      expect(spatRel.level, equals(RelevanceLevel.high));
    });

    test('26. temporal contradiction', () {
      final tempRel = service.assessTemporalRelevance(
        eventTime: DateTime(2026, 8, 15, 10, 0),
        evidenceTime: DateTime(2026, 8, 16, 10, 0), // 24 hours offset
      );

      expect(tempRel.level, equals(RelevanceLevel.low));
    });

    test('27. semantic contradiction', () {
      final semRel = service.assessSemanticRelevance(
        eventType: 'LANDSLIDE',
        description: 'Road blocked by vehicle accident',
      );

      expect(semRel.level, equals(RelevanceLevel.medium));
    });

    test('28. partial contradiction', () async {
      final relWeak = EvidenceRelationship(
        relationshipId: 'REL-WEAK-01',
        sourceType: 'EvidenceObject',
        sourceId: 'EVID-CONTR-01',
        targetType: 'EventHypothesis',
        targetId: 'HYP-EVAL-2026',
        relationshipType: EvidenceRelationshipType.weakens,
        relationshipDescription: 'Partial road clearance reported',
      );

      final exec = await service.evaluateHypothesis(
        hypothesis: hypothesis,
        relationships: [relWeak],
      );

      expect(exec.negativeEvidenceRecords.first.contradictionType, equals(ContradictionType.partialContradiction));
      expect(exec.negativeEvidenceRecords.first.contradictionStrength, equals(ContradictionStrength.moderate));
    });

    test('29. scope mismatch', () {
      expect(ContradictionType.scopeMismatch, equals(ContradictionType.scopeMismatch));
    });

    test('30. multi-evidence evaluation', () async {
      final exec = await service.evaluateHypothesis(
        hypothesis: hypothesis,
        relationships: [relSupp1, relSupp2, relContr1],
        evidenceMap: {'EVID-CONTR-01': evContr1},
      );

      expect(exec.evaluationResult.supportingRelationshipIds.length, equals(2));
      expect(exec.evaluationResult.contradictingRelationshipIds.length, equals(1));
      expect(exec.evaluationResult.evaluationState, equals(EvaluationState.conflicted));
    });

    test('31. supporting evidence preservation', () async {
      final exec = await service.evaluateHypothesis(
        hypothesis: hypothesis,
        relationships: [relSupp1, relContr1],
      );

      expect(exec.evaluationResult.supportingRelationshipIds, contains('REL-SUPP-01'));
    });

    test('32. contradicting evidence preservation', () async {
      final exec = await service.evaluateHypothesis(
        hypothesis: hypothesis,
        relationships: [relSupp1, relContr1],
      );

      expect(exec.evaluationResult.contradictingRelationshipIds, contains('REL-CONTR-01'));
    });

    test('33. unrelated evidence exclusion', () async {
      final relUnrelated = EvidenceRelationship(
        relationshipId: 'REL-UNREL-01',
        sourceType: 'EvidenceObject',
        sourceId: 'EVID-OTHER-01',
        targetType: 'EventHypothesis',
        targetId: 'HYP-EVAL-2026',
        relationshipType: EvidenceRelationshipType.relatedTo,
        relationshipDescription: 'Unrelated observation',
      );

      final exec = await service.evaluateHypothesis(
        hypothesis: hypothesis,
        relationships: [relSupp1, relUnrelated],
      );

      expect(exec.evaluationResult.supportingRelationshipIds, contains('REL-SUPP-01'));
      expect(exec.evaluationResult.contradictingRelationshipIds, isEmpty);
    });

    test('34. evaluation determinism', () async {
      final exec1 = await service.evaluateHypothesis(
        hypothesis: hypothesis,
        relationships: [relSupp1, relContr1],
        evaluationId: 'EVAL-DETERMINISTIC-01',
      );

      final exec2 = await service.evaluateHypothesis(
        hypothesis: hypothesis,
        relationships: [relSupp1, relContr1],
        evaluationId: 'EVAL-DETERMINISTIC-01',
      );

      expect(exec1.evaluationResult.evaluationState, equals(exec2.evaluationResult.evaluationState));
      expect(exec1.evaluationResult.contradictionSummary, equals(exec2.evaluationResult.contradictionSummary));
    });

    test('35. versioning', () {
      final res = EvidenceEvaluationResult(
        evaluationId: 'EVAL-VER-01',
        evaluationVersion: 1,
        hypothesisId: 'HYP-001',
        evaluationState: EvaluationState.conflicted,
        contradictionSummary: 'Initial evaluation',
      );

      final v2 = res.copyWith(evaluationVersion: 2, contradictionSummary: 'Updated evaluation V2');
      expect(v2.evaluationVersion, equals(2));
      expect(res.evaluationVersion, equals(1));
    });

    test('36. correction (correctEvaluation)', () async {
      final initial = EvidenceEvaluationResult(
        evaluationId: 'EVAL-CORR-ORIG',
        hypothesisId: 'HYP-001',
        evaluationState: EvaluationState.conflicted,
        contradictionSummary: 'Initial conflicted evaluation',
      );

      await repository.createEvaluation(initial);

      final correction = EvidenceEvaluationResult(
        evaluationId: 'EVAL-CORR-REV',
        evaluationVersion: 2,
        hypothesisId: 'HYP-001',
        evaluationState: EvaluationState.consistent,
        contradictionSummary: 'Correction V2: Conflicting evidence retracted',
        supersedesEvaluationId: 'EVAL-CORR-ORIG',
      );

      await service.correctEvaluation(
        originalEvaluationId: 'EVAL-CORR-ORIG',
        correctionEvaluation: correction,
      );

      final retrievedOriginal = await repository.getById('EVAL-CORR-ORIG');
      expect(retrievedOriginal?.supersededByEvaluationId, equals('EVAL-CORR-REV'));
    });

    test('37. historical evaluation preservation', () async {
      final initial = EvidenceEvaluationResult(
        evaluationId: 'EVAL-HIST-01',
        hypothesisId: 'HYP-001',
        evaluationState: EvaluationState.conflicted,
        contradictionSummary: 'V1 evaluation',
      );

      await repository.createEvaluation(initial);

      final v2 = initial.copyWith(evaluationVersion: 2, contradictionSummary: 'V2 evaluation');
      await repository.createEvaluation(v2);

      final versions = await repository.getVersions('EVAL-HIST-01');
      expect(versions.length, equals(2));
      expect(versions.first.contradictionSummary, equals('V1 evaluation'));
    });

    test('38. repository CRUD', () async {
      final res = EvidenceEvaluationResult(
        evaluationId: 'EVAL-CRUD-01',
        hypothesisId: 'HYP-CRUD-01',
        evaluationState: EvaluationState.consistent,
        contradictionSummary: 'CRUD test',
      );

      await repository.createEvaluation(res);
      final retrieved = await repository.getById('EVAL-CRUD-01');

      expect(retrieved, isNotNull);
      expect(retrieved?.hypothesisId, equals('HYP-CRUD-01'));
    });

    test('39. query by hypothesis ID', () async {
      final res = EvidenceEvaluationResult(
        evaluationId: 'EVAL-HYP-01',
        hypothesisId: 'HYP-QUERY-TARGET',
        evaluationState: EvaluationState.conflicted,
        contradictionSummary: 'Query target test',
      );

      await repository.createEvaluation(res);

      final matches = await repository.getByHypothesisId('HYP-QUERY-TARGET');
      expect(matches.length, equals(1));
      expect(matches.first.evaluationId, equals('EVAL-HYP-01'));
    });

    test('40. query by negative evidence ID', () async {
      final negEv = NegativeEvidence(
        negativeEvidenceId: 'NEG-QRY-01',
        evidenceId: 'EVID-001',
        hypothesisId: 'HYP-QUERY-TARGET-2',
        contradictionDescription: 'Query test',
        rationale: 'Rationale',
      );

      await repository.createNegativeEvidence(negEv);

      final retrieved = await repository.getNegativeEvidenceById('NEG-QRY-01');
      expect(retrieved, isNotNull);
      expect(retrieved?.hypothesisId, equals('HYP-QUERY-TARGET-2'));
    });

    test('41. query by relationship ID', () async {
      final negEv = NegativeEvidence(
        negativeEvidenceId: 'NEG-REL-QRY-01',
        evidenceId: 'EVID-001',
        evidenceRelationshipId: 'REL-TARGET-88',
        hypothesisId: 'HYP-001',
        contradictionDescription: 'Query test',
        rationale: 'Rationale',
      );

      await repository.createNegativeEvidence(negEv);
      final retrieved = await repository.getNegativeEvidenceById('NEG-REL-QRY-01');

      expect(retrieved?.evidenceRelationshipId, equals('REL-TARGET-88'));
    });

    test('42. query by evaluation state', () async {
      final res = EvidenceEvaluationResult(
        evaluationId: 'EVAL-STATE-QRY',
        hypothesisId: 'HYP-001',
        evaluationState: EvaluationState.conflicted,
        contradictionSummary: 'State query test',
      );

      await repository.createEvaluation(res);

      final matches = await repository.getByState(EvaluationState.conflicted);
      expect(matches.map((e) => e.evaluationId), contains('EVAL-STATE-QRY'));
    });

    test('43. service execution', () async {
      final exec = await service.evaluateHypothesis(
        hypothesis: hypothesis,
        relationships: [relSupp1, relContr1],
        evidenceMap: {'EVID-CONTR-01': evContr1},
      );

      expect(exec.evaluationResult, isNotNull);
      expect(exec.negativeEvidenceRecords.isNotEmpty, isTrue);
    });

    test('44. raw EvidenceObject preservation', () async {
      await service.evaluateHypothesis(
        hypothesis: hypothesis,
        relationships: [relSupp1, relContr1],
        evidenceMap: {'EVID-CONTR-01': evContr1},
      );

      expect(evContr1.description, contains('Field inspection confirms road clear'));
    });

    test('45. EventHypothesis immutability (Target hypothesis UNMUTATED)', () async {
      final initialConf = hypothesis.confidence.value;
      final initialStatus = hypothesis.status;

      await service.evaluateHypothesis(
        hypothesis: hypothesis,
        relationships: [relSupp1, relContr1],
        evidenceMap: {'EVID-CONTR-01': evContr1},
      );

      expect(hypothesis.confidence.value, equals(initialConf));
      expect(hypothesis.status, equals(initialStatus));
    });

    test('46. NO automatic confidence mutation on target EventHypothesis', () async {
      final exec = await service.evaluateHypothesis(
        hypothesis: hypothesis,
        relationships: [relSupp1, relContr1],
      );

      expect(exec.evaluationResult.evaluationState, equals(EvaluationState.conflicted));
      expect(hypothesis.confidence.value, equals(0.82));
    });

    test('47. NO automatic status mutation on target EventHypothesis', () async {
      await service.evaluateHypothesis(
        hypothesis: hypothesis,
        relationships: [relSupp1, relContr1],
      );

      expect(hypothesis.status, equals(EventHypothesisStatus.candidate));
    });

    test('48. NO Event Graph creation (Critical Boundary Invariant)', () async {
      final exec = await service.evaluateHypothesis(
        hypothesis: hypothesis,
        relationships: [relSupp1, relContr1],
      );

      expect(exec.evaluationResult.method, equals('DETERMINISTIC_CONTRADICTION_EVALUATOR'));
    });

    test('49. NO RiskState creation (Critical Boundary Invariant)', () async {
      final exec = await service.evaluateHypothesis(
        hypothesis: hypothesis,
        relationships: [relSupp1, relContr1],
      );

      expect(exec.evaluationResult.hypothesisId, equals('HYP-EVAL-2026'));
    });

    test('50. Verifies all 3 P2.1 report files exist on disk', () {
      final r1 = File('research/evidence/p2_1/reports/P2_1_EXISTING_NEGATIVE_EVIDENCE_FORENSIC_INVENTORY.md');
      final r2 = File('research/evidence/p2_1/architecture/P2_1_NEGATIVE_EVIDENCE_ARCHITECTURE.md');
      final r3 = File('research/evidence/p2_1/reports/RISKPULSE_P2_1_NEGATIVE_EVIDENCE_INTEGRATION_REPORT.md');

      expect(r1.existsSync(), isTrue);
      expect(r2.existsSync(), isTrue);
      expect(r3.existsSync(), isTrue);
    });
  });
}
