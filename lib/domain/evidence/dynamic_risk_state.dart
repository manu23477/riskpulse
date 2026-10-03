import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/evidence/exposure_condition.dart';
import 'package:riskpulse/domain/evidence/hazard_condition.dart';
import 'package:riskpulse/domain/evidence/impact_condition.dart';
import 'package:riskpulse/domain/evidence/risk_state_status.dart';
import 'package:riskpulse/domain/evidence/trend_direction.dart';
import 'package:riskpulse/domain/evidence/vulnerability_condition.dart';

/// Immutable domain model representing the versioned, provenance-preserving Dynamic Risk State for an EventHypothesis.
///
/// Integrates SpatialState, AdministrativeState, HazardCondition, ExposureCondition, VulnerabilityCondition,
/// and Evidence Lineage without mutating prior RiskState snapshots.
@immutable
class DynamicRiskState {
  static const int currentSchemaVersion = 1;

  final String riskStateId;
  final String eventHypothesisId;
  final int hypothesisVersion;
  final int riskStateVersion;

  /// Spatial & Administrative State Links
  final String spatialStateId;
  final int spatialStateVersion;
  final String? administrativeStateId;
  final int? administrativeStateVersion;

  /// Temporal Semantics
  final DateTime? observedAt;
  final DateTime calculatedAt;
  final DateTime? effectiveFrom;
  final DateTime? effectiveTo;

  /// Structured Conditions (Semantic Separation)
  final HazardCondition hazardCondition;
  final ExposureCondition exposureCondition;
  final VulnerabilityCondition vulnerabilityCondition;
  final ImpactCondition impactCondition;

  /// Evidence Lineage
  final List<String> supportingEvidenceIds;
  final List<String> contradictingEvidenceIds;
  final List<String> interpretationIds;

  /// Risk Assessment
  final String riskAssessmentStatus;
  final String? riskLevel; // 'HIGH', 'MODERATE', 'LOW', 'ELEVATED', 'UNCERTAIN'
  final double? riskScore; // 0.0 to 1.0 (Optional / scientifically calibrated)
  final String riskMethod;

  /// Uncertainty & Confidence
  final String? uncertaintyDescriptor;
  final double? confidenceScore; // 0.0 to 1.0
  final String? confidenceBasis;
  final String? confidenceMethod;

  /// Trend & Lineage
  final String? previousRiskStateId;
  final String? supersedesRiskStateId;
  final TrendDirection trendDirection;
  final String? changeReason;

  /// Status, Provenance & Metadata
  final RiskStateStatus status;
  final Map<String, dynamic> provenance;
  final List<String> warnings;
  final Map<String, dynamic> attributes;
  final Map<String, dynamic> metadata;

