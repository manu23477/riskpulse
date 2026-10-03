import 'package:flutter/foundation.dart';

/// Immutable reference pointing to raw media, payload document, satellite scene, or external API record.
@immutable
class EvidenceContentReference {
  final String referenceType; // 'URL', 'DOCUMENT', 'IMAGE', 'SATELLITE_SCENE', 'FILE', 'API_PAYLOAD'
  final String uri;
  final String? mediaType;
  final String? contentHash; // SHA-256
  final Map<String, dynamic> metadata;

  EvidenceContentReference({
    required this.referenceType,
    required this.uri,
    this.mediaType,
    this.contentHash,
    Map<String, dynamic>? metadata,
  }) : metadata = Map<String, dynamic>.unmodifiable(metadata ?? const {});

  Map<String, dynamic> toJson() {
    return {
      'referenceType': referenceType,
      'uri': uri,
      'mediaType': mediaType,
      'contentHash': contentHash,
      'metadata': metadata,
    };
  }

  factory EvidenceContentReference.fromJson(Map<String, dynamic> json) {
    return EvidenceContentReference(
      referenceType: json['referenceType'] as String? ?? 'URI',
      uri: json['uri'] as String? ?? '',
      mediaType: json['mediaType'] as String?,
      contentHash: json['contentHash'] as String?,
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? const {},
    );
  }
}
