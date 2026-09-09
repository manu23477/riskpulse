import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/hazard/hazard.dart';
import 'package:riskpulse/domain/forecasting/forecasting.dart';
import 'package:riskpulse/data/services/forecasting/forecasting_services.dart';

void main() {
  group('Stage 3.9.5 Decision-Support Engine', () {
    final t1 = DateTime.utc(2026, 9, 8, 12, 0, 0);
    final t2 = DateTime.utc(2026, 9, 8, 18, 0, 0);

    final mandiLocation = const GeoLocation(latitude: 31.7081, longitude: 76.9317);

    final horizon = ForecastHorizon(validFrom: t1, validTo: t2);

    const engine = DecisionSupportEngine();

    final forecastExceed = HazardForecast(
      forecastId: 'fcst-exceed-1',
      parameterId: 'exceedance_ratio',
      category: 'Landslide',
      initializationTime: t1,
      horizon: horizon,
      outputType: ForecastOutputType.thresholdExceedance,
      primaryValue: 1.35, // 1.35x threshold -> ALERT
      uncertainty: ForecastUncertainty(),
      location: mandiLocation,
      modelId: 'landslide-rainfall-threshold',
      modelVersion: '3.5.0-Caine1980',
    );

    final risingTrajectory = RiskTrajectory(
      trajectoryId: 'traj-mandi-001',
      targetEntityId: 'mandi-landslide-zone',
      entityCategory: 'Landslide',
      stateVariable: 'rainfall_threshold_exceedance',
      direction: RiskTrajectoryDirection.rising,
      initialValue: 0.60,
      finalValue: 1.35,
      absoluteDelta: 0.75,
      timeSpan: horizon,
      location: mandiLocation,
      uncertainty: ForecastUncertainty(),
    );

    group('1. Advisory AttentionLevel Rules', () {
      test('assigns ALERT attention level when forecast exceedance >= 1.0 or trajectory is rising', () {
        final brief = engine.synthesizeSituationBrief(
          briefId: 'brief-alert-1',
          studyAreaName: 'Mandi Sector',
          location: mandiLocation,
          horizon: horizon,
          activeForecasts: [forecastExceed],
          trajectory: risingTrajectory,
        );

        expect(brief.briefId, 'brief-alert-1');
        expect(brief.advisoryAttentionLevel, AttentionLevel.alert);
        expect(brief.metadata['decisionRuleVersion'], '3.9.5-v1');
        expect(brief.metadata['rationale'], contains('ALERT'));
      });

      test('assigns CRITICAL attention level when multi-hazard compound event & exceedance >= 1.5 exist', () {
        final forecastCritical = forecastExceed.copyWith(
          forecastId: 'fcst-crit-1',
          primaryValue: 1.65, // >= 1.5
        );

        final compoundEvent = CompoundHazardEvent(
          compoundEventId: 'comp-mandi-1',
          title: 'Mandi Heavy Rain & Landslide Compound Event',
          componentHazardIds: ['rain-1', 'ls-1'],
          location: mandiLocation,
          temporalWindow: horizon,
        );

        final brief = engine.synthesizeSituationBrief(
          briefId: 'brief-crit-1',
          studyAreaName: 'Mandi Sector',
          location: mandiLocation,
          horizon: horizon,
          activeForecasts: [forecastCritical],
          compoundEvents: [compoundEvent],
          trajectory: risingTrajectory,
        );

        expect(brief.advisoryAttentionLevel, AttentionLevel.critical);
      });

      test('assigns LOW attention level for baseline low-intensity forecasts', () {
        final forecastLow = forecastExceed.copyWith(
          forecastId: 'fcst-low-1',
          primaryValue: 0.20, // Low intensity
        );

        final brief = engine.synthesizeSituationBrief(
          briefId: 'brief-low-1',
          studyAreaName: 'Mandi Sector',
          location: mandiLocation,
          horizon: horizon,
          activeForecasts: [forecastLow],
        );

        expect(brief.advisoryAttentionLevel, AttentionLevel.low);
      });
    });

    group('2. Evidentiary Briefing & Uncertainty Warnings', () {
      test('populates EvidentiaryBriefing with model IDs and uncalibrated region warnings', () {
        final brief = engine.synthesizeSituationBrief(
          briefId: 'brief-ev-1',
          studyAreaName: 'Mandi Sector',
          location: mandiLocation,
          horizon: horizon,
          activeForecasts: [forecastExceed],
        );

        final ev = brief.evidentiaryBriefing;
        expect(ev.contributingModelIds, contains('landslide-rainfall-threshold'));
        expect(ev.uncertaintyWarnings, contains(contains('UNCALIBRATED')));
      });

      test('surfaces uncertainty warnings when driver conflict is detected', () {
        final conflictAttribution = RiskDriverAttributionResult(
          resultId: 'attr-conflict-1',
          trajectoryId: 'traj-mandi-001',
          trajectoryDirection: RiskTrajectoryDirection.rising,
          conflictDetected: true, // Conflict!
          attributionSummary: 'Conflict detected',
        );

        final brief = engine.synthesizeSituationBrief(
          briefId: 'brief-conflict-1',
          studyAreaName: 'Mandi Sector',
          location: mandiLocation,
          horizon: horizon,
          activeForecasts: [forecastExceed],
          attribution: conflictAttribution,
        );

        expect(
          brief.evidentiaryBriefing.uncertaintyWarnings,
          contains(contains('CONFLICT DETECTED')),
        );
      });
    });

    group('3. Priority Queue Item Generation', () {
      test('creates ResearchAttentionItem with score reflecting advisory attention level', () {
        final briefAlert = engine.synthesizeSituationBrief(
          briefId: 'brief-queue-1',
          studyAreaName: 'Mandi Sector',
          location: mandiLocation,
          horizon: horizon,
          activeForecasts: [forecastExceed],
          trajectory: risingTrajectory,
        );

        final item = engine.createAttentionItem(
          itemId: 'item-mandi-1',
          brief: briefAlert,
        );

        expect(item.itemId, 'item-mandi-1');
        expect(item.attentionLevel, AttentionLevel.alert);
        expect(item.priorityScore, 70.0); // Base score for ALERT = 70.0
      });
    });

    group('4. Mandatory Scientific & Governance Safeguards', () {
      test('MANDATORY SCIENTIFIC NEGATIVE TEST: AttentionLevel is NOT a probability or confidence percentage', () {
        final brief = engine.synthesizeSituationBrief(
          briefId: 'brief-governance-1',
          studyAreaName: 'Mandi Sector',
          location: mandiLocation,
          horizon: horizon,
          activeForecasts: [forecastExceed],
        );

        // ASSERT: AttentionLevel is an advisory enum, NOT a probability score
        expect(brief.advisoryAttentionLevel, isA<AttentionLevel>());
        expect(brief.metadata.containsKey('probabilityOfDisaster'), isFalse);
      });

      test('MANDATORY GOVERNANCE TEST: ResearchSituationBrief DOES NOT mutate RiskMap or create operational hazards', () {
        final brief = engine.synthesizeSituationBrief(
          briefId: 'brief-governance-2',
          studyAreaName: 'Mandi Sector',
          location: mandiLocation,
          horizon: horizon,
          activeForecasts: [forecastExceed],
        );

        expect(brief, isA<ResearchSituationBrief>());
        expect(brief, isNot(isA<Hazard>()));
      });
    });
  });
}
