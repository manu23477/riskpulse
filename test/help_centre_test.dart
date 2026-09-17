import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/domain/help_centre/help_topic.dart';
import 'package:riskpulse/data/services/help_centre_service.dart';
import 'package:riskpulse/screens/help_centre/help_centre_screen.dart';
import 'package:riskpulse/screens/help_centre/help_topic_detail_dialog.dart';

void main() {
  group('Phase R.1 Help Centre & User Manual Architecture', () {
    final service = HelpCentreService();

    group('1. HelpCentreService Data & Search Tests', () {
      test('retrieves all 14 structured help topics', () {
        final topics = service.getAllTopics();
        expect(topics.length, equals(14));
      });

      test('filters topics by category', () {
        final hydroTopics = service.getTopicsByCategory(HelpCategory.hydroAiAndHecRas);
        expect(hydroTopics.length, equals(1));
        expect(hydroTopics.first.topicId, equals('hydroai_hecras'));

        final ehTopics = service.getTopicsByCategory(HelpCategory.environmentalHealth);
        expect(ehTopics.length, equals(1));
        expect(ehTopics.first.topicId, equals('environmental_health'));
      });

      test('searches topics by query string', () {
        final results = service.searchTopics('Pearson');
        expect(results.isNotEmpty, isTrue);
        expect(results.first.topicId, equals('environmental_health'));

        final csiResults = service.searchTopics('Critical Success Index');
        expect(csiResults.isNotEmpty, isTrue);
        expect(csiResults.first.topicId, equals('sar_inundation_validation'));
      });

      test('retrieves topic by ID', () {
        final topic = service.getTopicById('dem_acquisition');
        expect(topic, isNotNull);
        expect(topic!.title, contains('DEM Acquisition'));
      });
    });

    group('2. HelpCentre UI Widget Tests', () {
      testWidgets('renders HelpCentreScreen with search bar, category chips, and topic list', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: HelpCentreScreen(),
          ),
        );

        expect(find.text('RiskPulse Help Centre & User Manual'), findsOneWidget);
        expect(find.text('Search user manual, workflows, tools, or terminology...'), findsOneWidget);
        expect(find.text('All Topics'), findsOneWidget);
        expect(find.text('HydroAI & HEC-RAS'), findsOneWidget);
      });

      testWidgets('renders HelpTopicDetailDialog with sections, workflow, and limitations', (WidgetTester tester) async {
        final topic = service.getTopicById('environmental_health')!;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HelpTopicDetailDialog(topic: topic),
            ),
          ),
        );

        expect(find.text('Environmental Health & Disease Spatial Intelligence'), findsOneWidget);
        expect(find.text('IMPLEMENTED & SOFTWARE-VERIFIED'), findsOneWidget);
        expect(find.text('Step-by-Step Workflow'), findsOneWidget);
        expect(find.text('Scientific & Application Limitations'), findsOneWidget);
      });
    });

    group('3. Mandatory Scientific Governance & Language Safeguards', () {
      test('MANDATORY GOVERNANCE TEST: Environmental Health topic preserves non-causality principle', () {
        final topic = service.getTopicById('environmental_health')!;

        final sec = topic.sections.lastWhere((s) => s.title.contains('Non-Causality'));
        expect(sec.content, contains('does NOT establish causation'));
      });

      test('MANDATORY GOVERNANCE TEST: SAR Validation topic preserves CSI evaluation metric distinction', () {
        final topic = service.getTopicById('sar_inundation_validation')!;

        final sec = topic.sections.firstWhere((s) => s.title.contains('Critical Success Index'));
        expect(sec.content, contains('CSI is an evaluation metric and NOT automatic scientific validation'));
      });
    });
  });
}
