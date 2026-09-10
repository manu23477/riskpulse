import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/gis/analytical_step.dart';
import 'package:riskpulse/domain/forecasting/forecast_horizon.dart';
import 'package:riskpulse/domain/forecasting/forecast_uncertainty.dart';
import 'package:riskpulse/domain/forecasting/exposure_element.dart';
import 'package:riskpulse/domain/forecasting/vulnerability_profile.dart';
import 'package:riskpulse/domain/forecasting/validation_dataset_record.dart';

/// Immutable domain contract representing an estimated or observed impact resulting from Hazard + Exposure + Vulnerability interaction.
@immutable
class ImpactAssessment {
  static const int currentSchemaVersion = 1;

  final String assessmentId;
  final String hazardId;
  final String hazardCategory;
  final String hazardSourceType; // 'observed', 'forecast_derived', 'scenario_derived', 'hypothetical'
  final ExposureCategory exposureCategory;
  final String exposureDatasetId;
  final List<String> exposedElementIds;
  final double totalExposedQuantity;
  final String quantityUnit;
  final double? estimatedImpactScore;
  final String impactSeverityLabel;
  final VulnerabilityProfile? vulnerabilityProfile;
  final ForecastHorizon horizon;
  final GeoLocation location;
  final ForecastUncertainty uncertainty;
  final ScientificValidationStatus scientificStatus;
  final String economicImpactEstimate;
  final List<AnalyticalStep> provenanceSteps;
  final Map<String, dynamic> metadata;
  final int schemaVersion;

  ImpactAssessment({
    required this.assessmentId,
    required this.hazardId,
    required this.hazardCategory,
    this.hazardSourceType = 'forecast_derived',
    required this.exposureCategory,
    required this.exposureDatasetId,
    this.exposedElementIds = const [],
    required this.totalExposedQuantity,
    required this.quantityUnit,
    this.estimatedImpactScore,
    this.impactSeverityLabel = 'Low',
    this.vulnerabilityProfile,
    required this.horizon,
    required this.location,
    required this.uncertainty,
    this.scientificStatus = ScientificValidationStatus.provisionalSoftwareOnly,
    this.economicImpactEstimate = 'NOT AVAILABLE',
    this.provenanceSteps = const [],
    this.metadata = const {},
    this.schemaVersion = currentSchemaVersion,
  }) {
    if (assessmentId.trim().isEmpty) {
      throw ArgumentError('assessmentId cannot be empty.');
    }
    if (hazardId.trim().isEmpty) {
      throw ArgumentError('hazardId cannot be empty.');
    }
    if (hazardCategory.trim().isEmpty) {
      throw ArgumentError('hazardCategory cannot be empty.');
    }
    if (quantityUnit.trim().isEmpty) {
      throw ArgumentError('quantityUnit cannot be empty.');
    }
    if (totalExposedQuantity.isNaN || totalExposedQuantity < 0.0) {
      throw ArgumentError('totalExposedQuantity cannot be negative or NaN.');
    }
    if (estimatedImpactScore != null &&
        (estimatedImpactScore!.isNaN ||
            estimatedImpactScore! < 0.0 ||
            estimatedImpactScore! > 1.0)) {
      throw ArgumentError(
        'estimatedImpactScore must be bounded within [0.0, 1.0] (got $estimatedImpactScore).',
      );
    }
    if (schemaVersion <= 0) {
      throw ArgumentError('schemaVersion must be positive.');
    }
  }

  bool get isObservedImpact => hazardSourceType == 'observed';
  bool get isForecastDerived => hazardSourceType == 'forecast_derived';
  bool get isVulnerabilityUnknown => vulnerabilityProfile == null;
  bool get isImpactEstimated => estimatedImpactScore != null;

