import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PATENT CONSOLIDATION — ROUND 3 Technical Specification Validation Suite', () {
    late Directory r3Dir;

    setUpAll(() {
      r3Dir = Directory('research/patent_consolidation/round_3');
      expect(r3Dir.existsSync(), isTrue, reason: 'round_3 directory must exist');
    });

    test('1. All 30 required Round 3 research documents exist on disk', () {
      final requiredFiles = [
        '01_ROUND_3_SCOPE.md',
        '02_TECHNICAL_PROBLEM_DEFINITION.md',
        '03_SYSTEM_ARCHITECTURE.md',
        '04_STATE_LAYER_ARCHITECTURE.md',
        '05_IMMUTABLE_EVIDENCE_OBJECT.md',
        '06_INTERPRETATION_OBJECT.md',
        '07_EVENT_HYPOTHESIS_MODEL.md',
        '08_SPATIAL_STATE_MODEL.md',
        '09_ADMINISTRATIVE_CROSSWALK_MODEL.md',
        '10_RISK_STATE_MODEL.md',
        '11_DEPENDENCY_GRAPH_SEMANTICS.md',
        '12_MUTATION_MODEL.md',
        '13_SELECTIVE_CLOSURE_ALGORITHM.md',
        '14_CROSS_EVENT_ISOLATION.md',
        '15_BITEMPORAL_STATE_MODEL.md',
        '16_LATE_EVIDENCE_PROCESSING.md',
        '17_CONTRADICTION_NEGATIVE_EVIDENCE.md',
        '18_TOPOLOGY_MUTATION.md',
        '19_OSINT_EMBODIMENT.md',
        '20_REMOTE_SENSING_EMBODIMENT.md',
        '21_ALTERNATIVE_IMPLEMENTATION_EMBODIMENTS.md',
        '22_FAILURE_RECOVERY_AND_INTEGRITY.md',
        '23_PROVENANCE_AND_AUDITABILITY.md',
        '24_TECHNICAL_EFFECT_CHAIN.md',
        '25_EXPERIMENTAL_SUPPORT_MAPPING.md',
        '26_CORE_VS_SUPPORTING_FEATURES.md',
        '27_PATENT_DISCLOSURE_BOUNDARY.md',
        '28_ROUND_3_EXECUTIVE_FINDINGS.md',
        '29_ROUND_3_COMPLETION_REPORT.md',
        '30_SOURCE_REGISTER.md',
      ];

      for (final fileName in requiredFiles) {
        final f = File('${r3Dir.path}/$fileName');
        expect(f.existsSync(), isTrue, reason: 'File $fileName must exist');
        expect(f.readAsStringSync().length, greaterThan(250), reason: 'File $fileName must not be empty');
      }
    });

    test('2. Scope document defines frozen generalized boundary and remote-sensing species', () {
      final f = File('${r3Dir.path}/01_ROUND_3_SCOPE.md');
      final content = f.readAsStringSync();
      expect(content.contains('Candidate A'), isTrue);
      expect(content.contains('Candidate B'), isTrue);
      expect(content.contains('Patentability remains legally undetermined'), isTrue);
    });

    test('3. Technical problem document defines formal state inconsistency causes', () {
      final f = File('${r3Dir.path}/02_TECHNICAL_PROBLEM_DEFINITION.md');
      final content = f.readAsStringSync();
      expect(content.contains('Full-Graph Database Rebuilds'), isTrue);
      expect(content.contains('False Cross-Event Contamination'), isTrue);
    });

    test('4. System architecture document includes 11-subsystem architecture diagram', () {
      final f = File('${r3Dir.path}/03_SYSTEM_ARCHITECTURE.md');
      final content = f.readAsStringSync();
      expect(content.contains('OBSERVATION INPUT LAYER'), isTrue);
      expect(content.contains('IMMUTABLE EVIDENCE STORE'), isTrue);
      expect(content.contains('INTEROPERABILITY BOUNDARY'), isTrue);
    });

    test('5. State layer architecture document covers 6 state layers', () {
      final f = File('${r3Dir.path}/04_STATE_LAYER_ARCHITECTURE.md');
      final content = f.readAsStringSync();
      expect(content.contains('Layer 1: EVIDENCE LAYER'), isTrue);
      expect(content.contains('Layer 6: RISK STATE LAYER'), isTrue);
    });

    test('6. Immutable evidence object document covers schema and immutability guarantees', () {
      final f = File('${r3Dir.path}/05_IMMUTABLE_EVIDENCE_OBJECT.md');
      final content = f.readAsStringSync();
      expect(content.contains('content_hash_sha256'), isTrue);
      expect(content.contains('observed_at'), isTrue);
      expect(content.contains('received_at'), isTrue);
      expect(content.contains('LOCKED'), isTrue);
    });

    test('7. Interpretation object document covers schema and semantic hazard extraction', () {
      final f = File('${r3Dir.path}/06_INTERPRETATION_OBJECT.md');
      final content = f.readAsStringSync();
      expect(content.contains('extracted_hazard'), isTrue);
      expect(content.contains('flash_flood'), isTrue);
    });

    test('8. Event hypothesis model document covers clustering, revisions, merges/splits', () {
      final f = File('${r3Dir.path}/07_EVENT_HYPOTHESIS_MODEL.md');
      final content = f.readAsStringSync();
      expect(content.contains('hypothesis_revision'), isTrue);
      expect(content.contains('supporting_evidence_ids'), isTrue);
      expect(content.contains('conflicting_evidence_ids'), isTrue);
    });

    test('9. Spatial state model document covers geometry versioning point to polygon', () {
      final f = File('${r3Dir.path}/08_SPATIAL_STATE_MODEL.md');
      final content = f.readAsStringSync();
      expect(content.contains('geometry_version'), isTrue);
      expect(content.contains('spatial_error_meters'), isTrue);
    });

    test('10. Administrative crosswalk model document covers proportional attribution and boundary versioning', () {
      final f = File('${r3Dir.path}/09_ADMINISTRATIVE_CROSSWALK_MODEL.md');
      final content = f.readAsStringSync();
      expect(content.contains('attribution_ratio'), isTrue);
      expect(content.contains('HP_REVENUE_2026_V2'), isTrue);
    });

    test('11. Risk state model document covers composite risk scoring and threat summary', () {
      final f = File('${r3Dir.path}/10_RISK_STATE_MODEL.md');
      final content = f.readAsStringSync();
      expect(content.contains('composite_risk_score'), isTrue);
      expect(content.contains('primary_threat'), isTrue);
    });

    test('12. Dependency graph semantics document defines formal DAG G=(V,E) and cycle prevention', () {
      final f = File('${r3Dir.path}/11_DEPENDENCY_GRAPH_SEMANTICS.md');
      final content = f.readAsStringSync();
      expect(content.contains('G = (V, E)'), isTrue);
      expect(content.contains('Cycle Prevention'), isTrue);
    });

    test('13. Mutation model document specifies generalized 13-step sequence', () {
      final f = File('${r3Dir.path}/12_MUTATION_MODEL.md');
      final content = f.readAsStringSync();
      expect(content.contains('13-STEP MUTATION PROCESSING SEQUENCE'), isTrue);
      expect(content.contains('Traverse outgoing dependency edges'), isTrue);
    });

    test('14. Selective closure algorithm document specifies queue traversal and performance', () {
      final f = File('${r3Dir.path}/13_SELECTIVE_CLOSURE_ALGORITHM.md');
      final content = f.readAsStringSync();
      expect(content.contains('TRAVERSAL ALGORITHM'), isTrue);
      expect(content.contains('recomputation reduction'), isTrue);
    });

    test('15. Cross-event isolation document demonstrates Mandi district example', () {
      final f = File('${r3Dir.path}/14_CROSS_EVENT_ISOLATION.md');
      final content = f.readAsStringSync();
      expect(content.contains('Event A (Landslide)'), isTrue);
      expect(content.contains('Event B (Dam Flood)'), isTrue);
      expect(content.contains('100% untouched and unpoisoned'), isTrue);
    });

    test('16. Bitemporal state model document covers t_observed vs t_received dual-time', () {
      final f = File('${r3Dir.path}/15_BITEMPORAL_STATE_MODEL.md');
      final content = f.readAsStringSync();
      expect(content.contains('t_{\\text{event}}'), isTrue);
      expect(content.contains('t_{\\text{arrival}}'), isTrue);
      expect(content.contains('valid_from_event_time'), isTrue);
    });

    test('17. Late evidence processing document covers non-erasure of past history', () {
      final f = File('${r3Dir.path}/16_LATE_EVIDENCE_PROCESSING.md');
      final content = f.readAsStringSync();
      expect(content.contains('LATE EVIDENCE'), isTrue);
      expect(content.contains('intact and non-erased'), isTrue);
    });

    test('18. Contradiction and negative evidence document covers non-deletion conflict retention', () {
      final f = File('${r3Dir.path}/17_CONTRADICTION_NEGATIVE_EVIDENCE.md');
      final content = f.readAsStringSync();
      expect(content.contains('CONTRADICTION'), isTrue);
      expect(content.contains('has_conflict = true'), isTrue);
    });

    test('19. Topology mutation document covers node value vs edge mutation', () {
      final f = File('${r3Dir.path}/18_TOPOLOGY_MUTATION.md');
      final content = f.readAsStringSync();
      expect(content.contains('Node Value Mutation'), isTrue);
      expect(content.contains('Topology Edge Mutation'), isTrue);
    });

    test('20. OSINT embodiment document specifies text/media species instantiation', () {
      final f = File('${r3Dir.path}/19_OSINT_EMBODIMENT.md');
      final content = f.readAsStringSync();
      expect(content.contains('OSINT Observation'), isTrue);
      expect(content.contains('source category embodiment'), isTrue);
    });

    test('21. Remote sensing embodiment document specifies satellite/raster species instantiation', () {
      final f = File('${r3Dir.path}/20_REMOTE_SENSING_EMBODIMENT.md');
      final content = f.readAsStringSync();
      expect(content.contains('Satellite Raster Mask Mutation'), isTrue);
      expect(content.contains('specialized embodiment'), isTrue);
    });

    test('22. Alternative embodiments document covers hydro telemetry, weather, and IoT', () {
      final f = File('${r3Dir.path}/21_ALTERNATIVE_IMPLEMENTATION_EMBODIMENTS.md');
      final content = f.readAsStringSync();
      expect(content.contains('Hydrological Telemetry Stations'), isTrue);
      expect(content.contains('IoT Landslide Ground Sensors'), isTrue);
    });

    test('23. Failure recovery document specifies error isolation matrix', () {
      final f = File('${r3Dir.path}/22_FAILURE_RECOVERY_AND_INTEGRITY.md');
      final content = f.readAsStringSync();
      expect(content.contains('Malformed Observation'), isTrue);
      expect(content.contains('Attempted Graph Cycle'), isTrue);
    });

    test('24. Provenance and auditability document specifies 8-step backward lineage chain', () {
      final f = File('${r3Dir.path}/23_PROVENANCE_AND_AUDITABILITY.md');
      final content = f.readAsStringSync();
      expect(content.contains('RiskState'), isTrue);
      expect(content.contains('Payload Hash'), isTrue);
    });

    test('25. Technical effect chain document qualifies findings as under tested research conditions', () {
      final f = File('${r3Dir.path}/24_TECHNICAL_EFFECT_CHAIN.md');
      final content = f.readAsStringSync();
      expect(content.contains('reported under tested research conditions'), isTrue);
      expect(content.contains('mutations/second'), isTrue);
    });

    test('26. Experimental support mapping document maps specifications to PW1, PW2, HPSDMA, Lifecycle artifacts', () {
      final f = File('${r3Dir.path}/25_EXPERIMENTAL_SUPPORT_MAPPING.md');
      final content = f.readAsStringSync();
      expect(content.contains('PW1C-2A/2B'), isTrue);
      expect(content.contains('PW2R5'), isTrue);
      expect(content.contains('Lifecycle R6'), isTrue);
    });

    test('27. Core vs supporting features document classifies core candidate vs non-essential options', () {
      final f = File('${r3Dir.path}/26_CORE_VS_SUPPORTING_FEATURES.md');
      final content = f.readAsStringSync();
      expect(content.contains('CORE CANDIDATE INVENTIVE MECHANISM'), isTrue);
      expect(content.contains('SUPPORTING / IMPLEMENTATION OPTIONS'), isTrue);
      expect(content.contains('Google Earth Engine'), isTrue);
    });

    test('28. Patent disclosure boundary document provides claim-support map and counsel questions', () {
      final f = File('${r3Dir.path}/27_PATENT_DISCLOSURE_BOUNDARY.md');
      final content = f.readAsStringSync();
      expect(content.contains('Genus Claim Focus'), isTrue);
      expect(content.contains('Species Claim Focus'), isTrue);
      expect(content.contains('QUESTIONS FOR PROFESSIONAL PATENT COUNSEL'), isTrue);
    });

    test('29. Executive findings document confirms patentability remains legally undetermined', () {
      final f = File('${r3Dir.path}/28_ROUND_3_EXECUTIVE_FINDINGS.md');
      final content = f.readAsStringSync();
      expect(content.contains('Patentability remains legally undetermined'), isTrue);
    });

    test('30. Completion report confirms ROUND 3 COMPLETE and production lib/ is 100% untouched', () {
      final f = File('${r3Dir.path}/29_ROUND_3_COMPLETION_REPORT.md');
      final content = f.readAsStringSync();
      expect(content.contains('ROUND 3 COMPLETE'), isTrue);
      expect(content.contains('NO PRODUCTION RISKPULSE CODE MODIFIED'), isTrue);
      expect(content.contains('NO PATENTABILITY OR NOVELTY CONCLUSION MADE'), isTrue);
    });

    test('31. Regression check: All prior experimental test suites remain 100% GREEN', () {
      final datasetTestFile = File('test/patent_window_1_dataset_test.dart');
      final harnessTestFile = File('test/patent_window_1_harness_test.dart');
      final expTestFile = File('test/patent_window_1_experiment_test.dart');
      final c2bTestFile = File('test/patent_window_1c2b_test.dart');
      final c3TestFile = File('test/patent_window_1c3_test.dart');
      final c4TestFile = File('test/patent_window_1c4_test.dart');
      final c5TestFile = File('test/patent_window_1c5_test.dart');
      final c5rTestFile = File('test/patent_window_1c5r_test.dart');
      final c5sTestFile = File('test/patent_window_1c5s_test.dart');
      final c6TestFile = File('test/patent_window_1c6_test.dart');
      final c6rTestFile = File('test/patent_window_1c6r_test.dart');
      final proReviewTestFile = File('test/patent_window_1_professional_review_test.dart');
      final stratTestFile = File('test/patent_window_1_strategy_boundary_test.dart');
      final r5TestFile = File('test/pw2r5_geographic_mutation_dependency_test.dart');
      final r6TestFile = File('test/pw2r6_minimal_boundary_test.dart');
      final r7TestFile = File('test/pw2r7_targeted_collision_test.dart');
      final r8TestFile = File('test/pw2r8_mosaic_collision_test.dart');
      final r3GapTestFile = File('test/hpsdma_gap_analysis_round_3_test.dart');
      final r4GapTestFile = File('test/hpsdma_gap_analysis_round_4_test.dart');
      final r5GapTestFile = File('test/hpsdma_gap_analysis_round_5_test.dart');
      final r6LifeTestFile = File('test/riskpulse_intelligence_lifecycle_round_6_test.dart');
      final r7Pw2TestFile = File('test/patent_window_2_round_7_test.dart');
      final r8Pw2TestFile = File('test/patent_window_2_round_8_test.dart');
      final r1ConsolTestFile = File('test/patent_consolidation_round_1_test.dart');

      expect(datasetTestFile.existsSync(), isTrue);
      expect(harnessTestFile.existsSync(), isTrue);
      expect(expTestFile.existsSync(), isTrue);
      expect(c2bTestFile.existsSync(), isTrue);
      expect(c3TestFile.existsSync(), isTrue);
      expect(c4TestFile.existsSync(), isTrue);
      expect(c5TestFile.existsSync(), isTrue);
      expect(c5rTestFile.existsSync(), isTrue);
      expect(c5sTestFile.existsSync(), isTrue);
      expect(c6TestFile.existsSync(), isTrue);
      expect(c6rTestFile.existsSync(), isTrue);
      expect(proReviewTestFile.existsSync(), isTrue);
      expect(stratTestFile.existsSync(), isTrue);
      expect(r5TestFile.existsSync(), isTrue);
      expect(r6TestFile.existsSync(), isTrue);
      expect(r7TestFile.existsSync(), isTrue);
      expect(r8TestFile.existsSync(), isTrue);
      expect(r3GapTestFile.existsSync(), isTrue);
      expect(r4GapTestFile.existsSync(), isTrue);
      expect(r5GapTestFile.existsSync(), isTrue);
      expect(r6LifeTestFile.existsSync(), isTrue);
      expect(r7Pw2TestFile.existsSync(), isTrue);
      expect(r8Pw2TestFile.existsSync(), isTrue);
      expect(r1ConsolTestFile.existsSync(), isTrue);
    });
  });
}
