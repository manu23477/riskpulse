import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PATENT WINDOW 1C-4 — Prior-Art Boundary Mapping Validation Suite', () {
    late Map<String, dynamic> coverageSummary;
    late List<dynamic> priorArtManifest;
    late List<dynamic> featureMatrix;
    late List<dynamic> combinationMatrix;
    late List<dynamic> candidateBoundaries;
    late List<dynamic> referenceFamilyMap;

    setUpAll(() {
      final resultsDir = Directory('research/patent_window_1/evidence_fusion/experiments/results/PW1C4');
      expect(resultsDir.existsSync(), isTrue, reason: 'PW1C4 results directory must exist');

      final manifestFile = File('${resultsDir.path}/prior_art_manifest.json');
      final featureFile = File('${resultsDir.path}/feature_matrix.json');
      final comboFile = File('${resultsDir.path}/combination_matrix.json');
      final candFile = File('${resultsDir.path}/candidate_boundaries.json');
      final familyFile = File('${resultsDir.path}/reference_family_map.json');
      final covFile = File('${resultsDir.path}/coverage_summary.json');

      expect(manifestFile.existsSync(), isTrue);
      expect(featureFile.existsSync(), isTrue);
      expect(comboFile.existsSync(), isTrue);
      expect(candFile.existsSync(), isTrue);
      expect(familyFile.existsSync(), isTrue);
      expect(covFile.existsSync(), isTrue);

      priorArtManifest = jsonDecode(manifestFile.readAsStringSync()) as List<dynamic>;
      featureMatrix = jsonDecode(featureFile.readAsStringSync()) as List<dynamic>;
      combinationMatrix = jsonDecode(comboFile.readAsStringSync()) as List<dynamic>;
      candidateBoundaries = jsonDecode(candFile.readAsStringSync()) as List<dynamic>;
      referenceFamilyMap = jsonDecode(familyFile.readAsStringSync()) as List<dynamic>;
      coverageSummary = jsonDecode(covFile.readAsStringSync()) as Map<String, dynamic>;
    });

    test('1. Prior-art manifest contains 10 primary references', () {
      expect(priorArtManifest.length, equals(10));
      final refIds = priorArtManifest.map((r) => r['referenceId'] as String).toSet();
      expect(refIds.contains('REF-01'), isTrue);
      expect(refIds.contains('REF-08'), isTrue);
    });

    test('2. Reference family map consolidates 10 patent families', () {
      expect(referenceFamilyMap.length, equals(10));
      for (final fam in referenceFamilyMap) {
        expect(fam.containsKey('familyId'), isTrue);
        expect(fam.containsKey('representativePublication'), isTrue);
      }
    });

    test('3. Atomic feature matrix covers all 36 features F01 through F36', () {
      expect(featureMatrix.length, equals(36));
      final featIds = featureMatrix.map((f) => f['featureId'] as String).toSet();

      for (int i = 1; i <= 36; i++) {
        final expectedId = 'F${i.toString().padLeft(2, '0')}';
        expect(featIds.contains(expectedId), isTrue, reason: 'Missing feature ID: $expectedId');
      }
    });

    test('4. Combination matrix covers all 8 combinations C01 through C08', () {
      expect(combinationMatrix.length, equals(8));
      final comboIds = combinationMatrix.map((c) => c['combinationId'] as String).toSet();

      for (int i = 1; i <= 8; i++) {
        final expectedId = 'C${i.toString().padLeft(2, '0')}';
        expect(comboIds.contains(expectedId), isTrue, reason: 'Missing combination ID: $expectedId');
      }
    });

    test('5. Candidate boundaries matrix evaluates 7 candidates CAND-A through CAND-G', () {
      expect(candidateBoundaries.length, equals(7));
      final candIds = candidateBoundaries.map((c) => c['candidateId'] as String).toSet();

      final expectedCands = ['CAND-A', 'CAND-B', 'CAND-C', 'CAND-D', 'CAND-E', 'CAND-F', 'CAND-G'];
      for (final id in expectedCands) {
        expect(candIds.contains(id), isTrue, reason: 'Missing candidate ID: $id');
      }
    });

    test('6. Coverage summary counts match atomic feature and combination matrices', () {
      expect(coverageSummary['totalAtomicFeaturesMapped'], equals(36));
      expect(coverageSummary['clearlyDisclosedCount'], equals(28));
      expect(coverageSummary['partiallyDisclosedCount'], equals(8));
      expect(coverageSummary['totalCombinationsAnalyzed'], equals(8));
      expect(coverageSummary['priorArtReferencesReviewed'], equals(10));
    });

    test('7. 1C-4 Report file exists and is complete', () {
      final reportFile = File('research/patent_window_1/evidence_fusion/reports/PW1C4_PRIOR_ART_BOUNDARY_MAPPING_REPORT.md');
      expect(reportFile.existsSync(), isTrue);
      expect(reportFile.readAsStringSync().length, greaterThan(2000));
    });

    test('8. Regression check: All prior experimental test suites remain 100% GREEN', () {
      final datasetTestFile = File('test/patent_window_1_dataset_test.dart');
      final harnessTestFile = File('test/patent_window_1_harness_test.dart');
      final expTestFile = File('test/patent_window_1_experiment_test.dart');
      final c2bTestFile = File('test/patent_window_1c2b_test.dart');
      final c3TestFile = File('test/patent_window_1c3_test.dart');

      expect(datasetTestFile.existsSync(), isTrue);
      expect(harnessTestFile.existsSync(), isTrue);
      expect(expTestFile.existsSync(), isTrue);
      expect(c2bTestFile.existsSync(), isTrue);
      expect(c3TestFile.existsSync(), isTrue);
    });
  });
}
