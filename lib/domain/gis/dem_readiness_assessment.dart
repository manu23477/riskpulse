import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/gis/analytical_step.dart';
import 'package:riskpulse/data/services/dem_validation_service.dart';

/// Scientific readiness status of a DEM for research analysis.
enum DemReadinessStatus {
  /// DEM is structurally valid and data quality is assessed.
  structurallyValid,

  /// DEM statistics are computed and data availability is fully assessed.
  dataQualityAssessed,

  /// DEM explicitly meets an authoritative, versioned research policy threshold.
  readyForAnalysis,

  /// DEM contains partial coverage or NoData cells requiring explicit researcher review before analysis.
  requiresResearcherReview,

  /// Data quality is calculated, but no authoritative scientific acceptance threshold is established in RiskPulse governance.
  notEstablished,

  /// DEM is structurally invalid or lies completely outside the study area AOI.
  rejected,
}

/// Immutable domain container representing a scientific DEM readiness assessment.
///
/// SCIENTIFIC GOVERNANCE:
/// 1. Measured data quality properties (footprint %, valid cell %, NoData %) are kept strictly separate from scientific acceptance decisions.
/// 2. When no authoritative policy threshold exists in RiskPulse governance, [isScientificThresholdEstablished] MUST be false.
/// 3. NO invented scientific acceptance thresholds.
@immutable
class DemReadinessAssessment {
  static const int currentSchemaVersion = 1;

  final String assessmentId;
  final String policyVersion;
  final String productContext; // 'general_terrain', 'hydrological_analysis', 'watershed_delineation'
  final DemReadinessStatus status;
  final DemValidationResult validationResult;
  final bool isScientificThresholdEstablished;
  final String rationale;
  final List<String> warnings;
  final AnalyticalStep provenanceStep;
  final Map<String, dynamic> metadata;
  final int schemaVersion;

  const DemReadinessAssessment({
    required this.assessmentId,
    this.policyVersion = '4K.8.14-v1',
    this.productContext = 'general_terrain',
    required this.status,
    required this.validationResult,
    this.isScientificThresholdEstablished = false,
    required this.rationale,
    this.warnings = const [],
    required this.provenanceStep,
    this.metadata = const {},
    this.schemaVersion = currentSchemaVersion,
  });

  bool get isRejected => status == DemReadinessStatus.rejected;
  bool get isReady => status == DemReadinessStatus.readyForAnalysis;
  bool get isNotEstablished => status == DemReadinessStatus.notEstablished;
  bool get requiresReview => status == DemReadinessStatus.requiresResearcherReview;

  Map<String, dynamic> toMap() {
    return {
      'assessmentId': assessmentId,
      'policyVersion': policyVersion,
      'productContext': productContext,
      'status': status.name,
      'isScientificThresholdEstablished': isScientificThresholdEstablished,
      'footprintCoveragePercentage': validationResult.footprintCoveragePercentage,
      'validCellPercentage': validationResult.validCellPercentage,
      'noDataPercentage': validationResult.noDataPercentage,
      'rationale': rationale,
      'schemaVersion': schemaVersion,
      'metadata': metadata,
    };
  }
}
