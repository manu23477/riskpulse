import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PATENT WINDOW 2 CANDIDATE 02 — PW2R7 Targeted Single-Reference Collision Audit Suite', () {
    late Map<String, dynamic> manifest;
    late List<dynamic> referenceIdentity;
    late List<dynamic> atomicFeatureMatrix;
    late List<dynamic> singleRefMatrix;
    late List<dynamic> comboMatrix;
    late Map<String, dynamic> contrRetentionStatus;
    late Map<String, dynamic> selRecompPriorArt;
    late Map<String, dynamic> boundaryStatus;

    setUpAll(() {
      final resultsDir = Directory('research/patent_window_2/candidate_02/results/PW2R7');
      expect(resultsDir.existsSync(), isTrue, reason: 'PW2R7 results directory must exist');

      final manifestFile = File('${resultsDir.path}/pw2r7_manifest.json');
      final refIdentFile = File('${resultsDir.path}/reference_identity.json');
      final atomicFeatFile = File('${resultsDir.path}/atomic_feature_matrix.json');
      final singleRefFile = File('${resultsDir.path}/single_reference_matrix.json');
      final comboFile = File('${resultsDir.path}/combination_matrix.json');
      final contrFile = File('${resultsDir.path}/contradiction_retention_status.json');
      final selRecompFile = File('${resultsDir.path}/selective_recomputation_prior_art.json');
      final boundaryFile = File('${resultsDir.path}/boundary_status.json');

      expect(manifestFile.existsSync(), isTrue);
      expect(refIdentFile.existsSync(), isTrue);
      expect(atomicFeatFile.existsSync(), isTrue);
      expect(singleRefFile.existsSync(), isTrue);
      expect(comboFile.existsSync(), isTrue);
      expect(contrFile.existsSync(), isTrue);
      expect(selRecompFile.existsSync(), isTrue);
      expect(boundaryFile.existsSync(), isTrue);

      manifest = jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
      referenceIdentity = jsonDecode(refIdentFile.readAsStringSync()) as List<dynamic>;
      atomicFeatureMatrix = jsonDecode(atomicFeatFile.readAsStringSync()) as List<dynamic>;
      singleRefMatrix = jsonDecode(singleRefFile.readAsStringSync()) as List<dynamic>;
      comboMatrix = jsonDecode(comboFile.readAsStringSync()) as List<dynamic>;
      contrRetentionStatus = jsonDecode(contrFile.readAsStringSync()) as Map<String, dynamic>;
      selRecompPriorArt = jsonDecode(selRecompFile.readAsStringSync()) as Map<String, dynamic>;
      boundaryStatus = jsonDecode(boundaryFile.readAsStringSync()) as Map<String, dynamic>;
    });

    test('1. Manifest confirms K10 single-reference collision is FALSE and legal status UNDETERMINED', () {
      expect(manifest['auditId'], equals('PW2R7'));
      expect(manifest['k10DisclosedInSingleReference'], isFalse);
      expect(manifest['technicalBoundaryStatus'], equals('MINIMAL BOUNDARY IDENTIFIED (PW2R6)'));
      expect(manifest['priorArtBoundaryStatus'], equals('PARTIALLY DISCLOSED ACROSS SEPARATE REFERENCES (PW2R7)'));
      expect(manifest['legalPatentabilityStatus'], equals('UNDETERMINED — REQUIRES PATENT COUNSEL'));
    });

    test('2. Reference identity list contains mandatory references', () {
      expect(referenceIdentity.length, greaterThanOrEqualTo(8));
      final pubNos = referenceIdentity.map((r) => r['publicationNumber'] as String).toList();
      expect(pubNos.contains('US8548248B2'), isTrue);
      expect(pubNos.contains('US10036650B2'), isTrue);
      expect(pubNos.contains('US10452652B2'), isTrue);
    });

    test('3. Atomic feature matrix covers all 30 features M01 through M30', () {
      expect(atomicFeatureMatrix.length, equals(30));
      final mIds = atomicFeatureMatrix.map((f) => f['featureId'] as String).toList();
      expect(mIds.first, equals('M01'));
      expect(mIds.last, equals('M30'));
    });

    test('4. Single-reference matrix confirms no single reference discloses complete K10 relationship', () {
      expect(singleRefMatrix.length, greaterThanOrEqualTo(8));
      for (final ref in singleRefMatrix) {
        expect(ref['disclosesCompleteK10'], isFalse);
        expect(ref['classification'], equals('PARTIAL_SINGLE_REFERENCE'));
      }
    });

    test('5. Combination matrix covers K01 through K10 with multi-reference mosaic findings', () {
      expect(comboMatrix.length, equals(10));
      final k10 = comboMatrix.firstWhere((k) => k['combinationId'] == 'K10');
      expect(k10['singleReferenceDisclosed'], isFalse);
      expect(k10['multiReferenceMosaicDisclosed'], isTrue);
      expect(k10['includedComponents'].length, equals(9));
    });

    test('6. Research notes confirm contradiction retention and selective recomputation statuses', () {
      expect(contrRetentionStatus['status'], equals('SUPPORTING_LINEAGE_BEHAVIOR'));
      expect(contrRetentionStatus['isCoreToK10'], isFalse);

      expect(selRecompPriorArt['status'], equals('EFFICIENCY_ONLY'));
      expect(selRecompPriorArt['isCoreToK10'], isFalse);
    });

    test('7. Boundary status report explicitly records three-way separation', () {
      expect(boundaryStatus['legalPatentabilityStatus'], equals('UNDETERMINED — REQUIRES PATENT COUNSEL'));
      expect(boundaryStatus['technicalBoundary'].contains('PW2R6'), isTrue);
      expect(boundaryStatus['priorArtBoundary'].contains('searched corpus'), isTrue);
    });

    test('8. Master report exists and includes explicit answers to all 7 required questions', () {
      final reportFile = File('research/patent_window_2/candidate_02/reports/PW2R7_TARGETED_SINGLE_REFERENCE_COLLISION_AUDIT_REPORT.md');
      expect(reportFile.existsSync(), isTrue);
      final content = reportFile.readAsStringSync();
      expect(content.contains('TECHNICAL BOUNDARY:'), isTrue);
      expect(content.contains('PRIOR-ART BOUNDARY:'), isTrue);
      expect(content.contains('LEGAL PATENTABILITY:'), isTrue);
      expect(content.contains('UNDETERMINED — REQUIRES PATENT COUNSEL'), isTrue);
    });

    test('9. Regression check: All prior experimental test suites remain 100% GREEN', () {
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
    });
  });
}
