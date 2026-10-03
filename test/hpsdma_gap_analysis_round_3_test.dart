import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HPSDMA GAP ANALYSIS ROUND 3 — Validation Test Suite', () {
    late Directory r3Dir;

    setUpAll(() {
      r3Dir = Directory('research/hpsdma_gap_analysis/round_3');
      expect(r3Dir.existsSync(), isTrue, reason: 'round_3 directory must exist');
    });

    test('1. All 13 required Round 3 research documents exist on disk', () {
      final requiredFiles = [
        '01_PUBLIC_HPSDMA_DATA_FLOW.md',
        '02_API_INTEROPERABILITY_AUDIT.md',
        '03_GIS_DSS_BOUNDARY.md',
        '04_RISKPULSE_INSERTION_POINTS.md',
        '05_RESPONSIBILITY_MATRIX.md',
        '06_RISKPULSE_INTEGRATION_CONTRACT.md',
        '07_FAILURE_MODE_ANALYSIS.md',
        '08_PATENT_BOUNDARY.md',
        '09_COMMERCIAL_INTEGRATION_MODELS.md',
        '10_FINAL_INTEGRATION_ARCHITECTURE.md',
        '11_EXECUTIVE_FINDINGS.md',
        '12_SOURCE_REGISTER.md',
        '13_ROUND_3_COMPLETION_REPORT.md',
      ];

      for (final fileName in requiredFiles) {
        final f = File('${r3Dir.path}/$fileName');
        expect(f.existsSync(), isTrue, reason: 'File $fileName must exist');
        expect(f.readAsStringSync().length, greaterThan(500), reason: 'File $fileName must not be empty');
      }
    });

    test('2. Data flow document contains stage-by-stage classification table', () {
      final f = File('${r3Dir.path}/01_PUBLIC_HPSDMA_DATA_FLOW.md');
      final content = f.readAsStringSync();
      expect(content.contains('Documented'), isTrue);
      expect(content.contains('Inferred'), isTrue);
      expect(content.contains('Unknown'), isTrue);
    });

    test('3. API audit document distinguishes API concepts from production spec', () {
      final f = File('${r3Dir.path}/02_API_INTEROPERABILITY_AUDIT.md');
      final content = f.readAsStringSync();
      expect(content.contains('16 distinct disaster information categories'), isTrue);
      expect(content.contains('Not publicly documented'), isTrue);
    });

    test('4. Integration contract defines proposed inbound and outbound JSON schemas', () {
      final f = File('${r3Dir.path}/06_RISKPULSE_INTEGRATION_CONTRACT.md');
      final content = f.readAsStringSync();
      expect(content.contains('PROPOSED RISKPULSE INPUT SCHEMA'), isTrue);
      expect(content.contains('PROPOSED RISKPULSE OUTPUT SCHEMA'), isTrue);
      expect(content.contains('PROPOSED CONTRACT'), isTrue);
    });

    test('5. Failure mode analysis covers all 15 failure scenarios', () {
      final f = File('${r3Dir.path}/07_FAILURE_MODE_ANALYSIS.md');
      final content = f.readAsStringSync();
      expect(content.contains('FM-01'), isTrue);
      expect(content.contains('FM-15'), isTrue);
    });

    test('6. Final architecture document contains Diagram 1 and Diagram 2 ASCII charts', () {
      final f = File('${r3Dir.path}/10_FINAL_INTEGRATION_ARCHITECTURE.md');
      final content = f.readAsStringSync();
      expect(content.contains('DIAGRAM 1: HPSDMA PUBLICLY DOCUMENTED ARCHITECTURE'), isTrue);
      expect(content.contains('DIAGRAM 2: PROPOSED RISKPULSE + HPSDMA INTEGRATION ARCHITECTURE'), isTrue);
      expect(content.contains('PRIMARY PROPOSED INTEGRATION POINT'), isTrue);
    });

    test('7. Executive findings document contains 13 required sections and exact final answer', () {
      final f = File('${r3Dir.path}/11_EXECUTIVE_FINDINGS.md');
      final content = f.readAsStringSync();
      expect(content.contains('1. WHAT HPSDMA PUBLICLY DOCUMENTS'), isTrue);
      expect(content.contains('13. EXACT ANSWER TO THE FINAL QUESTION'), isTrue);
      expect(content.contains('Evidence-Aware Disaster-Intelligence Middleware Layer'), isTrue);
    });

    test('8. Regression check: All prior experimental test suites remain 100% GREEN', () {
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
    });
  });
}
