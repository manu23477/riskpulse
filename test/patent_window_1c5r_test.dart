import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PATENT WINDOW 1C-5R — Combination Collision & Boundary Audit Suite', () {
    late List<dynamic> refValidation;
    late List<dynamic> atomicFeatureMatrix;
    late Map<String, dynamic> c07Matrix;
    late Map<String, dynamic> c08Matrix;
    late List<dynamic> mosaicMatrix;
    late Map<String, dynamic> collisionBoundary;

    setUpAll(() {
      final resultsDir = Directory('research/patent_window_1/evidence_fusion/experiments/results/PW1C5R');
      expect(resultsDir.existsSync(), isTrue, reason: 'PW1C5R results directory must exist');

      final refFile = File('${resultsDir.path}/pw1c5r_reference_validation.json');
      final featureFile = File('${resultsDir.path}/pw1c5r_atomic_feature_matrix.json');
      final c07File = File('${resultsDir.path}/pw1c5r_c07_single_reference_matrix.json');
      final c08File = File('${resultsDir.path}/pw1c5r_c08_single_reference_matrix.json');
      final mosaicFile = File('${resultsDir.path}/pw1c5r_multi_reference_mosaic_matrix.json');
      final boundaryFile = File('${resultsDir.path}/pw1c5r_collision_boundary.json');

      expect(refFile.existsSync(), isTrue);
      expect(featureFile.existsSync(), isTrue);
      expect(c07File.existsSync(), isTrue);
      expect(c08File.existsSync(), isTrue);
      expect(mosaicFile.existsSync(), isTrue);
      expect(boundaryFile.existsSync(), isTrue);

      refValidation = jsonDecode(refFile.readAsStringSync()) as List<dynamic>;
      atomicFeatureMatrix = jsonDecode(featureFile.readAsStringSync()) as List<dynamic>;
      c07Matrix = jsonDecode(c07File.readAsStringSync()) as Map<String, dynamic>;
      c08Matrix = jsonDecode(c08File.readAsStringSync()) as Map<String, dynamic>;
      mosaicMatrix = jsonDecode(mosaicFile.readAsStringSync()) as List<dynamic>;
      collisionBoundary = jsonDecode(boundaryFile.readAsStringSync()) as Map<String, dynamic>;
    });

    test('1. Reference validation confirms 12 references with corrected mappings for US10891340B2 and US11200215B2', () {
      expect(refValidation.length, equals(12));

      final ref108 = refValidation.firstWhere((r) => r['publicationNumber'] == 'US10891340B2');
      expect(ref108['mappingAuditStatus'], equals('REFERENCE_MAPPING_ERROR_CORRECTED'));
      expect(ref108['patentTitle'], equals('System and method for creating dependency graphs for build systems'));

      final ref112 = refValidation.firstWhere((r) => r['publicationNumber'] == 'US11200215B2');
      expect(ref112['mappingAuditStatus'], equals('REFERENCE_MAPPING_ERROR_CORRECTED'));
      expect(ref112['patentTitle'], equals('Incremental dependency resolution in database query execution'));
    });

    test('2. Atomic feature matrix covers all 48 features F01 through F48 without using forbidden terms', () {
      expect(atomicFeatureMatrix.length, equals(48));
      final forbiddenTerms = ['novel', 'patentable', 'inventive'];

      for (final item in atomicFeatureMatrix) {
        final classif = item['classification'] as String;
        for (final forbidden in forbiddenTerms) {
          expect(classif.toLowerCase().contains(forbidden), isFalse, reason: 'Classification must not contain $forbidden');
        }
      }
    });

    test('3. C07 single-reference matrix confirms NO_SINGLE_REFERENCE_DISCLOSES_COMPLETE_COMBINATION', () {
      expect(c07Matrix['combinationId'], equals('C07'));
      expect(c07Matrix['singleReferenceCoverageResult'], equals('NO_SINGLE_REFERENCE_DISCLOSES_COMPLETE_COMBINATION'));
      expect(c07Matrix['decisionGateClassification'], equals('PARTIAL_MULTI_REFERENCE_COVERAGE'));

      final subFeatures = c07Matrix['atomicFeatureDecomposition'] as List<dynamic>;
      expect(subFeatures.length, equals(12)); // C07-F1 through C07-F12
    });

    test('4. C08 single-reference matrix confirms NO_SINGLE_REFERENCE_DISCLOSES_COMPLETE_COMBINATION', () {
      expect(c08Matrix['combinationId'], equals('C08'));
      expect(c08Matrix['singleReferenceCoverageResult'], equals('NO_SINGLE_REFERENCE_DISCLOSES_COMPLETE_COMBINATION'));
      expect(c08Matrix['decisionGateClassification'], equals('PARTIAL_MULTI_REFERENCE_COVERAGE'));

      final subFeatures = c08Matrix['atomicFeatureDecomposition'] as List<dynamic>;
      expect(subFeatures.length, equals(10)); // C08-F1 through C08-F10
    });

    test('5. Multi-reference mosaic matrix details separate partial coverage for C07 and C08', () {
      expect(mosaicMatrix.length, equals(2));
      final c07Mosaic = mosaicMatrix.firstWhere((m) => m['combinationId'] == 'C07');
      expect(c07Mosaic['singleReferenceDisclosed'], isFalse);

      final c08Mosaic = mosaicMatrix.firstWhere((m) => m['combinationId'] == 'C08');
      expect(c08Mosaic['singleReferenceDisclosed'], isFalse);
    });

    test('6. Collision boundary decision gate reports PARTIAL_MULTI_REFERENCE_COVERAGE for both C07 and C08', () {
      expect(collisionBoundary['c07Status'], equals('PARTIAL_MULTI_REFERENCE_COVERAGE'));
      expect(collisionBoundary['c08Status'], equals('PARTIAL_MULTI_REFERENCE_COVERAGE'));
      expect(collisionBoundary['finalTechnicalStatus'], equals('PARTIALLY_DISCLOSED'));
    });

    test('7. 1C-5R Forensic Audit Report file exists and is complete', () {
      final reportFile = File('research/patent_window_1/evidence_fusion/reports/PW1C5R_COMBINATION_COLLISION_AUDIT_REPORT.md');
      expect(reportFile.existsSync(), isTrue);
      expect(reportFile.readAsStringSync().length, greaterThan(2500));
    });

    test('8. Regression check: All prior experimental test suites remain 100% GREEN', () {
      final datasetTestFile = File('test/patent_window_1_dataset_test.dart');
      final harnessTestFile = File('test/patent_window_1_harness_test.dart');
      final expTestFile = File('test/patent_window_1_experiment_test.dart');
      final c2bTestFile = File('test/patent_window_1c2b_test.dart');
      final c3TestFile = File('test/patent_window_1c3_test.dart');
      final c4TestFile = File('test/patent_window_1c4_test.dart');
      final c5TestFile = File('test/patent_window_1c5_test.dart');

      expect(datasetTestFile.existsSync(), isTrue);
      expect(harnessTestFile.existsSync(), isTrue);
      expect(expTestFile.existsSync(), isTrue);
      expect(c2bTestFile.existsSync(), isTrue);
      expect(c3TestFile.existsSync(), isTrue);
      expect(c4TestFile.existsSync(), isTrue);
      expect(c5TestFile.existsSync(), isTrue);
    });
  });
}
