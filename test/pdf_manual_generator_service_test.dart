import 'dart:io' as io;
import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/data/services/pdf_manual_generator_service.dart';

void main() {
  group('Phase R.3-R3-R4 Real PDF Document Generator & QA Tests', () {
    final service = PdfManualGeneratorService();

    test('compiles 30-section User Manual markdown content', () {
      final markdown = service.compileUserManualMarkdown();

      expect(markdown, contains('# RISKPULSE — USER MANUAL'));
      expect(markdown, contains('TABLE OF CONTENTS'));
      expect(markdown, contains('getting_started'));
      expect(topicContains(markdown, 'environmental_health'), isTrue);
    });

    test('compiles 25-workflow Feature Workflow Atlas markdown content', () {
      final atlas = service.compileFeatureWorkflowAtlasMarkdown();

      expect(atlas, contains('# RISKPULSE — FEATURE WORKFLOW ATLAS'));
      expect(atlas, contains('WORKFLOW 1: OPERATIONAL RISKMAP NAVIGATION'));
      expect(atlas, contains('WORKFLOW 6: ENVIRONMENTAL HEALTH'));
      expect(atlas, contains('does NOT establish causation'));
    });

    test('exports Markdown and genuine binary PDF documentation files to target directory', () {
      final createdFiles = service.exportDocumentationFiles('artifacts/docs');

      expect(createdFiles.length, equals(4));

      final manualMd = io.File('artifacts/docs/RiskPulse_User_Manual.md');
      final atlasMd = io.File('artifacts/docs/RiskPulse_Feature_Workflow_Atlas.md');
      final manualPdf = io.File('artifacts/docs/RiskPulse_User_Manual.pdf');
      final atlasPdf = io.File('artifacts/docs/RiskPulse_Feature_Workflow_Atlas.pdf');

      expect(manualMd.existsSync(), isTrue);
      expect(atlasMd.existsSync(), isTrue);
      expect(manualPdf.existsSync(), isTrue);
      expect(atlasPdf.existsSync(), isTrue);

      // Verify PDF header magic bytes (%PDF-1.4)
      final pdfBytes = manualPdf.readAsBytesSync();
      expect(pdfBytes.length, greaterThan(1000));
      final headerStr = String.fromCharCodes(pdfBytes.sublist(0, 8));
      expect(headerStr, contains('%PDF-1.4'));
    });
  });
}

bool topicContains(String text, String topicId) => text.contains(topicId);
