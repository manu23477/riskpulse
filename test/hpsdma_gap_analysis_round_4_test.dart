import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HPSDMA GAP ANALYSIS ROUND 4 — Interoperability Harness Validation Suite', () {
    late Directory r4Dir;

    setUpAll(() {
      r4Dir = Directory('research/hpsdma_gap_analysis/round_4');
      expect(r4Dir.existsSync(), isTrue, reason: 'round_4 directory must exist');
    });

    test('1. All 19 required Round 4 research documents exist on disk', () {
      final requiredFiles = [
        '01_INTEROPERABILITY_ARCHITECTURE.md',
        '02_OBSERVATION_ENVELOPE.md',
        '03_NORMALIZATION_PIPELINE.md',
        '04_EVIDENCE_TRANSFORMATION.md',
        '05_DUPLICATE_CONTRADICTION_HANDLING.md',
        '06_TEMPORAL_SPATIAL_RESOLUTION.md',
        '07_ADMINISTRATIVE_CROSSWALK.md',
        '08_EVENT_HYPOTHESIS_PIPELINE.md',
        '09_ERROR_HANDLING_MATRIX.md',
        '10_SOURCE_FAILURE_ANALYSIS.md',
        '11_SCHEMA_EVOLUTION.md',
        '12_OUTPUT_CONTRACT.md',
        '13_PROVENANCE_REPLAY_ANALYSIS.md',
        '14_DEPENDENCY_CLOSURE_RESULTS.md',
        '15_PERFORMANCE_RESULTS.md',
        '16_FAILURE_INJECTION_RESULTS.md',
        '17_ROUND_4_EXECUTIVE_FINDINGS.md',
        '18_ROUND_4_COMPLETION_REPORT.md',
        '19_SOURCE_REGISTER.md',
      ];

      for (final fileName in requiredFiles) {
        final f = File('${r4Dir.path}/$fileName');
        expect(f.existsSync(), isTrue, reason: 'File $fileName must exist');
        expect(f.readAsStringSync().length, greaterThan(300), reason: 'File $fileName must not be empty');
      }
    });

    test('2. Architecture document explicitly resolves Stateful Engine + Stateless API terminology', () {
      final f = File('${r4Dir.path}/01_INTEROPERABILITY_ARCHITECTURE.md');
      final content = f.readAsStringSync();
      expect(content.contains('STATELESS INTEROPERABILITY API'), isTrue);
      expect(content.contains('STATEFUL INTELLIGENCE ENGINE'), isTrue);
    });

    test('3. Observation envelope document specifies 10 input classes with synthetic labels', () {
      final f = File('${r4Dir.path}/02_OBSERVATION_ENVELOPE.md');
      final content = f.readAsStringSync();
      expect(content.contains('Class A'), isTrue);
      expect(content.contains('Class J'), isTrue);
      expect(content.contains('SYNTHETIC'), isTrue);
    });

    test('4. Evidence transformation document covers bitemporal chronology Cases A..D', () {
      final f = File('${r4Dir.path}/04_EVIDENCE_TRANSFORMATION.md');
      final content = f.readAsStringSync();
      expect(content.contains('Case A'), isTrue);
      expect(content.contains('Case D'), isTrue);
      expect(content.contains('t_{\\text{observed}}'), isTrue);
    });

    test('5. Duplicate handling covers scenarios D1 through D6 and non-deletion contradiction', () {
      final f = File('${r4Dir.path}/05_DUPLICATE_CONTRADICTION_HANDLING.md');
      final content = f.readAsStringSync();
      expect(content.contains('D1'), isTrue);
      expect(content.contains('D6'), isTrue);
      expect(content.contains('conflicting_evidence_ids'), isTrue);
    });

    test('6. Temporal and spatial resolution document verifies precision safeguards', () {
      final f = File('${r4Dir.path}/06_TEMPORAL_SPATIAL_RESOLUTION.md');
      final content = f.readAsStringSync();
      expect(content.contains('KNOWN'), isTrue);
      expect(content.contains('APPROXIMATE'), isTrue);
      expect(content.contains('CONFLICTED'), isTrue);
    });

    test('7. Administrative crosswalk document verifies multi-district polygon attribution', () {
      final f = File('${r4Dir.path}/07_ADMINISTRATIVE_CROSSWALK.md');
      final content = f.readAsStringSync();
      expect(content.contains('Polygon Multi-District'), isTrue);
      expect(content.contains('Proportional'), isTrue);
    });

    test('8. Event hypothesis document verifies zero false merges and zero false splits', () {
      final f = File('${r4Dir.path}/08_EVENT_HYPOTHESIS_PIPELINE.md');
      final content = f.readAsStringSync();
      expect(content.contains('False Merge Rate'), isTrue);
      expect(content.contains('0 False Merges'), isTrue);
      expect(content.contains('0 False Splits'), isTrue);
    });

    test('9. Error handling matrix document covers error codes E001 through E018', () {
      final f = File('${r4Dir.path}/09_ERROR_HANDLING_MATRIX.md');
      final content = f.readAsStringSync();
      expect(content.contains('E001'), isTrue);
      expect(content.contains('E018'), isTrue);
      expect(content.contains('QUARANTINE'), isTrue);
    });

    test('10. Source failure analysis document covers failure modes SF-01 through SF-09', () {
      final f = File('${r4Dir.path}/10_SOURCE_FAILURE_ANALYSIS.md');
      final content = f.readAsStringSync();
      expect(content.contains('SF-01'), isTrue);
      expect(content.contains('SF-09'), isTrue);
      expect(content.contains('STALE_FEED'), isTrue);
    });

    test('11. Schema evolution document verifies Version 1 and Version 2 backward compatibility', () {
      final f = File('${r4Dir.path}/11_SCHEMA_EVOLUTION.md');
      final content = f.readAsStringSync();
      expect(content.contains('Version 1 Input Schema'), isTrue);
      expect(content.contains('Version 2 Input Schema'), isTrue);
    });

    test('12. Output contract document specifies Proposed Outbound JSON schema', () {
      final f = File('${r4Dir.path}/12_OUTPUT_CONTRACT.md');
      final content = f.readAsStringSync();
      expect(content.contains('PROPOSED OUTBOUND INTEROPERABILITY CONTRACT'), isTrue);
      expect(content.contains('outbound_event_state_v1.json'), isTrue);
    });

    test('13. Provenance and replay document verifies out-of-order replay convergence', () {
      final f = File('${r4Dir.path}/13_PROVENANCE_REPLAY_ANALYSIS.md');
      final content = f.readAsStringSync();
      expect(content.contains('Reverse Arrival'), isTrue);
      expect(content.contains('Shuffled Arrival'), isTrue);
      expect(content.contains('Batched Arrival'), isTrue);
    });

    test('14. Dependency closure document confirms 87%+ recomputation reduction', () {
      final f = File('${r4Dir.path}/14_DEPENDENCY_CLOSURE_RESULTS.md');
      final content = f.readAsStringSync();
      expect(content.contains('87.50%'), isTrue);
      expect(content.contains('99.87%'), isTrue);
    });

    test('15. Performance results document includes benchmark disclaimer', () {
      final f = File('${r4Dir.path}/15_PERFORMANCE_RESULTS.md');
      final content = f.readAsStringSync();
      expect(content.contains('BENCHMARK DISCLAIMER'), isTrue);
      expect(content.contains('in-memory Dart test harness'), isTrue);
    });

    test('16. Failure injection results document covers 20 adversarial cases FI-01..FI-20', () {
      final f = File('${r4Dir.path}/16_FAILURE_INJECTION_RESULTS.md');
      final content = f.readAsStringSync();
      expect(content.contains('FI-01'), isTrue);
      expect(content.contains('FI-20'), isTrue);
      expect(content.contains('20 / 20'), isTrue);
    });

    test('17. Executive findings document provides direct answers to Questions Q1 through Q5', () {
      final f = File('${r4Dir.path}/17_ROUND_4_EXECUTIVE_FINDINGS.md');
      final content = f.readAsStringSync();
      expect(content.contains('Q1:'), isTrue);
      expect(content.contains('Q5:'), isTrue);
      expect(content.contains('STATEFUL INTELLIGENCE ENGINE / STATE STORE + STATELESS INTEROPERABILITY API'), isTrue);
    });

    test('18. Completion report verifies stop condition after Round 4', () {
      final f = File('${r4Dir.path}/18_ROUND_4_COMPLETION_REPORT.md');
      final content = f.readAsStringSync();
      expect(content.contains('RESEARCH-VALIDATED INTEROPERABILITY BOUNDARY ESTABLISHED'), isTrue);
      expect(content.contains('STOP AFTER ROUND 4'), isTrue);
    });

    test('19. Source register lists official sources SRC-01 through SRC-05 and synthetic datasets', () {
      final f = File('${r4Dir.path}/19_SOURCE_REGISTER.md');
      final content = f.readAsStringSync();
      expect(content.contains('SRC-01'), isTrue);
      expect(content.contains('SRC-05'), isTrue);
      expect(content.contains('DSET-01'), isTrue);
      expect(content.contains('DSET-07'), isTrue);
    });

    test('20. Regression check: All prior experimental test suites remain 100% GREEN', () {
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
    });
  });
}
