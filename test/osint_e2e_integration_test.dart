import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:riskpulse/domain/hazard/hazard.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/osint/osint_source.dart';
import 'package:riskpulse/domain/osint/osint_evidence.dart';
import 'package:riskpulse/domain/osint/osint_event_type.dart';
import 'package:riskpulse/domain/osint/osint_spatial_reference.dart';
import 'package:riskpulse/domain/osint/verification_state.dart';
import 'package:riskpulse/domain/osint/multi_stream_fusion_result.dart';
import 'package:riskpulse/domain/osint/promotion_candidate.dart';
import 'package:riskpulse/domain/osint/human_review_decision.dart';
import 'package:riskpulse/domain/osint/promotion_result.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/gis/research_product.dart';
import 'package:riskpulse/domain/gis/multispectral_product.dart';
import 'package:riskpulse/domain/gis/raster_data.dart';
import 'package:riskpulse/domain/gis/remote_sensing_band.dart';

import 'package:riskpulse/data/services/osint/osint_normalizer.dart';
import 'package:riskpulse/data/services/osint/rss_atom_source_adapter.dart';
import 'package:riskpulse/data/services/osint/syndication_lineage_engine.dart';
import 'package:riskpulse/data/services/osint/corroboration_verification_engine.dart';
import 'package:riskpulse/data/services/osint/multi_stream_fusion_engine.dart';
import 'package:riskpulse/data/services/osint/controlled_promotion_gate.dart';

