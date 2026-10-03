import 'package:flutter/foundation.dart';

/// Immutable source identity model preserving authoritative publishing metadata.
@immutable
class EvidenceSource {
  final String sourceSystem;
  final String sourceId;
  final String sourceName;
  final String? sourcePublisher;
  final String? sourceUri;
  final String sourceType;
  final Map<String, dynamic> metadata;

  EvidenceSource({
    required this.sourceSystem,
    required this.sourceId,
    required this.sourceName,
    this.sourcePublisher,
    this.sourceUri,
    this.sourceType = 'DIRECT_OBSERVATION',
    Map<String, dynamic>? metadata,
  }) : metadata = Map<String, dynamic>.unmodifiable(metadata ?? const {}) {
    if (sourceSystem.trim().isEmpty) {
      throw ArgumentError('EvidenceSource.sourceSystem cannot be empty.');
    }
    if (sourceId.trim().isEmpty) {
      throw ArgumentError('EvidenceSource.sourceId cannot be empty.');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'sourceSystem': sourceSystem,
      'sourceId': sourceId,
      'sourceName': sourceName,
      'sourcePublisher': sourcePublisher,
      'sourceUri': sourceUri,
      'sourceType': sourceType,
      'metadata': metadata,
    };
  }

  factory EvidenceSource.fromJson(Map<String, dynamic> json) {
    return EvidenceSource(
      sourceSystem: json['sourceSystem'] as String? ?? 'UNKNOWN',
      sourceId: json['sourceId'] as String? ?? 'UNKNOWN',
      sourceName: json['sourceName'] as String? ?? 'Unknown Source',
      sourcePublisher: json['sourcePublisher'] as String?,
      sourceUri: json['sourceUri'] as String?,
      sourceType: json['sourceType'] as String? ?? 'DIRECT_OBSERVATION',
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? const {},
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EvidenceSource &&
          runtimeType == other.runtimeType &&
          sourceSystem == other.sourceSystem &&
          sourceId == other.sourceId;

  @override
  int get hashCode => Object.hash(sourceSystem, sourceId);
}
