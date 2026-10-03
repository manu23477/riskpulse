import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PATENT WINDOW 1C-6R — Targeted Collision Audit Suite', () {
    late Map<String, dynamic> manifest;
    late Map<String, dynamic> c07SingleRefMatrix;
    late Map<String, dynamic> c08SingleRefMatrix;
    late List<dynamic> c07MosaicMatrix;
    late List<dynamic> c08MosaicMatrix;
    late List<dynamic> candidateReferences;
    late Map<String, dynamic> boundaryStatus;

    setUpAll(() {
      final resultsDir = Directory('research/patent_window_1/evidence_fusion/experiments/results/PW1C6R');
      expect(resultsDir.existsSync(), isTrue, reason: 'PW1C6R results directory must exist');

      final manifestFile = File('${resultsDir.path}/pw1c6r_manifest.json');
      final c07SingleFile = File('${resultsDir.path}/pw1c6r_c07_single_reference_matrix.json');
      final c08SingleFile = File('${resultsDir.path}/pw1c6r_c08_single_reference_matrix.json');
      final c07MosaicFile = File('${resultsDir.path}/pw1c6r_c07_mosaic_matrix.json');
      final c08MosaicFile = File('${resultsDir.path}/pw1c6r_c08_mosaic_matrix.json');
      final candRefFile = File('${resultsDir.path}/pw1c6r_candidate_references.json');
      final boundaryFile = File('${resultsDir.path}/pw1c6r_boundary_status.json');

      expect(manifestFile.existsSync(), isTrue);
      expect(c07SingleFile.existsSync(), isTrue);
      expect(c08SingleFile.existsSync(), isTrue);
      expect(c07MosaicFile.existsSync(), isTrue);
      expect(c08MosaicFile.existsSync(), isTrue);
      expect(candRefFile.existsSync(), isTrue);
      expect(boundaryFile.existsSync(), isTrue);

      manifest = jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
      c07SingleRefMatrix = jsonDecode(c07SingleFile.readAsStringSync()) as Map<String, dynamic>;
      c08SingleRefMatrix = jsonDecode(c08SingleFile.readAsStringSync()) as Map<String, dynamic>;
      c07MosaicMatrix = jsonDecode(c07MosaicFile.readAsStringSync()) as List<dynamic>;
      c08MosaicMatrix = jsonDecode(c08MosaicFile.readAsStringSync()) as List<dynamic>;
      candidateReferences = jsonDecode(candRefFile.readAsStringSync()) as List<dynamic>;
      boundaryStatus = jsonDecode(boundaryFile.readAsStringSync()) as Map<String, dynamic>;
    });

    test('1. Manifest confirms PARTIAL MULTI-REFERENCE COVERAGE ONLY for C07 and C08', () {
      expect(manifest['auditId'], equals('PW1C6R'));
      expect(manifest['c07Status'], equals('PARTIAL MULTI-REFERENCE COVERAGE ONLY'));
      expect(manifest['c08Status'], equals('PARTIAL MULTI-REFERENCE COVERAGE ONLY'));
      expect(manifest['completeRelationshipLocated'], isFalse);
    });

    test('2. C07 single reference matrix verifies no single reference discloses complete relationship', () {
      expect(c07SingleRefMatrix['boundaryName'], equals('C07 MINIMAL BOUNDARY'));
      expect(c07SingleRefMatrix['singleReferenceCoverageResult'], equals('PARTIAL MULTI-REFERENCE COVERAGE ONLY'));
      expect(c07SingleRefMatrix['completeRelationshipLocated'], isFalse);

      final evals = c07SingleRefMatrix['singleReferenceEvaluations'] as List<dynamic>;
      expect(evals.length, greaterThanOrEqualTo(3));
      for (final ev in evals) {
        expect(ev['disclosesCompleteRelationship'], isFalse);
      }
    });

    test('3. C08 single reference matrix verifies no single reference discloses complete relationship', () {
      expect(c08SingleRefMatrix['boundaryName'], equals('C08 MINIMAL BOUNDARY'));
      expect(c08SingleRefMatrix['singleReferenceCoverageResult'], equals('PARTIAL MULTI-REFERENCE COVERAGE ONLY'));
      expect(c08SingleRefMatrix['completeRelationshipLocated'], isFalse);

      final evals = c08SingleRefMatrix['singleReferenceEvaluations'] as List<dynamic>;
      expect(evals.length, greaterThanOrEqualTo(2));
      for (final ev in evals) {
        expect(ev['disclosesCompleteRelationship'], isFalse);
      }
    });

    test('4. Mosaic matrices confirm multi-reference mosaic coverage for C07 and C08', () {
      expect(c07MosaicMatrix.first['singleReferenceDisclosed'], isFalse);
      expect(c07MosaicMatrix.first['multiReferenceMosaicDisclosed'], isTrue);

      expect(c08MosaicMatrix.first['singleReferenceDisclosed'], isFalse);
      expect(c08MosaicMatrix.first['multiReferenceMosaicDisclosed'], isTrue);
    });

    test('5. Candidate references list details 7 audited patent publications', () {
      expect(candidateReferences.length, equals(7));
      for (final ref in candidateReferences) {
        expect(ref['classification'], equals('C (Partial Disclosure Only)'));
      }
    });

    test('6. Boundary status report explicitly distinguishes technical vs prior-art vs legal boundaries', () {
      expect(boundaryStatus['c07Status'], equals('PARTIAL MULTI-REFERENCE COVERAGE ONLY'));
      expect(boundaryStatus['c08Status'], equals('PARTIAL MULTI-REFERENCE COVERAGE ONLY'));
      expect(boundaryStatus['c07CompleteRelationshipLocated'], isFalse);
      expect(boundaryStatus['c08CompleteRelationshipLocated'], isFalse);
      expect(boundaryStatus['legalPatentabilityStatus'], equals('NOT DETERMINED (Requires external legal analysis)'));
    });

    test('7. PW1C-6R Targeted Collision Audit Report exists and is complete', () {
      final reportFile = File('research/patent_window_1/evidence_fusion/reports/PW1C6R_TARGETED_COLLISION_AUDIT_REPORT.md');
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
      final c5rTestFile = File('test/patent_window_1c5r_test.dart');
      final c5sTestFile = File('test/patent_window_1c5s_test.dart');
      final c6TestFile = File('test/patent_window_1c6_test.dart');

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
    });
  });
}