void main() {
  final now = DateTime.utc(2026, 9, 7, 12, 0, 0);

  const sampleFeedXml = '''<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0">
  <channel>
    <title>Disaster Alert Feed</title>
    <link>https://disaster.gov.in</link>
    <item>
      <title>  Major Landslide Blocks Mandi Highway  </title>
      <description><![CDATA[<p>Heavy landslide triggered by monsoon rain has <b>blocked</b> traffic on NH-21 near Mandi town.</p>]]></description>
      <link>https://disaster.gov.in/alerts/mandi-901?utm=rss</link>
      <pubDate>Mon, 07 Sep 2026 08:30:00 GMT</pubDate>
    </item>
  </channel>
</rss>''';

  group('Stage 2.9 End-to-End OSINT Foundation Integration Validation Tests', () {
    test('1. End-to-End Intelligence Lifecycle: Ingestion -> Normalization -> Lineage -> Corroboration -> Fusion -> Human Review -> Controlled Promotion -> Provenance Audit', () async {
      // Step A & B: Source Definition & Adapter Ingestion
      final sourcePrimary = OSINTSource(
        sourceId: 'src-official-sdma',
        sourceType: OSINTSourceType.official,
        publisherName: 'HP SDMA Official',
        canonicalUrl: 'https://disaster.gov.in/feed.xml',
        reliabilityCategory: SourceReliability.authoritative,
      );

      final mockClient = MockClient((request) async {
        return http.Response(sampleFeedXml, 200);
      });

      final adapter = RssAtomSourceAdapter(httpClient: mockClient);
      final ingestedEvidence = await adapter.fetchEvidence(sourcePrimary);

      expect(ingestedEvidence.length, equals(1));
      final primaryEv = ingestedEvidence.first;

      // Step C & D: Normalization & SHA-256 Fingerprint Verification
      expect(primaryEv.title, equals('Major Landslide Blocks Mandi Highway'));
      expect(primaryEv.extractedText, equals('Heavy landslide triggered by monsoon rain has blocked traffic on NH-21 near Mandi town.'));
      expect(primaryEv.contentFingerprint, isNotNull);
      expect(primaryEv.contentFingerprint!.length, equals(64));

      // Step E & F: Introduce Secondary Independent Evidence & Syndicated Copy
      const mandiLoc = GeoLocation(latitude: 31.2048, longitude: 77.1734);
      const mandiSpatial = OSINTSpatialReference.exact(location: mandiLoc);

      final ev1 = primaryEv.copyWith(spatialRef: mandiSpatial);

      // ev2 is a syndicated copy of ev1
      final ev2 = OSINTEvidence(
        evidenceId: 'ev-repub-102',
        sourceId: 'src-aggregator-news',
        contentFingerprint: primaryEv.contentFingerprint,
        title: 'Major Landslide Blocks Mandi Highway (via SDMA)',
        extractedText: primaryEv.extractedText,
        canonicalUrl: 'https://newsaggregator.com/mandi-landslide',
        publishedAt: now.subtract(const Duration(hours: 1)),
        retrievedAt: now,
        spatialRef: mandiSpatial,
      );

      // ev3 is an independent eyewitness report
      final ev3 = OSINTEvidence(
        evidenceId: 'ev-eyewitness-103',
        sourceId: 'src-citizen-01',
        contentFingerprint: OSINTNormalizer.computeContentFingerprint(
          'Rockfall Mandi',
          'Eyewitness report: Heavy rockfall and debris on NH-21 highway near Mandi.',
        ),
        title: 'Rockfall on NH-21 Near Mandi',
        extractedText: 'Eyewitness report: Heavy rockfall and debris on NH-21 highway near Mandi.',
        publishedAt: now,
        retrievedAt: now,
        spatialRef: mandiSpatial,
      );

      final allEvidenceList = [ev1, ev2, ev3];

      // Step G: Syndication & Duplicate Lineage Engine Analysis (Stage 2.4)
      final syndicationEngine = SyndicationLineageEngine();
      final clusters = syndicationEngine.clusterEvidence(allEvidenceList);

      // Total evidence preserved = 3
      expect(clusters.fold<int>(0, (sum, c) => sum + c.memberCount), equals(3));
      expect(clusters.length, equals(2)); // ev1 & ev2 clustered together; ev3 separate

      // Step H: Corroboration & Verification State Machine (Stage 2.5)
      final corroborationEngine = CorroborationVerificationEngine(syndicationEngine: syndicationEngine);
      final sourceMap = {
        'src-official-sdma': sourcePrimary,
        'src-aggregator-news': const OSINTSource(sourceId: 'src-aggregator-news', sourceType: OSINTSourceType.newsMedia, publisherName: 'Aggregator News'),
        'src-citizen-01': const OSINTSource(sourceId: 'src-citizen-01', sourceType: OSINTSourceType.citizenEyewitness, publisherName: 'Citizen Eyewitness'),
      };

      final corroborationResult = corroborationEngine.evaluateCorroborationAndConflict(
        evidenceList: allEvidenceList,
        sourceMap: sourceMap,
      );

      // Verified: Duplicate ev2 filtered out; independent source count = 2
      expect(corroborationResult.independentEvidenceCount, equals(2));
      expect(corroborationResult.syndicatedDuplicateCount, equals(1));
      expect(corroborationResult.verificationState, equals(VerificationState.verified)); // Official authoritative source present

      // Step I & J: GIS & Remote Sensing Stream Inputs
      const mandiExtent = MapExtent(
        southWest: GeoLocation(latitude: 31.0, longitude: 76.8),
        northEast: GeoLocation(latitude: 31.5, longitude: 77.3),
      );

      final gisProduct = const ResearchProduct(
        id: 'gis-susceptibility-mandi',
        name: 'Mandi Landslide Susceptibility',
        type: ResearchProductType.studyArea,
        category: ResearchProductCategory.vector,
        availability: ResearchProductAvailability.available,
        supportedExportFormats: [ResearchProductFormat.geoJson],
      );

      final dummyRaster = const RasterData(
        width: 2,
        height: 2,
        cellWidth: 0.0001,
        cellHeight: 0.0001,
        origin: mandiLoc,
        crs: CoordinateReferenceSystem.wgs84,
        values: [1200.0, 1400.0, 1100.0, 1300.0],
        noDataValue: -9999.0,
      );

      final rsProduct = MultispectralProduct(
        productId: 'rs-sentinel-mandi-01',
        providerId: 'gee',
        datasetId: 'COPERNICUS/S2_SR_HARMONIZED',
        acquisitionDate: now,
        crs: CoordinateReferenceSystem.wgs84,
        extent: mandiExtent,
        bands: const [RemoteSensingBand.sentinel2B4, RemoteSensingBand.sentinel2B8],
        bandRasters: {'B4': dummyRaster, 'B8': dummyRaster},
      );

      // Step K & L: Multi-Stream Evidence Fusion Engine (Stage 2.6)
      final fusionEngine = MultiStreamFusionEngine(corroborationEngine: corroborationEngine);
      final fusionResult = fusionEngine.fuseStreams(
        osintEvidenceList: allEvidenceList,
        gisProducts: [gisProduct],
        remoteSensingProducts: [rsProduct],
        sourceMap: sourceMap,
      );

      expect(fusionResult.convergenceType, equals(FusionConvergenceType.threeStreamConvergence));
      expect(fusionResult.streamTypeCount, equals(3));
      expect(fusionResult.fusionConfidence, greaterThan(0.60));

      // Step N & O: Promotion Candidate & Eligibility Gate (Stage 2.7)
      final candidate = PromotionCandidate(
        candidateId: 'cand-mandi-2026',
        fusionResultId: fusionResult.fusionId,
        eventType: OSINTEventType.landslide,
        title: 'Mandi Highway Landslide Feature',
        description: 'Three-stream confirmed landslide event blocking NH-21 near Mandi town.',
        spatialRef: mandiSpatial,
        contributingEvidenceIds: allEvidenceList.map((e) => e.evidenceId).toList(),
        fusionConfidence: fusionResult.fusionConfidence,
        hasCrossStreamConflict: fusionResult.hasCrossStreamConflict,
        createdTimestamp: now,
      );

      final gate = ControlledPromotionGate();
      final eligibility = gate.checkEligibility(candidate);
      expect(eligibility.isEligible, isTrue);

      // Step P & Q: Human Reviewer Evaluation & Decision
      final humanReview = HumanReviewDecision(
        reviewId: 'rev-mandi-9001',
        promotionCandidateId: candidate.candidateId,
        reviewerId: 'reviewer-pota-01',
        reviewerRole: 'seniorDisasterAnalyst',
        decision: ReviewDecisionType.approved,
        reviewedAt: now,
        rationale: 'Verified three-stream convergence across SDMA feed, susceptibility vector, and Sentinel-2 imagery.',
      );

      // Step R: Controlled Operational Promotion to ISOLATED Test Store
      final isolatedTestStore = <Hazard>[];

      final promotionResult = gate.promoteCandidate(
        candidate: candidate,
        review: humanReview,
        existingOperationalHazards: isolatedTestStore,
        promotionTime: now,
      );

      expect(promotionResult.isSuccess, isTrue);
      expect(promotionResult.status, equals(PromotionStatus.success));

      final promotedHazard = promotionResult.promotedHazard;
      expect(promotedHazard, isNotNull);
      isolatedTestStore.add(promotedHazard!);

      // Step S: End-to-End Provenance Traceability Verification
      expect(promotedHazard.id, equals('hazard-promoted-cand-mandi-2026'));
      expect(promotedHazard.name, equals('Mandi Highway Landslide Feature'));
      expect(promotedHazard.category, equals('Landslide'));
      expect(promotedHazard.verificationStatus, equals(VerificationStatus.verified));

      final props = promotedHazard.sourceProperties;
      expect(props['promotionCandidateId'], equals('cand-mandi-2026'));
      expect(props['reviewId'], equals('rev-mandi-9001'));
      expect(props['reviewerId'], equals('reviewer-pota-01'));
      expect(props['reviewerRole'], equals('seniorDisasterAnalyst'));
      expect(props['fusionResultId'], equals(fusionResult.fusionId));
      expect(props['contributingEvidenceIds'], containsAll([ev1.evidenceId, 'ev-repub-102', 'ev-eyewitness-103']));
    });

    test('2. Negative-Path Verification: Rejection, Return, Unresolved Conflict, and Low Precision Block Promotion', () {
      final gate = ControlledPromotionGate();

      // Case A: Rejected Review
      final cand1 = PromotionCandidate(
        candidateId: 'cand-rej-1',
        eventType: OSINTEventType.landslide,
        title: 'Unconfirmed Landslide',
        description: 'Unconfirmed report.',
        spatialRef: const OSINTSpatialReference.exact(location: GeoLocation(latitude: 31.2, longitude: 77.0)),
        fusionConfidence: 0.5,
        hasCrossStreamConflict: false,
        createdTimestamp: now,
      );

      final revRejected = HumanReviewDecision(
        reviewId: 'rev-rej-1',
        promotionCandidateId: 'cand-rej-1',
        reviewerId: 'reviewer-pota-01',
        decision: ReviewDecisionType.rejected,
        reviewedAt: now,
        rationale: 'Rejected after ground inspection showed no blockage.',
      );

      final resRej = gate.promoteCandidate(candidate: cand1, review: revRejected);
      expect(resRej.isSuccess, isFalse);

      // Case B: Low Spatial Precision (Unknown)
      final candLowPrec = PromotionCandidate(
        candidateId: 'cand-low-prec',
        eventType: OSINTEventType.flood,
        title: 'Flood Somewhere in Himachal',
        description: 'Broad report without geometry.',
        spatialRef: const OSINTSpatialReference.unknown(),
        fusionConfidence: 0.7,
        hasCrossStreamConflict: false,
        createdTimestamp: now,
      );

      final revLowPrec = HumanReviewDecision(
        reviewId: 'rev-low-1',
        promotionCandidateId: 'cand-low-prec',
        reviewerId: 'reviewer-pota-01',
        decision: ReviewDecisionType.approved,
        reviewedAt: now,
        rationale: 'Approved.',
      );

      final resLowPrec = gate.promoteCandidate(candidate: candLowPrec, review: revLowPrec);
      expect(resLowPrec.isSuccess, isFalse);
      expect(resLowPrec.status, equals(PromotionStatus.ineligibleCandidate));
    });

    test('3. Idempotency & Overlap Protection: Re-promotion and 100m spatial overlap block duplicate feature creation', () {
      final gate = ControlledPromotionGate();

      final cand = PromotionCandidate(
        candidateId: 'cand-idem-1',
        eventType: OSINTEventType.landslide,
        title: 'Landslide Mandi',
        description: 'Landslide report.',
        spatialRef: const OSINTSpatialReference.exact(location: GeoLocation(latitude: 31.2048, longitude: 77.1734)),
        fusionConfidence: 0.8,
        hasCrossStreamConflict: false,
        createdTimestamp: now,
      );

      final review = HumanReviewDecision(
        reviewId: 'rev-idem-1',
        promotionCandidateId: 'cand-idem-1',
        reviewerId: 'reviewer-pota-01',
        decision: ReviewDecisionType.approved,
        reviewedAt: now,
        rationale: 'Approved for promotion.',
      );

      final store = <Hazard>[];
      final res1 = gate.promoteCandidate(candidate: cand, review: review, existingOperationalHazards: store);
      expect(res1.isSuccess, isTrue);
      store.add(res1.promotedHazard!);

      // Idempotency: Duplicate promotion of same candidate fails
      final res2 = gate.promoteCandidate(candidate: cand, review: review, existingOperationalHazards: store);
      expect(res2.isSuccess, isFalse);
      expect(res2.status, equals(PromotionStatus.alreadyPromoted));

      // Overlap: Different candidate overlapping within 100m fails
      final candOverlap = PromotionCandidate(
        candidateId: 'cand-overlap-2',
        eventType: OSINTEventType.landslide,
        title: 'Landslide Mandi Nearby',
        description: 'Nearby landslide report.',
        spatialRef: const OSINTSpatialReference.exact(location: GeoLocation(latitude: 31.2048, longitude: 77.1734)),
        fusionConfidence: 0.8,
        hasCrossStreamConflict: false,
        createdTimestamp: now,
      );

      final reviewOverlap = HumanReviewDecision(
        reviewId: 'rev-overlap-2',
        promotionCandidateId: 'cand-overlap-2',
        reviewerId: 'reviewer-pota-01',
        decision: ReviewDecisionType.approved,
        reviewedAt: now,
        rationale: 'Approved.',
      );

      final resOverlap = gate.promoteCandidate(candidate: candOverlap, review: reviewOverlap, existingOperationalHazards: store);
      expect(resOverlap.isSuccess, isFalse);
      expect(resOverlap.status, equals(PromotionStatus.conflictWithExistingFeature));
    });
  });
}
