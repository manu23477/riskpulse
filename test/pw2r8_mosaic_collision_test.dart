import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PATENT WINDOW 2 CANDIDATE 02 — PW2R8 Mosaic Collision & Relationship-Gap Suite', () {
    late Map<String, dynamic> manifest;
    late List<dynamic> relMatrix;
    late List<dynamic> comboResults;
    late Map<String, dynamic> teachMatrix;
    late List<dynamic> exResults;
    late Map<String, dynamic> mosaicDistance;
    late Map<String, dynamic> minRelCore;
    late Map<String, dynamic> boundaryStatus;

    setUpAll(() {
      final resultsDir = Directory('research/patent_window_2/candidate_02/results/PW2R8');
      expect(resultsDir.existsSync(), isTrue, reason: 'PW2R8 results directory must exist');

      final manifestFile = File('${resultsDir.path}/pw2r8_manifest.json');
      final relMatFile = File('${resultsDir.path}/relationship_matrix.json');
      final comboResFile = File('${resultsDir.path}/combination_results.json');
      final teachMatFile = File('${resultsDir.path}/teaching_matrix.json');
      final exResFile = File('${resultsDir.path}/examiner_reconstruction_results.json');
      final distMatFile = File('${resultsDir.path}/mosaic_distance.json');
      final minCoreFile = File('${resultsDir.path}/minimal_relationship_core.json');
      final boundaryFile = File('${resultsDir.path}/boundary_status.json');

      expect(manifestFile.existsSync(), isTrue);
      expect(relMatFile.existsSync(), isTrue);
      expect(comboResFile.existsSync(), isTrue);
      expect(teachMatFile.existsSync(), isTrue);
      expect(exResFile.existsSync(), isTrue);
      expect(distMatFile.existsSync(), isTrue);
      expect(minCoreFile.existsSync(), isTrue);
      expect(boundaryFile.existsSync(), isTrue);

      manifest = jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
      relMatrix = jsonDecode(relMatFile.readAsStringSync()) as List<dynamic>;
      comboResults = jsonDecode(comboResFile.readAsStringSync()) as List<dynamic>;
      teachMatrix = jsonDecode(teachMatFile.readAsStringSync()) as Map<String, dynamic>;
      exResults = jsonDecode(exResFile.readAsStringSync()) as List<dynamic>;
      mosaicDistance = jsonDecode(distMatFile.readAsStringSync()) as Map<String, dynamic>;
      minRelCore = jsonDecode(minCoreFile.readAsStringSync()) as Map<String, dynamic>;
      boundaryStatus = jsonDecode(boundaryFile.readAsStringSync()) as Map<String, dynamic>;
    });

    test('1. Manifest confirms K10 single-reference disclosure is FALSE and legal status UNDETERMINED', () {
      expect(manifest['auditId'], equals('PW2R8'));
      expect(manifest['k10CompleteRelationshipLocatedInSingleRef'], isFalse);
      expect(manifest['technicalBoundaryStatus'], equals('MINIMAL BOUNDARY IDENTIFIED (PW2R6 K10)'));
      expect(manifest['mosaicPriorArtBoundaryStatus'], equals('PARTIALLY DISCLOSED ACROSS MULTI-REFERENCE MOSAIC (PW2R8)'));
      expect(manifest['legalPatentabilityStatus'], equals('UNDETERMINED — REQUIRES PATENT COUNSEL'));
    });

    test('2. Relationship matrix covers all 30 relationships R01 through R30', () {
      expect(relMatrix.length, equals(30));
      final rIds = relMatrix.map((r) => r['relationshipId'] as String).toList();
      expect(rIds.first, equals('R01'));
      expect(rIds.last, equals('R30'));

      final r08 = relMatrix.firstWhere((r) => r['relationshipId'] == 'R08');
      expect(r08['status'], equals('STATUS_D'));
      expect(r08['notLocatedInSearchedCorpus'], isTrue);
    });

    test('3. Combination results (COMBO-01..COMBO-10) confirm K10 is disclosed only as multi-reference mosaic', () {
      expect(comboResults.length, equals(10));
      final combo10 = comboResults.firstWhere((c) => c['comboId'] == 'COMBO-10');
      expect(combo10['singleReferenceDisclosed'], isFalse);
      expect(combo10['multiReferenceMosaicDisclosed'], isTrue);
      expect(combo10['referencesIncluded'].length, equals(6));
    });

    test('4. Teaching matrix confirms combining references requires substantial redesign', () {
      expect(teachMatrix['T01_ExplicitTeachingToCombine'], equals('NO'));
      expect(teachMatrix['T10_CombinationRequiresSubstantialRedesign'], equals('YES'));
    });

    test('5. Examiner reconstructions (E01..E08) confirm redesign required to equal K10', () {
      expect(exResults.length, equals(8));
      for (final ex in exResults) {
        expect(ex['equalsK10Architecture'], isFalse);
        expect(ex['requiresSubstantialRedesign'], isTrue);
      }
    });

    test('6. Mosaic distance metrics (M01..M07) record multi-reference gap measures', () {
      expect(mosaicDistance['m01ReferencesForComponents'], equals(6));
      expect(mosaicDistance['m03RelationshipsRequiringMosaic'], equals(22));
      expect(mosaicDistance['m04RelationshipsNotLocatedCompletely'], equals(8));
    });

    test('7. PW2-MINIMAL-RELATIONSHIP-CORE identifies critical coupling relationships', () {
      expect(minRelCore['coreName'], equals('PW2-MINIMAL-RELATIONSHIP-CORE'));
      final criticalRels = (minRelCore['criticalRelationships'] as List<dynamic>).cast<String>();
      expect(criticalRels.contains('R08'), isTrue);
      expect(criticalRels.contains('R10'), isTrue);
      expect(criticalRels.contains('R11'), isTrue);
      expect(criticalRels.contains('R22'), isTrue);
      expect(criticalRels.contains('R30'), isTrue);
    });

    test('8. Boundary status report explicitly records four-way separation', () {
      expect(boundaryStatus['legalPatentabilityStatus'], equals('UNDETERMINED — REQUIRES PATENT COUNSEL'));
      expect(boundaryStatus['technicalBoundary'].contains('PW2R6'), isTrue);
      expect(boundaryStatus['mosaicPriorArtBoundary'].contains('multi-reference mosaic'), isTrue);
      expect(boundaryStatus['relationshipGap'].contains('R08'), isTrue);
    });

    test('9. Master report exists and includes answers to all 10 required final questions', () {
      final reportFile = File('research/patent_window_2/candidate_02/reports/PW2R8_MOSAIC_COMBINATION_RELATIONSHIP_GAP_REPORT.md');
      expect(reportFile.existsSync(), isTrue);
      final content = reportFile.readAsStringSync();
      expect(content.contains('TECHNICAL BOUNDARY:'), isTrue);
      expect(content.contains('MOSAIC PRIOR-ART BOUNDARY:'), isTrue);
      expect(content.contains('RELATIONSHIP GAP:'), isTrue);
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
      final r6TestFile = File('test/pw2r6_minimal_boundary_test.dart');
      final r7TestFile = File('test/pw2r7_targeted_collision_test.dart');

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
    });
  });
}
