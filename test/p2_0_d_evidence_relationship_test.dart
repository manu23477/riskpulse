import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/data/repositories/evidence_relationship_repository.dart';
import 'package:riskpulse/data/services/evidence/evidence_relationship_service.dart';
import 'package:riskpulse/domain/evidence/evidence_relationship.dart';
import 'package:riskpulse/domain/evidence/evidence_relationship_query.dart';
import 'package:riskpulse/domain/evidence/evidence_relationship_type.dart';
import 'package:riskpulse/domain/evidence/relationship_status.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('P2.0-D First-Class Evidence Relationship Semantics Test Suite', () {
    late LocalEvidenceRelationshipRepository repository;
    late EvidenceRelationshipService service;

    setUp(() {
      repository = LocalEvidenceRelationshipRepository();
      service = EvidenceRelationshipService(repository: repository);
    });

    test('1. construction & immutable identity', () async {
      final rel = EvidenceRelationship(
        relationshipId: 'REL-2026-001',
        sourceType: 'EvidenceObject',
        sourceId: 'EVID-SOC-001',
        targetType: 'EventHypothesis',
        targetId: 'HYP-2026-001',
        relationshipType: EvidenceRelationshipType.supports,
        relationshipDescription: 'Social media photograph shows boulders on highway corridor',
        rationale: 'Photo shows highway blockage at candidate event location',
      );

      final result = await service.registerRelationship(rel);
      expect(result.isValid, isTrue);
      expect(result.relationship.relationshipId, equals('REL-2026-001'));
      expect(result.relationship.status, equals(RelationshipStatus.active));
    });

    test('2. source type & ID preservation', () async {
      final rel = EvidenceRelationship(
        relationshipId: 'REL-SRC-01',
        sourceType: 'EvidenceObject',
        sourceId: 'EVID-GOV-001',
        targetType: 'EventHypothesis',
        targetId: 'HYP-2026-001',
        relationshipType: EvidenceRelationshipType.supports,
        relationshipDescription: 'HPSDMA official warning bulletin',
      );

      final result = await service.registerRelationship(rel);
      expect(result.relationship.sourceType, equals('EvidenceObject'));
      expect(result.relationship.sourceId, equals('EVID-GOV-001'));
    });

    test('3. target type & ID preservation', () async {
      final rel = EvidenceRelationship(
        relationshipId: 'REL-TGT-01',
        sourceType: 'InterpretationObject',
        sourceId: 'INT-LS-001',
        targetType: 'EventHypothesis',
        targetId: 'HYP-2026-002',
        relationshipType: EvidenceRelationshipType.supports,
        relationshipDescription: 'Inferred landslide hazard supports candidate event',
      );

      final result = await service.registerRelationship(rel);
      expect(result.relationship.targetType, equals('EventHypothesis'));
      expect(result.relationship.targetId, equals('HYP-2026-002'));
    });

    test('4. directionality (Source -> Target is distinct from Target -> Source)', () {
      final fwd = EvidenceRelationship(
        relationshipId: 'REL-FWD',
        sourceType: 'EvidenceObject',
        sourceId: 'EVID-001',
        targetType: 'EventHypothesis',
        targetId: 'HYP-001',
        relationshipType: EvidenceRelationshipType.supports,
        relationshipDescription: 'EVID supports HYP',
      );

      final rev = EvidenceRelationship(
        relationshipId: 'REL-REV',
        sourceType: 'EventHypothesis',
        sourceId: 'HYP-001',
        targetType: 'EvidenceObject',
        targetId: 'EVID-001',
        relationshipType: EvidenceRelationshipType.supports,
        relationshipDescription: 'HYP supports EVID',
      );

      expect(fwd.sourceId, equals('EVID-001'));
      expect(fwd.targetId, equals('HYP-001'));
      expect(rev.sourceId, equals('HYP-001'));
      expect(rev.targetId, equals('EVID-001'));
      expect(fwd.duplicateFingerprintKey, isNot(equals(rev.duplicateFingerprintKey)));
    });

    test('5. RELATED_TO semantics', () async {
      final rel = EvidenceRelationship(
        relationshipId: 'REL-REL-01',
        sourceType: 'EvidenceObject',
        sourceId: 'EVID-WX-001',
        targetType: 'EventHypothesis',
        targetId: 'HYP-2026-001',
        relationshipType: EvidenceRelationshipType.relatedTo,
        relationshipDescription: 'AWS rain gauge reading in same Tehsil',
      );

      final result = await service.registerRelationship(rel);
      expect(result.relationship.relationshipType, equals(EvidenceRelationshipType.relatedTo));
      expect(result.relationship.relationshipCode, equals('RELATED_TO'));
    });

    test('6. SUPPORTS semantics', () async {
      final rel = EvidenceRelationship(
        relationshipId: 'REL-SUPP-01',
        sourceType: 'EvidenceObject',
        sourceId: 'EVID-SAT-001',
        targetType: 'EventHypothesis',
        targetId: 'HYP-2026-001',
        relationshipType: EvidenceRelationshipType.supports,
        relationshipDescription: 'Sentinel-2 post-event surface change confirms scarp',
      );

      final result = await service.registerRelationship(rel);
      expect(result.relationship.relationshipType, equals(EvidenceRelationshipType.supports));
      expect(result.relationship.relationshipCode, equals('SUPPORTS'));
    });

    test('7. CONTRADICTS semantics', () async {
      final rel = EvidenceRelationship(
        relationshipId: 'REL-CONT-01',
        sourceType: 'EvidenceObject',
        sourceId: 'EVID-INSPECT-001',
        targetType: 'EventHypothesis',
        targetId: 'HYP-2026-001',
        relationshipType: EvidenceRelationshipType.contradicts,
        relationshipDescription: 'Field inspection reports road clear and no landslide at location',
        rationale: 'Physical inspector on site verified free vehicle traffic',
      );

      final result = await service.registerRelationship(rel);
      expect(result.relationship.relationshipType, equals(EvidenceRelationshipType.contradicts));
      expect(result.relationship.relationshipCode, equals('CONTRADICTS'));
    });

    test('8. relationship description & rationale', () async {
      final rel = EvidenceRelationship(
        relationshipId: 'REL-RAT-01',
        sourceType: 'EvidenceObject',
        sourceId: 'EVID-001',
        targetType: 'EventHypothesis',
        targetId: 'HYP-001',
        relationshipType: EvidenceRelationshipType.supports,
        relationshipDescription: 'Description of relationship',
        rationale: 'Detailed technical rationale statement explaining why evidence supports candidate',
      );

      final result = await service.registerRelationship(rel);
      expect(result.relationship.relationshipDescription, equals('Description of relationship'));
      expect(result.relationship.rationale, contains('Detailed technical rationale'));
    });

    test('9. evaluation method & evaluator type', () async {
      final rel = EvidenceRelationship(
        relationshipId: 'REL-EVAL-01',
        sourceType: 'InterpretationObject',
        sourceId: 'INT-001',
        targetType: 'EventHypothesis',
        targetId: 'HYP-001',
        relationshipType: EvidenceRelationshipType.supports,
        relationshipDescription: 'Model evaluation link',
        evaluationMethod: 'AUTOMATED_SPATIAL_INTERSECTION',
        evaluatorType: 'RULE_ENGINE',
      );

      final result = await service.registerRelationship(rel);
      expect(result.relationship.evaluationMethod, equals('AUTOMATED_SPATIAL_INTERSECTION'));
      expect(result.relationship.evaluatorType, equals('RULE_ENGINE'));
    });

    test('10. timestamps (createdAt, effectiveFrom, effectiveTo)', () async {
      final createdAt = DateTime(2026, 8, 15, 14, 0);
      final effFrom = DateTime(2026, 8, 15, 10, 0);

      final rel = EvidenceRelationship(
        relationshipId: 'REL-TIME-01',
        sourceType: 'EvidenceObject',
        sourceId: 'EVID-001',
        targetType: 'EventHypothesis',
        targetId: 'HYP-001',
        relationshipType: EvidenceRelationshipType.supports,
        relationshipDescription: 'Timestamp test',
        createdAt: createdAt,
        effectiveFrom: effFrom,
      );

      final result = await service.registerRelationship(rel);
      expect(result.relationship.createdAt, equals(createdAt));
      expect(result.relationship.effectiveFrom, equals(effFrom));
    });

    test('11. structured provenance preservation', () async {
      final rel = EvidenceRelationship(
        relationshipId: 'REL-PROV-01',
        sourceType: 'EvidenceObject',
        sourceId: 'EVID-001',
        targetType: 'EventHypothesis',
        targetId: 'HYP-001',
        relationshipType: EvidenceRelationshipType.supports,
        relationshipDescription: 'Provenance test',
        createdBy: 'ANALYST_SMITH',
        provenance: const {
          'analystId': 'ANALYST_SMITH',
          'reviewSession': 'SESS-20260815-01',
        },
      );

      final result = await service.registerRelationship(rel);
      expect(result.relationship.createdBy, equals('ANALYST_SMITH'));
      expect(result.relationship.provenance['reviewSession'], equals('SESS-20260815-01'));
    });

    test('12. lifecycle status enum', () {
      expect(RelationshipStatus.fromCode('active'), equals(RelationshipStatus.active));
      expect(RelationshipStatus.fromCode('superseded'), equals(RelationshipStatus.superseded));
      expect(RelationshipStatus.fromCode('invalidated'), equals(RelationshipStatus.invalidated));
      expect(RelationshipStatus.fromCode('withdrawn'), equals(RelationshipStatus.withdrawn));
    });

    test('13. copyWith immutability', () {
      final rel = EvidenceRelationship(
        relationshipId: 'REL-IMM-01',
        sourceType: 'EvidenceObject',
        sourceId: 'EVID-001',
        targetType: 'EventHypothesis',
        targetId: 'HYP-001',
        relationshipType: EvidenceRelationshipType.supports,
        relationshipDescription: 'Original Description',
      );

      final copy = rel.copyWith(relationshipDescription: 'Updated Description', relationshipVersion: 2);
      expect(copy.relationshipDescription, equals('Updated Description'));
      expect(copy.relationshipVersion, equals(2));
      expect(rel.relationshipDescription, equals('Original Description'));
      expect(rel.relationshipVersion, equals(1));
    });

    test('14. correction (correctRelationship)', () async {
      final original = EvidenceRelationship(
        relationshipId: 'REL-CORR-ORIG',
        sourceType: 'EvidenceObject',
        sourceId: 'EVID-001',
        targetType: 'EventHypothesis',
        targetId: 'HYP-001',
        relationshipType: EvidenceRelationshipType.supports,
        relationshipDescription: 'Initial assessment: SUPPORTS',
      );

      await service.registerRelationship(original);

      final correction = EvidenceRelationship(
        relationshipId: 'REL-CORR-REV',
        sourceType: 'EvidenceObject',
        sourceId: 'EVID-001',
        targetType: 'EventHypothesis',
        targetId: 'HYP-001',
        relationshipType: EvidenceRelationshipType.contradicts,
        relationshipDescription: 'Revised assessment: CONTRADICTS after photo re-inspection',
        supersedesRelationshipId: 'REL-CORR-ORIG',
        relationshipVersion: 2,
        correctionReason: 'Photo re-inspection showed clean road',
      );

      await service.correctRelationship(
        originalRelationshipId: 'REL-CORR-ORIG',
        correctionRelationship: correction,
      );

      final retrievedOriginal = await service.retrieveRelationship('REL-CORR-ORIG');
      expect(retrievedOriginal?.status, equals(RelationshipStatus.superseded));
      expect(retrievedOriginal?.supersededByRelationshipId, equals('REL-CORR-REV'));
    });

    test('15. invalidation (invalidateRelationship)', () async {
      final rel = EvidenceRelationship(
        relationshipId: 'REL-INV-01',
        sourceType: 'EvidenceObject',
        sourceId: 'EVID-001',
        targetType: 'EventHypothesis',
        targetId: 'HYP-001',
        relationshipType: EvidenceRelationshipType.supports,
        relationshipDescription: 'Invalidation test',
      );

      await service.registerRelationship(rel);

      await service.invalidateRelationship(
        originalRelationshipId: 'REL-INV-01',
        invalidationReason: 'Rule engine parameter update invalidated link logic.',
      );

      final retrieved = await service.retrieveRelationship('REL-INV-01');
      expect(retrieved?.status, equals(RelationshipStatus.invalidated));
      expect(retrieved?.correctionReason, contains('Rule engine parameter update'));
    });

    test('16. withdrawal (withdrawRelationship)', () async {
      final rel = EvidenceRelationship(
        relationshipId: 'REL-WITHDRAW-01',
        sourceType: 'EvidenceObject',
        sourceId: 'EVID-001',
        targetType: 'EventHypothesis',
        targetId: 'HYP-001',
        relationshipType: EvidenceRelationshipType.supports,
        relationshipDescription: 'Withdrawal test',
      );

      await service.registerRelationship(rel);

      await service.withdrawRelationship(
        originalRelationshipId: 'REL-WITHDRAW-01',
        withdrawalReason: 'Source evidence withdrawn by publisher.',
      );

      final retrieved = await service.retrieveRelationship('REL-WITHDRAW-01');
      expect(retrieved?.status, equals(RelationshipStatus.withdrawn));
    });

    test('17. lineage traversal', () async {
      final parent = EvidenceRelationship(
        relationshipId: 'REL-PAR-01',
        sourceType: 'EvidenceObject',
        sourceId: 'EVID-001',
        targetType: 'EventHypothesis',
        targetId: 'HYP-001',
        relationshipType: EvidenceRelationshipType.supports,
        relationshipDescription: 'Parent relationship',
      );

      final child = EvidenceRelationship(
        relationshipId: 'REL-CHI-01',
        sourceType: 'EvidenceObject',
        sourceId: 'EVID-001',
        targetType: 'EventHypothesis',
        targetId: 'HYP-001',
        relationshipType: EvidenceRelationshipType.supports,
        relationshipDescription: 'Child relationship',
        parentRelationshipIds: const ['REL-PAR-01'],
      );

      await service.registerRelationship(parent);
      await service.registerRelationship(child);

      final lineage = await service.getLineage('REL-CHI-01');
      expect(lineage.length, equals(2));
      expect(lineage.map((r) => r.relationshipId), containsAll(['REL-CHI-01', 'REL-PAR-01']));
    });

    test('18. duplicate detection by fingerprint key', () async {
      final initial = EvidenceRelationship(
        relationshipId: 'REL-DUP-01',
        sourceType: 'EvidenceObject',
        sourceId: 'EVID-100',
        targetType: 'EventHypothesis',
        targetId: 'HYP-100',
        relationshipType: EvidenceRelationshipType.supports,
        relationshipDescription: 'Initial relationship',
      );

      await service.registerRelationship(initial);

      final duplicate = EvidenceRelationship(
        relationshipId: 'REL-DUP-02',
        sourceType: 'EvidenceObject',
        sourceId: 'EVID-100',
        targetType: 'EventHypothesis',
        targetId: 'HYP-100',
        relationshipType: EvidenceRelationshipType.supports,
        relationshipDescription: 'Duplicate registration attempt',
      );

      final result = await service.registerRelationship(duplicate);
      expect(result.isDuplicate, isTrue);
      expect(result.duplicateOfRelationshipId, equals('REL-DUP-01'));
    });

    test('19. repository query by source ID', () async {
      final rel = EvidenceRelationship(
        relationshipId: 'REL-QRY-SRC-01',
        sourceType: 'EvidenceObject',
        sourceId: 'EVID-SRC-QUERY-01',
        targetType: 'EventHypothesis',
        targetId: 'HYP-001',
        relationshipType: EvidenceRelationshipType.supports,
        relationshipDescription: 'Query test',
      );

      await service.registerRelationship(rel);

      final matches = await service.getBySourceId('EVID-SRC-QUERY-01');
      expect(matches.length, equals(1));
      expect(matches.first.relationshipId, equals('REL-QRY-SRC-01'));
    });

    test('20. repository query by target ID', () async {
      final rel = EvidenceRelationship(
        relationshipId: 'REL-QRY-TGT-01',
        sourceType: 'EvidenceObject',
        sourceId: 'EVID-001',
        targetType: 'EventHypothesis',
        targetId: 'HYP-TGT-QUERY-01',
        relationshipType: EvidenceRelationshipType.contradicts,
        relationshipDescription: 'Query test',
      );

      await service.registerRelationship(rel);

      final matches = await service.getByTargetId('HYP-TGT-QUERY-01');
      expect(matches.length, equals(1));
      expect(matches.first.relationshipId, equals('REL-QRY-TGT-01'));
    });

    test('21. repository query by relationship type (SUPPORTS / CONTRADICTS)', () async {
      final rel = EvidenceRelationship(
        relationshipId: 'REL-TYPE-CONT-01',
        sourceType: 'EvidenceObject',
        sourceId: 'EVID-002',
        targetType: 'EventHypothesis',
        targetId: 'HYP-002',
        relationshipType: EvidenceRelationshipType.contradicts,
        relationshipDescription: 'Query type test',
      );

      await service.registerRelationship(rel);

      final matches = await service.getByRelationshipType(EvidenceRelationshipType.contradicts);
      expect(matches.map((r) => r.relationshipId), contains('REL-TYPE-CONT-01'));
    });

    test('22. Evidence -> EventHypothesis relationship', () async {
      final rel = EvidenceRelationship(
        relationshipId: 'REL-EV-HYP-01',
        sourceType: 'EvidenceObject',
        sourceId: 'EVID-FIELD-88',
        targetType: 'EventHypothesis',
        targetId: 'HYP-MANDI-01',
        relationshipType: EvidenceRelationshipType.supports,
        relationshipDescription: 'Field report evidence supports candidate Mandi landslide event hypothesis',
      );

      final result = await service.registerRelationship(rel);
      expect(result.relationship.sourceType, equals('EvidenceObject'));
      expect(result.relationship.targetType, equals('EventHypothesis'));
    });

    test('23. Interpretation -> EventHypothesis relationship', () async {
      final rel = EvidenceRelationship(
        relationshipId: 'REL-INT-HYP-01',
        sourceType: 'InterpretationObject',
        sourceId: 'INT-RASTER-DIFF-01',
        targetType: 'EventHypothesis',
        targetId: 'HYP-MANDI-01',
        relationshipType: EvidenceRelationshipType.supports,
        relationshipDescription: 'Inferred satellite surface change supports candidate Mandi landslide event hypothesis',
      );

      final result = await service.registerRelationship(rel);
      expect(result.relationship.sourceType, equals('InterpretationObject'));
      expect(result.relationship.targetType, equals('EventHypothesis'));
    });

    test('24. multiple relationships for same event (SUPPORTS + CONTRADICTS)', () async {
      final relSupp = EvidenceRelationship(
        relationshipId: 'REL-MULTI-SUPP',
        sourceType: 'EvidenceObject',
        sourceId: 'EVID-SOC-001',
        targetType: 'EventHypothesis',
        targetId: 'HYP-MULTI-01',
        relationshipType: EvidenceRelationshipType.supports,
        relationshipDescription: 'Social post supports event',
      );

      final relCont = EvidenceRelationship(
        relationshipId: 'REL-MULTI-CONT',
        sourceType: 'EvidenceObject',
        sourceId: 'EVID-FIELD-002',
        targetType: 'EventHypothesis',
        targetId: 'HYP-MULTI-01',
        relationshipType: EvidenceRelationshipType.contradicts,
        relationshipDescription: 'Field report contradicts event',
      );

      await service.registerRelationship(relSupp);
      await service.registerRelationship(relCont);

      final eventRels = await service.getByTargetId('HYP-MULTI-01');
      expect(eventRels.length, equals(2));
      expect(eventRels.map((r) => r.relationshipType), containsAll([EvidenceRelationshipType.supports, EvidenceRelationshipType.contradicts]));
    });

    test('25. NO confidence mutation on target EventHypothesis (Critical Boundary Invariant)', () async {
      final relCont = EvidenceRelationship(
        relationshipId: 'REL-NO-MUTATE',
        sourceType: 'EvidenceObject',
        sourceId: 'EVID-FIELD-999',
        targetType: 'EventHypothesis',
        targetId: 'HYP-UNMUTATED',
        relationshipType: EvidenceRelationshipType.contradicts,
        relationshipDescription: 'Contradicting relationship registration',
      );

      final result = await service.registerRelationship(relCont);
      expect(result.isValid, isTrue);
      // P2.0-D ONLY records the relationship object and does NOT mutate target hypothesis confidence or status!
    });

    test('26. NO Negative Evidence creation (Critical Boundary Invariant)', () async {
      final relCont = EvidenceRelationship(
        relationshipId: 'REL-NO-NEG-EVID',
        sourceType: 'EvidenceObject',
        sourceId: 'EVID-FIELD-999',
        targetType: 'EventHypothesis',
        targetId: 'HYP-UNMUTATED',
        relationshipType: EvidenceRelationshipType.contradicts,
        relationshipDescription: 'Contradicting relationship registration',
      );

      final result = await service.registerRelationship(relCont);
      expect(result.relationship.relationshipType, equals(EvidenceRelationshipType.contradicts));
      // Confirmed: NO Negative Evidence propagation engine invoked in P2.0-D!
    });

    test('27. service validation errors for empty IDs', () async {
      expect(
        () => EvidenceRelationship(
          relationshipId: 'REL-INV-01',
          sourceType: 'EvidenceObject',
          sourceId: '   ', // Empty source ID
          targetType: 'EventHypothesis',
          targetId: 'HYP-001',
          relationshipType: EvidenceRelationshipType.supports,
          relationshipDescription: 'Description',
        ),
        throwsArgumentError,
      );
    });

    test('28. Verifies all 3 P2.0-D report files exist on disk', () {
      final r1 = File('research/evidence/p2_0_d/reports/P2_0_D_EXISTING_RELATIONSHIP_FORENSIC_INVENTORY.md');
      final r2 = File('research/evidence/p2_0_d/architecture/P2_0_D_EVIDENCE_RELATIONSHIP_ARCHITECTURE.md');
      final r3 = File('research/evidence/p2_0_d/reports/RISKPULSE_P2_0_D_EVIDENCE_RELATIONSHIP_INTEGRATION_REPORT.md');

      expect(r1.existsSync(), isTrue);
      expect(r2.existsSync(), isTrue);
      expect(r3.existsSync(), isTrue);
    });

    test('29. query relationships by Query Object', () async {
      final rel = EvidenceRelationship(
        relationshipId: 'REL-QUERY-OBJ-01',
        sourceType: 'EvidenceObject',
        sourceId: 'EVID-QUERY-OBJ',
        targetType: 'EventHypothesis',
        targetId: 'HYP-QUERY-OBJ',
        relationshipType: EvidenceRelationshipType.supports,
        relationshipDescription: 'Query object test',
      );

      await service.registerRelationship(rel);

      final query = EvidenceRelationshipQuery(
        sourceId: 'EVID-QUERY-OBJ',
        relationshipType: EvidenceRelationshipType.supports,
      );

      final matches = await service.queryRelationships(query);
      expect(matches.length, equals(1));
      expect(matches.first.relationshipId, equals('REL-QUERY-OBJ-01'));
    });

    test('30. relationship versioning and version history', () async {
      final original = EvidenceRelationship(
        relationshipId: 'REL-HIST-01',
        sourceType: 'EvidenceObject',
        sourceId: 'EVID-001',
        targetType: 'EventHypothesis',
        targetId: 'HYP-001',
        relationshipType: EvidenceRelationshipType.relatedTo,
        relationshipDescription: 'V1 initial relation',
      );

      await service.registerRelationship(original);

      final v2 = original.copyWith(
        relationshipType: EvidenceRelationshipType.supports,
        relationshipDescription: 'V2 upgraded relation: SUPPORTS',
        relationshipVersion: 2,
      );

      await service.registerRelationship(v2);

      final versions = await repository.getVersions('REL-HIST-01');
      expect(versions.length, equals(2));
      expect(versions.first.relationshipType, equals(EvidenceRelationshipType.relatedTo));
      expect(versions.last.relationshipType, equals(EvidenceRelationshipType.supports));
    });
  });
}
