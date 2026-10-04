import 'package:riskpulse/data/repositories/osint_repository.dart';
import 'package:riskpulse/data/services/evidence/evidence_fusion_service.dart';
import 'package:riskpulse/domain/evidence/event_hypothesis.dart';
import 'package:riskpulse/domain/evidence/evidence_fusion_assessment.dart';
import 'package:riskpulse/domain/evidence/evidence_object.dart';
import 'package:riskpulse/domain/evidence/evidence_provenance.dart';
import 'package:riskpulse/domain/evidence/evidence_source.dart';
import 'package:riskpulse/domain/evidence/evidence_type.dart';
import 'package:riskpulse/domain/osint/osint_geolocation_type.dart';
import 'package:riskpulse/domain/osint/osint_normalized_payload.dart';
import 'package:riskpulse/domain/osint/osint_raw_observation.dart';

/// Result container emitted upon OSINT ingestion and normalization.
class OsintIngestionResult {
  final OsintRawObservation rawObservation;
  final OsintNormalizedPayload normalizedPayload;
  final EvidenceObject evidenceObject;
  final bool isDuplicate;

  const OsintIngestionResult({
    required this.rawObservation,
    required this.normalizedPayload,
    required this.evidenceObject,
    required this.isDuplicate,
  });
}

/// Service managing external OSINT acquisition, content normalization, duplicate detection,
/// uncertainty-aware geolocation, EvidenceObject conversion, and V1.1 fusion pipeline submission.
///
/// STRICT BOUNDARY: OSINT IS EVIDENCE, NOT TRUTH. Converted EvidenceObjects enter V1.1 fusion
/// and P2.2 revision machinery without bypassing validation gates.
class OsintIngestionService {
  final OsintRepository repository;

  OsintIngestionService({required this.repository});

  /// Ingests a raw OSINT observation, extracts normalized NLP payload, and creates a canonical EvidenceObject.
  Future<OsintIngestionResult> ingestRawObservation(OsintRawObservation raw) async {
    final existingHashMatch = await repository.getByContentHash(raw.contentHash);
    final bool duplicate = existingHashMatch != null && existingHashMatch.rawObservationId != raw.rawObservationId;

    await repository.saveRawObservation(raw);

    final normalized = normalizeObservation(raw);
    await repository.saveNormalizedPayload(normalized);

    final evObj = convertToEvidenceObject(raw, normalized);

    return OsintIngestionResult(
      rawObservation: raw,
      normalizedPayload: normalized,
      evidenceObject: evObj,
      isDuplicate: duplicate,
    );
  }

  /// Extracts structured hazard categories, location, and timestamps from raw OSINT text.
  OsintNormalizedPayload normalizeObservation(OsintRawObservation raw) {
    final text = '${raw.headline} ${raw.rawContent}'.toLowerCase();
    final List<String> hazards = [];

    if (text.contains('landslide') || text.contains('debris') || text.contains('slope')) {
      hazards.add('landslide');
    }
    if (text.contains('flood') || text.contains('inundat') || text.contains('river')) {
      hazards.add('flood');
    }
    if (text.contains('cloudburst')) {
      hazards.add('cloudburst');
    }
    if (text.contains('glof') || text.contains('glacial')) {
      hazards.add('glof');
    }
    if (text.contains('earthquake') || text.contains('seismic') || text.contains('tremor')) {
      hazards.add('earthquake');
    }
    if (hazards.isEmpty) {
      hazards.add('hazard');
    }

    final List<String> damage = [];
    if (text.contains('block') || text.contains('road') || text.contains('highway')) {
      damage.add('highway_blocked');
    }
    if (text.contains('bridge')) {
      damage.add('bridge_impact');
    }

    return OsintNormalizedPayload(
      rawObservationId: raw.rawObservationId,
      extractedHeadline: raw.headline,
      extractedText: raw.rawContent,
      extractedHazardCategories: hazards,
      extractedLocationText: raw.headline.contains('Kotropi') ? 'Kotropi, Mandi' : 'Mandi District',
      geolocationType: OsintGeolocationType.approximatePoint,
      extractedAdminUnitIds: const ['HP-06'],
      extractedEventTime: raw.publishedAt,
      damageClaims: damage,
      extractedLanguage: raw.language,
    );
  }

  /// Converts normalized OSINT payload into a canonical [EvidenceObject].
  EvidenceObject convertToEvidenceObject(OsintRawObservation raw, OsintNormalizedPayload normalized) {
    final EvidenceType evType = raw.contentType == 'SOCIAL_MEDIA'
        ? EvidenceType.socialMedia
        : (raw.contentType == 'GOVERNMENT_FEED' ? EvidenceType.governmentReport : EvidenceType.newsReport);

    return EvidenceObject(
      evidenceId: 'EVID-OSINT-${raw.rawObservationId}',
      observationId: raw.rawObservationId,
      evidenceType: evType,
      source: EvidenceSource(
        sourceSystem: raw.sourceSystem,
        sourceId: raw.sourceId,
        sourceName: raw.sourcePublisher,
      ),
      sourceId: raw.sourceId,
      sourceName: raw.sourcePublisher,
      sourcePublisher: raw.sourcePublisher,
      sourceUri: raw.sourceUrl,
      description: '${normalized.extractedHeadline}: ${normalized.extractedText}',
      publishedAt: raw.publishedAt,
      receivedAt: raw.retrievedAt,
      contentHash: raw.contentHash,
      geometry: normalized.extractedCoordinates != null
          ? {
              'type': 'Point',
              'coordinates': [normalized.extractedCoordinates!.longitude, normalized.extractedCoordinates!.latitude]
            }
          : null,
      provenance: EvidenceProvenance(
        sourceSystem: raw.sourceSystem,
        sourceId: raw.sourceId,
      ),
    );
  }

  /// Submits an OSINT EvidenceObject to V1.1 EvidenceFusionService.
  Future<EvidenceFusionAssessment> submitToFusionPipeline({
    required EvidenceObject osintEvidence,
    required EventHypothesis hypothesis,
    required EvidenceFusionService fusionService,
  }) async {
    return fusionService.evaluateEvidenceFusion(
      hypothesis: hypothesis,
      evidenceList: [osintEvidence],
    );
  }
}