  DynamicRiskState({
    required this.riskStateId,
    required this.eventHypothesisId,
    this.hypothesisVersion = 1,
    this.riskStateVersion = 1,
    required this.spatialStateId,
    this.spatialStateVersion = 1,
    this.administrativeStateId,
    this.administrativeStateVersion,
    this.observedAt,
    DateTime? calculatedAt,
    this.effectiveFrom,
    this.effectiveTo,
    required this.hazardCondition,
    this.exposureCondition = const ExposureCondition(),
    this.vulnerabilityCondition = const VulnerabilityCondition(),
    this.impactCondition = const ImpactCondition(),
    List<String>? supportingEvidenceIds,
    List<String>? contradictingEvidenceIds,
    List<String>? interpretationIds,
    this.riskAssessmentStatus = 'EVALUATED',
    this.riskLevel = 'MODERATE',
    this.riskScore,
    this.riskMethod = 'STRUCTURED_MULTI_CONDITION_STATE_RESOLVER',
    this.uncertaintyDescriptor,
    this.confidenceScore = 0.80,
    this.confidenceBasis,
    this.confidenceMethod,
    this.previousRiskStateId,
    this.supersedesRiskStateId,
    this.trendDirection = TrendDirection.stable,
    this.changeReason,
    this.status = RiskStateStatus.active,
    Map<String, dynamic>? provenance,
    List<String>? warnings,
    Map<String, dynamic>? attributes,
    Map<String, dynamic>? metadata,
  })  : calculatedAt = calculatedAt ?? DateTime.now().toUtc(),
        supportingEvidenceIds = List<String>.unmodifiable(supportingEvidenceIds ?? const []),
        contradictingEvidenceIds = List<String>.unmodifiable(contradictingEvidenceIds ?? const []),
        interpretationIds = List<String>.unmodifiable(interpretationIds ?? const []),
        provenance = Map<String, dynamic>.unmodifiable(provenance ?? const {}),
        warnings = List<String>.unmodifiable(warnings ?? const []),
        attributes = Map<String, dynamic>.unmodifiable(attributes ?? const {}),
        metadata = Map<String, dynamic>.unmodifiable(metadata ?? const {}) {
    if (riskStateId.trim().isEmpty) {
      throw ArgumentError('DynamicRiskState.riskStateId cannot be empty.');
    }
    if (eventHypothesisId.trim().isEmpty) {
      throw ArgumentError('DynamicRiskState.eventHypothesisId cannot be empty.');
    }
    if (spatialStateId.trim().isEmpty) {
      throw ArgumentError('DynamicRiskState.spatialStateId cannot be empty.');
    }
    if (confidenceScore != null && (confidenceScore! < 0.0 || confidenceScore! > 1.0)) {
      throw ArgumentError('confidenceScore must be between 0.0 and 1.0.');
    }
    if (riskScore != null && (riskScore! < 0.0 || riskScore! > 1.0)) {
      throw ArgumentError('riskScore must be between 0.0 and 1.0.');
    }
  }

