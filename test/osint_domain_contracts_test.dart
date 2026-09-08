import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/osint/osint_source.dart';
import 'package:riskpulse/domain/osint/osint_spatial_reference.dart';
import 'package:riskpulse/domain/osint/osint_temporal_reference.dart';
import 'package:riskpulse/domain/osint/osint_evidence.dart';
import 'package:riskpulse/domain/osint/osint_event_type.dart';
import 'package:riskpulse/domain/osint/osint_claim.dart';
import 'package:riskpulse/domain/osint/evidence_confidence.dart';
import 'package:riskpulse/domain/osint/verification_state.dart';
import 'package:riskpulse/domain/osint/osint_candidate_event.dart';
import 'package:riskpulse/domain/osint/evidence_relationship.dart';

void main() {
  final now = DateTime(2026, 9, 7, 12, 0, 0);

  group('Stage 2.2 OSINT Domain Contracts & Core Entities Tests', () {
    // 1. OSINTSource Construction, Validation & Round-Trip
    test(
      '1. OSINTSource construction, validation, and serialization round-trip',
      () {
        final source = OSINTSource(
          sourceId: 'src-ndtv-01',
          sourceType: OSINTSourceType.newsMedia,
          publisherName: 'NDTV India',
          canonicalUrl: 'https://ndtv.com/news/12345',
          reliabilityCategory: SourceReliability.establishedMedia,
          language: 'en',
        );

        expect(source.isValid, isTrue);
        expect(source.sourceId, equals('src-ndtv-01'));
        expect(source.sourceType, equals(OSINTSourceType.newsMedia));
        expect(
          source.reliabilityCategory,
          equals(SourceReliability.establishedMedia),
        );

        final map = source.toMap();
        final recovered = OSINTSource.fromMap(map);

        expect(recovered.sourceId, equals(source.sourceId));
        expect(recovered.publisherName, equals(source.publisherName));
        expect(recovered.canonicalUrl, equals(source.canonicalUrl));
        expect(recovered, equals(source));
      },
    );

    // 2. OSINTSource Validation Rejects Empty Required Fields
    test(
      '2. OSINTSource validation rejects empty sourceId or publisherName',
      () {
        final invalidId = OSINTSource(
          sourceId: '',
          sourceType: OSINTSourceType.newsMedia,
          publisherName: 'NDTV India',
        );
        expect(invalidId.isValid, isFalse);

        final invalidName = OSINTSource(
          sourceId: 'src-01',
          sourceType: OSINTSourceType.newsMedia,
          publisherName: '   ',
        );
        expect(invalidName.isValid, isFalse);
      },
    );

    // 3. OSINTSpatialReference Precision Types
    test(
      '3. OSINTSpatialReference represents exact, approximate, named, admin, linear, and unknown precision without false precision',
      () {
        final exact = OSINTSpatialReference.exact(
          location: const GeoLocation(latitude: 31.1048, longitude: 77.1734),
          accuracyMeters: 15.0,
        );
        expect(
          exact.spatialPrecision,
          equals(OSINTSpatialPrecision.exactPoint),
        );
        expect(exact.accuracyMeters, equals(15.0));

        final approx = OSINTSpatialReference.approximate(
          location: const GeoLocation(latitude: 31.1000, longitude: 77.1700),
          uncertaintyRadiusKm: 5.0,
          placeName: 'Near Mandi Highway',
        );
        expect(
          approx.spatialPrecision,
          equals(OSINTSpatialPrecision.approximatePoint),
        );
        expect(approx.isGeocodedInferred, isTrue);

        final named = OSINTSpatialReference.named(
          placeName: 'Mandi Valley',
          district: 'Mandi',
          state: 'Himachal Pradesh',
        );
        expect(
          named.spatialPrecision,
          equals(OSINTSpatialPrecision.namedPlace),
        );
        expect(named.placeName, equals('Mandi Valley'));

        final unknown = const OSINTSpatialReference.unknown();
        expect(unknown.spatialPrecision, equals(OSINTSpatialPrecision.unknown));

        final recovered = OSINTSpatialReference.fromMap(approx.toMap());
        expect(
          recovered.spatialPrecision,
          equals(OSINTSpatialPrecision.approximatePoint),
        );
        expect(recovered.uncertaintyRadiusKm, equals(5.0));
      },
    );

    // 4. OSINTTemporalReference Timestamps Distinction
    test(
      '4. OSINTTemporalReference keeps eventTime, publishedAt, retrievedAt, and verifiedAt semantically distinct',
      () {
        final eventT = DateTime(2026, 9, 7, 8, 30, 0);
        final pubT = DateTime(2026, 9, 7, 9, 15, 0);
        final retT = DateTime(2026, 9, 7, 9, 30, 0);
        final verT = DateTime(2026, 9, 7, 10, 0, 0);

        final tempRef = OSINTTemporalReference(
          eventTime: eventT,
          publishedAt: pubT,
          retrievedAt: retT,
          verifiedAt: verT,
        );

        expect(tempRef.isValid, isTrue);
        expect(tempRef.eventTime, equals(eventT));
        expect(tempRef.publishedAt, equals(pubT));
        expect(tempRef.retrievedAt, equals(retT));
        expect(tempRef.verifiedAt, equals(verT));
        expect(tempRef.eventTime, isNot(equals(tempRef.publishedAt)));

        final recovered = OSINTTemporalReference.fromMap(tempRef.toMap());
        expect(recovered, equals(tempRef));
      },
    );

    // 5. OSINTEvidence Construction, Validation & Round-Trip
    test(
      '5. OSINTEvidence construction, contentFingerprint, and serialization round-trip',
      () {
        final evidence = OSINTEvidence(
          evidenceId: 'ev-1001',
          sourceId: 'src-ndtv-01',
          contentFingerprint: 'a1b2c3d4e5f67890sha256hash',
          title: 'Landslide Blocks Mandi-Kullu National Highway',
          extractedText:
              'A major landslide triggered by heavy rainfall has blocked traffic near Mandi on NH-21.',
          canonicalUrl: 'https://ndtv.com/news/landslide-mandi-12345',
          publishedAt: now.subtract(const Duration(hours: 2)),
          retrievedAt: now,
          spatialRef: const OSINTSpatialReference.named(
            placeName: 'Mandi-Kullu Highway',
            district: 'Mandi',
            state: 'Himachal Pradesh',
          ),
        );

        expect(evidence.isValid, isTrue);
        expect(
          evidence.contentFingerprint,
          equals('a1b2c3d4e5f67890sha256hash'),
        );

        final map = evidence.toMap();
        final recovered = OSINTEvidence.fromMap(map);

        expect(recovered.evidenceId, equals('ev-1001'));
        expect(recovered.extractedText, contains('blocked traffic near Mandi'));
        expect(recovered.spatialRef?.placeName, equals('Mandi-Kullu Highway'));
        expect(recovered, equals(evidence));
      },
    );

    // 6. OSINTClaim Construction & AI-Extraction Distinction
    test(
      '6. OSINTClaim represents structured assertion and explicitly flags AI-derived extraction',
      () {
        final claim = OSINTClaim(
          claimId: 'claim-501',
          evidenceId: 'ev-1001',
          claimType: OSINTEventType.roadBlockage,
          subject: 'NH-21 Mandi-Kullu Highway',
          predicate: 'blocked by landslide debris',
          extractionMethod: 'llm-ner-v1',
          isAiExtracted: true,
        );

        expect(claim.isValid, isTrue);
        expect(claim.claimType, equals(OSINTEventType.roadBlockage));
        expect(claim.isAiExtracted, isTrue);
        expect(claim.extractionMethod, equals('llm-ner-v1'));

        final recovered = OSINTClaim.fromMap(claim.toMap());
        expect(recovered.claimId, equals('claim-501'));
        expect(recovered.isAiExtracted, isTrue);
        expect(recovered, equals(claim));
      },
    );

    // 7. EvidenceConfidence Metrics Validation
    test(
      '7. EvidenceConfidence validates score bounds and supports individual metric factors',
      () {
        final confidence = const EvidenceConfidence(
          sourceReliabilityScore: 0.85,
          independentCorroborationCount: 3,
          spatialPrecisionScore: 0.70,
          temporalConsistencyScore: 0.90,
          hasConflictingEvidence: false,
          compositeConfidenceScore: 0.82,
        );

        expect(confidence.isValid, isTrue);
        expect(confidence.sourceReliabilityScore, equals(0.85));
        expect(confidence.independentCorroborationCount, equals(3));

        final invalid = const EvidenceConfidence(
          sourceReliabilityScore: 1.5, // Invalid > 1.0
          independentCorroborationCount: -1, // Invalid < 0
        );
        expect(invalid.isValid, isFalse);

        final recovered = EvidenceConfidence.fromMap(confidence.toMap());
        expect(recovered, equals(confidence));
      },
    );

    // 8. OSINTCandidateEvent Supporting vs Conflicting Claims Separation
    test(
      '8. OSINTCandidateEvent keeps supporting and conflicting claims in separate unmodifiable collections',
      () {
        final event = OSINTCandidateEvent(
          eventId: 'event-cand-8801',
          eventType: OSINTEventType.landslide,
          title: 'Mandi Landslide & Road Closure',
          description: 'Landslide on NH-21 affecting traffic movement.',
          spatialRef: const OSINTSpatialReference.named(
            placeName: 'Mandi',
            district: 'Mandi',
            state: 'Himachal Pradesh',
          ),
          detectionTime: now,
          evidenceIds: const ['ev-1001', 'ev-1002'],
          supportingClaimIds: const ['claim-501', 'claim-502'],
          conflictingClaimIds: const ['claim-901'],
          verificationState: VerificationState.conflicting,
        );

        expect(event.isValid, isTrue);
        expect(event.supportingClaimIds, equals(['claim-501', 'claim-502']));
        expect(event.conflictingClaimIds, equals(['claim-901']));
        expect(event.verificationState, equals(VerificationState.conflicting));

        // Verify unmodifiable list enforcement
        expect(() => event.evidenceIds.add('ev-999'), throwsUnsupportedError);

        final recovered = OSINTCandidateEvent.fromMap(event.toMap());
        expect(recovered.eventId, equals('event-cand-8801'));
        expect(
          recovered.verificationState,
          equals(VerificationState.conflicting),
        );
        expect(recovered, equals(event));
      },
    );

    // 9. EvidenceRelationship Construction & Validation
    test(
      '9. EvidenceRelationship links entities cleanly with typed relationships',
      () {
        final rel = EvidenceRelationship(
          relationshipId: 'rel-001',
          sourceEntityId: 'ev-1001',
          targetEntityId: 'claim-501',
          relationshipType: RelationshipType.supports,
          notes: 'Source text directly asserts road blockage',
        );

        expect(rel.isValid, isTrue);
        expect(rel.relationshipType, equals(RelationshipType.supports));

        final invalidSelfRel = EvidenceRelationship(
          relationshipId: 'rel-002',
          sourceEntityId: 'ev-1001',
          targetEntityId: 'ev-1001', // Self-reference fails validation
          relationshipType: RelationshipType.duplicates,
        );
        expect(invalidSelfRel.isValid, isFalse);

        final recovered = EvidenceRelationship.fromMap(rel.toMap());
        expect(recovered, equals(rel));
      },
    );

    // 10. Immutability & copyWith across all OSINT domain models
    test(
      '10. Immutability and copyWith create updated instances without mutating original objects',
      () {
        final origSource = OSINTSource(
          sourceId: 'src-01',
          sourceType: OSINTSourceType.publicWeb,
          publisherName: 'Publisher A',
        );

        final updatedSource = origSource.copyWith(
          publisherName: 'Publisher B',
          reliabilityCategory: SourceReliability.authoritative,
        );

        expect(origSource.publisherName, equals('Publisher A'));
        expect(updatedSource.publisherName, equals('Publisher B'));
        expect(
          updatedSource.reliabilityCategory,
          equals(SourceReliability.authoritative),
        );
      },
    );

    // 11. Deterministic Serialization Across All 10 Contracts
    test(
      '11. Deterministic round-trip map serialization across all 10 OSINT domain contracts',
      () {
        final source = OSINTSource(
          sourceId: 's1',
          sourceType: OSINTSourceType.newsMedia,
          publisherName: 'Pub 1',
        );
        final spatial = const OSINTSpatialReference.named(
          placeName: 'Mandi',
          district: 'Mandi',
          state: 'HP',
        );
        final temporal = OSINTTemporalReference(
          publishedAt: now,
          retrievedAt: now,
        );
        final evidence = OSINTEvidence(
          evidenceId: 'e1',
          sourceId: 's1',
          extractedText: 'Text 1',
          publishedAt: now,
          retrievedAt: now,
          spatialRef: spatial,
          temporalRef: temporal,
        );
        final claim = OSINTClaim(
          claimId: 'c1',
          evidenceId: 'e1',
          claimType: OSINTEventType.flood,
          subject: 'River',
          predicate: 'overflowed',
        );
        final confidence = const EvidenceConfidence(
          sourceReliabilityScore: 0.9,
          independentCorroborationCount: 2,
        );
        final candidateEvent = OSINTCandidateEvent(
          eventId: 'ev1',
          eventType: OSINTEventType.flood,
          title: 'Flood Event',
          description: 'Desc',
          spatialRef: spatial,
          detectionTime: now,
          confidence: confidence,
        );
        final rel = EvidenceRelationship(
          relationshipId: 'r1',
          sourceEntityId: 'e1',
          targetEntityId: 'c1',
          relationshipType: RelationshipType.supports,
        );

        expect(OSINTSource.fromMap(source.toMap()), equals(source));
        expect(OSINTSpatialReference.fromMap(spatial.toMap()), equals(spatial));
        expect(
          OSINTTemporalReference.fromMap(temporal.toMap()),
          equals(temporal),
        );
        expect(OSINTEvidence.fromMap(evidence.toMap()), equals(evidence));
        expect(OSINTClaim.fromMap(claim.toMap()), equals(claim));
        expect(
          EvidenceConfidence.fromMap(confidence.toMap()),
          equals(confidence),
        );
        expect(
          OSINTCandidateEvent.fromMap(candidateEvent.toMap()),
          equals(candidateEvent),
        );
        expect(EvidenceRelationship.fromMap(rel.toMap()), equals(rel));
      },
    );
  });
}
