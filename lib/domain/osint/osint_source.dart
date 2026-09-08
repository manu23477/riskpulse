import 'package:flutter/foundation.dart';

/// Taxonomy of public OSINT intelligence sources.
enum OSINTSourceType {
  official,
  scientificAcademic,
  newsMedia,
  publicWeb,
  publicSocial,
  citizenEyewitness,
  other,
}

/// Baseline reliability classification for an OSINT publisher or source.
enum SourceReliability {
  authoritative,
  establishedMedia,
  communityReporter,
  unverifiedPublic,
  unknown,
}

/// Immutable domain model representing a public OSINT information source/publisher.
///
/// Disconnects source publisher reliability from individual claim confidence.
@immutable
class OSINTSource {
  static const int currentSchemaVersion = 1;

  final String sourceId;
  final OSINTSourceType sourceType;
  final String publisherName;
  final String? canonicalUrl;
  final SourceReliability reliabilityCategory;
  final String language;
  final int schemaVersion;

  const OSINTSource({
    required this.sourceId,
    required this.sourceType,
    required this.publisherName,
    this.canonicalUrl,
    this.reliabilityCategory = SourceReliability.unknown,
    this.language = 'en',
    this.schemaVersion = currentSchemaVersion,
  });

  bool get isValid =>
      sourceId.trim().isNotEmpty &&
      publisherName.trim().isNotEmpty &&
      schemaVersion > 0;

  OSINTSource copyWith({
    String? sourceId,
    OSINTSourceType? sourceType,
    String? publisherName,
    String? canonicalUrl,
    bool clearCanonicalUrl = false,
    SourceReliability? reliabilityCategory,
    String? language,
    int? schemaVersion,
  }) {
    return OSINTSource(
      sourceId: sourceId ?? this.sourceId,
      sourceType: sourceType ?? this.sourceType,
      publisherName: publisherName ?? this.publisherName,
      canonicalUrl: clearCanonicalUrl
          ? null
          : (canonicalUrl ?? this.canonicalUrl),
      reliabilityCategory: reliabilityCategory ?? this.reliabilityCategory,
      language: language ?? this.language,
      schemaVersion: schemaVersion ?? this.schemaVersion,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sourceId': sourceId,
      'sourceType': sourceType.name,
      'publisherName': publisherName,
      'canonicalUrl': canonicalUrl,
      'reliabilityCategory': reliabilityCategory.name,
      'language': language,
      'schemaVersion': schemaVersion,
    };
  }

  factory OSINTSource.fromMap(Map<String, dynamic> map) {
    return OSINTSource(
      sourceId: map['sourceId'] as String? ?? '',
      sourceType: OSINTSourceType.values.firstWhere(
        (e) => e.name == map['sourceType'],
        orElse: () => OSINTSourceType.other,
      ),
      publisherName: map['publisherName'] as String? ?? '',
      canonicalUrl: map['canonicalUrl'] as String?,
      reliabilityCategory: SourceReliability.values.firstWhere(
        (e) => e.name == map['reliabilityCategory'],
        orElse: () => SourceReliability.unknown,
      ),
      language: map['language'] as String? ?? 'en',
      schemaVersion: map['schemaVersion'] as int? ?? currentSchemaVersion,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OSINTSource &&
          runtimeType == other.runtimeType &&
          sourceId == other.sourceId &&
          schemaVersion == other.schemaVersion;

  @override
  int get hashCode => Object.hash(sourceId, schemaVersion);
}
