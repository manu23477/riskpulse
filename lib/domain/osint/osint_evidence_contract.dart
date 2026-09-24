import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/osint/osint_spatial_reference.dart';

/// Enumeration of explicit OSINT source classification categories.
enum OsintSourceCategory {
  officialGovernment,
  meteorologicalService,
  remoteSensingSatellite,
  newsMedia,
  communityReport,
  institutionalResearch,
  other,
}

/// Enumeration of explicit OSINT evidence freshness states.
enum OsintFreshnessState {
  current,
  recent,
  stale,
  unknown,
}

/// Immutable domain contract representing an OSINT intelligence source definition.
@immutable
class OsintSourceContract {
  final String sourceId;
  final String sourceName;
  final OsintSourceCategory category;
  final String publisher;
  final String? sourceUri;
  final DateTime acquisitionTimestamp;
  final DateTime? publicationTimestamp;
  final double sourceReliability; // 0.0 to 1.0
  final bool isSynthetic;

  const OsintSourceContract({
    required this.sourceId,
    required this.sourceName,
    required this.category,
    required this.publisher,
    this.sourceUri,
    required this.acquisitionTimestamp,
    this.publicationTimestamp,
    this.sourceReliability = 0.70,
    this.isSynthetic = false,
  })  : assert(sourceId.length > 0, 'sourceId cannot be empty.'),
        assert(sourceName.length > 0, 'sourceName cannot be empty.'),
        assert(sourceReliability >= 0.0 && sourceReliability <= 1.0, 'sourceReliability must be between 0.0 and 1.0.');
}

/// Immutable domain contract representing a normalized OSINT evidence record.
@immutable
class OsintEvidenceContract {
  final String evidenceId;
  final String sourceId;
  final String rawContentReference;
  final String normalizedContent;
  final String contentHash;
  final DateTime? observedAt;
  final DateTime publishedAt;
  final DateTime acquiredAt;
  final GeoLocation? location;
  final OSINTSpatialPrecision spatialPrecision;
  final String hazardCategory;
  final Map<String, double> confidenceComponents;
  final OsintFreshnessState freshnessState;
  final bool isSynthetic;

  const OsintEvidenceContract({
    required this.evidenceId,
    required this.sourceId,
    required this.rawContentReference,
    required this.normalizedContent,
    required this.contentHash,
    this.observedAt,
    required this.publishedAt,
    required this.acquiredAt,
    this.location,
    this.spatialPrecision = OSINTSpatialPrecision.approximate,
    required this.hazardCategory,
    this.confidenceComponents = const {},
    this.freshnessState = OsintFreshnessState.current,
    this.isSynthetic = false,
  })  : assert(evidenceId.length > 0, 'evidenceId cannot be empty.'),
        assert(sourceId.length > 0, 'sourceId cannot be empty.'),
        assert(contentHash.length > 0, 'contentHash cannot be empty.');
}
