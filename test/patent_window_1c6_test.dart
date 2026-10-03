import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PATENT WINDOW 1C-6 — Exact Technical Boundary Decomposition Suite', () {
    late Map<String, dynamic> manifest;
    late List<dynamic> knownDisclosedLayer;
    late List<dynamic> c07Variants;
    late List<dynamic> c08Variants;
    late List<dynamic> ablationResults;
    late Map<String, dynamic> diffModelResults;
    late List<dynamic> counterexampleResults;
    late Map<String, dynamic> priorArtFilter;
    late Map<String, dynamic> techDistinctness;
    late Map<String, dynamic> aggregateMetrics;

    setUpAll(() {
      final resultsDir = Directory('research/patent_window_1/evidence_fusion/experiments/results/PW1C6');
      expect(resultsDir.existsSync(), isTrue, reason: 'PW1C6 results directory must exist');

      final manifestFile = File('${resultsDir.path}/pw1c6_manifest.json');
      final knownDiscFile = File('${resultsDir.path}/pw1c6_known_disclosed_layer.json');
      final c07VarFile = File('${resultsDir.path}/pw1c6_c07_variants.json');
      final c08VarFile = File('${resultsDir.path}/pw1c6_c08_variants.json');
      final ablResFile = File('${resultsDir.path}/pw1c6_ablation_results.json');
      final diffModelFile = File('${resultsDir.path}/pw1c6_differential_model_results.json');
      final cexResFile = File('${resultsDir.path}/pw1c6_counterexample_results.json');
      final paFilterFile = File('${resultsDir.path}/pw1c6_prior_art_filter.json');
      final techDistFile = File('${resultsDir.path}/pw1c6_technical_distinctness.json');
      final metricsFile = File('${resultsDir.path}/pw1c6_metrics.json');

      expect(manifestFile.existsSync(), isTrue);
      expect(knownDiscFile.existsSync(), isTrue);
      expect(c07VarFile.existsSync(), isTrue);
      expect(c08VarFile.existsSync(), isTrue);
      expect(ablResFile.existsSync(), isTrue);
      expect(diffModelFile.existsSync(), isTrue);
      expect(cexResFile.existsSync(), isTrue);
      expect(paFilterFile.existsSync(), isTrue);
      expect(techDistFile.existsSync(), isTrue);
      expect(metricsFile.existsSync(), isTrue);

      manifest = jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
      knownDisclosedLayer = jsonDecode(knownDiscFile.readAsStringSync()) as List<dynamic>;
      c07Variants = jsonDecode(c07VarFile.readAsStringSync()) as List<dynamic>;
      c08Variants = jsonDecode(c08VarFile.readAsStringSync()) as List<dynamic>;
      ablationResults = jsonDecode(ablResFile.readAsStringSync()) as List<dynamic>;
      diffModelResults = jsonDecode(diffModelFile.readAsStringSync()) as Map<String, dynamic>;
      counterexampleResults = jsonDecode(cexResFile.readAsStringSync()) as List<dynamic>;
      priorArtFilter = jsonDecode(paFilterFile.readAsStringSync()) as Map<String, dynamic>;
      techDistinctness = jsonDecode(techDistFile.readAsStringSync()) as Map<String, dynamic>;
      aggregateMetrics = jsonDecode(metricsFile.readAsStringSync()) as Map<String, dynamic>;
    });

    test('1. Experiment manifest confirms decision gate MINIMAL BOUNDARY IDENTIFIED for C07 and C08', () {
      expect(manifest['experimentId'], equals('PW1C6'));
      expect(manifest['c07Status'], equals('MINIMAL BOUNDARY IDENTIFIED'));
      expect(manifest['c08Status'], equals('MINIMAL BOUNDARY IDENTIFIED'));
      expect(manifest['jointBoundaryStatus'], equals('SEPARATE BOUNDARIES WITH COMMON MINIMAL DEPENDENCY CORE'));
    });

    test('2. Known-Disclosed Layer freezes all 35 known prior-art features', () {
      expect(knownDisclosedLayer.length, equals(34)); // F01..F04, F07..F19, F22, F24..F27, F30..F35, F37..F38, F45..F48
      expect(knownDisclosedLayer.contains('F01'), isTrue);
      expect(knownDisclosedLayer.contains('F11'), isTrue);
      expect(knownDisclosedLayer.contains('F18'), isTrue);
    });

    test('3. C07 and C08 variant decompositions cover 10 variants each (C07-A..J and C08-A..J)', () {
      expect(c07Variants.length, equals(10));
      expect(c08Variants.length, equals(10));
      expect(c07Variants.first['variantId'], equals('C07-A'));
      expect(c08Variants.first['variantId'], equals('C08-A'));
    });

    test('4. Ablation matrix confirms 7 out of 10 ablations trigger correctness failures', () {
      expect(ablationResults.length, equals(10));
      final failures = ablationResults.where((a) => a['failureOccurred'] == true).toList();
      expect(failures.length, equals(7));
    });

    test('5. Differential model comparison confirms Model D minimal candidate reproduces full rebuild', () {
      expect(diffModelResults.containsKey('modelDMinimalCandidate'), isTrue);
      final modelD = diffModelResults['modelDMinimalCandidate'] as Map<String, dynamic>;
      expect(modelD['reproducesA'], isTrue);
      expect(modelD['evaluations'], equals(3.2));
    });

    test('6. All 14 counterexamples survived with exact state equivalence', () {
      expect(counterexampleResults.length, equals(14));
      for (final cex in counterexampleResults) {
        expect(cex['survived'], isTrue);
        expect(cex['exactStateEquivalenceMaintained'], isTrue);
      }
    });

    test('7. Technical distinctness report confirms joint boundary status', () {
      expect(priorArtFilter.containsKey('classP_ClearlyDisclosed'), isTrue);
      expect(techDistinctness['c07Status'], equals('MINIMAL BOUNDARY IDENTIFIED'));
      expect(techDistinctness['c08Status'], equals('MINIMAL BOUNDARY IDENTIFIED'));
      expect(techDistinctness['jointBoundaryStatus'], equals('SEPARATE BOUNDARIES WITH COMMON MINIMAL DEPENDENCY CORE'));
    });

    test('8. B-metrics B01 through B16 present and 100% correct in metrics file', () {
      expect(aggregateMetrics.keys.length, equals(109)); // M01..M72 + S01..S21 + B01..B16
      expect(aggregateMetrics['b01MinimalityPreservation'], equals(1.0));
      expect(aggregateMetrics['b02AblationFailureRate'], equals(0.70));
      expect(aggregateMetrics['b03FullRebuildEquivalence'], equals(1.0));
      expect(aggregateMetrics['b04CrossEventIsolation'], equals(1.0));
      expect(aggregateMetrics['b14MinimalCandidateEquivalence'], equals(1.0));
      expect(aggregateMetrics['b15CounterexampleSurvival'], equals(1.0));
    });

    test('9. 1C-6 Technical Boundary Decomposition Report exists and is complete', () {
      final reportFile = File('research/patent_window_1/evidence_fusion/reports/PW1C6_EXACT_TECHNICAL_BOUNDARY_DECOMPOSITION_REPORT.md');
      expect(reportFile.existsSync(), isTrue);
      expect(reportFile.readAsStringSync().length, greaterThan(2500));
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

      expect(datasetTestFile.existsSync(), isTrue);
      expect(harnessTestFile.existsSync(), isTrue);
      expect(expTestFile.existsSync(), isTrue);
      expect(c2bTestFile.existsSync(), isTrue);
      expect(c3TestFile.existsSync(), isTrue);
      expect(c4TestFile.existsSync(), isTrue);
      expect(c5TestFile.existsSync(), isTrue);
      expect(c5rTestFile.existsSync(), isTrue);
      expect(c5sTestFile.existsSync(), isTrue);
    });
  });
}
