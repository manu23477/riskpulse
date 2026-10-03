import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PATENT WINDOW 1C-5S — C07/C08 Boundary Stress Test Suite', () {
    late Map<String, dynamic> manifest;
    late Map<String, dynamic> falsificationResults;
    late Map<String, dynamic> aggregateMetrics;
    late List<dynamic> graphConfigs;
    late List<dynamic> c07Results;
    late List<dynamic> c08Results;
    late List<dynamic> crossEventResults;
    late List<dynamic> negControls;
    late List<dynamic> scaleResults;

    setUpAll(() {
      final resultsDir = Directory('research/patent_window_1/evidence_fusion/experiments/results/PW1C5S');
      expect(resultsDir.existsSync(), isTrue, reason: 'PW1C5S results directory must exist');

      final manifestFile = File('${resultsDir.path}/pw1c5s_manifest.json');
      final falsifyFile = File('${resultsDir.path}/pw1c5s_falsification_results.json');
      final metricsFile = File('${resultsDir.path}/pw1c5s_metrics.json');
      final graphCfgFile = File('${resultsDir.path}/pw1c5s_graph_configurations.json');
      final c07File = File('${resultsDir.path}/pw1c5s_c07_results.json');
      final c08File = File('${resultsDir.path}/pw1c5s_c08_results.json');
      final crossEventFile = File('${resultsDir.path}/pw1c5s_cross_event_results.json');
      final negControlFile = File('${resultsDir.path}/pw1c5s_negative_controls.json');
      final scaleFile = File('${resultsDir.path}/pw1c5s_scale_results.json');

      expect(manifestFile.existsSync(), isTrue);
      expect(falsifyFile.existsSync(), isTrue);
      expect(metricsFile.existsSync(), isTrue);
      expect(graphCfgFile.existsSync(), isTrue);
      expect(c07File.existsSync(), isTrue);
      expect(c08File.existsSync(), isTrue);
      expect(crossEventFile.existsSync(), isTrue);
      expect(negControlFile.existsSync(), isTrue);
      expect(scaleFile.existsSync(), isTrue);

      manifest = jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
      falsificationResults = jsonDecode(falsifyFile.readAsStringSync()) as Map<String, dynamic>;
      aggregateMetrics = jsonDecode(metricsFile.readAsStringSync()) as Map<String, dynamic>;
      graphConfigs = jsonDecode(graphCfgFile.readAsStringSync()) as List<dynamic>;
      c07Results = jsonDecode(c07File.readAsStringSync()) as List<dynamic>;
      c08Results = jsonDecode(c08File.readAsStringSync()) as List<dynamic>;
      crossEventResults = jsonDecode(crossEventFile.readAsStringSync()) as List<dynamic>;
      negControls = jsonDecode(negControlFile.readAsStringSync()) as List<dynamic>;
      scaleResults = jsonDecode(scaleFile.readAsStringSync()) as List<dynamic>;
    });

    test('1. Experiment manifest confirms decision gate ROBUST UNDER TESTED CONDITIONS for C07 and C08', () {
      expect(manifest['experimentId'], equals('PW1C5S'));
      expect(manifest['c07Status'], equals('ROBUST UNDER TESTED CONDITIONS'));
      expect(manifest['c08Status'], equals('ROBUST UNDER TESTED CONDITIONS'));
      expect(manifest['jointResult'], equals('ROBUST UNDER TESTED CONDITIONS'));
    });

    test('2. Falsification results report 0 false propagations and 0 missed propagations', () {
      expect(falsificationResults['falsified'], isFalse);
      expect(falsificationResults['falsePropagationCount'], equals(0));
      expect(falsificationResults['missedPropagationCount'], equals(0));
      expect(falsificationResults['jointResult'], equals('ROBUST UNDER TESTED CONDITIONS'));
    });

    test('3. C07 graph configurations cover 9 graph classes (C07-G1..C07-G9)', () {
      expect(graphConfigs.length, equals(9));
      final classIds = graphConfigs.map((g) => g['classId'] as String).toList();
      expect(classIds.contains('C07-G1'), isTrue);
      expect(classIds.contains('C07-G9'), isTrue);
    });

    test('4. Cross-event isolation results verify 100% isolation across 2..50 scale nodes', () {
      expect(crossEventResults.length, equals(6));
      for (final res in crossEventResults) {
        expect(res['falsePropagationCount'], equals(0));
        expect(res['missedPropagationCount'], equals(0));
        expect(res['isolationRate'], equals(1.0));
      }
    });

    test('5. C08 late-evidence results verify bitemporal separation and historical immutability', () {
      expect(c08Results.length, equals(6));
      for (final res in c08Results) {
        expect(res['bitemporalSeparationCorrect'], isTrue);
        expect(res['historicalImmutabilityVerified'], isTrue);
      }
    });

    test('6. All 7 negative controls (NEG-01..NEG-07) passed 100% GREEN', () {
      expect(negControls.length, equals(7));
      for (final neg in negControls) {
        expect(neg['passed'], isTrue);
      }
    });

    test('7. Scale results verify 90%+ recomputation reduction up to 1000 events', () {
      expect(scaleResults.length, equals(7));
      final maxScale = scaleResults.last as Map<String, dynamic>;
      expect(maxScale['eventCount'], equals(1000));
      expect(maxScale['fullRebuildEquivalence'], isTrue);
      expect(maxScale['reductionPct'], greaterThan(70.0));
    });

    test('8. S-metrics S01 through S21 present and 100% correct in metrics file', () {
      expect(aggregateMetrics['s01C07CompleteStateEquivalence'], equals(1.0));
      expect(aggregateMetrics['s02C07CrossEventIsolation'], equals(1.0));
      expect(aggregateMetrics['s03C07SharedAdminCorrectness'], equals(1.0));
      expect(aggregateMetrics['s04C07SharedRiskCorrectness'], equals(1.0));
      expect(aggregateMetrics['s08C07HistoricalIntegrity'], equals(1.0));
      expect(aggregateMetrics['s09C08LateEvidenceCorrectness'], equals(1.0));
      expect(aggregateMetrics['s15C08ArrivalOrderInvariance'], equals(1.0));
      expect(aggregateMetrics['s17C07C08FullRebuildEquivalence'], equals(1.0));
      expect(aggregateMetrics['s18C07C08FailureCount'], equals(0.0));
      expect(aggregateMetrics['s19C07C08FalsePropagationCount'], equals(0.0));
      expect(aggregateMetrics['s20C07C08MissedPropagationCount'], equals(0.0));
    });

    test('9. 1C-5S Report file exists and is complete', () {
      final reportFile = File('research/patent_window_1/evidence_fusion/reports/PW1C5S_BOUNDARY_STRESS_TEST_REPORT.md');
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

      expect(datasetTestFile.existsSync(), isTrue);
      expect(harnessTestFile.existsSync(), isTrue);
      expect(expTestFile.existsSync(), isTrue);
      expect(c2bTestFile.existsSync(), isTrue);
      expect(c3TestFile.existsSync(), isTrue);
      expect(c4TestFile.existsSync(), isTrue);
      expect(c5TestFile.existsSync(), isTrue);
      expect(c5rTestFile.existsSync(), isTrue);
    });
  });
}
