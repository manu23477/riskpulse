import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/evidence/evidence_content_reference.dart';
import 'package:riskpulse/domain/evidence/evidence_provenance.dart';
import 'package:riskpulse/domain/evidence/evidence_source.dart';
import 'package:riskpulse/domain/evidence/evidence_status.dart';
import 'package:riskpulse/domain/evidence/evidence_type.dart';
import 'package:riskpulse/domain/location/geo_location.dart';

/// Normalized, immutable domain representation of a factual observation or retrieved data artifact.
///
/// Keeps raw evidence strictly separated from downstream interpretation and event hypothesis reasoning.
@immutable
class EvidenceObject {
  static const int currentSchemaVersion = 1;

  final String evidenceId;
  final String observationId;
  final EvidenceType evidenceType;
  final EvidenceSource source;
  final String sourceId;
  final String? sourceUri;
  final String? sourcePublisher;
  final String sourceName;

  /// Timestamps with distinct semantic meanings
  final DateTime? observedAt;
  final DateTime? publishedAt;
  final DateTime receivedAt;
  final DateTime ingestedAt;
  final DateTime? effectiveFrom;
  final DateTime? effectiveTo;

  /// Location representation
  final String locationType; // 'none', 'point', 'polygon', 'line', 'boundingBox', 'textual'
  final String? rawLocationDescription;
  final GeoLocation? location;
  final Map<String, dynamic>? geometry;

  /// Content, hash & integrity
  final EvidenceContentReference? contentReference;
  final String? contentHash; // SHA-256
  final String description;
  final Map<String, dynamic> attributes;
  final EvidenceProvenance provenance;
  final EvidenceIntegrityStatus integrityStatus;
  final EvidenceStatus status;

  /// Versioning & Lineage
  final int evidenceVersion;
  final String? supersedesEvidenceId;
  final String? supersededByEvidenceId;
  final String? parentEvidenceId;
  final String? derivedFrom;
  final String? processingMethod;
  final String? processingVersion;

  /// Event & Administrative Linkage Contracts
  final List<String> relatedEventIds;
  final String? administrativeContextReference;

  /// Model Output vs Direct Observation distinction
  final bool isModelOutput;
  final String? modelName;
  final String? modelVersion;
  final List<String> inputEvidenceIds;
  final Map<String, dynamic> uncertaintyMetadata;

  EvidenceObject({
    required this.evidenceId,
    required this.observationId,
    required this.evidenceType,
    required this.source,
    required this.sourceId,
    this.sourceUri,
    this.sourcePublisher,
    required this.sourceName,
    this.observedAt,
    this.publishedAt,
    DateTime? receivedAt,
    DateTime? ingestedAt,
    this.effectiveFrom,
    this.effectiveTo,
    this.locationType = 'none',
    this.rawLocationDescription,
    this.location,
    this.geometry,
    this.contentReference,
    this.contentHash,
    required this.description,
    Map<String, dynamic>? attributes,
    required this.provenance,
    this.integrityStatus = EvidenceIntegrityStatus.contentHashUnavailable,
    this.status = EvidenceStatus.received,
    this.evidenceVersion = 1,
    this.supersedesEvidenceId,
    this.supersededByEvidenceId,
    this.parentEvidenceId,
    this.derivedFrom,
    this.processingMethod,
    this.processingVersion,
    List<String>? relatedEventIds,
    this.administrativeContextReference,
    this.isModelOutput = false,
    this.modelName,
    this.modelVersion,
    List<String>? inputEvidenceIds,
    Map<String, dynamic>? uncertaintyMetadata,
  })  : receivedAt = receivedAt ?? DateTime.now().toUtc(),
        ingestedAt = ingestedAt ?? DateTime.now().toUtc(),
        attributes = Map<String, dynamic>.unmodifiable(attributes ?? const {}),
        relatedEventIds = List<String>.unmodifiable(relatedEventIds ?? const []),
        inputEvidenceIds = List<String>.unmodifiable(inputEvidenceIds ?? const []),
        uncertaintyMetadata = Map<String, dynamic>.unmodifiable(uncertaintyMetadata ?? const {}) {
    if (evidenceId.trim().isEmpty) {
      throw ArgumentError('EvidenceObject.evidenceId cannot be empty.');
    }
    if (observationId.trim().isEmpty) {
      throw ArgumentError('EvidenceObject.observationId cannot be empty.');
    }
  }

