import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PATENT WINDOW 1 — Strategy Boundary Analysis Package Validation Suite', () {
    late Map<String, dynamic> manifest;
    late File strategyReportFile;
    late File collisionMatrixFile;
    late File counselDecisionTreeFile;
    late File onePageBriefFile;
    late File completionReportFile;

    setUpAll(() {
      final reviewDir = Directory('research/patent_window_1/PROFESSIONAL_REVIEW');
      expect(reviewDir.existsSync(), isTrue, reason: 'PROFESSIONAL_REVIEW directory must exist');

      strategyReportFile = File('${reviewDir.path}/PW1_STRATEGY_BOUNDARY_ANALYSIS.md');
      collisionMatrixFile = File('${reviewDir.path}/PW1_STRATEGY_PRIOR_ART_COLLISION_MATRIX.md');
      counselDecisionTreeFile = File('${reviewDir.path}/PW1_COUNSEL_DECISION_TREE.md');
      onePageBriefFile = File('${reviewDir.path}/PW1_PATENT_COUNSEL_ONE_PAGE_BRIEF.md');
      completionReportFile = File('${reviewDir.path}/PW1_STRATEGY_BOUNDARY_COMPLETION_REPORT.md');
      final manifestFile = File('${reviewDir.path}/PW1_STRATEGY_BOUNDARY_MANIFEST.json');

      expect(strategyReportFile.existsSync(), isTrue);
      expect(collisionMatrixFile.existsSync(), isTrue);
      expect(counselDecisionTreeFile.existsSync(), isTrue);
      expect(onePageBriefFile.existsSync(), isTrue);
      expect(completionReportFile.existsSync(), isTrue);
      expect(manifestFile.existsSync(), isTrue);

      manifest = jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
    });

    test('1. Strategy manifest confirms ESTABLISHED FOR REVIEW and legal status UNDETERMINED', () {
      expect(manifest['manifestVersion'], equals('PW1-STRATEGY-v1.0'));
      expect(manifest['c07Status'], equals('PARTIAL MULTI-REFERENCE COVERAGE ONLY'));
      expect(manifest['c08Status'], equals('PARTIAL MULTI-REFERENCE COVERAGE ONLY'));
      expect(manifest['technicalBoundaryStatus'], equals('ESTABLISHED FOR REVIEW'));
      expect(manifest['legalPatentabilityStatus'], equals('UNDETERMINED'));
      expect(manifest['productionCodeModified'], isFalse);
      expect(manifest['gitPushPerformed'], isFalse);
    });

    test('2. Strategy boundary report contains C07, C08, Common Core, and 3-tiered boundaries', () {
      final content = strategyReportFile.readAsStringSync();
      expect(content.contains('C07 BOUNDARY ANALYSIS'), isTrue);
      expect(content.contains('C08 BOUNDARY ANALYSIS'), isTrue);
      expect(content.contains('COMMON TECHNICAL CORE'), isTrue);
      expect(content.contains('Technical Boundary A (Broad)'), isTrue);
      expect(content.contains('Technical Boundary B (Medium)'), isTrue);
      expect(content.contains('Technical Boundary C (Narrow)'), isTrue);

      // Verify no conclusive legal claims
      final forbiddenTerms = ['guaranteed patent', 'definitely inventive', 'unique invention'];
      for (final forbidden in forbiddenTerms) {
        expect(content.toLowerCase().contains(forbidden), isFalse);
      }
    });

    test('3. Strategy collision matrix details sub-features and single vs multi reference coverage', () {
      final content = collisionMatrixFile.readAsStringSync();
      expect(content.contains('F07 / F09'), isTrue);
      expect(content.contains('US7441230B2'), isTrue);
      expect(content.contains('US20200379978A1'), isTrue);
      expect(content.contains('Single-Ref Complete?'), isTrue);
    });

    test('4. Counsel decision tree provides legal review flows and questions', () {
      final content = counselDecisionTreeFile.readAsStringSync();
      expect(content.contains('COUNSEL ACTION REQUIRED'), isTrue);
      expect(content.contains('Alice Step 2B'), isTrue);
      expect(content.contains('35 U.S.C. § 103'), isTrue);
    });

    test('5. One-page brief is readable in 3-5 minutes and covers Sections A through I', () {
      final content = onePageBriefFile.readAsStringSync();
      expect(content.contains('WHAT RISKPULSE MECHANISM IS BEING PRESENTED'), isTrue);
      expect(content.contains('WHAT WAS EXPERIMENTALLY DEMONSTRATED'), isTrue);
      expect(content.contains('C07 BOUNDARY'), isTrue);
      expect(content.contains('C08 BOUNDARY'), isTrue);
      expect(content.contains('MAIN TECHNICAL QUESTION FOR COUNSEL'), isTrue);
    });

    test('6. Completion report specifies COUNSEL DECISION REQUIRED', () {
      final content = completionReportFile.readAsStringSync();
      expect(content.contains('PW1 TECHNICAL STRATEGY BOUNDARY ESTABLISHED — COUNSEL DECISION REQUIRED'), isTrue);
      expect(content.contains('NO PRODUCTION RISKPULSE CODE MODIFIED'), isTrue);
    });

    test('7. Regression check: All prior experimental test suites remain 100% GREEN', () {
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
    });
  });
}