  ImpactAssessment copyWith({
    String? assessmentId,
    String? hazardId,
    String? hazardCategory,
    String? hazardSourceType,
    ExposureCategory? exposureCategory,
    String? exposureDatasetId,
    List<String>? exposedElementIds,
    double? totalExposedQuantity,
    String? quantityUnit,
    double? estimatedImpactScore,
    bool clearEstimatedImpactScore = false,
    String? impactSeverityLabel,
    VulnerabilityProfile? vulnerabilityProfile,
    bool clearVulnerabilityProfile = false,
    ForecastHorizon? horizon,
    GeoLocation? location,
    ForecastUncertainty? uncertainty,
    ScientificValidationStatus? scientificStatus,
    String? economicImpactEstimate,
    List<AnalyticalStep>? provenanceSteps,
    Map<String, dynamic>? metadata,
    int? schemaVersion,
  }) {
    return ImpactAssessment(
      assessmentId: assessmentId ?? this.assessmentId,
      hazardId: hazardId ?? this.hazardId,
      hazardCategory: hazardCategory ?? this.hazardCategory,
      hazardSourceType: hazardSourceType ?? this.hazardSourceType,
      exposureCategory: exposureCategory ?? this.exposureCategory,
      exposureDatasetId: exposureDatasetId ?? this.exposureDatasetId,
      exposedElementIds: exposedElementIds ?? this.exposedElementIds,
      totalExposedQuantity: totalExposedQuantity ?? this.totalExposedQuantity,
      quantityUnit: quantityUnit ?? this.quantityUnit,
      estimatedImpactScore: clearEstimatedImpactScore
          ? null
          : (estimatedImpactScore ?? this.estimatedImpactScore),
      impactSeverityLabel: impactSeverityLabel ?? this.impactSeverityLabel,
      vulnerabilityProfile: clearVulnerabilityProfile
          ? null
          : (vulnerabilityProfile ?? this.vulnerabilityProfile),
      horizon: horizon ?? this.horizon,
      location: location ?? this.location,
      uncertainty: uncertainty ?? this.uncertainty,
      scientificStatus: scientificStatus ?? this.scientificStatus,
      economicImpactEstimate:
          economicImpactEstimate ?? this.economicImpactEstimate,
      provenanceSteps: provenanceSteps ?? this.provenanceSteps,
      metadata: metadata ?? this.metadata,
      schemaVersion: schemaVersion ?? this.schemaVersion,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'assessmentId': assessmentId,
      'hazardId': hazardId,
      'hazardCategory': hazardCategory,
      'hazardSourceType': hazardSourceType,
      'exposureCategory': exposureCategory.name,
      'exposureDatasetId': exposureDatasetId,
      'exposedElementCount': exposedElementIds.length,
      'totalExposedQuantity': totalExposedQuantity,
      'quantityUnit': quantityUnit,
      'estimatedImpactScore': estimatedImpactScore,
      'impactSeverityLabel': impactSeverityLabel,
      'latitude': location.latitude,
      'longitude': location.longitude,
      'horizon': horizon.toMap(),
      'uncertainty': uncertainty.toMap(),
      'scientificStatus': scientificStatus.name,
      'economicImpactEstimate': economicImpactEstimate,
      'schemaVersion': schemaVersion,
      'metadata': metadata,
    };
  }

  factory ImpactAssessment.fromMap(Map<String, dynamic> map) {
    final catName = map['exposureCategory'] as String? ?? 'other';
    final cat = ExposureCategory.values.firstWhere(
      (e) => e.name == catName,
      orElse: () => ExposureCategory.other,
    );

    final statusName =
        map['scientificStatus'] as String? ?? 'provisionalSoftwareOnly';
    final status = ScientificValidationStatus.values.firstWhere(
      (e) => e.name == statusName,
      orElse: () => ScientificValidationStatus.provisionalSoftwareOnly,
    );

    return ImpactAssessment(
      assessmentId: map['assessmentId'] as String? ?? '',
      hazardId: map['hazardId'] as String? ?? '',
      hazardCategory: map['hazardCategory'] as String? ?? '',
      hazardSourceType: map['hazardSourceType'] as String? ?? 'forecast_derived',
      exposureCategory: cat,
      exposureDatasetId: map['exposureDatasetId'] as String? ?? '',
      totalExposedQuantity:
          (map['totalExposedQuantity'] as num?)?.toDouble() ?? 0.0,
      quantityUnit: map['quantityUnit'] as String? ?? '',
      estimatedImpactScore:
          (map['estimatedImpactScore'] as num?)?.toDouble(),
      impactSeverityLabel: map['impactSeverityLabel'] as String? ?? 'Low',
      horizon: ForecastHorizon.fromMap(
        map['horizon'] as Map<String, dynamic>,
      ),
      location: GeoLocation(
        latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
        longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      ),
      uncertainty: map['uncertainty'] != null
          ? ForecastUncertainty.fromMap(
              map['uncertainty'] as Map<String, dynamic>,
            )
          : ForecastUncertainty(),
      scientificStatus: status,
      economicImpactEstimate:
          map['economicImpactEstimate'] as String? ?? 'NOT AVAILABLE',
      schemaVersion: map['schemaVersion'] as int? ?? currentSchemaVersion,
      metadata: (map['metadata'] as Map<String, dynamic>?) ?? const {},
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImpactAssessment &&
          runtimeType == other.runtimeType &&
          assessmentId == other.assessmentId &&
          hazardId == other.hazardId &&
          hazardCategory == other.hazardCategory &&
          hazardSourceType == other.hazardSourceType &&
          exposureCategory == other.exposureCategory &&
          exposureDatasetId == other.exposureDatasetId &&
          totalExposedQuantity == other.totalExposedQuantity &&
          quantityUnit == other.quantityUnit &&
          estimatedImpactScore == other.estimatedImpactScore &&
          impactSeverityLabel == other.impactSeverityLabel &&
          location == other.location &&
          scientificStatus == other.scientificStatus &&
          economicImpactEstimate == other.economicImpactEstimate &&
          schemaVersion == other.schemaVersion &&
          listEquals(exposedElementIds, other.exposedElementIds);

  @override
  int get hashCode => Object.hash(
        assessmentId,
        hazardId,
        hazardCategory,
        hazardSourceType,
        exposureCategory,
        exposureDatasetId,
        totalExposedQuantity,
        quantityUnit,
        estimatedImpactScore,
        impactSeverityLabel,
        location,
        scientificStatus,
        economicImpactEstimate,
        schemaVersion,
      );
}
