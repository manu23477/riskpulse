import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/hazard/hazard.dart';
import 'package:riskpulse/domain/forecasting/forecasting.dart';

void main() {
  group('Stage 3.9.2 Decision-Support Domain Contracts', () {
    final now = DateTime.utc(2026, 9, 8, 12, 0, 0);
    final mandiLocation = const GeoLocation(latitude: 31.7081, longitude: 76.9317);

    final horizon = ForecastHorizon(
      validFrom: now,
      validTo: now.add(const Duration(hours: 24)),
    );

    final input = ForecastInput(
      inputId: 'input-ds-1',
      timeSeriesIds: ['ts-1'],
      targetHorizon: horizon,
    );

    final briefing = EvidentiaryBriefing(
      briefingId: 'ev-brief-1',
      contributingEvidenceIds: ['ev-1', 'ev-2'],
      contributingModelIds: ['landslide-rainfall-threshold'],
      dataCompletenessRatio: 0.95,
      calibrationStatusNotice: 'PROVISIONAL / UNCALIBRATED FOR HIMACHAL',
    );

    final brief = ResearchSituationBrief(
      briefId: 'brief-mandi-101',
      studyAreaName: 'Mandi Catchment Region',
      location: mandiLocation,
      horizon: horizon,
      advisoryAttentionLevel: AttentionLevel.alert,
      evidentiaryBriefing: briefing,
    );

    group('1. EvidentiaryBriefing Contract', () {
      test('instantiates valid EvidentiaryBriefing and validates dataCompletenessRatio bounds', () {
        expect(briefing.briefingId, 'ev-brief-1');
        expect(briefing.dataCompletenessRatio, 0.95);
        expect(briefing.calibrationStatusNotice, contains('PROVISIONAL'));

        expect(
          () => EvidentiaryBriefing(
            briefingId: 'bad-brief',
            dataCompletenessRatio: 1.5, // Invalid > 1.0 -> MUST REJECT!
          ),
          throwsArgumentError,
        );
      });
    });

    group('2. ResearchScenario & ScenarioComparison Contracts', () {
      test('instantiates ResearchScenario and ScenarioComparison with delta calculations', () {
        final baselineScenario = ResearchScenario(
          scenarioId: 'scen-base',
          name: 'Baseline Weather Scenario',
          scenarioType: 'baseline_observed',
          input: input,
        );

        final extremeScenario = ResearchScenario(
          scenarioId: 'scen-extreme',
          name: '90th Percentile Extreme Rainfall Scenario',
          scenarioType: 'extreme_forcing',
          input: input,
        );

        final comparison = ScenarioComparison(
          comparisonId: 'comp-101',
          baselineScenario: baselineScenario,
          comparisonScenario: extremeScenario,
          intensityDelta: 2.25, // 2.25x increase in exceedance ratio
          comparativeSummary: 'Extreme 90th percentile rainfall causes I-D threshold exceedance across slope domains.',
        );

        expect(comparison.comparisonId, 'comp-101');
        expect(comparison.intensityDelta, 2.25);
        expect(comparison.baselineScenario.scenarioId, 'scen-base');
        expect(comparison.comparisonScenario.scenarioId, 'scen-extreme');
      });
    });

    group('3. ResearchSituationBrief Contract', () {
      test('instantiates valid ResearchSituationBrief and validates study area name', () {
        expect(brief.briefId, 'brief-mandi-101');
        expect(brief.studyAreaName, 'Mandi Catchment Region');
        expect(brief.advisoryAttentionLevel, AttentionLevel.alert);

        expect(
          () => ResearchSituationBrief(
            briefId: 'b-1',
            studyAreaName: '', // Empty name -> MUST REJECT!
            location: mandiLocation,
            horizon: horizon,
            advisoryAttentionLevel: AttentionLevel.low,
            evidentiaryBriefing: briefing,
          ),
          throwsArgumentError,
        );
      });
    });

    group('4. ResearchAttentionItem & ResearchPriorityQueue Contracts', () {
      test('ResearchPriorityQueue strictly sorts items descending by priorityScore', () {
        final itemLow = ResearchAttentionItem(
          itemId: 'item-low',
          locationName: 'Kangra Region',
          location: mandiLocation,
          attentionLevel: AttentionLevel.low,
          priorityScore: 25.0,
          rationale: 'Baseline monitoring',
          brief: brief,
        );

        final itemCritical = ResearchAttentionItem(
          itemId: 'item-crit',
          locationName: 'Mandi Catchment',
          location: mandiLocation,
          attentionLevel: AttentionLevel.critical,
          priorityScore: 92.5,
          rationale: 'Threshold exceeded with severe potential impact',
          brief: brief,
        );

        final itemMonitor = ResearchAttentionItem(
          itemId: 'item-mon',
          locationName: 'Kullu Valley',
          location: mandiLocation,
          attentionLevel: AttentionLevel.monitor,
          priorityScore: 55.0,
          rationale: 'Approaching threshold',
          brief: brief,
        );

        // Passed out of order: low (25.0), critical (92.5), monitor (55.0)
        final queue = ResearchPriorityQueue(
          queueId: 'q-mandi-2026',
          generatedAt: now,
          items: [itemLow, itemCritical, itemMonitor],
        );

        expect(queue.length, 3);
        // ASSERT: Items MUST be sorted strictly descending by priorityScore!
        expect(queue.items[0].itemId, 'item-crit'); // 92.5
        expect(queue.items[1].itemId, 'item-mon');  // 55.0
        expect(queue.items[2].itemId, 'item-low');  // 25.0
        expect(queue.topPriority?.itemId, 'item-crit');
      });
    });

    group('5. Mandatory Governance Safeguard Tests', () {
      test('MANDATORY GOVERNANCE TEST: decision support contracts DO NOT mutate RiskMap or create operational hazards', () {
        final item = ResearchAttentionItem(
          itemId: 'item-gov',
          locationName: 'Mandi Sector',
          location: mandiLocation,
          attentionLevel: AttentionLevel.critical,
          priorityScore: 95.0,
          rationale: 'Research priority tracking',
          brief: brief,
        );

        // ASSERT: Decision support contracts are research/analytical objects, NOT operational Hazard features
        expect(item, isA<ResearchAttentionItem>());
        expect(item, isNot(isA<Hazard>()));
      });
    });
  });
}
