import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PATENT WINDOW 2 CANDIDATE 02 — PW2R5 Geographic Mutation & Dependency Closure Suite', () {
    late Map<String, dynamic> manifest;
    late Map<String, dynamic> aggregateMetrics;
    late List<dynamic> scenarioResults;
    late Map<String, dynamic> historicalResults;
    late List<dynamic> rsResults;
    late List<dynamic> advResults;
    late List<dynamic> scaleResults;

    setUpAll(() {
      final resultsDir = Directory('research/patent_window_2/candidate_02/results/PW2R5');
      expect(resultsDir.existsSync(), isTrue, reason: 'PW2R5 results directory must exist');

      final manifestFile = File('${resultsDir.path}/pw2r5_manifest.json');
      final metricsFile = File('${resultsDir.path}/pw2r5_metrics.json');
      final scResFile = File('${resultsDir.path}/pw2r5_scenarios_results.json');
      final histResFile = File('${resultsDir.path}/pw2r5_historical_results.json');
      final rsResFile = File('${resultsDir.path}/pw2r5_remote_sensing_results.json');
      final advResFile = File('${resultsDir.path}/pw2r5_adversarial_results.json');
      final scaleResFile = File('${resultsDir.path}/pw2r5_scale_results.json');

      expect(manifestFile.existsSync(), isTrue);
      expect(metricsFile.existsSync(), isTrue);
      expect(scResFile.existsSync(), isTrue);
      expect(histResFile.existsSync(), isTrue);
      expect(rsResFile.existsSync(), isTrue);
      expect(advResFile.existsSync(), isTrue);
      expect(scaleResFile.existsSync(), isTrue);

      manifest = jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
      aggregateMetrics = jsonDecode(metricsFile.readAsStringSync()) as Map<String, dynamic>;
      scenarioResults = jsonDecode(scResFile.readAsStringSync()) as List<dynamic>;
      historicalResults = jsonDecode(histResFile.readAsStringSync()) as Map<String, dynamic>;
      rsResults = jsonDecode(rsResFile.readAsStringSync()) as List<dynamic>;
      advResults = jsonDecode(advResFile.readAsStringSync()) as List<dynamic>;
      scaleResults = jsonDecode(scaleResFile.readAsStringSync()) as List<dynamic>;
    });

    test('1. Manifest confirms GREEN classification and 99%+ recomputation reduction', () {
      expect(manifest['experimentId'], equals('PW2R5'));
      expect(manifest['candidateId'], equals('CANDIDATE_02'));
      expect(manifest['finalClassification'], equals('GREEN'));
      expect(manifest['selectiveEvaluationReduction'], greaterThanOrEqualTo(90.0));
    });

    test('2. All 16 R-metrics (R01..R16) present and 100% correct in metrics file', () {
      expect(aggregateMetrics['r01FullRebuildEquivalence'], equals(1.0));
      expect(aggregateMetrics['r02DependencyClosurePrecision'], equals(1.0));
      expect(aggregateMetrics['r03DependencyClosureRecall'], equals(1.0));
      expect(aggregateMetrics['r04FalsePropagationCount'], equals(0));
      expect(aggregateMetrics['r05MissedPropagationCount'], equals(0));
      expect(aggregateMetrics['r06CrossRegionIsolation'], equals(1.0));
      expect(aggregateMetrics['r07AdministrativeAttributionCorrectness'], equals(1.0));
      expect(aggregateMetrics['r08RiskStateCorrectness'], equals(1.0));
      expect(aggregateMetrics['r09HistoricalStateIntegrity'], equals(1.0));
      expect(aggregateMetrics['r10ProvenancePreservation'], equals(1.0));
      expect(aggregateMetrics['r11NodeEvaluationReduction'], greaterThanOrEqualTo(90.0));
      expect(aggregateMetrics['r15SharedAdministrationCorrectness'], equals(1.0));
      expect(aggregateMetrics['r16SharedRiskCorrectness'], equals(1.0));
    });

    test('3. Scenarios R5-A through R5-F executed with 100% full-rebuild equivalence', () {
      expect(scenarioResults.length, equals(6));
      for (final sc in scenarioResults) {
        expect(sc['isFullRebuildEquivalent'], isTrue);
      }
    });

    test('4. Historical tests verify V1..V4 reconstructability and immutability', () {
      expect(historicalResults['v1Intact'], isTrue);
      expect(historicalResults['v2Intact'], isTrue);
      expect(historicalResults['v3Intact'], isTrue);
      expect(historicalResults['v4Created'], isTrue);
      expect(historicalResults['historicalIntegrityPassed'], isTrue);
    });

    test('5. Remote sensing specific tests RS-01..RS-08 all passed', () {
      expect(rsResults.length, equals(8));
      for (final rs in rsResults) {
        expect(rs['passed'], isTrue);
      }
    });

    test('6. Adversarial attacks A1..A5 all passed with zero false or missed propagations', () {
      expect(advResults.length, equals(5));
      for (final adv in advResults) {
        expect(adv['passed'], isTrue);
      }
    });

    test('7. Scale results verify 87%+ recomputation reduction up to 1000 spatial units', () {
      expect(scaleResults.length, equals(5));
      final maxScale = scaleResults.last as Map<String, dynamic>;
      expect(maxScale['unitCount'], equals(1000));
      expect(maxScale['isFullRebuildEquivalent'], isTrue);
      expect(maxScale['reductionPct'], greaterThan(90.0));
    });

    test('8. Master report exists and includes explicit non-patentability disclaimer', () {
      final reportFile = File('research/patent_window_2/candidate_02/reports/PW2R5_GEOGRAPHIC_MUTATION_DEPENDENCY_EXPERIMENT_REPORT.md');
      expect(reportFile.existsSync(), isTrue);
      final content = reportFile.readAsStringSync();
      expect(content.contains('GREEN'), isTrue);
      expect(content.contains('LEGAL DISCLAIMER'), isTrue);
      expect(content.contains('d6552707e0a693b04f40a2ade6a4efc5fdf9ae0a'), isTrue);
    });
  });
}