  /// Creates a copy of this [EvidenceObject] with updated fields.
  EvidenceObject copyWith({
    String? evidenceId,
    String? observationId,
    EvidenceType? evidenceType,
    EvidenceSource? source,
    String? sourceId,
    String? sourceUri,
    String? sourcePublisher,
    String? sourceName,
    DateTime? observedAt,
    DateTime? publishedAt,
    DateTime? receivedAt,
    DateTime? ingestedAt,
    DateTime? effectiveFrom,
    DateTime? effectiveTo,
    String? locationType,
    String? rawLocationDescription,
    GeoLocation? location,
    Map<String, dynamic>? geometry,
    EvidenceContentReference? contentReference,
    String? contentHash,
    String? description,
    Map<String, dynamic>? attributes,
    EvidenceProvenance? provenance,
    EvidenceIntegrityStatus? integrityStatus,
    EvidenceStatus? status,
    int? evidenceVersion,
    String? supersedesEvidenceId,
    String? supersededByEvidenceId,
    String? parentEvidenceId,
    String? derivedFrom,
    String? processingMethod,
    String? processingVersion,
    List<String>? relatedEventIds,
    String? administrativeContextReference,
    bool? isModelOutput,
    String? modelName,
    String? modelVersion,
    List<String>? inputEvidenceIds,
    Map<String, dynamic>? uncertaintyMetadata,
  }) {
    return EvidenceObject(
      evidenceId: evidenceId ?? this.evidenceId,
      observationId: observationId ?? this.observationId,
      evidenceType: evidenceType ?? this.evidenceType,
      source: source ?? this.source,
      sourceId: sourceId ?? this.sourceId,
      sourceUri: sourceUri ?? this.sourceUri,
      sourcePublisher: sourcePublisher ?? this.sourcePublisher,
      sourceName: sourceName ?? this.sourceName,
      observedAt: observedAt ?? this.observedAt,
      publishedAt: publishedAt ?? this.publishedAt,
      receivedAt: receivedAt ?? this.receivedAt,
      ingestedAt: ingestedAt ?? this.ingestedAt,
      effectiveFrom: effectiveFrom ?? this.effectiveFrom,
      effectiveTo: effectiveTo ?? this.effectiveTo,
      locationType: locationType ?? this.locationType,
      rawLocationDescription: rawLocationDescription ?? this.rawLocationDescription,
      location: location ?? this.location,
      geometry: geometry ?? this.geometry,
      contentReference: contentReference ?? this.contentReference,
      contentHash: contentHash ?? this.contentHash,
      description: description ?? this.description,
      attributes: attributes ?? this.attributes,
      provenance: provenance ?? this.provenance,
      integrityStatus: integrityStatus ?? this.integrityStatus,
      status: status ?? this.status,
      evidenceVersion: evidenceVersion ?? this.evidenceVersion,
      supersedesEvidenceId: supersedesEvidenceId ?? this.supersedesEvidenceId,
      supersededByEvidenceId: supersededByEvidenceId ?? this.supersededByEvidenceId,
      parentEvidenceId: parentEvidenceId ?? this.parentEvidenceId,
      derivedFrom: derivedFrom ?? this.derivedFrom,
      processingMethod: processingMethod ?? this.processingMethod,
      processingVersion: processingVersion ?? this.processingVersion,
      relatedEventIds: relatedEventIds ?? this.relatedEventIds,
      administrativeContextReference: administrativeContextReference ?? this.administrativeContextReference,
      isModelOutput: isModelOutput ?? this.isModelOutput,
      modelName: modelName ?? this.modelName,
      modelVersion: modelVersion ?? this.modelVersion,
      inputEvidenceIds: inputEvidenceIds ?? this.inputEvidenceIds,
      uncertaintyMetadata: uncertaintyMetadata ?? this.uncertaintyMetadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'evidenceId': evidenceId,
      'observationId': observationId,
      'evidenceType': evidenceType.name,
      'source': source.toJson(),
      'sourceId': sourceId,
      'sourceUri': sourceUri,
      'sourcePublisher': sourcePublisher,
      'sourceName': sourceName,
      'observedAt': observedAt?.toIso8601String(),
      'publishedAt': publishedAt?.toIso8601String(),
      'receivedAt': receivedAt.toIso8601String(),
      'ingestedAt': ingestedAt.toIso8601String(),
      'effectiveFrom': effectiveFrom?.toIso8601String(),
      'effectiveTo': effectiveTo?.toIso8601String(),
      'locationType': locationType,
      'rawLocationDescription': rawLocationDescription,
      'latitude': location?.latitude,
      'longitude': location?.longitude,
      'geometry': geometry,
      'contentReference': contentReference?.toJson(),
      'contentHash': contentHash,
      'description': description,
      'attributes': attributes,
      'provenance': provenance.toJson(),
      'integrityStatus': integrityStatus.name,
      'status': status.name,
      'evidenceVersion': evidenceVersion,
      'supersedesEvidenceId': supersedesEvidenceId,
      'supersededByEvidenceId': supersededByEvidenceId,
      'parentEvidenceId': parentEvidenceId,
      'derivedFrom': derivedFrom,
      'processingMethod': processingMethod,
      'processingVersion': processingVersion,
      'relatedEventIds': relatedEventIds,
      'administrativeContextReference': administrativeContextReference,
      'isModelOutput': isModelOutput,
      'modelName': modelName,
      'modelVersion': modelVersion,
      'inputEvidenceIds': inputEvidenceIds,
      'uncertaintyMetadata': uncertaintyMetadata,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EvidenceObject &&
          runtimeType == other.runtimeType &&
          evidenceId == other.evidenceId &&
          evidenceVersion == other.evidenceVersion &&
          contentHash == other.contentHash;

  @override
  int get hashCode => Object.hash(evidenceId, evidenceVersion, contentHash);

  @override
  String toString() {
    return 'EvidenceObject(id: $evidenceId, obs: $observationId, type: ${evidenceType.name}, status: ${status.name}, hash: ${contentHash ?? "NONE"})';
  }
}