  /// Creates a copy of this [DynamicRiskState] with updated fields.
  DynamicRiskState copyWith({
    String? riskStateId,
    String? eventHypothesisId,
    int? hypothesisVersion,
    int? riskStateVersion,
    String? spatialStateId,
    int? spatialStateVersion,
    String? administrativeStateId,
    int? administrativeStateVersion,
    DateTime? observedAt,
    DateTime? calculatedAt,
    DateTime? effectiveFrom,
    DateTime? effectiveTo,
    HazardCondition? hazardCondition,
    ExposureCondition? exposureCondition,
    VulnerabilityCondition? vulnerabilityCondition,
    ImpactCondition? impactCondition,
    List<String>? supportingEvidenceIds,
    List<String>? contradictingEvidenceIds,
    List<String>? interpretationIds,
    String? riskAssessmentStatus,
    String? riskLevel,
    double? riskScore,
    String? riskMethod,
    String? uncertaintyDescriptor,
    double? confidenceScore,
    String? confidenceBasis,
    String? confidenceMethod,
    String? previousRiskStateId,
    String? supersedesRiskStateId,
    TrendDirection? trendDirection,
    String? changeReason,
    RiskStateStatus? status,
    Map<String, dynamic>? provenance,
    List<String>? warnings,
    Map<String, dynamic>? attributes,
    Map<String, dynamic>? metadata,
  }) {
    return DynamicRiskState(
      riskStateId: riskStateId ?? this.riskStateId,
      eventHypothesisId: eventHypothesisId ?? this.eventHypothesisId,
      hypothesisVersion: hypothesisVersion ?? this.hypothesisVersion,
      riskStateVersion: riskStateVersion ?? this.riskStateVersion,
      spatialStateId: spatialStateId ?? this.spatialStateId,
      spatialStateVersion: spatialStateVersion ?? this.spatialStateVersion,
      administrativeStateId: administrativeStateId ?? this.administrativeStateId,
      administrativeStateVersion: administrativeStateVersion ?? this.administrativeStateVersion,
      observedAt: observedAt ?? this.observedAt,
      calculatedAt: calculatedAt ?? this.calculatedAt,
      effectiveFrom: effectiveFrom ?? this.effectiveFrom,
      effectiveTo: effectiveTo ?? this.effectiveTo,
      hazardCondition: hazardCondition ?? this.hazardCondition,
      exposureCondition: exposureCondition ?? this.exposureCondition,
      vulnerabilityCondition: vulnerabilityCondition ?? this.vulnerabilityCondition,
      impactCondition: impactCondition ?? this.impactCondition,
      supportingEvidenceIds: supportingEvidenceIds ?? this.supportingEvidenceIds,
      contradictingEvidenceIds: contradictingEvidenceIds ?? this.contradictingEvidenceIds,
      interpretationIds: interpretationIds ?? this.interpretationIds,
      riskAssessmentStatus: riskAssessmentStatus ?? this.riskAssessmentStatus,
      riskLevel: riskLevel ?? this.riskLevel,
      riskScore: riskScore ?? this.riskScore,
      riskMethod: riskMethod ?? this.riskMethod,
      uncertaintyDescriptor: uncertaintyDescriptor ?? this.uncertaintyDescriptor,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      confidenceBasis: confidenceBasis ?? this.confidenceBasis,
      confidenceMethod: confidenceMethod ?? this.confidenceMethod,
      previousRiskStateId: previousRiskStateId ?? this.previousRiskStateId,
      supersedesRiskStateId: supersedesRiskStateId ?? this.supersedesRiskStateId,
      trendDirection: trendDirection ?? this.trendDirection,
      changeReason: changeReason ?? this.changeReason,
      status: status ?? this.status,
      provenance: provenance ?? this.provenance,
      warnings: warnings ?? this.warnings,
      attributes: attributes ?? this.attributes,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'riskStateId': riskStateId,
      'eventHypothesisId': eventHypothesisId,
      'hypothesisVersion': hypothesisVersion,
      'riskStateVersion': riskStateVersion,
      'spatialStateId': spatialStateId,
      'spatialStateVersion': spatialStateVersion,
      'administrativeStateId': administrativeStateId,
      'administrativeStateVersion': administrativeStateVersion,
      'observedAt': observedAt?.toIso8601String(),
      'calculatedAt': calculatedAt.toIso8601String(),
      'effectiveFrom': effectiveFrom?.toIso8601String(),
      'effectiveTo': effectiveTo?.toIso8601String(),
      'hazardCondition': hazardCondition.toJson(),
      'exposureCondition': exposureCondition.toJson(),
      'vulnerabilityCondition': vulnerabilityCondition.toJson(),
      'impactCondition': impactCondition.toJson(),
      'supportingEvidenceIds': supportingEvidenceIds,
      'contradictingEvidenceIds': contradictingEvidenceIds,
      'interpretationIds': interpretationIds,
      'riskAssessmentStatus': riskAssessmentStatus,
      'riskLevel': riskLevel,
      'riskScore': riskScore,
      'riskMethod': riskMethod,
      'uncertaintyDescriptor': uncertaintyDescriptor,
      'confidenceScore': confidenceScore,
      'confidenceBasis': confidenceBasis,
      'confidenceMethod': confidenceMethod,
      'previousRiskStateId': previousRiskStateId,
      'supersedesRiskStateId': supersedesRiskStateId,
      'trendDirection': trendDirection.name,
      'changeReason': changeReason,
      'status': status.name,
      'provenance': provenance,
      'warnings': warnings,
      'attributes': attributes,
      'metadata': metadata,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DynamicRiskState &&
          runtimeType == other.runtimeType &&
          riskStateId == other.riskStateId &&
          riskStateVersion == other.riskStateVersion &&
          status == other.status;

  @override
  int get hashCode => Object.hash(riskStateId, riskStateVersion, status);

  @override
  String toString() {
    return 'DynamicRiskState(id: $riskStateId, hyp: $eventHypothesisId, v$riskStateVersion, lvl: $riskLevel, trend: ${trendDirection.name}, status: ${status.name})';
  }
}
