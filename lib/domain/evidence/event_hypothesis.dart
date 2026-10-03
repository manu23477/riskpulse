import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/evidence/event_hypothesis_status.dart';
import 'package:riskpulse/domain/evidence/interpretation_confidence.dart';
import 'package:riskpulse/domain/location/geo_location.dart';

/// Immutable domain representation of a structured candidate representation of a possible real-world
/// hazard/disaster/event inferred from one or more Interpretation Objects.
///
/// Serves as the candidate event hypothesis layer between derived Interpretation Objects and future Event Graph / RiskState reasoning.
@immutable
class EventHypothesis {
  static const int currentSchemaVersion = 1;

  final String hypothesisId;
  final int hypothesisVersion;

  /// Semantic identity
  final String eventType; // e.g. 'ROAD_BLOCKAGE', 'FLASH_FLOOD_FOOTPRINT', 'LANDSLIDE_SLOPE_MOVEMENT'
  final String hazardCategory; // e.g. 'landslide', 'flood', 'cloudburst', 'glof'
  final String title;
  final String description;
  final String eventCode;

  /// Parent interpretations linkage
  final List<String> interpretationIds;
  final String? primaryInterpretationId;

  /// Spatial state
  final GeoLocation? location;
  final Map<String, dynamic>? geometry;
  final Map<String, dynamic>? spatialExtent;
  final List<double>? boundingBox;
  final String? spatialPrecision;
  final double? spatialUncertaintyMeters;

  /// Temporal state
  final DateTime detectedAt;
  final DateTime? estimatedStart;
  final DateTime? estimatedEnd;
  final DateTime? effectiveFrom;
  final DateTime? effectiveTo;
  final String? temporalUncertainty;

  /// Confidence & Uncertainty
  final InterpretationConfidence confidence;
  final String confidenceMethod;
  final String confidenceBasis;
  final double? uncertainty;

  /// Lifecycle status
  final EventHypothesisStatus status;

  /// Provenance & Lineage
  final Map<String, dynamic> provenance;
  final DateTime createdAt;
  final List<String> parentHypothesisIds;
  final List<String> derivedFromInterpretations;
  final String? supersedesHypothesisId;
  final String? supersededByHypothesisId;
  final String? correctionReason;

  /// Administrative context linkage
  final String? administrativeContextReference;

  /// Attributes, warnings & metadata
  final Map<String, dynamic> attributes;
  final List<String> warnings;
  final Map<String, dynamic> metadata;

  EventHypothesis({
    required this.hypothesisId,
    this.hypothesisVersion = 1,
    required this.eventType,
    required this.hazardCategory,
    required this.title,
    required this.description,
    this.eventCode = 'CANDIDATE_EVENT',
    required List<String> interpretationIds,
    this.primaryInterpretationId,
    this.location,
    this.geometry,
    this.spatialExtent,
    this.boundingBox,
    this.spatialPrecision,
    this.spatialUncertaintyMeters,
    DateTime? detectedAt,
    this.estimatedStart,
    this.estimatedEnd,
    this.effectiveFrom,
    this.effectiveTo,
    this.temporalUncertainty,
    required this.confidence,
    this.confidenceMethod = 'MULTI_INTERPRETATION_FUSION',
    this.confidenceBasis = 'Derived from parent interpretation confidence metrics',
    this.uncertainty,
    this.status = EventHypothesisStatus.candidate,
    Map<String, dynamic>? provenance,
    DateTime? createdAt,
    List<String>? parentHypothesisIds,
    List<String>? derivedFromInterpretations,
    this.supersedesHypothesisId,
    this.supersededByHypothesisId,
    this.correctionReason,
    this.administrativeContextReference,
    Map<String, dynamic>? attributes,
    List<String>? warnings,
    Map<String, dynamic>? metadata,
  })  : interpretationIds = List<String>.unmodifiable(interpretationIds),
        detectedAt = detectedAt ?? DateTime.now().toUtc(),
        provenance = Map<String, dynamic>.unmodifiable(provenance ?? const {}),
        createdAt = createdAt ?? DateTime.now().toUtc(),
        parentHypothesisIds = List<String>.unmodifiable(parentHypothesisIds ?? const []),
        derivedFromInterpretations = List<String>.unmodifiable(derivedFromInterpretations ?? interpretationIds),
        attributes = Map<String, dynamic>.unmodifiable(attributes ?? const {}),
        warnings = List<String>.unmodifiable(warnings ?? const []),
        metadata = Map<String, dynamic>.unmodifiable(metadata ?? const {}) {
    if (hypothesisId.trim().isEmpty) {
      throw ArgumentError('EventHypothesis.hypothesisId cannot be empty.');
    }
    if (title.trim().isEmpty) {
      throw ArgumentError('EventHypothesis.title cannot be empty.');
    }
    if (interpretationIds.isEmpty) {
      throw ArgumentError('EventHypothesis requires at least one parent interpretation ID in interpretationIds.');
    }
  }

