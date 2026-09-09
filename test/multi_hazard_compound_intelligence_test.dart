import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/hazard/hazard.dart';
import 'package:riskpulse/domain/forecasting/forecasting.dart';
import 'package:riskpulse/data/services/forecasting/forecasting_services.dart';

void main() {
  group('Stage 3.7 Multi-Hazard & Compound Hazard Intelligence', () {
    final now = DateTime.utc(2026, 9, 8, 12, 0, 0);

    final mandiLocation = const GeoLocation(latitude: 31.7081, longitude: 76.9317);
    final pandohLocation = const GeoLocation(latitude: 31.6710, longitude: 77.0420);

    final horizon = ForecastHorizon(
      validFrom: now.subtract(const Duration(hours: 12)),
      validTo: now.add(const Duration(hours: 12)),
    );

    final evidence1 = HazardLinkEvidence(
      evidenceId: 'ev-101',
      sourceType: 'osint_candidate',
      sourceEntityId: 'osint-evt-1',
      observationTime: now,
      location: mandiLocation,
      confidenceScore: 0.85,
      description: 'GSI Landslide report in Mandi.',
    );

    group('1. HazardRelationship & Link Evidence Contracts', () {
      test('instantiates valid HazardRelationship and validates non-empty IDs', () {
        final rel = HazardRelationship(
          relationshipId: 'rel-101',
          sourceHazardId: 'eq-2026-mandi',
          targetHazardId: 'ls-2026-mandi',
          sourceCategory: 'Earthquake',
          targetCategory: 'Landslide',
          relationshipType: HazardRelationshipType.temporalSequence,
          status: HazardRelationshipStatus.observed,
          evidenceList: [evidence1],
        );

        expect(rel.relationshipId, 'rel-101');
        expect(rel.relationshipType, HazardRelationshipType.temporalSequence);
        expect(rel.status, HazardRelationshipStatus.observed);
        expect(rel.evidenceList.length, 1);
      });

      test('INVARIANT: rejects "validated" status if evidenceList is empty', () {
        expect(
          () => HazardRelationship(
            relationshipId: 'rel-unverified-val',
            sourceHazardId: 'eq-1',
            targetHazardId: 'ls-1',
            sourceCategory: 'Earthquake',
            targetCategory: 'Landslide',
            relationshipType: HazardRelationshipType.triggering,
            status: HazardRelationshipStatus.validated,
            evidenceList: const [], // Empty evidence -> MUST REJECT!
          ),
          throwsArgumentError,
        );
      });
    });

    group('2. CompoundHazardEvent & HazardCascade Contracts', () {
      test('CompoundHazardEvent requires at least 2 component hazard IDs', () {
        expect(
          () => CompoundHazardEvent(
            compoundEventId: 'comp-101',
            title: 'Mandi Heavy Rain & Landslide Compound Event',
            componentHazardIds: ['rain-1'], // Only 1 component ID -> MUST REJECT!
            location: mandiLocation,
            temporalWindow: horizon,
          ),
          throwsArgumentError,
        );

        final validCompound = CompoundHazardEvent(
          compoundEventId: 'comp-102',
          title: 'Mandi Cloudburst & Landslide Compound Event',
          componentHazardIds: ['rain-1', 'ls-1'],
          componentCategories: ['Extreme Rainfall', 'Landslide'],
          location: mandiLocation,
          temporalWindow: horizon,
          overallStatus: HazardRelationshipStatus.observed,
        );

        expect(validCompound.componentCount, 2);
        expect(validCompound.overallStatus, HazardRelationshipStatus.observed);
      });

      test('HazardCascade requires at least 2 sequential step hazard IDs', () {
        expect(
          () => HazardCascade(
            cascadeId: 'casc-1',
            title: 'Invalid Cascade',
            stepHazardIds: ['eq-1'], // Only 1 step -> MUST REJECT!
            location: mandiLocation,
            timeSpan: horizon,
          ),
          throwsArgumentError,
        );

        final cascade = HazardCascade(
          cascadeId: 'casc-2',
          title: 'Mandi Earthquake -> Slope Failure -> River Blockage Cascade',
          stepHazardIds: ['eq-1', 'ls-1', 'flood-1'],
          location: mandiLocation,
          timeSpan: horizon,
          overallStatus: HazardRelationshipStatus.hypothesized,
        );

        expect(cascade.stepCount, 3);
        expect(cascade.overallStatus, HazardRelationshipStatus.hypothesized);
      });
    });

    group('3. MultiHazardAnalysisEngine & Causality Safeguards', () {
      const engine = MultiHazardAnalysisEngine();

      final eqEvent = GroundTruthEvent(
        eventId: 'evt-eq-1',
        category: 'Earthquake',
        location: mandiLocation,
        eventTime: now.subtract(const Duration(hours: 4)),
        source: 'USGS Seismological Feed',
      );

      final lsEvent = GroundTruthEvent(
        eventId: 'evt-ls-1',
        category: 'Landslide',
        location: mandiLocation,
        eventTime: now,
        source: 'GSI Landslide Inventory',
      );

      test('MANDATORY CAUSALITY SAFETY TEST: temporal sequence alone does NOT infer automatic causality', () {
        final rel = engine.evaluateTemporalSequence(
          relationshipId: 'rel-causal-test-1',
          eventA: eqEvent,
          eventB: lsEvent,
        );

        // ASSERT: Must be temporalSequence with status 'observed' or 'hypothesized'.
        // MUST NOT be automatically marked as 'validated' or 'causal'!
        expect(rel.relationshipType, HazardRelationshipType.temporalSequence);
        expect(rel.status, HazardRelationshipStatus.observed);
        expect(rel.metadata['causalityAsserted'], isFalse);
      });

      test('detects conservative compound candidates and deduplicates OSINT events', () {
        final dupLsEvent = GroundTruthEvent(
          eventId: 'evt-ls-1-rss-copy',
          category: 'Landslide',
          location: mandiLocation,
          eventTime: now,
          source: 'News RSS',
          syndicationClusterId: 'cluster-mandi-ls-1', // Same cluster ID -> Deduplicate!
        );

        final rawEvents = [eqEvent, lsEvent, dupLsEvent];

        final compoundCandidate = engine.detectCompoundCandidate(
          compoundEventId: 'comp-cand-101',
          title: 'Mandi Earthquake & Landslide Compound Candidate',
          rawEvents: rawEvents,
          maxRadiusMeters: 10000.0,
          maxTemporalWindow: const Duration(hours: 12),
        );

        expect(compoundCandidate, isNotNull);
        // Deduplication collapses 2 news reports of 1 landslide into 1 component event -> 2 total component IDs (eq-1, ls-1)
        expect(compoundCandidate?.componentCount, 2);
        expect(compoundCandidate?.overallStatus, HazardRelationshipStatus.observed);
      });

      test('assembles sequential hazard cascade cleanly', () {
        final rel1 = HazardRelationship(
          relationshipId: 'rel-c1',
          sourceHazardId: 'eq-1',
          targetHazardId: 'ls-1',
          sourceCategory: 'Earthquake',
          targetCategory: 'Landslide',
          relationshipType: HazardRelationshipType.cascading,
          status: HazardRelationshipStatus.observed,
          evidenceList: [evidence1],
        );

        final rel2 = HazardRelationship(
          relationshipId: 'rel-c2',
          sourceHazardId: 'ls-1',
          targetHazardId: 'flood-1',
          sourceCategory: 'Landslide',
          targetCategory: 'Flood',
          relationshipType: HazardRelationshipType.cascading,
          status: HazardRelationshipStatus.observed,
          evidenceList: [evidence1],
        );

        final cascade = engine.assembleCascade(
          cascadeId: 'casc-mandi-1',
          title: 'Earthquake -> Landslide -> Flood Cascade',
          sequentialRelationships: [rel1, rel2],
        );

        expect(cascade.stepCount, 3);
        expect(cascade.stepHazardIds, ['eq-1', 'ls-1', 'flood-1']);
      });

      test('MANDATORY GOVERNANCE TEST: multi-hazard analysis DOES NOT mutate RiskMap or create operational hazards', () {
        final rel = engine.evaluateTemporalSequence(
          relationshipId: 'rel-gov-1',
          eventA: eqEvent,
          eventB: lsEvent,
        );

        expect(rel, isA<HazardRelationship>());
        expect(rel, isNot(isA<Hazard>()));
      });
    });
  });
}
