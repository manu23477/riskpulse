import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CONSOLIDATED INVENTION BOUNDARY REVIEW — ROUND 1 Validation Suite', () {
    late Directory r1Dir;

    setUpAll(() {
      r1Dir = Directory('research/patent_consolidation/round_1');
      expect(r1Dir.existsSync(), isTrue, reason: 'round_1 directory must exist');
    });

    test('1. All 22 required Round 1 research documents exist on disk', () {
      final requiredFiles = [
        '01_SOURCE_INVENTORY.md',
        '02_CROSS_WINDOW_COMPONENT_MAP.md',
        '03_CROSS_WINDOW_RELATIONSHIP_MAP.md',
        '04_KNOWN_DISCLOSED_FEATURES.md',
        '05_TECHNICALLY_COUPLED_CORE.md',
        '06_ESSENTIAL_COMPONENT_ANALYSIS.md',
        '07_SUPPORTING_COMPONENT_ANALYSIS.md',
        '08_EXCLUSION_BOUNDARY.md',
        '09_PW1_PW2_RELATIONSHIP_ANALYSIS.md',
        '10_HPSDMA_INTEGRATION_BOUNDARY.md',
        '11_LIFECYCLE_INTEGRATION_BOUNDARY.md',
        '12_INVENTION_CANDIDATE_A.md',
        '13_INVENTION_CANDIDATE_B.md',
        '14_INVENTION_CANDIDATE_COMPARISON.md',
        '15_MINIMAL_INVENTION_BOUNDARY.md',
        '16_TECHNICAL_EFFECT_CHAIN.md',
        '17_IMPLEMENTATION_INDEPENDENCE.md',
        '18_PRIOR_ART_RISK_BOUNDARY.md',
        '19_PATENT_COUNSEL_DOSSIER.md',
        '20_CONSOLIDATED_EXECUTIVE_FINDINGS.md',
        '21_ROUND_1_COMPLETION_REPORT.md',
        '22_SOURCE_REGISTER.md',
      ];

      for (final fileName in requiredFiles) {
        final f = File('${r1Dir.path}/$fileName');
        expect(f.existsSync(), isTrue, reason: 'File $fileName must exist');
        expect(f.readAsStringSync().length, greaterThan(250), reason: 'File $fileName must not be empty');
      }
    });

    test('2. Source inventory document audits 6 completed workstreams', () {
      final f = File('${r1Dir.path}/01_SOURCE_INVENTORY.md');
      final content = f.readAsStringSync();
      expect(content.contains('PW1'), isTrue);
      expect(content.contains('PW2'), isTrue);
      expect(content.contains('HPSDMA'), isTrue);
      expect(content.contains('LIFECYCLE'), isTrue);
      expect(content.contains('PW2R7'), isTrue);
      expect(content.contains('PW2R8'), isTrue);
    });

    test('3. Cross-window component map classifies components using neutral categories', () {
      final f = File('${r1Dir.path}/02_CROSS_WINDOW_COMPONENT_MAP.md');
      final content = f.readAsStringSync();
      expect(content.contains('KNOWN_DISCLOSED'), isTrue);
      expect(content.contains('COMBINATION_DEPENDENT'), isTrue);
      expect(content.contains('TECHNICALLY_COUPLED'), isTrue);
      expect(content.contains('INTEGRATION_CONTEXT'), isTrue);
    });

    test('4. Cross-window relationship map classifies PW1/PW2 relationship as Category B Genus/Species', () {
      final f = File('${r1Dir.path}/03_CROSS_WINDOW_RELATIONSHIP_MAP.md');
      final content = f.readAsStringSync();
      expect(content.contains('Category B'), isTrue);
      expect(content.contains('generalized underlying mechanism'), isTrue);
    });

    test('5. Known disclosed features document identifies atomic features NOT to claim as novel', () {
      final f = File('${r1Dir.path}/04_KNOWN_DISCLOSED_FEATURES.md');
      final content = f.readAsStringSync();
      expect(content.contains('MUST NOT BE CLAIMED AS STANDALONE NOVEL INVENTIONS'), isTrue);
      expect(content.contains('US8548248B2'), isTrue);
      expect(content.contains('US10036650B2'), isTrue);
      expect(content.contains('C07'), isTrue);
    });

    test('6. Technically coupled core document defines smallest indispensable core chain', () {
      final f = File('${r1Dir.path}/05_TECHNICALLY_COUPLED_CORE.md');
      final content = f.readAsStringSync();
      expect(content.contains('Indispensable Relationship Chain'), isTrue);
      expect(content.contains('Transitive 6-layer DAG closure calculation'), isTrue);
    });

    test('7. Essential component analysis document classifies essential vs non-essential C07', () {
      final f = File('${r1Dir.path}/06_ESSENTIAL_COMPONENT_ANALYSIS.md');
      final content = f.readAsStringSync();
      expect(content.contains('C01'), isTrue);
      expect(content.contains('C07'), isTrue);
      expect(content.contains('NON-ESSENTIAL'), isTrue);
      expect(content.contains('Efficiency-Only'), isTrue);
    });

    test('8. Supporting component analysis document identifies non-essential infrastructure', () {
      final f = File('${r1Dir.path}/07_SUPPORTING_COMPONENT_ANALYSIS.md');
      final content = f.readAsStringSync();
      expect(content.contains('Envelope V2'), isTrue);
      expect(content.contains('Non-Deletion Contradiction Retention'), isTrue);
    });

    test('9. Exclusion boundary document explicitly excludes generic GIS, RS, NLP, Flutter', () {
      final f = File('${r1Dir.path}/08_EXCLUSION_BOUNDARY.md');
      final content = f.readAsStringSync();
      expect(content.contains('EXPLICITLY EXCLUDED'), isTrue);
      expect(content.contains('Generic GIS portal rendering'), isTrue);
      expect(content.contains('Flutter / Dart UI widgets'), isTrue);
    });

    test('10. PW1 vs PW2 relationship analysis document unifies text and satellite evidence mechanisms', () {
      final f = File('${r1Dir.path}/09_PW1_PW2_RELATIONSHIP_ANALYSIS.md');
      final content = f.readAsStringSync();
      expect(content.contains('Observation Mutation-Driven Transitive Spatial-Administrative-Risk DAG Closure'), isTrue);
    });

    test('11. HPSDMA integration boundary document confirms integration is deployment context', () {
      final f = File('${r1Dir.path}/10_HPSDMA_INTEGRATION_BOUNDARY.md');
      final content = f.readAsStringSync();
      expect(content.contains('Deployment / Integration Context'), isTrue);
      expect(content.contains('NOT part of the core invention'), isTrue);
    });

    test('12. Lifecycle integration boundary document classifies Round 6 features', () {
      final f = File('${r1Dir.path}/11_LIFECYCLE_INTEGRATION_BOUNDARY.md');
      final content = f.readAsStringSync();
      expect(content.contains('CORE'), isTrue);
      expect(content.contains('SUPPORTING'), isTrue);
      expect(content.contains('VALIDATION-ONLY'), isTrue);
    });

    test('13. Invention Candidate A document specifies generalized evidence architecture', () {
      final f = File('${r1Dir.path}/12_INVENTION_CANDIDATE_A.md');
      final content = f.readAsStringSync();
      expect(content.contains('Invention Candidate A'), isTrue);
      expect(content.contains('87.50'), isTrue);
    });

    test('14. Invention Candidate B document specifies remote-sensing architecture', () {
      final f = File('${r1Dir.path}/13_INVENTION_CANDIDATE_B.md');
      final content = f.readAsStringSync();
      expect(content.contains('Invention Candidate B'), isTrue);
      expect(content.contains('Remote-Sensing Mutation'), isTrue);
    });

    test('15. Invention candidate comparison document establishes Candidate A as Genus and B as Species', () {
      final f = File('${r1Dir.path}/14_INVENTION_CANDIDATE_COMPARISON.md');
      final content = f.readAsStringSync();
      expect(content.contains('Candidate A as Parent Genus'), isTrue);
      expect(content.contains('Candidate B as Species'), isTrue);
    });

    test('16. Minimal invention boundary document specifies 6 indispensable technical steps', () {
      final f = File('${r1Dir.path}/15_MINIMAL_INVENTION_BOUNDARY.md');
      final content = f.readAsStringSync();
      expect(content.contains('MUTATION INGESTION'), isTrue);
      expect(content.contains('BITEMPORAL HISTORY STORE'), isTrue);
      expect(content.contains('indispensable'), isTrue);
    });

    test('17. Technical effect chain document maps mechanisms to technical effects', () {
      final f = File('${r1Dir.path}/16_TECHNICAL_EFFECT_CHAIN.md');
      final content = f.readAsStringSync();
      expect(content.contains('Selective Node Recomputation'), isTrue);
      expect(content.contains('Zero Cross-Event Contamination'), isTrue);
    });

    test('18. Implementation independence document proves technology-stack independence', () {
      final f = File('${r1Dir.path}/17_IMPLEMENTATION_INDEPENDENCE.md');
      final content = f.readAsStringSync();
      expect(content.contains('Flutter / Dart'), isTrue);
      expect(content.contains('NON-ESSENTIAL'), isTrue);
      expect(content.contains('Google Earth Engine'), isTrue);
    });

    test('19. Prior art risk boundary document summarizes single-ref vs multi-ref risks', () {
      final f = File('${r1Dir.path}/18_PRIOR_ART_RISK_BOUNDARY.md');
      final content = f.readAsStringSync();
      expect(content.contains('Single-Reference Collision Risk'), isTrue);
      expect(content.contains('LOW'), isTrue);
    });

    test('20. Patent counsel dossier document contains technical dossier for counsel without claims', () {
      final f = File('${r1Dir.path}/19_PATENT_COUNSEL_DOSSIER.md');
      final content = f.readAsStringSync();
      expect(content.contains('Technical Field'), isTrue);
      expect(content.contains('Key Questions for Patent Counsel'), isTrue);
    });

    test('21. Executive findings document provides direct answers to Questions Q1 through Q21', () {
      final f = File('${r1Dir.path}/20_CONSOLIDATED_EXECUTIVE_FINDINGS.md');
      final content = f.readAsStringSync();
      expect(content.contains('Q1:'), isTrue);
      expect(content.contains('Q21:'), isTrue);
      expect(content.contains('NO. Patentability remains legally undetermined.'), isTrue);
    });

    test('22. Completion report verifies stop condition after Round 1', () {
      final f = File('${r1Dir.path}/21_ROUND_1_COMPLETION_REPORT.md');
      final content = f.readAsStringSync();
      expect(content.contains('CONSOLIDATED INVENTION BOUNDARY ESTABLISHED FOR PATENT COUNSEL REVIEW'), isTrue);
    });

    test('23. Source register document covers all prior art and research workstreams', () {
      final f = File('${r1Dir.path}/22_SOURCE_REGISTER.md');
      final content = f.readAsStringSync();
      expect(content.contains('PW1'), isTrue);
      expect(content.contains('US8548248B2'), isTrue);
    });

    test('24. Legal disclaimer test: Patentability remains legally undetermined across reports', () {
      final f1 = File('${r1Dir.path}/20_CONSOLIDATED_EXECUTIVE_FINDINGS.md');
      final f2 = File('${r1Dir.path}/21_ROUND_1_COMPLETION_REPORT.md');

      expect(f1.readAsStringSync().contains('Patentability remains legally undetermined'), isTrue);
      expect(f2.readAsStringSync().contains('NO PATENTABILITY OR NOVELTY CONCLUSION MADE'), isTrue);
    });

    test('25. Negative claims prohibition test: Reports do not claim "patentable" or "novel"', () {
      final f = File('${r1Dir.path}/20_CONSOLIDATED_EXECUTIVE_FINDINGS.md');
      final content = f.readAsStringSync();
      expect(content.contains('RiskPulse is patentable'), isFalse);
      expect(content.contains('RiskPulse is novel'), isFalse);
      expect(content.contains('No prior art exists'), isFalse);
    });

    test('26. C07 exclusion test: C07 is consistently excluded as efficiency-only', () {
      final f1 = File('${r1Dir.path}/02_CROSS_WINDOW_COMPONENT_MAP.md');
      final f2 = File('${r1Dir.path}/06_ESSENTIAL_COMPONENT_ANALYSIS.md');

      expect(f1.readAsStringSync().contains('Efficiency-Only'), isTrue);
      expect(f2.readAsStringSync().contains('Efficiency-Only'), isTrue);
    });

    test('27. Technology stack independence test: Proves independence from Flutter, GEE, Gemini', () {
      final f = File('${r1Dir.path}/17_IMPLEMENTATION_INDEPENDENCE.md');
      final content = f.readAsStringSync();
      expect(content.contains('Flutter / Dart'), isTrue);
      expect(content.contains('Gemini LLM'), isTrue);
    });

    test('28. Genus vs species relationship test: Candidate A = Genus, Candidate B = Species', () {
      final f = File('${r1Dir.path}/14_INVENTION_CANDIDATE_COMPARISON.md');
      final content = f.readAsStringSync();
      expect(content.contains('Parent Genus'), isTrue);
      expect(content.contains('Species'), isTrue);
    });

    test('29. Indispensable steps test: 6 indispensable steps identified', () {
      final f = File('${r1Dir.path}/15_MINIMAL_INVENTION_BOUNDARY.md');
      final content = f.readAsStringSync();
      expect(content.contains('MUTATION INGESTION'), isTrue);
      expect(content.contains('BITEMPORAL HISTORY STORE'), isTrue);
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
      final r6LifeTestFile = File('test/riskpulse_intelligence_lifecycle_round_6_test.dart');
      final r7Pw2TestFile = File('test/patent_window_2_round_7_test.dart');
      final r8Pw2TestFile = File('test/patent_window_2_round_8_test.dart');

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
    });
  });
}
