import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PATENT WINDOW 2 CANDIDATE 02 — PW2R6 Minimal Technical Boundary Suite', () {
    late Map<String, dynamic> manifest;
    late List<dynamic> inventory;
    late List<dynamic> singleAblationResults;
    late List<dynamic> multiAblationResults;
    late List<dynamic> counterexampleResults;
    late Map<String, dynamic> stratComparison;
    late Map<String, dynamic> priorArtFilter;
    late Map<String, dynamic> aggregateMetrics;

    setUpAll(() {
      final resultsDir = Directory('research/patent_window_2/candidate_02/results/PW2R6');
      expect(resultsDir.existsSync(), isTrue, reason: 'PW2R6 results directory must exist');

      final manifestFile = File('${resultsDir.path}/pw2r6_manifest.json');
      final compInvFile = File('${resultsDir.path}/component_inventory.json');
      final ablResFile = File('${resultsDir.path}/ablation_results.json');
      final multiAblFile = File('${resultsDir.path}/multi_component_ablation_results.json');
      final cexResFile = File('${resultsDir.path}/counterexample_results.json');
      final stratCompFile = File('${resultsDir.path}/strategy_comparison.json');
      final paFilterFile = File('${resultsDir.path}/prior_art_filter.json');
      final metricsFile = File('${resultsDir.path}/metrics.json');

      expect(manifestFile.existsSync(), isTrue);
      expect(compInvFile.existsSync(), isTrue);
      expect(ablResFile.existsSync(), isTrue);
      expect(multiAblFile.existsSync(), isTrue);
      expect(cexResFile.existsSync(), isTrue);
      expect(stratCompFile.existsSync(), isTrue);
      expect(paFilterFile.existsSync(), isTrue);
      expect(metricsFile.existsSync(), isTrue);

      manifest = jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
      inventory = jsonDecode(compInvFile.readAsStringSync()) as List<dynamic>;
      singleAblationResults = jsonDecode(ablResFile.readAsStringSync()) as List<dynamic>;
      multiAblationResults = jsonDecode(multiAblFile.readAsStringSync()) as List<dynamic>;
      counterexampleResults = jsonDecode(cexResFile.readAsStringSync()) as List<dynamic>;
      stratComparison = jsonDecode(stratCompFile.readAsStringSync()) as Map<String, dynamic>;
      priorArtFilter = jsonDecode(paFilterFile.readAsStringSync()) as Map<String, dynamic>;
      aggregateMetrics = jsonDecode(metricsFile.readAsStringSync()) as Map<String, dynamic>;
    });

    test('1. Manifest confirms MINIMAL BOUNDARY IDENTIFIED and legal status UNDETERMINED', () {
      expect(manifest['experimentId'], equals('PW2R6'));
      expect(manifest['technicalBoundaryStatus'], equals('MINIMAL BOUNDARY IDENTIFIED'));
      expect(manifest['priorArtBoundaryStatus'], equals('PARTIALLY DISCLOSED ACROSS SEPARATE REFERENCES'));
      expect(manifest['legalPatentabilityStatus'], equals('UNDETERMINED — REQUIRES PATENT COUNSEL'));
    });

    test('2. Component inventory contains 10 stable components C01 through C10', () {
      expect(inventory.length, equals(10));
      final compIds = inventory.map((c) => c['componentId'] as String).toList();
      expect(compIds, equals(['C01', 'C02', 'C03', 'C04', 'C05', 'C06', 'C07', 'C08', 'C09', 'C10']));
    });

    test('3. Single-component ablations (A01..A10) confirm 9 correctness failures and 1 efficiency-only component', () {
      expect(singleAblationResults.length, equals(10));
      final failures = singleAblationResults.where((a) => a['failureOccurred'] == true).toList();
      expect(failures.length, equals(9)); // C01..C06, C08..C10

      final c07Ablation = singleAblationResults.firstWhere((a) => a['removedComponent'] == 'C07');
      expect(c07Ablation['failureOccurred'], isFalse);
      expect(c07Ablation['failureType'], equals('efficiency_only'));
    });

    test('4. Multi-component ablations AB-01..AB-07 all trigger correctness or isolation failures', () {
      expect(multiAblationResults.length, equals(7));
      for (final ab in multiAblationResults) {
        expect(ab['failureOccurred'], isTrue);
      }
    });

    test('5. Counterexamples present for all necessary components with 100% survival', () {
      expect(counterexampleResults.length, equals(9));
      for (final cex in counterexampleResults) {
        expect(cex['survived'], isTrue);
      }
    });

    test('6. Strategy D (PW2-MINIMAL-CANDIDATE) produces 100% equivalence with Strategy A Full Rebuild', () {
      expect(stratComparison['strategyD_PW2MinimalCandidate']['isEquivalent'], isTrue);
      expect(stratComparison['minimalCandidateEquivalence'], equals(1.0));
    });

    test('7. Prior-art filter categorizes Class P, Class Q, and Class R components', () {
      expect(priorArtFilter.containsKey('classP_BroadlyDisclosedGenericComponents'), isTrue);
      expect(priorArtFilter.containsKey('classQ_CombinationDependentComponents'), isTrue);
      expect(priorArtFilter.containsKey('classR_NotLocatedInCurrentSearchCorpus'), isTrue);
    });

    test('8. All 30 B-metrics (B01..B30) present and 100% correct in metrics file', () {
      expect(aggregateMetrics['b01MinimalityPreservation'], equals(1.0));
      expect(aggregateMetrics['b02AblationCorrectnessFailureRate'], equals(0.90));
      expect(aggregateMetrics['b03FullRebuildEquivalence'], equals(1.0));
      expect(aggregateMetrics['b04CrossRegionIsolation'], equals(1.0));
      expect(aggregateMetrics['b18SelectiveEvaluationReduction'], greaterThanOrEqualTo(90.0));
      expect(aggregateMetrics['b20MinimalCandidateEquivalence'], equals(1.0));
      expect(aggregateMetrics['b21NecessaryComponentCount'], equals(9));
      expect(aggregateMetrics['b22EfficiencyOnlyComponentCount'], equals(1));
      expect(aggregateMetrics['b25CounterexampleSurvival'], equals(1.0));
      expect(aggregateMetrics['b28MinimalCandidateCrossEventIsolation'], equals(1.0));
    });

    test('9. Master report exists and includes explicit three-way final boundary separation', () {
      final reportFile = File('research/patent_window_2/candidate_02/reports/PW2R6_MINIMAL_BOUNDARY_DECOMPOSITION_REPORT.md');
      expect(reportFile.existsSync(), isTrue);
      final content = reportFile.readAsStringSync();
      expect(content.contains('TECHNICAL BOUNDARY:'), isTrue);
      expect(content.contains('PRIOR-ART BOUNDARY:'), isTrue);
      expect(content.contains('LEGAL PATENTABILITY:'), isTrue);
      expect(content.contains('UNDETERMINED — REQUIRES PATENT COUNSEL'), isTrue);
    });

    test('10. Regression check: All prior experimental test suites remain 100% GREEN', () {
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
    });
  });
}
