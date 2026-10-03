import 'package:flutter/foundation.dart';

/// Structured provenance lineage tracking the exact retrieval and transformation path of an Evidence Object.
@immutable
class EvidenceProvenance {
  final String sourceSystem;
  final String sourceId;
  final String? publisher;
  final String? sourceUri;
  final DateTime acquisitionTimestamp;
  final DateTime? publicationTimestamp;
  final DateTime ingestionTimestamp;
  final String ingestionMethod;
  final String originalFormat;
  final List<String> transformationHistory;
  final String? parentEvidenceId;
  final String? contentHash;

  EvidenceProvenance({
    required this.sourceSystem,
    required this.sourceId,
    this.publisher,
    this.sourceUri,
    DateTime? acquisitionTimestamp,
    this.publicationTimestamp,
    DateTime? ingestionTimestamp,
    this.ingestionMethod = 'AUTOMATED_INGESTION_PIPELINE',
    this.originalFormat = 'GeoJSON / REST Payload',
    List<String>? transformationHistory,
    this.parentEvidenceId,
    this.contentHash,
  })  : acquisitionTimestamp = acquisitionTimestamp ?? DateTime.now().toUtc(),
        ingestionTimestamp = ingestionTimestamp ?? DateTime.now().toUtc(),
        transformationHistory = List<String>.unmodifiable(transformationHistory ?? const []);

  Map<String, dynamic> toJson() {
    return {
      'sourceSystem': sourceSystem,
      'sourceId': sourceId,
      'publisher': publisher,
      'sourceUri': sourceUri,
      'acquisitionTimestamp': acquisitionTimestamp.toIso8601String(),
      'publicationTimestamp': publicationTimestamp?.toIso8601String(),
      'ingestionTimestamp': ingestionTimestamp.toIso8601String(),
      'ingestionMethod': ingestionMethod,
      'originalFormat': originalFormat,
      'transformationHistory': transformationHistory,
      'parentEvidenceId': parentEvidenceId,
      'contentHash': contentHash,
    };
  }

  factory EvidenceProvenance.fromJson(Map<String, dynamic> json) {
    return EvidenceProvenance(
      sourceSystem: json['sourceSystem'] as String? ?? 'UNKNOWN',
      sourceId: json['sourceId'] as String? ?? 'UNKNOWN',
      publisher: json['publisher'] as String?,
      sourceUri: json['sourceUri'] as String?,
      acquisitionTimestamp: json['acquisitionTimestamp'] != null
          ? DateTime.parse(json['acquisitionTimestamp'] as String)
          : DateTime.now().toUtc(),
      publicationTimestamp: json['publicationTimestamp'] != null
          ? DateTime.parse(json['publicationTimestamp'] as String)
          : null,
      ingestionTimestamp: json['ingestionTimestamp'] != null
          ? DateTime.parse(json['ingestionTimestamp'] as String)
          : DateTime.now().toUtc(),
      ingestionMethod: json['ingestionMethod'] as String? ?? 'AUTOMATED_INGESTION_PIPELINE',
      originalFormat: json['originalFormat'] as String? ?? 'GeoJSON / REST Payload',
      transformationHistory: (json['transformationHistory'] as List<dynamic>?)?.cast<String>() ?? const [],
      parentEvidenceId: json['parentEvidenceId'] as String?,
      contentHash: json['contentHash'] as String?,
    );
  }
}
