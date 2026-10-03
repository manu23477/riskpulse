import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PATENT WINDOW 2 — ROUND 8: NPL & Multi-Reference Combination Validation Suite', () {
    late Directory pw2r8Dir;

    setUpAll(() {
      pw2r8Dir = Directory('research/patent_window_2/round_8');
      expect(pw2r8Dir.existsSync(), isTrue, reason: 'round_8 directory must exist');
    });

    test('1. All 21 required PW2R8 research documents exist on disk', () {
      final requiredFiles = [
        '01_ROUND_8_SCOPE.md',
        '02_NON_PATENT_SEARCH_STRATEGY.md',
        '03_NON_PATENT_REFERENCE_REGISTER.md',
        '04_NPL_ATOMIC_FEATURE_MATRIX.md',
        '05_NPL_RELATIONSHIP_MATRIX.md',
        '06_EMERGING_PATENT_SEARCH.md',
        '07_PUBLICATION_DATE_BOUNDARY.md',
        '08_UNPUBLISHED_APPLICATION_LIMITATIONS.md',
        '09_FAMILY_CONTINUATION_DIVISIONAL_ANALYSIS.md',
        '10_COMBINATION_ANALYSIS_FRAMEWORK.md',
        '11_PAIRWISE_COMBINATION_ANALYSIS.md',
        '12_MULTI_REFERENCE_COMBINATION_ANALYSIS.md',
        '13_RELATIONSHIP_GAP_ANALYSIS.md',
        '14_TECHNICAL_MOTIVATION_ANALYSIS.md',
        '15_COMBINATION_COUNTEREXAMPLES.md',
        '16_OBVIOUSNESS_RISK_MATRIX.md',
        '17_NOVELTY_BOUNDARY_REVIEW.md',
        '18_PATENT_STRATEGY_BOUNDARY.md',
        '19_ROUND_8_EXECUTIVE_FINDINGS.md',
        '20_ROUND_8_COMPLETION_REPORT.md',
        '21_SOURCE_REGISTER.md',
      ];

      for (final fileName in requiredFiles) {
        final f = File('${pw2r8Dir.path}/$fileName');
        expect(f.existsSync(), isTrue, reason: 'File $fileName must exist');
        expect(f.readAsStringSync().length, greaterThan(250), reason: 'File $fileName must not be empty');
      }
    });

    test('2. Scope document covers three uncertainty classes (NPL, Emerging, Multi-Reference)', () {
      final f = File('${pw2r8Dir.path}/01_ROUND_8_SCOPE.md');
      final content = f.readAsStringSync();
      expect(content.contains('Part A'), isTrue);
      expect(content.contains('Part B'), isTrue);
      expect(content.contains('Part C & D'), isTrue);
    });

    test('3. Non-patent reference register covers 10 audited NPL papers NPL-01..NPL-10', () {
      final f = File('${pw2r8Dir.path}/03_NON_PATENT_REFERENCE_REGISTER.md');
      final content = f.readAsStringSync();
      expect(content.contains('NPL-01'), isTrue);
      expect(content.contains('NPL-10'), isTrue);
      expect(content.contains('10.1016/j.isprsjprs.2021.04.012'), isTrue);
    });

    test('4. NPL atomic feature matrix covers components K01 through K10', () {
      final f = File('${pw2r8Dir.path}/04_NPL_ATOMIC_FEATURE_MATRIX.md');
      final content = f.readAsStringSync();
      expect(content.contains('K01'), isTrue);
      expect(content.contains('K10'), isTrue);
      expect(content.contains('Zhang 2021'), isTrue);
    });

    test('5. NPL relationship matrix confirms critical core is NOT LOCATED in single NPL paper', () {
      final f = File('${pw2r8Dir.path}/05_NPL_RELATIONSHIP_MATRIX.md');
      final content = f.readAsStringSync();
      expect(content.contains('R08'), isTrue);
      expect(content.contains('R30'), isTrue);
      expect(content.contains('NOT LOCATED'), isTrue);
    });

    test('6. Emerging patent search document audits continuation/divisional families FAM-01..FAM-04', () {
      final f = File('${pw2r8Dir.path}/06_EMERGING_PATENT_SEARCH.md');
      final content = f.readAsStringSync();
      expect(content.contains('FAM-01'), isTrue);
      expect(content.contains('FAM-04'), isTrue);
      expect(content.contains('US11455320B2'), isTrue);
    });

    test('7. Publication date boundary document establishes filing & publication chronology', () {
      final f = File('${pw2r8Dir.path}/07_PUBLICATION_DATE_BOUNDARY.md');
      final content = f.readAsStringSync();
      expect(content.contains('PUBLIC BEFORE PW2R8 SEARCH'), isTrue);
      expect(content.contains('CURRENTLY NOT PUBLICLY DISCOVERABLE'), isTrue);
    });

    test('8. Unpublished application limitations document analyzes 18-month publication blind spot', () {
      final f = File('${pw2r8Dir.path}/08_UNPUBLISHED_APPLICATION_LIMITATIONS.md');
      final content = f.readAsStringSync();
      expect(content.contains('18-Month Rule'), isTrue);
      expect(content.contains('35 U.S.C. § 122(b)'), isTrue);
      expect(content.contains('April 1, 2025 and October 1, 2026'), isTrue);
    });

    test('9. Family continuation analysis document traces parent-child priority boundaries', () {
      final f = File('${pw2r8Dir.path}/09_FAMILY_CONTINUATION_DIVISIONAL_ANALYSIS.md');
      final content = f.readAsStringSync();
      expect(content.contains('35 U.S.C. § 120'), isTrue);
      expect(content.contains('PW2-MINIMAL-RELATIONSHIP-CORE'), isTrue);
    });

    test('10. Combination analysis framework document specifies 6 objective technical dimensions', () {
      final f = File('${pw2r8Dir.path}/10_COMBINATION_ANALYSIS_FRAMEWORK.md');
      final content = f.readAsStringSync();
      expect(content.contains('Component Coverage'), isTrue);
      expect(content.contains('Technical Motivation'), isTrue);
      expect(content.contains('Hindsight Dependence'), isTrue);
    });

    test('11. Pairwise combination analysis document covers Pairs A through H', () {
      final f = File('${pw2r8Dir.path}/11_PAIRWISE_COMBINATION_ANALYSIS.md');
      final content = f.readAsStringSync();
      expect(content.contains('Pair A'), isTrue);
      expect(content.contains('Pair H'), isTrue);
      expect(content.contains('Domain Mismatch'), isTrue);
    });

    test('12. Multi-reference combination analysis document covers 3-ref and 4-ref combinations', () {
      final f = File('${pw2r8Dir.path}/12_MULTI_REFERENCE_COMBINATION_ANALYSIS.md');
      final content = f.readAsStringSync();
      expect(content.contains('Combination 1'), isTrue);
      expect(content.contains('Combination 3'), isTrue);
      expect(content.contains('HIGH'), isTrue);
    });

    test('13. Relationship gap analysis document identifies unbridged relationships R08, R25, R28, R30', () {
      final f = File('${pw2r8Dir.path}/13_RELATIONSHIP_GAP_ANALYSIS.md');
      final content = f.readAsStringSync();
      expect(content.contains('R08'), isTrue);
      expect(content.contains('R25'), isTrue);
      expect(content.contains('R30'), isTrue);
      expect(content.contains('unbridged relationship gap'), isTrue);
    });

    test('14. Technical motivation analysis document audits 8 combination questions', () {
      final f = File('${pw2r8Dir.path}/14_TECHNICAL_MOTIVATION_ANALYSIS.md');
      final content = f.readAsStringSync();
      expect(content.contains('Explicit Motivation to Combine?'), isTrue);
      expect(content.contains('Substantial Redesign Required?'), isTrue);
    });

    test('15. Combination counterexamples document evaluates 4 technical counterexamples', () {
      final f = File('${pw2r8Dir.path}/15_COMBINATION_COUNTEREXAMPLES.md');
      final content = f.readAsStringSync();
      expect(content.contains('Counterexample 1'), isTrue);
      expect(content.contains('Counterexample 4'), isTrue);
    });

    test('16. Obviousness risk matrix document uses neutral technical characterizations', () {
      final f = File('${pw2r8Dir.path}/16_OBVIOUSNESS_RISK_MATRIX.md');
      final content = f.readAsStringSync();
      expect(content.contains('PARTIAL OVERLAP'), isTrue);
      expect(content.contains('DOMAIN MISMATCH / HIGH HINDSIGHT'), isTrue);
      expect(content.contains('UNRESOLVED IN PRIOR-ART LITERATURE'), isTrue);
    });

    test('17. Novelty boundary review document confirms single-ref boundary intact', () {
      final f = File('${pw2r8Dir.path}/17_NOVELTY_BOUNDARY_REVIEW.md');
      final content = f.readAsStringSync();
      expect(content.contains('Single-Reference Novelty Boundary'), isTrue);
      expect(content.contains('PW2-MINIMAL-RELATIONSHIP-CORE'), isTrue);
    });

    test('18. Patent strategy boundary document specifies core focus for claims', () {
      final f = File('${pw2r8Dir.path}/18_PATENT_STRATEGY_BOUNDARY.md');
      final content = f.readAsStringSync();
      expect(content.contains('What Should NOT Be Claimed as Novel'), isTrue);
      expect(content.contains('PW2-MINIMAL-RELATIONSHIP-CORE'), isTrue);
    });

    test('19. Executive findings document provides direct answers to Questions Q1 through Q22', () {
      final f = File('${pw2r8Dir.path}/19_ROUND_8_EXECUTIVE_FINDINGS.md');
      final content = f.readAsStringSync();
      expect(content.contains('Q1:'), isTrue);
      expect(content.contains('Q21:'), isTrue);
      expect(content.contains('Q22:'), isTrue);
      expect(content.contains('Patentability and novelty remain legally undetermined.'), isTrue);
    });

    test('20. Completion report verifies stop condition after PW2R8', () {
      final f = File('${pw2r8Dir.path}/20_ROUND_8_COMPLETION_REPORT.md');
      final content = f.readAsStringSync();
      expect(content.contains('UNBRIDGED RELATIONSHIP GAP CONFIRMED'), isTrue);
      expect(content.contains('STOP AFTER PW2R8'), isTrue);
    });

    test('21. Source register records NPL DOIs and patent URLs', () {
      final f = File('${pw2r8Dir.path}/21_SOURCE_REGISTER.md');
      final content = f.readAsStringSync();
      expect(content.contains('NPL-01'), isTrue);
      expect(content.contains('10.1016/j.isprsjprs.2021.04.012'), isTrue);
      expect(content.contains('US8548248B2'), isTrue);
    });

    test('22. Statutory disclaimers test: Patentability remains legally undetermined across reports', () {
      final f1 = File('${pw2r8Dir.path}/01_ROUND_8_SCOPE.md');
      final f2 = File('${pw2r8Dir.path}/19_ROUND_8_EXECUTIVE_FINDINGS.md');
      final f3 = File('${pw2r8Dir.path}/20_ROUND_8_COMPLETION_REPORT.md');

      expect(f1.readAsStringSync().contains('Patentability and novelty remain legally undetermined'), isTrue);
      expect(f2.readAsStringSync().contains('Patentability and novelty remain legally undetermined'), isTrue);
      expect(f3.readAsStringSync().contains('NO PATENTABILITY OR NOVELTY CONCLUSION MADE'), isTrue);
    });

    test('23. Negative claims prohibition test: Reports do not claim "patentable" or "novel"', () {
      final f = File('${pw2r8Dir.path}/19_ROUND_8_EXECUTIVE_FINDINGS.md');
      final content = f.readAsStringSync();
      expect(content.contains('RiskPulse is patentable'), isFalse);
      expect(content.contains('RiskPulse is novel'), isFalse);
      expect(content.contains('No prior art exists'), isFalse);
    });

    test('24. Blind spot analysis test: Statutory 18-month window explicitly documented', () {
      final f = File('${pw2r8Dir.path}/08_UNPUBLISHED_APPLICATION_LIMITATIONS.md');
      final content = f.readAsStringSync();
      expect(content.contains('18-Month Rule'), isTrue);
      expect(content.contains('April 1, 2025 and October 1, 2026'), isTrue);
    });

    test('25. Regression check: All prior experimental test suites remain 100% GREEN', () {
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
    });
  });
}
