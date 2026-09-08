import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/osint/osint_spatial_reference.dart';
import 'package:riskpulse/domain/osint/osint_temporal_reference.dart';

/// Immutable domain record representing raw retrieved content from a public OSINT source.
///
/// Holds retrieved text/title/reference without treating the content as established fact.
@immutable
class OSINTEvidence {
  static const int currentSchemaVersion = 1;

  final String evidenceId;
  final String sourceId;
  final String? contentFingerprint;
  final String? title;
  final String extractedText;
  final String? canonicalUrl;
  final DateTime? publishedAt;
  final DateTime retrievedAt;
  final OSINTSpatialReference? spatialRef;
  final OSINTTemporalReference? temporalRef;
  final int schemaVersion;

  const OSINTEvidence({
    required this.evidenceId,
    required this.sourceId,
    this.contentFingerprint,
    this.title,
    required this.extractedText,
    this.canonicalUrl,
    this.publishedAt,
    required this.retrievedAt,
    this.spatialRef,
    this.temporalRef,
    this.schemaVersion = currentSchemaVersion,
  });

  bool get isValid =>
      evidenceId.trim().isNotEmpty &&
      sourceId.trim().isNotEmpty &&
      extractedText.trim().isNotEmpty &&
      schemaVersion > 0 &&
      (spatialRef == null || spatialRef!.isValid) &&
      (temporalRef == null || temporalRef!.isValid);

  OSINTEvidence copyWith({
    String? evidenceId,
    String? sourceId,
    String? contentFingerprint,
    bool clearContentFingerprint = false,
    String? title,
    bool clearTitle = false,
    String? extractedText,
    String? canonicalUrl,
    bool clearCanonicalUrl = false,
    DateTime? publishedAt,
    bool clearPublishedAt = false,
    DateTime? retrievedAt,
    OSINTSpatialReference? spatialRef,
    bool clearSpatialRef = false,
    OSINTTemporalReference? temporalRef,
    bool clearTemporalRef = false,
    int? schemaVersion,
  }) {
    return OSINTEvidence(
      evidenceId: evidenceId ?? this.evidenceId,
      sourceId: sourceId ?? this.sourceId,
      contentFingerprint: clearContentFingerprint
          ? null
          : (contentFingerprint ?? this.contentFingerprint),
      title: clearTitle ? null : (title ?? this.title),
      extractedText: extractedText ?? this.extractedText,
      canonicalUrl: clearCanonicalUrl
          ? null
          : (canonicalUrl ?? this.canonicalUrl),
      publishedAt: clearPublishedAt ? null : (publishedAt ?? this.publishedAt),
      retrievedAt: retrievedAt ?? this.retrievedAt,
      spatialRef: clearSpatialRef ? null : (spatialRef ?? this.spatialRef),
      temporalRef: clearTemporalRef ? null : (temporalRef ?? this.temporalRef),
      schemaVersion: schemaVersion ?? this.schemaVersion,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'evidenceId': evidenceId,
      'sourceId': sourceId,
      'contentFingerprint': contentFingerprint,
      'title': title,
      'extractedText': extractedText,
      'canonicalUrl': canonicalUrl,
      'publishedAt': publishedAt?.toIso8601String(),
      'retrievedAt': retrievedAt.toIso8601String(),
      'spatialRef': spatialRef?.toMap(),
      'temporalRef': temporalRef?.toMap(),
      'schemaVersion': schemaVersion,
    };
  }

  factory OSINTEvidence.fromMap(Map<String, dynamic> map) {
    return OSINTEvidence(
      evidenceId: map['evidenceId'] as String? ?? '',
      sourceId: map['sourceId'] as String? ?? '',
      contentFingerprint: map['contentFingerprint'] as String?,
      title: map['title'] as String?,
      extractedText: map['extractedText'] as String? ?? '',
      canonicalUrl: map['canonicalUrl'] as String?,
      publishedAt: map['publishedAt'] != null
          ? DateTime.parse(map['publishedAt'] as String)
          : null,
      retrievedAt: map['retrievedAt'] != null
          ? DateTime.parse(map['retrievedAt'] as String)
          : DateTime.now(),
      spatialRef: map['spatialRef'] != null
          ? OSINTSpatialReference.fromMap(
              map['spatialRef'] as Map<String, dynamic>,
            )
          : null,
      temporalRef: map['temporalRef'] != null
          ? OSINTTemporalReference.fromMap(
              map['temporalRef'] as Map<String, dynamic>,
            )
          : null,
      schemaVersion: map['schemaVersion'] as int? ?? currentSchemaVersion,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OSINTEvidence &&
          runtimeType == other.runtimeType &&
          evidenceId == other.evidenceId &&
          sourceId == other.sourceId &&
          schemaVersion == other.schemaVersion;

  @override
  int get hashCode => Object.hash(evidenceId, sourceId, schemaVersion);
}
