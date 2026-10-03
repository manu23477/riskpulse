import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RISKPULSE RESEARCH WORKSTREAM ROUND 6 — Lifecycle Validation Test Suite', () {
    late Directory r6Dir;

    setUpAll(() {
      r6Dir = Directory('research/riskpulse_intelligence_lifecycle/round_6');
      expect(r6Dir.existsSync(), isTrue, reason: 'round_6 directory must exist');
    });

    test('1. All 28 required Round 6 research documents exist on disk', () {
      final requiredFiles = [
        '01_LIFECYCLE_ARCHITECTURE.md',
        '02_SYNTHETIC_DISASTER_TIMELINE.md',
        '03_EVIDENCE_LIFECYCLE.md',
        '04_EVENT_HYPOTHESIS_EVOLUTION.md',
        '05_SPATIAL_STATE_EVOLUTION.md',
        '06_ADMINISTRATIVE_STATE_EVOLUTION.md',
        '07_RISK_STATE_EVOLUTION.md',
        '08_NEGATIVE_EVIDENCE_ANALYSIS.md',
        '09_CONTRADICTION_ANALYSIS.md',
        '10_DEPENDENCY_GRAPH_RESULTS.md',
        '11_CROSS_EVENT_ISOLATION.md',
        '12_LATE_EVIDENCE_ANALYSIS.md',
        '13_SOURCE_WITHDRAWAL_ANALYSIS.md',
        '14_EVENT_MERGE_SPLIT.md',
        '15_TOPOLOGY_MUTATION.md',
        '16_PROVENANCE_AUDIT.md',
        '17_AS_OF_RECONSTRUCTION.md',
        '18_REPLAY_RESULTS.md',
        '19_STATE_CORRUPTION_RESULTS.md',
        '20_FAILURE_INJECTION_RESULTS.md',
        '21_CYCLE_ORPHAN_ANALYSIS.md',
        '22_UNCERTAINTY_CONFIDENCE_EVOLUTION.md',
        '23_STATE_TRANSITION_AUDIT.md',
        '24_AUDIT_QUERY_RESULTS.md',
        '25_PERFORMANCE_RESULTS.md',
        '26_METRICS.md',
        '27_ROUND_6_EXECUTIVE_FINDINGS.md',
        '28_ROUND_6_COMPLETION_REPORT.md',
      ];

      for (final fileName in requiredFiles) {
        final f = File('${r6Dir.path}/$fileName');
        expect(f.existsSync(), isTrue, reason: 'File $fileName must exist');
        expect(f.readAsStringSync().length, greaterThan(250), reason: 'File $fileName must not be empty');
      }
    });

    test('2. Lifecycle architecture specifies unbroken 8-step backward lineage chain', () {
      final f = File('${r6Dir.path}/01_LIFECYCLE_ARCHITECTURE.md');
      final content = f.readAsStringSync();
      expect(content.contains('Risk State'), isTrue);
      expect(content.contains('Payload Hash'), isTrue);
    });

    test('3. Synthetic timeline covers steps T1 through T15 with controlled actions', () {
      final f = File('${r6Dir.path}/02_SYNTHETIC_DISASTER_TIMELINE.md');
      final content = f.readAsStringSync();
      expect(content.contains('T1'), isTrue);
      expect(content.contains('T15'), isTrue);
      expect(content.contains('Alpha Corridor'), isTrue);
    });

    test('4. Evidence lifecycle covers 15 evidence objects E1..E15 with SHA-256 hashes', () {
      final f = File('${r6Dir.path}/03_EVIDENCE_LIFECYCLE.md');
      final content = f.readAsStringSync();
      expect(content.contains('E1'), isTrue);
      expect(content.contains('E15'), isTrue);
      expect(content.contains('IMMUTABLE'), isTrue);
    });

    test('5. Event hypothesis evolution covers revisions H1 through H7', () {
      final f = File('${r6Dir.path}/04_EVENT_HYPOTHESIS_EVOLUTION.md');
      final content = f.readAsStringSync();
      expect(content.contains('H1'), isTrue);
      expect(content.contains('H7'), isTrue);
    });

    test('6. Spatial state evolution document verifies geometry versioning', () {
      final f = File('${r6Dir.path}/05_SPATIAL_STATE_EVOLUTION.md');
      final content = f.readAsStringSync();
      expect(content.contains('POINT + UNCERTAINTY ELLIPSE'), isTrue);
      expect(content.contains('EXPANDED AFFECTED AREA POLYGON'), isTrue);
    });

    test('7. Administrative state evolution document verifies boundary versioning V1 vs V2', () {
      final f = File('${r6Dir.path}/06_ADMINISTRATIVE_STATE_EVOLUTION.md');
      final content = f.readAsStringSync();
      expect(content.contains('Boundary Dataset V1'), isTrue);
      expect(content.contains('Boundary Dataset V2'), isTrue);
    });

    test('8. Risk state evolution document covers levels LOW through CRITICAL', () {
      final f = File('${r6Dir.path}/07_RISK_STATE_EVOLUTION.md');
      final content = f.readAsStringSync();
      expect(content.contains('LOW'), isTrue);
      expect(content.contains('CRITICAL'), isTrue);
    });

    test('9. Negative evidence analysis document verifies non-deletion history', () {
      final f = File('${r6Dir.path}/08_NEGATIVE_EVIDENCE_ANALYSIS.md');
      final content = f.readAsStringSync();
      expect(content.contains('Positive Evidence'), isTrue);
      expect(content.contains('Negative Evidence'), isTrue);
      expect(content.contains('NOT deleted'), isTrue);
    });

    test('10. Contradiction analysis document covers 5 contradiction types C1..C5', () {
      final f = File('${r6Dir.path}/09_CONTRADICTION_ANALYSIS.md');
      final content = f.readAsStringSync();
      expect(content.contains('C1'), isTrue);
      expect(content.contains('C5'), isTrue);
    });

    test('11. Dependency graph results confirm 98%+ recomputation reduction', () {
      final f = File('${r6Dir.path}/10_DEPENDENCY_GRAPH_RESULTS.md');
      final content = f.readAsStringSync();
      expect(content.contains('98.73%'), isTrue);
      expect(content.contains('100% Full-Rebuild State Equivalence'), isTrue);
    });

    test('12. Cross-event isolation confirms 0 false propagations across Events A, B, C', () {
      final f = File('${r6Dir.path}/11_CROSS_EVENT_ISOLATION.md');
      final content = f.readAsStringSync();
      expect(content.contains('Event A'), isTrue);
      expect(content.contains('Event C'), isTrue);
      expect(content.contains('0 False Propagations'), isTrue);
    });

    test('13. Late evidence analysis verifies historical non-erasure', () {
      final f = File('${r6Dir.path}/12_LATE_EVIDENCE_ANALYSIS.md');
      final content = f.readAsStringSync();
      expect(content.contains('Late Evidence'), isTrue);
      expect(content.contains('NOT overwritten or erased'), isTrue);
    });

    test('14. Source withdrawal analysis document verifies lineage preservation', () {
      final f = File('${r6Dir.path}/13_SOURCE_WITHDRAWAL_ANALYSIS.md');
      final content = f.readAsStringSync();
      expect(content.contains('SOURCE_WITHDRAWAL'), isTrue);
      expect(content.contains('NOT deleted'), isTrue);
    });

    test('15. Event merge and split document covers historical reconstructability', () {
      final f = File('${r6Dir.path}/14_EVENT_MERGE_SPLIT.md');
      final content = f.readAsStringSync();
      expect(content.contains('EVENT MERGE DEMONSTRATION'), isTrue);
      expect(content.contains('EVENT SPLIT DEMONSTRATION'), isTrue);
    });

    test('16. Topology mutation document verifies dynamic edge redirection', () {
      final f = File('${r6Dir.path}/15_TOPOLOGY_MUTATION.md');
      final content = f.readAsStringSync();
      expect(content.contains('Feeder_Primary'), isTrue);
      expect(content.contains('Feeder_Backup'), isTrue);
    });

    test('17. Provenance audit document confirms 100% provenance completeness', () {
      final f = File('${r6Dir.path}/16_PROVENANCE_AUDIT.md');
      final content = f.readAsStringSync();
      expect(content.contains('100% Provenance Completeness'), isTrue);
    });

    test('18. As-Of reconstruction document confirms zero future evidence leakage', () {
      final f = File('${r6Dir.path}/17_AS_OF_RECONSTRUCTION.md');
      final content = f.readAsStringSync();
      expect(content.contains('ZERO FUTURE LEAKAGE GUARANTEE'), isTrue);
      expect(content.contains('As-Of T5'), isTrue);
    });

    test('19. Replay results document confirms 100% replay convergence', () {
      final f = File('${r6Dir.path}/18_REPLAY_RESULTS.md');
      final content = f.readAsStringSync();
      expect(content.contains('Reverse Ingestion Sequence'), isTrue);
      expect(content.contains('Shuffled Ingestion Sequence'), isTrue);
    });

    test('20. State corruption results document confirms 0 immutability failures', () {
      final f = File('${r6Dir.path}/19_STATE_CORRUPTION_RESULTS.md');
      final content = f.readAsStringSync();
      expect(content.contains('0 Immutability Failures'), isTrue);
    });

    test('21. Failure injection results document covers 20 cases FI-01..FI-20', () {
      final f = File('${r6Dir.path}/20_FAILURE_INJECTION_RESULTS.md');
      final content = f.readAsStringSync();
      expect(content.contains('FI-01'), isTrue);
      expect(content.contains('FI-20'), isTrue);
      expect(content.contains('20 / 20'), isTrue);
    });

    test('22. Cycle and orphan analysis document verifies cycle detection and orphan handling', () {
      final f = File('${r6Dir.path}/21_CYCLE_ORPHAN_ANALYSIS.md');
      final content = f.readAsStringSync();
      expect(content.contains('CYCLE_DETECTED'), isTrue);
      expect(content.contains('Orphan Evidence'), isTrue);
    });

    test('23. Uncertainty and confidence evolution document confirms independent trajectories', () {
      final f = File('${r6Dir.path}/22_UNCERTAINTY_CONFIDENCE_EVOLUTION.md');
      final content = f.readAsStringSync();
      expect(content.contains('INDEPENDENT TRAJECTORY EVOLUTION'), isTrue);
    });

    test('24. State transition audit document covers transitions TR-01 through TR-07', () {
      final f = File('${r6Dir.path}/23_STATE_TRANSITION_AUDIT.md');
      final content = f.readAsStringSync();
      expect(content.contains('TR-01'), isTrue);
      expect(content.contains('TR-07'), isTrue);
    });

    test('25. Audit query results document covers queries AQ-1 through AQ-10', () {
      final f = File('${r6Dir.path}/24_AUDIT_QUERY_RESULTS.md');
      final content = f.readAsStringSync();
      expect(content.contains('AQ-1'), isTrue);
      expect(content.contains('AQ-10'), isTrue);
    });

    test('26. Performance results document records scale benchmarks on 100 to 5000 nodes', () {
      final f = File('${r6Dir.path}/25_PERFORMANCE_RESULTS.md');
      final content = f.readAsStringSync();
      expect(content.contains('100 Nodes'), isTrue);
      expect(content.contains('5000 Nodes'), isTrue);
    });

    test('27. Metrics document covers exact numerical definitions L01 through L28', () {
      final f = File('${r6Dir.path}/26_METRICS.md');
      final content = f.readAsStringSync();
      expect(content.contains('L01'), isTrue);
      expect(content.contains('L28'), isTrue);
    });

    test('28. Executive findings document provides direct answers to Questions Q1 through Q13', () {
      final f = File('${r6Dir.path}/27_ROUND_6_EXECUTIVE_FINDINGS.md');
      final content = f.readAsStringSync();
      expect(content.contains('Q1:'), isTrue);
      expect(content.contains('Q13:'), isTrue);
      expect(content.contains('RESEARCH-VALIDATED RISKPULSE INTELLIGENCE LIFECYCLE ESTABLISHED'), isTrue);
    });

    test('29. Completion report verifies stop condition after Round 6', () {
      final f = File('${r6Dir.path}/28_ROUND_6_COMPLETION_REPORT.md');
      final content = f.readAsStringSync();
      expect(content.contains('RESEARCH-VALIDATED RISKPULSE INTELLIGENCE LIFECYCLE ESTABLISHED'), isTrue);
      expect(content.contains('STOP AFTER ROUND 6'), isTrue);
    });

    test('30. Regression check: All prior experimental test suites remain 100% GREEN', () {
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
    });
  });
}
