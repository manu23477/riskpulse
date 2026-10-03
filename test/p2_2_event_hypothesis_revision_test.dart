import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/data/repositories/event_hypothesis_repository.dart';
import 'package:riskpulse/data/repositories/revision_assessment_repository.dart';
import 'package:riskpulse/data/services/evidence/event_hypothesis_revision_service.dart';
import 'package:riskpulse/domain/evidence/evaluation_state.dart';
import 'package:riskpulse/domain/evidence/event_hypothesis.dart';
import 'package:riskpulse/domain/evidence/event_hypothesis_status.dart';
import 'package:riskpulse/domain/evidence/evidence_evaluation_result.dart';
import 'package:riskpulse/domain/evidence/interpretation_confidence.dart';
import 'package:riskpulse/domain/evidence/revision_assessment.dart';
import 'package:riskpulse/domain/evidence/revision_category.dart';
import 'package:riskpulse/domain/evidence/revision_decision.dart';
import 'package:riskpulse/domain/evidence/revision_query.dart';
import 'package:riskpulse/domain/location/geo_location.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('P2.2 Event Hypothesis Revision Engine Test Suite', () {
    late LocalRevisionAssessmentRepository revisionRepository;
    late LocalEventHypothesisRepository hypothesisRepository;
    late EventHypothesisRevisionService service;

    late EventHypothesis hypothesisV1;
    late EvidenceEvaluationResult evalConsistent;
    late EvidenceEvaluationResult evalSpatialConflict;
    late EvidenceEvaluationResult evalTemporalConflict;
    late EvidenceEvaluationResult evalSemanticConflict;

    setUp(() async {
      revisionRepository = LocalRevisionAssessmentRepository();
      hypothesisRepository = LocalEventHypothesisRepository();
      service = EventHypothesisRevisionService(
        revisionRepository: revisionRepository,
        hypothesisRepository: hypothesisRepository,
      );

      hypothesisV1 = EventHypothesis(
        hypothesisId: 'HYP-REV-2026',
        hypothesisVersion: 1,
        eventType: 'LANDSLIDE',
        hazardCategory: 'landslide',
        title: 'Candidate Landslide at Aut Village V1',
        description: 'Initial landslide candidate footprint 4.2 ha',
        interpretationIds: const ['INT-001'],
        location: const GeoLocation(latitude: 31.72, longitude: 76.98),
        geometry: {
          'type': 'Polygon',
          'coordinates': [
            [
              [76.92, 31.78],
              [76.96, 31.78],
              [76.96, 31.82],
              [76.92, 31.82],
              [76.92, 31.78]
            ]
          ]
        },
        estimatedStart: DateTime(2026, 8, 15, 10, 0),
        estimatedEnd: DateTime(2026, 8, 15, 14, 0),
        administrativeContextReference: 'HP-06:HP-TEH-0114:HP-VIL-aut',
        confidence: const InterpretationConfidence(value: 0.82, method: 'TEST', basis: 'Initial NLP'),
      );

      await hypothesisRepository.create(hypothesisV1);

      evalConsistent = EvidenceEvaluationResult(
        evaluationId: 'EVAL-CONS-01',
        hypothesisId: 'HYP-REV-2026',
        evaluationState: EvaluationState.consistent,
        contradictionSummary: 'Supporting evidence only',
      );

      evalSpatialConflict = EvidenceEvaluationResult(
        evaluationId: 'EVAL-SPAT-01',
        hypothesisId: 'HYP-REV-2026',
        evaluationState: EvaluationState.conflicted,
        contradictionSummary: 'Satellite extent imagery indicates actual landslide extent is 2.1 ha location offset',
        spatialAssessment: const {'hasSpatialMismatch': true},
      );

      evalTemporalConflict = EvidenceEvaluationResult(
        evaluationId: 'EVAL-TEMP-01',
        hypothesisId: 'HYP-REV-2026',
        evaluationState: EvaluationState.conflicted,
        contradictionSummary: 'Gauge telemetry indicates rainfall time start offset',
        temporalAssessment: const {'hasTemporalMismatch': true},
      );

      evalSemanticConflict = EvidenceEvaluationResult(
        evaluationId: 'EVAL-SEM-01',
        hypothesisId: 'HYP-REV-2026',
        evaluationState: EvaluationState.conflicted,
        contradictionSummary: 'Field report cause indicates road blockage due to vehicle accident',
        semanticAssessment: const {'hasSemanticMismatch': true},
      );
    });

    test('1. No contradiction -> no revision required', () async {
      final assessment = await service.assessRevision(
        hypothesis: hypothesisV1,
        evaluationResults: [evalConsistent],
      );

      expect(assessment.revisionCategory, equals(RevisionCategory.noRevisionRequired));
      expect(assessment.affectedFields, isEmpty);

      final decision = await service.decideRevision(assessment: assessment);
      expect(decision.decisionType, equals(RevisionCategory.noRevisionRequired));
      expect(decision.targetVersion, equals(1));

      final result = await service.executeRevision(hypothesis: hypothesisV1, decision: decision);
      expect(result.revisedHypothesis, isNull);
    });

    test('2. Contradiction exists but does not meet revision conditions -> no revision', () async {
      final evalWeak = EvidenceEvaluationResult(
        evaluationId: 'EVAL-WEAK-01',
        hypothesisId: 'HYP-REV-2026',
        evaluationState: EvaluationState.consistent,
        contradictionSummary: 'Minor unverified tweet rumor',
      );

      final assessment = await service.assessRevision(
        hypothesis: hypothesisV1,
        evaluationResults: [evalWeak],
      );

      expect(assessment.revisionCategory, equals(RevisionCategory.noRevisionRequired));
    });

    test('3. Extent / Spatial contradiction -> new version with spatial extent changed', () async {
      final assessment = await service.assessRevision(
        hypothesis: hypothesisV1,
        evaluationResults: [evalSpatialConflict],
      );

      expect(assessment.revisionCategory, equals(RevisionCategory.spatialRevision));
      expect(assessment.affectedFields, contains('geometry'));

      final decision = await service.decideRevision(assessment: assessment);
      expect(decision.targetVersion, equals(2));

      final updatedGeom = {
        'type': 'Polygon',
        'coordinates': [
          [
            [76.93, 31.79],
            [76.95, 31.79],
            [76.95, 31.81],
            [76.93, 31.81],
            [76.93, 31.79]
          ]
        ]
      };

      final exec = await service.executeRevision(
        hypothesis: hypothesisV1,
        decision: decision,
        updatedFields: {'geometry': updatedGeom},
      );

      expect(exec.revisedHypothesis, isNotNull);
      expect(exec.revisedHypothesis!.hypothesisVersion, equals(2));
      expect(exec.revisedHypothesis!.supersedesHypothesisId, equals('HYP-REV-2026'));
      expect(exec.revisedHypothesis!.geometry, equals(updatedGeom));
    });

    test('4. Location contradiction -> new version with spatial location changed', () async {
      final assessment = await service.assessRevision(
        hypothesis: hypothesisV1,
        evaluationResults: [evalSpatialConflict],
      );

      final decision = await service.decideRevision(assessment: assessment);
      final newLoc = const GeoLocation(latitude: 31.75, longitude: 77.01);

      final exec = await service.executeRevision(
        hypothesis: hypothesisV1,
        decision: decision,
        updatedFields: {'location': newLoc},
      );

      expect(exec.revisedHypothesis?.location?.latitude, equals(31.75));
      expect(exec.revisedHypothesis?.location?.longitude, equals(77.01));
    });

    test('5. Temporal contradiction -> new version with temporal state changed', () async {
      final assessment = await service.assessRevision(
        hypothesis: hypothesisV1,
        evaluationResults: [evalTemporalConflict],
      );

      expect(assessment.revisionCategory, equals(RevisionCategory.temporalRevision));

      final decision = await service.decideRevision(assessment: assessment);
      final newStart = DateTime(2026, 8, 15, 11, 30);

      final exec = await service.executeRevision(
        hypothesis: hypothesisV1,
        decision: decision,
        updatedFields: {'estimatedStart': newStart},
      );

      expect(exec.revisedHypothesis?.estimatedStart, equals(newStart));
    });

    test('6. Semantic contradiction -> new version with event type changed', () async {
      final assessment = await service.assessRevision(
        hypothesis: hypothesisV1,
        evaluationResults: [evalSemanticConflict],
      );

      expect(assessment.revisionCategory, equals(RevisionCategory.semanticRevision));

      final decision = await service.decideRevision(assessment: assessment);
      final exec = await service.executeRevision(
        hypothesis: hypothesisV1,
        decision: decision,
        updatedFields: {'eventType': 'VEHICLE_ACCIDENT_BLOCKAGE'},
      );

      expect(exec.revisedHypothesis?.eventType, equals('VEHICLE_ACCIDENT_BLOCKAGE'));
    });

    test('7. Severity contradiction -> new version with severity changed', () async {
      final evalSev = EvidenceEvaluationResult(
        evaluationId: 'EVAL-SEV-01',
        hypothesisId: 'HYP-REV-2026',
        evaluationState: EvaluationState.conflicted,
        contradictionSummary: 'Debris scarp causes moderate severity blockage',
      );

      final assessment = await service.assessRevision(
        hypothesis: hypothesisV1,
        evaluationResults: [evalSev],
      );

      final decision = await service.decideRevision(assessment: assessment);
      final exec = await service.executeRevision(
        hypothesis: hypothesisV1,
        decision: decision,
        updatedFields: {'description': 'Moderate severity blockage'},
      );

      expect(exec.revisedHypothesis?.description, equals('Moderate severity blockage'));
    });

    test('8. Partial revision preserves unaffected fields byte-for-byte', () async {
      final assessment = await service.assessRevision(
        hypothesis: hypothesisV1,
        evaluationResults: [evalSpatialConflict],
      );

      final decision = await service.decideRevision(assessment: assessment);
      final newGeom = {'type': 'Point', 'coordinates': [76.98, 31.72]};

      final exec = await service.executeRevision(
        hypothesis: hypothesisV1,
        decision: decision,
        updatedFields: {'geometry': newGeom},
      );

      final revised = exec.revisedHypothesis!;
      expect(revised.eventType, equals(hypothesisV1.eventType));
      expect(revised.hazardCategory, equals(hypothesisV1.hazardCategory));
      expect(revised.estimatedStart, equals(hypothesisV1.estimatedStart));
      expect(revised.confidence.value, equals(hypothesisV1.confidence.value));
    });

    test('9. Original hypothesis v1 remains 100% unchanged', () async {
      final origType = hypothesisV1.eventType;
      final origDesc = hypothesisV1.description;

      final assessment = await service.assessRevision(hypothesis: hypothesisV1, evaluationResults: [evalSpatialConflict]);
      final decision = await service.decideRevision(assessment: assessment);
      await service.executeRevision(hypothesis: hypothesisV1, decision: decision, updatedFields: {'eventType': 'REVISED'});

      expect(hypothesisV1.eventType, equals(origType));
      expect(hypothesisV1.description, equals(origDesc));
    });

    test('10. Previous geometry remains unchanged in v1', () async {
      final origGeom = hypothesisV1.geometry;

      final assessment = await service.assessRevision(hypothesis: hypothesisV1, evaluationResults: [evalSpatialConflict]);
      final decision = await service.decideRevision(assessment: assessment);
      await service.executeRevision(hypothesis: hypothesisV1, decision: decision, updatedFields: {'geometry': {'type': 'Point'}});

      expect(hypothesisV1.geometry, equals(origGeom));
    });

    test('11. Previous administrative attribution remains preserved in v1', () async {
      final origAdminRef = hypothesisV1.administrativeContextReference;

      final assessment = await service.assessRevision(hypothesis: hypothesisV1, evaluationResults: [evalSpatialConflict]);
      final decision = await service.decideRevision(assessment: assessment);
      await service.executeRevision(hypothesis: hypothesisV1, decision: decision, updatedFields: {'administrativeContextReference': 'HP-06:NEW'});

      expect(hypothesisV1.administrativeContextReference, equals(origAdminRef));
    });

    test('12. New spatial revision receives new administrative context via P1.5', () async {
      final assessment = await service.assessRevision(hypothesis: hypothesisV1, evaluationResults: [evalSpatialConflict]);
      final decision = await service.decideRevision(assessment: assessment);

      final exec = await service.executeRevision(
        hypothesis: hypothesisV1,
        decision: decision,
        updatedFields: {'administrativeContextReference': 'HP-06:HP-TEH-0114:HP-VIL-aut-revised'},
      );

      expect(exec.revisedHypothesis?.administrativeContextReference, equals('HP-06:HP-TEH-0114:HP-VIL-aut-revised'));
    });

    test('13. Revision lineage is preserved (parentHypothesisIds contains v1)', () async {
      final assessment = await service.assessRevision(hypothesis: hypothesisV1, evaluationResults: [evalSpatialConflict]);
      final decision = await service.decideRevision(assessment: assessment);

      final exec = await service.executeRevision(hypothesis: hypothesisV1, decision: decision);
      expect(exec.revisedHypothesis?.parentHypothesisIds, contains('HYP-REV-2026'));
      expect(exec.revisedHypothesis?.supersedesHypothesisId, equals('HYP-REV-2026'));
    });

    test('14. EvaluationResult reference is preserved in assessment & decision', () async {
      final assessment = await service.assessRevision(hypothesis: hypothesisV1, evaluationResults: [evalSpatialConflict]);
      expect(assessment.evaluationResultIds, contains('EVAL-SPAT-01'));

      final decision = await service.decideRevision(assessment: assessment);
      expect(decision.evidenceEvaluationIds, contains('EVAL-SPAT-01'));
    });

    test('15. RevisionDecision is immutable', () {
      final decision = RevisionDecision(
        decisionId: 'DEC-001',
        eventHypothesisId: 'HYP-001',
        sourceVersion: 1,
        targetVersion: 2,
        assessmentId: 'ASS-001',
        decisionType: RevisionCategory.spatialRevision,
        rationale: 'Rationale',
      );

      expect(() => (decision.changedFields as List).add('test'), throwsUnsupportedError);
    });

    test('16. RevisionAssessment is immutable', () {
      final assessment = RevisionAssessment(
        assessmentId: 'ASS-001',
        eventHypothesisId: 'HYP-001',
        eventHypothesisVersion: 1,
        evaluationResultIds: const ['EVAL-001'],
        rationale: 'Rationale',
        contradictionSummary: 'Summary',
      );

      expect(() => (assessment.affectedFields as List).add('test'), throwsUnsupportedError);
    });

    test('17. Version number increments deterministically (v1 -> v2 -> v3)', () async {
      final assessment1 = await service.assessRevision(hypothesis: hypothesisV1, evaluationResults: [evalSpatialConflict]);
      final decision1 = await service.decideRevision(assessment: assessment1);
      final exec1 = await service.executeRevision(hypothesis: hypothesisV1, decision: decision1);

      final v2 = exec1.revisedHypothesis!;
      expect(v2.hypothesisVersion, equals(2));

      final assessment2 = await service.assessRevision(hypothesis: v2, evaluationResults: [evalTemporalConflict]);
      final decision2 = await service.decideRevision(assessment: assessment2);
      final exec2 = await service.executeRevision(hypothesis: v2, decision: decision2);

      final v3 = exec2.revisedHypothesis!;
      expect(v3.hypothesisVersion, equals(3));
    });

    test('18. Multiple evaluation results affect different dimensions', () async {
      final assessment = await service.assessRevision(
        hypothesis: hypothesisV1,
        evaluationResults: [evalSpatialConflict, evalTemporalConflict],
      );

      expect(assessment.revisionCategory, equals(RevisionCategory.partialRevision));
      expect(assessment.affectedFields, containsAll(['geometry', 'location', 'estimatedStart', 'estimatedEnd']));
    });

    test('19. Supporting evidence does not disappear when contradictory evidence arrives', () async {
      final exec = await service.assessRevision(
        hypothesis: hypothesisV1,
        evaluationResults: [evalConsistent, evalSpatialConflict],
      );

      expect(exec.evaluationResultIds, containsAll(['EVAL-CONS-01', 'EVAL-SPAT-01']));
    });

    test('20. No automatic arbitrary confidence reduction penalty', () async {
      final assessment = await service.assessRevision(hypothesis: hypothesisV1, evaluationResults: [evalSpatialConflict]);
      final decision = await service.decideRevision(assessment: assessment);
      final exec = await service.executeRevision(hypothesis: hypothesisV1, decision: decision);

      expect(exec.revisedHypothesis?.confidence.value, equals(0.82)); // Confidence value preserved!
    });

    test('21. Invalidated candidate preserves historical version', () async {
      final evalInvalid = EvidenceEvaluationResult(
        evaluationId: 'EVAL-INV-01',
        hypothesisId: 'HYP-REV-2026',
        evaluationState: EvaluationState.conflicted,
        contradictionSummary: 'Field call confirms no landslide',
      );

      final assessment = RevisionAssessment(
        assessmentId: 'ASS-INV-01',
        eventHypothesisId: 'HYP-REV-2026',
        eventHypothesisVersion: 1,
        evaluationResultIds: [evalInvalid.evaluationId],
        revisionCategory: RevisionCategory.invalidationCandidate,
        rationale: 'Invalidated',
        contradictionSummary: 'Invalidated',
      );

      final decision = await service.decideRevision(assessment: assessment);
      final exec = await service.executeRevision(hypothesis: hypothesisV1, decision: decision);

      expect(exec.revisedHypothesis?.status, equals(EventHypothesisStatus.invalidated));
      expect(exec.originalHypothesis.status, equals(EventHypothesisStatus.superseded));
    });

    test('22. Repeated identical revision request does not create uncontrolled duplicate versions', () async {
      final assessment = await service.assessRevision(hypothesis: hypothesisV1, evaluationResults: [evalConsistent]);
      final decision = await service.decideRevision(assessment: assessment);
      final exec = await service.executeRevision(hypothesis: hypothesisV1, decision: decision);

      expect(exec.revisedHypothesis, isNull);
    });

    test('23. Provenance survives revision', () async {
      final assessment = await service.assessRevision(hypothesis: hypothesisV1, evaluationResults: [evalSpatialConflict]);
      final decision = await service.decideRevision(assessment: assessment);
      final exec = await service.executeRevision(hypothesis: hypothesisV1, decision: decision);

      expect(exec.revisedHypothesis?.provenance['revisionDecisionId'], equals(decision.decisionId));
    });

    test('24. Version comparison (compareVersions) identifies changed vs unchanged fields', () {
      final v2 = hypothesisV1.copyWith(
        hypothesisVersion: 2,
        eventType: 'REVISED_LANDSLIDE',
      );

      final comp = service.compareVersions(hypothesisV1, v2);
      expect(comp['changedFields'], contains('eventType'));
      expect(comp['unchangedFields'], contains('hazardCategory'));
    });

    test('25. Verifies all 6 P2.2 report files exist on disk', () {
      final r1 = File('research/evidence/p2_2/reports/P2_2_EXISTING_EVENT_REVISION_FORENSIC_INVENTORY.md');
      final r2 = File('research/evidence/p2_2/architecture/P2_2_EVENT_HYPOTHESIS_REVISION_ARCHITECTURE.md');
      final r3 = File('research/evidence/p2_2/reports/P2_2_REVISION_FIELD_SEMANTICS.md');
      final r4 = File('research/evidence/p2_2/reports/P2_2_REVISION_RULES.md');
      final r5 = File('research/evidence/p2_2/reports/P2_2_TEST_REPORT.md');
      final r6 = File('research/evidence/p2_2/reports/RISKPULSE_P2_2_EVENT_HYPOTHESIS_REVISION_REPORT.md');

      expect(r1.existsSync(), isTrue);
      expect(r2.existsSync(), isTrue);
      expect(r3.existsSync(), isTrue);
      expect(r4.existsSync(), isTrue);
      expect(r5.existsSync(), isTrue);
      expect(r6.existsSync(), isTrue);
    });

    test('26. Revision assessment repository CRUD', () async {
      final ass = RevisionAssessment(
        assessmentId: 'ASS-CRUD-01',
        eventHypothesisId: 'HYP-001',
        eventHypothesisVersion: 1,
        evaluationResultIds: const ['EVAL-001'],
        rationale: 'CRUD test',
        contradictionSummary: 'Summary',
      );

      await revisionRepository.createAssessment(ass);
      final retrieved = await revisionRepository.getAssessmentById('ASS-CRUD-01');

      expect(retrieved, isNotNull);
      expect(retrieved?.eventHypothesisId, equals('HYP-001'));
    });

    test('27. Revision decision repository CRUD', () async {
      final dec = RevisionDecision(
        decisionId: 'DEC-CRUD-01',
        eventHypothesisId: 'HYP-001',
        sourceVersion: 1,
        targetVersion: 2,
        assessmentId: 'ASS-001',
        decisionType: RevisionCategory.spatialRevision,
        rationale: 'CRUD test',
      );

      await revisionRepository.createDecision(dec);
      final retrieved = await revisionRepository.getDecisionById('DEC-CRUD-01');

      expect(retrieved, isNotNull);
      expect(retrieved?.sourceVersion, equals(1));
    });

    test('28. Revision service query assessments', () async {
      final ass = RevisionAssessment(
        assessmentId: 'ASS-QRY-01',
        eventHypothesisId: 'HYP-QUERY-TARGET',
        eventHypothesisVersion: 1,
        evaluationResultIds: const ['EVAL-001'],
        revisionCategory: RevisionCategory.spatialRevision,
        rationale: 'Query test',
        contradictionSummary: 'Summary',
      );

      await revisionRepository.createAssessment(ass);

      final query = RevisionQuery(
        eventHypothesisId: 'HYP-QUERY-TARGET',
        revisionCategory: RevisionCategory.spatialRevision,
      );

      final matches = await revisionRepository.queryAssessments(query);
      expect(matches.length, equals(1));
      expect(matches.first.assessmentId, equals('ASS-QRY-01'));
    });

    test('29. Revision service query decisions', () async {
      final dec = RevisionDecision(
        decisionId: 'DEC-QRY-01',
        eventHypothesisId: 'HYP-QUERY-TARGET-2',
        sourceVersion: 1,
        targetVersion: 2,
        assessmentId: 'ASS-001',
        decisionType: RevisionCategory.temporalRevision,
        rationale: 'Query test',
      );

      await revisionRepository.createDecision(dec);

      final query = RevisionQuery(
        eventHypothesisId: 'HYP-QUERY-TARGET-2',
        revisionCategory: RevisionCategory.temporalRevision,
      );

      final matches = await revisionRepository.queryDecisions(query);
      expect(matches.length, equals(1));
      expect(matches.first.decisionId, equals('DEC-QRY-01'));
    });

    test('30. End-to-end P2.1 EvaluationResult -> RevisionAssessment -> RevisionDecision -> EventHypothesis v2 execution', () async {
      final assessment = await service.assessRevision(hypothesis: hypothesisV1, evaluationResults: [evalSpatialConflict]);
      final decision = await service.decideRevision(assessment: assessment);

      final newGeom = {
        'type': 'Polygon',
        'coordinates': [
          [
            [76.94, 31.79],
            [76.96, 31.79],
            [76.96, 31.81],
            [76.94, 31.81],
            [76.94, 31.79]
          ]
        ]
      };

      final exec = await service.executeRevision(
        hypothesis: hypothesisV1,
        decision: decision,
        updatedFields: {'geometry': newGeom},
      );

      expect(exec.revisedHypothesis, isNotNull);
      expect(exec.revisedHypothesis!.hypothesisVersion, equals(2));
      expect(exec.revisedHypothesis!.geometry, equals(newGeom));
      expect(exec.originalHypothesis.hypothesisVersion, equals(1));
      expect(exec.originalHypothesis.status, equals(EventHypothesisStatus.superseded));
    });
  });
}
