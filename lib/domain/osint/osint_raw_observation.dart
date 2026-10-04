import 'package:flutter/foundation.dart';

/// Immutable domain model representing a raw external OSINT observation acquired from a public source.
///
/// Preserves unedited acquired text, original media references, content hash, and source metadata.
@immutable
class OsintRawObservation {
  static const int currentSchemaVersion = 1;

  final String rawObservationId;
  final String sourceSystem; // e.g. 'RSS', 'GSI_FEED', 'TWITTER_API', 'NEWS_API'
  final String sourcePublisher; // e.g. 'Geological Survey of India', 'The Tribune'
  final String sourceId;
  final String? sourceUrl;
  final String contentType; // 'NEWS', 'SOCIAL_MEDIA', 'GOVERNMENT_FEED', 'CITIZEN_REPORT'

  final String headline;
  final String rawContent;
  final List<String> mediaUrls;
  final String language; // 'en', 'hi', etc.
  final String contentHash;

  final DateTime retrievedAt;
  final DateTime publishedAt;
  final Map<String, dynamic> metadata;

  OsintRawObservation({
    required this.rawObservationId,
    required this.sourceSystem,
    required this.sourcePublisher,
    required this.sourceId,
    this.sourceUrl,
    this.contentType = 'NEWS',
    required this.headline,
    required this.rawContent,
    List<String>? mediaUrls,
    this.language = 'en',
    required this.contentHash,
    DateTime? retrievedAt,
    DateTime? publishedAt,
    Map<String, dynamic>? metadata,
  })  : mediaUrls = List<String>.unmodifiable(mediaUrls ?? const []),
        retrievedAt = retrievedAt ?? DateTime.now().toUtc(),
        publishedAt = publishedAt ?? DateTime.now().toUtc(),
        metadata = Map<String, dynamic>.unmodifiable(metadata ?? const {}) {
    if (rawObservationId.trim().isEmpty) {
      throw ArgumentError('OsintRawObservation.rawObservationId cannot be empty.');
    }
    if (sourcePublisher.trim().isEmpty) {
      throw ArgumentError('OsintRawObservation.sourcePublisher cannot be empty.');
    }
    if (rawContent.trim().isEmpty) {
      throw ArgumentError('OsintRawObservation.rawContent cannot be empty.');
    }
    if (contentHash.trim().isEmpty) {
      throw ArgumentError('OsintRawObservation.contentHash cannot be empty.');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'rawObservationId': rawObservationId,
      'sourceSystem': sourceSystem,
      'sourcePublisher': sourcePublisher,
      'sourceId': sourceId,
      'sourceUrl': sourceUrl,
      'contentType': contentType,
      'headline': headline,
      'rawContent': rawContent,
      'mediaUrls': mediaUrls,
      'language': language,
      'contentHash': contentHash,
      'retrievedAt': retrievedAt.toIso8601String(),
      'publishedAt': publishedAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OsintRawObservation &&
          runtimeType == other.runtimeType &&
          rawObservationId == other.rawObservationId &&
          contentHash == other.contentHash;

  @override
  int get hashCode => Object.hash(rawObservationId, contentHash);
}
