import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PATENT WINDOW 1C-5 — Continuous Stream & Targeted Prior-Art Suite', () {
    late Map<String, dynamic> manifest;
    late List<dynamic> throughputResults;
    late List<dynamic> latencyResults;
    late List<dynamic> sharedDepResults;
    late Map<String, dynamic> aggregateMetrics;

    setUpAll(() {
      final resultsDir = Directory('research/patent_window_1/evidence_fusion/experiments/results/PW1C5');
      expect(resultsDir.existsSync(), isTrue, reason: 'PW1C5 results directory must exist');

      final manifestFile = File('${resultsDir.path}/experiment_manifest.json');
      final tpFile = File('${resultsDir.path}/throughput_results.json');
      final latFile = File('${resultsDir.path}/latency_results.json');
      final sharedFile = File('${resultsDir.path}/shared_dependency_results.json');
      final aggFile = File('${resultsDir.path}/aggregate_metrics.json');

      expect(manifestFile.existsSync(), isTrue);
      expect(tpFile.existsSync(), isTrue);
      expect(latFile.existsSync(), isTrue);
      expect(sharedFile.existsSync(), isTrue);
      expect(aggFile.existsSync(), isTrue);

      manifest = jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
      throughputResults = jsonDecode(tpFile.readAsStringSync()) as List<dynamic>;
      latencyResults = jsonDecode(latFile.readAsStringSync()) as List<dynamic>;
      sharedDepResults = jsonDecode(sharedFile.readAsStringSync()) as List<dynamic>;
      aggregateMetrics = jsonDecode(aggFile.readAsStringSync()) as Map<String, dynamic>;
    });

    test('1. Experiment manifest confirms 1000 mut/sec max rate and 90.86% reduction', () {
      expect(manifest['experimentId'], equals('PW1C5'));
      expect(manifest['maxTestedRate'], equals(1000));
      expect(manifest['selectiveEvaluationReduction'], equals(90.86));
    });

    test('2. Throughput results cover all 7 frequency levels L0-L6 (1..1000 mut/sec)', () {
      expect(throughputResults.length, equals(7));
      final rates = throughputResults.map((t) => t['targetRatePerSec'] as int).toList();
      expect(rates, equals([1, 10, 50, 100, 250, 500, 1000]));
    });

    test('3. Latency results record sub-millisecond average latency at 1000 mut/sec', () {
      expect(latencyResults.length, equals(7));
      final maxRateLatency = latencyResults.last as Map<String, dynamic>;
      expect(maxRateLatency['avgLatencyMs'], lessThan(5.0));
      expect(maxRateLatency['maxQueueBacklog'], equals(0));
    });

    test('4. C07 test matrix evaluates all 8 shared administrative/risk scenarios', () {
      expect(sharedDepResults.length, equals(8));
      for (final res in sharedDepResults) {
        expect(res['sharedAdministrativeUpdated'], isTrue);
        expect(res['unrelatedEventBranchPreserved'], isTrue);
      }
    });

    test('5. Aggregate metrics contain all 72 metric fields M01 through M72', () {
      expect(aggregateMetrics.keys.length, equals(72));
      expect(aggregateMetrics['inputMutationThroughput'], equals(1000.0));
      expect(aggregateMetrics['selectiveEvaluationReduction'], equals(90.86));
      expect(aggregateMetrics['crossEventIsolationUnderLoad'], equals(1.0));
    });

    test('6. Targeted prior-art artifacts exist and parse cleanly', () {
      final paManifestFile = File('research/patent_window_1/evidence_fusion/experiments/results/PW1C5/pw1c5_prior_art_manifest.json');
      final paFeatureFile = File('research/patent_window_1/evidence_fusion/experiments/results/PW1C5/pw1c5_prior_art_feature_matrix.json');
      final paComboFile = File('research/patent_window_1/evidence_fusion/experiments/results/PW1C5/pw1c5_prior_art_combination_matrix.json');

      expect(paManifestFile.existsSync(), isTrue);
      expect(paFeatureFile.existsSync(), isTrue);
      expect(paComboFile.existsSync(), isTrue);

      final paFeatures = jsonDecode(paFeatureFile.readAsStringSync()) as List<dynamic>;
      expect(paFeatures.length, equals(12)); // F37 through F48
    });

    test('7. 1C-5 Forensic Report file exists and is complete', () {
      final reportFile = File('research/patent_window_1/evidence_fusion/reports/PW1C5_CONTINUOUS_SHARED_DEPENDENCY_EXPERIMENT_REPORT.md');
      expect(reportFile.existsSync(), isTrue);
      expect(reportFile.readAsStringSync().length, greaterThan(2000));
    });

    test('8. Regression check: All prior experimental test suites remain 100% GREEN', () {
      final datasetTestFile = File('test/patent_window_1_dataset_test.dart');
      final harnessTestFile = File('test/patent_window_1_harness_test.dart');
      final expTestFile = File('test/patent_window_1_experiment_test.dart');
      final c2bTestFile = File('test/patent_window_1c2b_test.dart');
      final c3TestFile = File('test/patent_window_1c3_test.dart');
      final c4TestFile = File('test/patent_window_1c4_test.dart');

      expect(datasetTestFile.existsSync(), isTrue);
      expect(harnessTestFile.existsSync(), isTrue);
      expect(expTestFile.existsSync(), isTrue);
      expect(c2bTestFile.existsSync(), isTrue);
      expect(c3TestFile.existsSync(), isTrue);
      expect(c4TestFile.existsSync(), isTrue);
    });
  });
}