  /// Creates a copy of this [EventHypothesis] with updated fields.
  EventHypothesis copyWith({
    String? hypothesisId,
    int? hypothesisVersion,
    String? eventType,
    String? hazardCategory,
    String? title,
    String? description,
    String? eventCode,
    List<String>? interpretationIds,
    String? primaryInterpretationId,
    GeoLocation? location,
    Map<String, dynamic>? geometry,
    Map<String, dynamic>? spatialExtent,
    List<double>? boundingBox,
    String? spatialPrecision,
    double? spatialUncertaintyMeters,
    DateTime? detectedAt,
    DateTime? estimatedStart,
    DateTime? estimatedEnd,
    DateTime? effectiveFrom,
    DateTime? effectiveTo,
    String? temporalUncertainty,
    InterpretationConfidence? confidence,
    String? confidenceMethod,
    String? confidenceBasis,
    double? uncertainty,
    EventHypothesisStatus? status,
    Map<String, dynamic>? provenance,
    DateTime? createdAt,
    List<String>? parentHypothesisIds,
    List<String>? derivedFromInterpretations,
    String? supersedesHypothesisId,
    String? supersededByHypothesisId,
    String? correctionReason,
    String? administrativeContextReference,
    Map<String, dynamic>? attributes,
    List<String>? warnings,
    Map<String, dynamic>? metadata,
  }) {
    return EventHypothesis(
      hypothesisId: hypothesisId ?? this.hypothesisId,
      hypothesisVersion: hypothesisVersion ?? this.hypothesisVersion,
      eventType: eventType ?? this.eventType,
      hazardCategory: hazardCategory ?? this.hazardCategory,
      title: title ?? this.title,
      description: description ?? this.description,
      eventCode: eventCode ?? this.eventCode,
      interpretationIds: interpretationIds ?? this.interpretationIds,
      primaryInterpretationId: primaryInterpretationId ?? this.primaryInterpretationId,
      location: location ?? this.location,
      geometry: geometry ?? this.geometry,
      spatialExtent: spatialExtent ?? this.spatialExtent,
      boundingBox: boundingBox ?? this.boundingBox,
      spatialPrecision: spatialPrecision ?? this.spatialPrecision,
      spatialUncertaintyMeters: spatialUncertaintyMeters ?? this.spatialUncertaintyMeters,
      detectedAt: detectedAt ?? this.detectedAt,
      estimatedStart: estimatedStart ?? this.estimatedStart,
      estimatedEnd: estimatedEnd ?? this.estimatedEnd,
      effectiveFrom: effectiveFrom ?? this.effectiveFrom,
      effectiveTo: effectiveTo ?? this.effectiveTo,
      temporalUncertainty: temporalUncertainty ?? this.temporalUncertainty,
      confidence: confidence ?? this.confidence,
      confidenceMethod: confidenceMethod ?? this.confidenceMethod,
      confidenceBasis: confidenceBasis ?? this.confidenceBasis,
      uncertainty: uncertainty ?? this.uncertainty,
      status: status ?? this.status,
      provenance: provenance ?? this.provenance,
      createdAt: createdAt ?? this.createdAt,
      parentHypothesisIds: parentHypothesisIds ?? this.parentHypothesisIds,
      derivedFromInterpretations: derivedFromInterpretations ?? this.derivedFromInterpretations,
      supersedesHypothesisId: supersedesHypothesisId ?? this.supersedesHypothesisId,
      supersededByHypothesisId: supersededByHypothesisId ?? this.supersededByHypothesisId,
      correctionReason: correctionReason ?? this.correctionReason,
      administrativeContextReference: administrativeContextReference ?? this.administrativeContextReference,
      attributes: attributes ?? this.attributes,
      warnings: warnings ?? this.warnings,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hypothesisId': hypothesisId,
      'hypothesisVersion': hypothesisVersion,
      'eventType': eventType,
      'hazardCategory': hazardCategory,
      'title': title,
      'description': description,
      'eventCode': eventCode,
      'interpretationIds': interpretationIds,
      'primaryInterpretationId': primaryInterpretationId,
      'latitude': location?.latitude,
      'longitude': location?.longitude,
      'geometry': geometry,
      'spatialExtent': spatialExtent,
      'boundingBox': boundingBox,
      'spatialPrecision': spatialPrecision,
      'spatialUncertaintyMeters': spatialUncertaintyMeters,
      'detectedAt': detectedAt.toIso8601String(),
      'estimatedStart': estimatedStart?.toIso8601String(),
      'estimatedEnd': estimatedEnd?.toIso8601String(),
      'effectiveFrom': effectiveFrom?.toIso8601String(),
      'effectiveTo': effectiveTo?.toIso8601String(),
      'temporalUncertainty': temporalUncertainty,
      'confidence': confidence.toJson(),
      'confidenceMethod': confidenceMethod,
      'confidenceBasis': confidenceBasis,
      'uncertainty': uncertainty,
      'status': status.name,
      'provenance': provenance,
      'createdAt': createdAt.toIso8601String(),
      'parentHypothesisIds': parentHypothesisIds,
      'derivedFromInterpretations': derivedFromInterpretations,
      'supersedesHypothesisId': supersedesHypothesisId,
      'supersededByHypothesisId': supersededByHypothesisId,
      'correctionReason': correctionReason,
      'administrativeContextReference': administrativeContextReference,
      'attributes': attributes,
      'warnings': warnings,
      'metadata': metadata,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventHypothesis &&
          runtimeType == other.runtimeType &&
          hypothesisId == other.hypothesisId &&
          hypothesisVersion == other.hypothesisVersion &&
          status == other.status;

  @override
  int get hashCode => Object.hash(hypothesisId, hypothesisVersion, status);

  @override
  String toString() {
    return 'EventHypothesis(id: $hypothesisId, v$hypothesisVersion, type: $eventType, cat: $hazardCategory, status: ${status.name}, conf: ${confidence.value})';
  }
}
