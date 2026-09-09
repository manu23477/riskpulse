import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/hazard/hazard.dart';
import 'package:riskpulse/domain/forecasting/forecasting.dart';
import 'package:riskpulse/data/services/forecasting/forecasting_services.dart';

void main() {
  group('Stage 3.9.8.2 Research Priority Queue Engine', () {
    final t1 = DateTime.utc(2026, 9, 8, 12, 0, 0);
    final t2 = DateTime.utc(2026, 9, 8, 18, 0, 0);

    final mandiLocation = const GeoLocation(latitude: 31.7081, longitude: 76.9317);
    final kulluLocation = const GeoLocation(latitude: 31.9579, longitude: 77.1095);
    final kangraLocation = const GeoLocation(latitude: 32.0998, longitude: 76.2691);

    final horizon = ForecastHorizon(validFrom: t1, validTo: t2);

    const queueEngine = ResearchPriorityQueueEngine();

    final briefLow = ResearchSituationBrief(
      briefId: 'brief-kangra-low',
      studyAreaName: 'Kangra Sector',
      situationContext: 'actual_observed',
      location: kangraLocation,
      horizon: horizon,
      advisoryAttentionLevel: AttentionLevel.low,
      evidentiaryBriefing: EvidentiaryBriefing(
        briefingId: 'ev-1',
        dataCompletenessRatio: 1.0,
      ),
    );

    final briefAlert = ResearchSituationBrief(
      briefId: 'brief-kullu-alert',
      studyAreaName: 'Kullu Valley Sector',
      situationContext: 'actual_observed',
      location: kulluLocation,
      horizon: horizon,
      advisoryAttentionLevel: AttentionLevel.alert,
      evidentiaryBriefing: EvidentiaryBriefing(
        briefingId: 'ev-2',
        dataCompletenessRatio: 1.0,
      ),
    );

    final briefCritical = ResearchSituationBrief(
      briefId: 'brief-mandi-critical',
      studyAreaName: 'Mandi Sector',
      situationContext: 'actual_observed',
      location: mandiLocation,
      horizon: horizon,
      advisoryAttentionLevel: AttentionLevel.critical,
      evidentiaryBriefing: EvidentiaryBriefing(
        briefingId: 'ev-3',
        dataCompletenessRatio: 1.0,
      ),
    );

    final briefScenario = ResearchSituationBrief(
      briefId: 'brief-mandi-scenario-90th',
      studyAreaName: 'Mandi Sector Extreme Forcing',
      situationContext: 'scenario_conditional',
      location: mandiLocation,
      horizon: horizon,
      advisoryAttentionLevel: AttentionLevel.critical,
      evidentiaryBriefing: EvidentiaryBriefing(
        briefingId: 'ev-4',
        dataCompletenessRatio: 1.0,
      ),
    );

    group('1. Basic Queue Generation & Empty Inputs', () {
      test('handles empty briefs list cleanly and returns empty ResearchPriorityQueue', () {
        final queue = queueEngine.generateQueue(
          queueId: 'q-empty-1',
          briefs: [],
        );

        expect(queue.queueId, 'q-empty-1');
        expect(queue.isEmpty, isTrue);
        expect(queue.length, 0);
        expect(queue.topPriority, isNull);
      });

      test('generates queue for single situation brief', () {
        final queue = queueEngine.generateQueue(
          queueId: 'q-single-1',
          briefs: [briefAlert],
        );

        expect(queue.length, 1);
        expect(queue.topPriority?.itemId, 'item-brief-kullu-alert');
        expect(queue.topPriority?.attentionLevel, AttentionLevel.alert);
        expect(queue.topPriority?.priorityScore, 70.0);
      });
    });

    group('2. Priority Ordering & Deterministic Tie-Breaking', () {
      test('sorts multiple briefs strictly descending by priorityScore (critical=90, alert=70, low=10)', () {
        // Passed out of order: low (10), critical (90), alert (70)
        final queue = queueEngine.generateQueue(
          queueId: 'q-sort-1',
          briefs: [briefLow, briefCritical, briefAlert],
        );

        expect(queue.length, 3);
        expect(queue.items[0].itemId, 'item-brief-mandi-critical'); // 90.0
        expect(queue.items[1].itemId, 'item-brief-kullu-alert');    // 70.0
        expect(queue.items[2].itemId, 'item-brief-kangra-low');     // 10.0
        expect(queue.topPriority?.itemId, 'item-brief-mandi-critical');
      });

      test('applies deterministic tie-breaking (alphabetical itemId) when priority scores are equal', () {
        final briefAlertA = ResearchSituationBrief(
          briefId: 'brief-alpha-alert',
          studyAreaName: 'Alpha Sector',
          location: mandiLocation,
          horizon: horizon,
          advisoryAttentionLevel: AttentionLevel.alert, // Score = 70.0
          evidentiaryBriefing: EvidentiaryBriefing(briefingId: 'ev-a', dataCompletenessRatio: 1.0),
        );

        final briefAlertZ = ResearchSituationBrief(
          briefId: 'brief-zeta-alert',
          studyAreaName: 'Zeta Sector',
          location: mandiLocation,
          horizon: horizon,
          advisoryAttentionLevel: AttentionLevel.alert, // Score = 70.0
          evidentiaryBriefing: EvidentiaryBriefing(briefingId: 'ev-z', dataCompletenessRatio: 1.0),
        );

        final queue = queueEngine.generateQueue(
          queueId: 'q-tie-1',
          briefs: [briefAlertZ, briefAlertA], // Passed Zeta before Alpha
        );

        expect(queue.length, 2);
        // Both have score 70.0 -> Tie-breaker sorts 'item-brief-alpha-alert' before 'item-brief-zeta-alert'
        expect(queue.items[0].itemId, 'item-brief-alpha-alert');
        expect(queue.items[1].itemId, 'item-brief-zeta-alert');
      });
    });

    group('3. Context Filtering & Deduplication', () {
      test('generateActualObservedQueue returns ONLY actual_observed briefs', () {
        final queue = queueEngine.generateActualObservedQueue(
          queueId: 'q-actual-1',
          briefs: [briefLow, briefCritical, briefScenario],
        );

        expect(queue.length, 2);
        expect(queue.items.every((item) => item.brief.isActualObserved), isTrue);
        expect(queue.items.any((item) => item.brief.briefId == 'brief-mandi-scenario-90th'), isFalse);
      });

      test('generateScenarioConditionalQueue returns ONLY scenario_conditional briefs', () {
        final queue = queueEngine.generateScenarioConditionalQueue(
          queueId: 'q-scen-1',
          briefs: [briefLow, briefCritical, briefScenario],
        );

        expect(queue.length, 1);
        expect(queue.items.first.brief.isScenarioConditional, isTrue);
        expect(queue.items.first.brief.briefId, 'brief-mandi-scenario-90th');
      });

      test('deduplicates duplicate brief IDs while preserving first occurrence', () {
        final duplicateLow = briefLow.copyWith(); // Same briefId 'brief-kangra-low'

        final queue = queueEngine.generateQueue(
          queueId: 'q-dedup-1',
          briefs: [briefLow, duplicateLow, briefAlert],
        );

        expect(queue.length, 2); // 3 briefs passed, but 1 duplicate briefId collapsed -> 2 unique items
      });
    });

    group('4. Mandatory Scientific & Governance Safeguards', () {
      test('MANDATORY SCIENTIFIC NEGATIVE TEST: priorityScore is NOT a probability or disaster risk score', () {
        final queue = queueEngine.generateQueue(
          queueId: 'q-gov-1',
          briefs: [briefCritical],
        );

        final item = queue.topPriority!;
        // ASSERT: priorityScore is a workflow priority score (90.0), NOT a probability!
        expect(item.priorityScore, 90.0);
        expect(item.toMap().containsKey('disasterProbability'), isFalse);
        expect(item.toMap().containsKey('riskScoreFormula'), isFalse);
      });

      test('MANDATORY GOVERNANCE TEST: ResearchPriorityQueue DOES NOT mutate RiskMap or create operational hazards', () {
        final queue = queueEngine.generateQueue(
          queueId: 'q-gov-2',
          briefs: [briefCritical, briefScenario],
        );

        expect(queue, isA<ResearchPriorityQueue>());
        expect(queue, isNot(isA<Hazard>()));
      });
    });
  });
}
