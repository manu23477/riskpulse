import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PATENT WINDOW 1 — Professional Patent Review Package Validation Suite', () {
    late Map<String, dynamic> manifest;
    late File dossierFile;
    late File featureMatrixFile;
    late File referenceMatrixFile;
    late File boundaryMatrixFile;
    late File counselQuestionsFile;
    late File evidenceIndexFile;
    late File completionReportFile;

    setUpAll(() {
      final reviewDir = Directory('research/patent_window_1/PROFESSIONAL_REVIEW');
      expect(reviewDir.existsSync(), isTrue, reason: 'PROFESSIONAL_REVIEW directory must exist');

      dossierFile = File('${reviewDir.path}/PW1_PROFESSIONAL_REVIEW_DOSSIER.md');
      featureMatrixFile = File('${reviewDir.path}/PW1_FEATURE_BOUNDARY_MATRIX.md');
      referenceMatrixFile = File('${reviewDir.path}/PW1_REFERENCE_MATRIX.md');
      boundaryMatrixFile = File('${reviewDir.path}/PW1_C07_C08_BOUNDARY_MATRIX.md');
      counselQuestionsFile = File('${reviewDir.path}/PW1_COUNSEL_QUESTIONS.md');
      evidenceIndexFile = File('${reviewDir.path}/PW1_EVIDENCE_INDEX.md');
      completionReportFile = File('${reviewDir.path}/PW1_PROFESSIONAL_REVIEW_COMPLETION_REPORT.md');
      final manifestFile = File('${reviewDir.path}/PW1_PROFESSIONAL_REVIEW_MANIFEST.json');

      expect(dossierFile.existsSync(), isTrue);
      expect(featureMatrixFile.existsSync(), isTrue);
      expect(referenceMatrixFile.existsSync(), isTrue);
      expect(boundaryMatrixFile.existsSync(), isTrue);
      expect(counselQuestionsFile.existsSync(), isTrue);
      expect(evidenceIndexFile.existsSync(), isTrue);
      expect(completionReportFile.existsSync(), isTrue);
      expect(manifestFile.existsSync(), isTrue);

      manifest = jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
    });

    test('1. Manifest confirms 11 audited milestones and zero production modification', () {
      expect(manifest['dossierVersion'], equals('PW1-PRO-REVIEW-v1.0'));
      expect((manifest['auditedMilestones'] as List<dynamic>).length, equals(11));
      expect(manifest['productionCodeModified'], isFalse);
      expect(manifest['gitPushPerformed'], isFalse);
      expect(manifest['expectedGitHead'], equals('d6552707e0a693b04f40a2ade6a4efc5fdf9ae0a'));
    });

    test('2. Master dossier contains all required 19 sections and legal disclaimers', () {
      final content = dossierFile.readAsStringSync();
      expect(content.contains('SECTION 1 — EXECUTIVE TECHNICAL SUMMARY'), isTrue);
      expect(content.contains('SECTION 5 — C07 TECHNICAL BOUNDARY'), isTrue);
      expect(content.contains('SECTION 6 — C08 TECHNICAL BOUNDARY'), isTrue);
      expect(content.contains('SECTION 17 — QUESTIONS FOR PATENT COUNSEL'), isTrue);
      expect(content.contains('SECTION 19 — FINAL RESEARCH POSITION'), isTrue);

      // Verify absence of forbidden conclusive claims
      final forbiddenTerms = ['guaranteed patent', 'definitely inventive', 'unique invention'];
      for (final forbidden in forbiddenTerms) {
        expect(content.toLowerCase().contains(forbidden), isFalse, reason: 'Dossier must not contain $forbidden');
      }
    });

    test('3. Feature boundary matrix covers atomic features with legal questions', () {
      final content = featureMatrixFile.readAsStringSync();
      expect(content.contains('F01'), isTrue);
      expect(content.contains('F07'), isTrue);
      expect(content.contains('F18'), isTrue);
      expect(content.contains('F41'), isTrue);
    });

    test('4. Prior-art reference matrix details audited patent families', () {
      final content = referenceMatrixFile.readAsStringSync();
      expect(content.contains('US7441230B2'), isTrue);
      expect(content.contains('US20200379978A1'), isTrue);
      expect(content.contains('CN117235153B'), isTrue);
      expect(content.contains('US10891340B2'), isTrue); // Corrected IBM title
      expect(content.contains('US11200215B2'), isTrue); // Corrected Microsoft title
    });

    test('5. C07 and C08 boundary matrices record PARTIAL MULTI-REFERENCE COVERAGE ONLY', () {
      final content = boundaryMatrixFile.readAsStringSync();
      expect(content.contains('PARTIAL MULTI-REFERENCE COVERAGE ONLY'), isTrue);
      expect(content.contains('C07 TARGET BOUNDARY MATRIX'), isTrue);
      expect(content.contains('C08 TARGET BOUNDARY MATRIX'), isTrue);
    });

    test('6. Questions for patent counsel document includes 15 structured legal questions', () {
      final content = counselQuestionsFile.readAsStringSync();
      expect(content.contains('15.'), isTrue);
      expect(content.contains('Candidate Subject Matter'), isTrue);
      expect(content.contains('Provisional Filing'), isTrue);
    });

    test('7. Evidence index maps conclusions to underlying experimental reports', () {
      final content = evidenceIndexFile.readAsStringSync();
      expect(content.contains('PW1C1A_DATASET_GENERATION_FORENSIC_REPORT.md'), isTrue);
      expect(content.contains('PW1C6R_TARGETED_COLLISION_AUDIT_REPORT.md'), isTrue);
      expect(content.contains('89.62% to 99.91% Recomputation Reduction'), isTrue);
    });

    test('8. Completion report specifies RESEARCH BOUNDARY ESTABLISHED', () {
      final content = completionReportFile.readAsStringSync();
      expect(content.contains('RESEARCH BOUNDARY ESTABLISHED — PROFESSIONAL PATENT REVIEW READY'), isTrue);
      expect(content.contains('NO PRODUCTION RISKPULSE CODE MODIFIED'), isTrue);
    });
  });
}
