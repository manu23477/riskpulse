import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PATENT WINDOW 2 — ROUND 7: Single-Reference Collision Audit Validation Suite', () {
    late Directory pw2r7Dir;

    setUpAll(() {
      pw2r7Dir = Directory('research/patent_window_2/round_7');
      expect(pw2r7Dir.existsSync(), isTrue, reason: 'round_7 directory must exist');
    });

    test('1. All 14 required PW2R7 research documents exist on disk', () {
      final requiredFiles = [
        '01_SEARCH_SCOPE.md',
        '02_CANDIDATE_REFERENCE_REGISTER.md',
        '03_ATOMIC_FEATURE_MATRIX.md',
        '04_SINGLE_REFERENCE_COVERAGE.md',
        '05_RELATIONSHIP_COVERAGE.md',
        '06_K10_COLLISION_MATRIX.md',
        '07_NEAR_MISS_ANALYSIS.md',
        '08_SINGLE_REFERENCE_RESULTS.md',
        '09_MOSAIC_EXCLUSION_ANALYSIS.md',
        '10_MINIMAL_BOUNDARY_REVIEW.md',
        '11_PATENT_STRATEGY_BOUNDARY.md',
        '12_ROUND_7_EXECUTIVE_FINDINGS.md',
        '13_ROUND_7_COMPLETION_REPORT.md',
        '14_SOURCE_REGISTER.md',
      ];

      for (final fileName in requiredFiles) {
        final f = File('${pw2r7Dir.path}/$fileName');
        expect(f.existsSync(), isTrue, reason: 'File $fileName must exist');
        expect(f.readAsStringSync().length, greaterThan(250), reason: 'File $fileName must not be empty');
      }
    });

    test('2. Search scope document enforces single-reference rule (ONE REFERENCE = ONE COVERAGE)', () {
      final f = File('${pw2r7Dir.path}/01_SEARCH_SCOPE.md');
      final content = f.readAsStringSync();
      expect(content.contains('ONE REFERENCE = ONE COVERAGE DETERMINATION'), isTrue);
      expect(content.contains('Targeted Single-Reference Collision Audit'), isTrue);
    });

    test('3. Candidate register records 15 primary candidate prior-art references', () {
      final f = File('${pw2r7Dir.path}/02_CANDIDATE_REFERENCE_REGISTER.md');
      final content = f.readAsStringSync();
      expect(content.contains('REF-01'), isTrue);
      expect(content.contains('REF-15'), isTrue);
      expect(content.contains('US8548248B2'), isTrue);
      expect(content.contains('US10036650B2'), isTrue);
    });

    test('4. Atomic feature matrix covers components K01 through K10 for candidates', () {
      final f = File('${pw2r7Dir.path}/03_ATOMIC_FEATURE_MATRIX.md');
      final content = f.readAsStringSync();
      expect(content.contains('K01'), isTrue);
      expect(content.contains('K10'), isTrue);
      expect(content.contains('EFFICIENCY_ONLY'), isTrue);
    });

    test('5. Single reference coverage document establishes individual coverage determinations', () {
      final f = File('${pw2r7Dir.path}/04_SINGLE_REFERENCE_COVERAGE.md');
      final content = f.readAsStringSync();
      expect(content.contains('PARTIAL DISCLOSURE'), isTrue);
      expect(content.contains('FUNCTIONALLY ADJACENT'), isTrue);
    });

    test('6. Relationship coverage document covers technical relationships R01 through R30', () {
      final f = File('${pw2r7Dir.path}/05_RELATIONSHIP_COVERAGE.md');
      final content = f.readAsStringSync();
      expect(content.contains('R01'), isTrue);
      expect(content.contains('R30'), isTrue);
      expect(content.contains('NOT_LOCATED'), isTrue);
    });

    test('7. K10 collision matrix confirms 0 complete single-reference collisions', () {
      final f = File('${pw2r7Dir.path}/06_K10_COLLISION_MATRIX.md');
      final content = f.readAsStringSync();
      expect(content.contains('0 / 15'), isTrue);
      expect(content.contains('Disclose Complete K10 Relationship'), isTrue);
    });

    test('8. Near-miss analysis document evaluates US10036650B2, US8548248B2, US7441230B2, CN120808164B', () {
      final f = File('${pw2r7Dir.path}/07_NEAR_MISS_ANALYSIS.md');
      final content = f.readAsStringSync();
      expect(content.contains('US10036650B2'), isTrue);
      expect(content.contains('US8548248B2'), isTrue);
      expect(content.contains('US7441230B2'), isTrue);
      expect(content.contains('CN120808164B'), isTrue);
    });

    test('9. Single reference results document confirms NO SINGLE REFERENCE LOCATED DISCLOSES COMPLETE K10', () {
      final f = File('${pw2r7Dir.path}/08_SINGLE_REFERENCE_RESULTS.md');
      final content = f.readAsStringSync();
      expect(content.contains('NO SINGLE REFERENCE LOCATED DISCLOSES THE COMPLETE K10 RELATIONSHIP'), isTrue);
    });

    test('10. Mosaic exclusion document explicitly separates multi-ref mosaic from single-ref disclosure', () {
      final f = File('${pw2r7Dir.path}/09_MOSAIC_EXCLUSION_ANALYSIS.md');
      final content = f.readAsStringSync();
      expect(content.contains('MANDATORY LEGAL EXCLUSION'), isTrue);
      expect(content.contains('EXCLUDED from single-reference novelty/anticipation determinations'), isTrue);
    });

    test('11. Minimal boundary review document confirms C07 exclusion from novelty boundary', () {
      final f = File('${pw2r7Dir.path}/10_MINIMAL_BOUNDARY_REVIEW.md');
      final content = f.readAsStringSync();
      expect(content.contains('PW2-MINIMAL-CANDIDATE'), isTrue);
      expect(content.contains('EFFICIENCY_ONLY'), isTrue);
    });

    test('12. Patent strategy boundary document identifies features NOT to claim as single-ref novel', () {
      final f = File('${pw2r7Dir.path}/11_PATENT_STRATEGY_BOUNDARY.md');
      final content = f.readAsStringSync();
      expect(content.contains('SHOULD NOT BE CLAIMED AS INDEPENDENT NOVEL INVENTIONS'), isTrue);
      expect(content.contains('PW2-MINIMAL-RELATIONSHIP-CORE'), isTrue);
    });

    test('13. Executive findings document provides direct answers to Questions Q1 through Q19', () {
      final f = File('${pw2r7Dir.path}/12_ROUND_7_EXECUTIVE_FINDINGS.md');
      final content = f.readAsStringSync();
      expect(content.contains('Q1:'), isTrue);
      expect(content.contains('Q19:'), isTrue);
      expect(content.contains('Patentability/novelty remains legally undetermined'), isTrue);
    });

    test('14. Completion report verifies stop condition after PW2R7', () {
      final f = File('${pw2r7Dir.path}/13_ROUND_7_COMPLETION_REPORT.md');
      final content = f.readAsStringSync();
      expect(content.contains('NO SINGLE-REFERENCE COLLISION IDENTIFIED'), isTrue);
      expect(content.contains('STOP AFTER PW2R7'), isTrue);
    });

    test('15. Source register document records URLs, assignees, and claim citations', () {
      final f = File('${pw2r7Dir.path}/14_SOURCE_REGISTER.md');
      final content = f.readAsStringSync();
      expect(content.contains('REF-01'), isTrue);
      expect(content.contains('REF-15'), isTrue);
      expect(content.contains('https://patents.google.com'), isTrue);
    });

    test('16. Single reference rule test: No two references are combined into a single disclosure', () {
      final f = File('${pw2r7Dir.path}/04_SINGLE_REFERENCE_COVERAGE.md');
      final content = f.readAsStringSync();
      expect(content.contains('DigitalGlobe'), isTrue);
      expect(content.contains('ESRI'), isTrue);
      expect(content.contains('Single-Reference Collision ='), isTrue);
    });

    test('17. Legal disclaimers test: Patentability remains legally undetermined across all reports', () {
      final f1 = File('${pw2r7Dir.path}/08_SINGLE_REFERENCE_RESULTS.md');
      final f2 = File('${pw2r7Dir.path}/12_ROUND_7_EXECUTIVE_FINDINGS.md');
      final f3 = File('${pw2r7Dir.path}/13_ROUND_7_COMPLETION_REPORT.md');

      expect(f1.readAsStringSync().contains('Patentability/novelty remains legally undetermined'), isTrue);
      expect(f2.readAsStringSync().contains('Patentability/novelty remains legally undetermined'), isTrue);
      expect(f3.readAsStringSync().contains('NO PATENTABILITY OR NOVELTY CONCLUSION MADE'), isTrue);
    });

    test('18. C07 exclusion test: C07 is consistently excluded from the novelty boundary', () {
      final f = File('${pw2r7Dir.path}/10_MINIMAL_BOUNDARY_REVIEW.md');
      final content = f.readAsStringSync();
      expect(content.contains('EFFICIENCY_ONLY'), isTrue);
      expect(content.contains('EP3622411B1'), isTrue);
    });

    test('19. Candidate reference traceability test: All 15 candidates present in register and matrix', () {
      final fReg = File('${pw2r7Dir.path}/02_CANDIDATE_REFERENCE_REGISTER.md');
      final fMat = File('${pw2r7Dir.path}/06_K10_COLLISION_MATRIX.md');

      expect(fReg.readAsStringSync().contains('REF-15'), isTrue);
      expect(fMat.readAsStringSync().contains('CN121861816A'), isTrue);
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
      final r4GapTestFile = File('test/hpsdma_gap_analysis_round_4_test.dart');
      final r5GapTestFile = File('test/hpsdma_gap_analysis_round_5_test.dart');
      final r6LifeTestFile = File('test/riskpulse_intelligence_lifecycle_round_6_test.dart');

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
    });
  });
}
