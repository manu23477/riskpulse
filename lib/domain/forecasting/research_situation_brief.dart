import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/gis/analytical_step.dart';
import 'package:riskpulse/domain/forecasting/forecast_horizon.dart';
import 'package:riskpulse/domain/forecasting/hazard_forecast.dart';
import 'package:riskpulse/domain/forecasting/compound_hazard_event.dart';
import 'package:riskpulse/domain/forecasting/impact_assessment.dart';
import 'package:riskpulse/domain/forecasting/evidentiary_briefing.dart';
import 'package:riskpulse/domain/forecasting/validation_dataset_record.dart';

/// Advisory attention level classifications for researchers and emergency decision support.
enum AttentionLevel {
  low,
  monitor,
  alert,
  critical,
}

/// Immutable research situation brief aggregating forecasts, multi-hazard candidates, impact assessments,
/// advisory attention level, and evidentiary briefing for a study area.
@immutable
class ResearchSituationBrief {
  static const int currentSchemaVersion = 1;

  final String briefId;
  final String studyAreaName;
  final String situationContext; // 'actual_observed', 'scenario_conditional'
  final GeoLocation location;
  final MapExtent? spatialDomain;
  final ForecastHorizon horizon;
  final AttentionLevel advisoryAttentionLevel;
  final List<HazardForecast> activeForecasts;
  final List<CompoundHazardEvent> compoundEvents;
  final List<ImpactAssessment> impactAssessments;
  final EvidentiaryBriefing evidentiaryBriefing;
  final ScientificValidationStatus scientificStatus;
  final List<AnalyticalStep> provenanceSteps;
  final Map<String, dynamic> metadata;
  final int schemaVersion;

  ResearchSituationBrief({
    required this.briefId,
    required this.studyAreaName,
    this.situationContext = 'actual_observed',
    required this.location,
    this.spatialDomain,
    required this.horizon,
    required this.advisoryAttentionLevel,
    this.activeForecasts = const [],
    this.compoundEvents = const [],
    this.impactAssessments = const [],
    required this.evidentiaryBriefing,
    this.scientificStatus = ScientificValidationStatus.provisionalSoftwareOnly,
    this.provenanceSteps = const [],
    this.metadata = const {},
    this.schemaVersion = currentSchemaVersion,
  }) {
    if (briefId.trim().isEmpty) {
      throw ArgumentError('briefId cannot be empty.');
    }
    if (studyAreaName.trim().isEmpty) {
      throw ArgumentError('studyAreaName cannot be empty.');
    }
    if (schemaVersion <= 0) {
      throw ArgumentError('schemaVersion must be positive.');
    }
  }

  bool get isActualObserved => situationContext == 'actual_observed';
  bool get isScenarioConditional => situationContext == 'scenario_conditional';

  ResearchSituationBrief copyWith({
    String? briefId,
    String? studyAreaName,
    String? situationContext,
    GeoLocation? location,
    MapExtent? spatialDomain,
    bool clearSpatialDomain = false,
    ForecastHorizon? horizon,
    AttentionLevel? advisoryAttentionLevel,
    List<HazardForecast>? activeForecasts,
    List<CompoundHazardEvent>? compoundEvents,
    List<ImpactAssessment>? impactAssessments,
    EvidentiaryBriefing? evidentiaryBriefing,
    ScientificValidationStatus? scientificStatus,
    List<AnalyticalStep>? provenanceSteps,
    Map<String, dynamic>? metadata,
    int? schemaVersion,
  }) {
    return ResearchSituationBrief(
      briefId: briefId ?? this.briefId,
      studyAreaName: studyAreaName ?? this.studyAreaName,
      situationContext: situationContext ?? this.situationContext,
      location: location ?? this.location,
      spatialDomain:
          clearSpatialDomain ? null : (spatialDomain ?? this.spatialDomain),
      horizon: horizon ?? this.horizon,
      advisoryAttentionLevel:
          advisoryAttentionLevel ?? this.advisoryAttentionLevel,
      activeForecasts: activeForecasts ?? this.activeForecasts,
      compoundEvents: compoundEvents ?? this.compoundEvents,
      impactAssessments: impactAssessments ?? this.impactAssessments,
      evidentiaryBriefing: evidentiaryBriefing ?? this.evidentiaryBriefing,
      scientificStatus: scientificStatus ?? this.scientificStatus,
      provenanceSteps: provenanceSteps ?? this.provenanceSteps,
      metadata: metadata ?? this.metadata,
      schemaVersion: schemaVersion ?? this.schemaVersion,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'briefId': briefId,
      'studyAreaName': studyAreaName,
      'situationContext': situationContext,
      'latitude': location.latitude,
      'longitude': location.longitude,
      'horizon': horizon.toMap(),
      'advisoryAttentionLevel': advisoryAttentionLevel.name,
      'forecastCount': activeForecasts.length,
      'compoundEventCount': compoundEvents.length,
      'impactAssessmentCount': impactAssessments.length,
      'scientificStatus': scientificStatus.name,
      'schemaVersion': schemaVersion,
      'metadata': metadata,
    };
  }

  factory ResearchSituationBrief.fromMap(Map<String, dynamic> map) {
    final attName = map['advisoryAttentionLevel'] as String? ?? 'low';
    final attention = AttentionLevel.values.firstWhere(
      (e) => e.name == attName,
      orElse: () => AttentionLevel.low,
    );

    final statusName =
        map['scientificStatus'] as String? ?? 'provisionalSoftwareOnly';
    final status = ScientificValidationStatus.values.firstWhere(
      (e) => e.name == statusName,
      orElse: () => ScientificValidationStatus.provisionalSoftwareOnly,
    );

    return ResearchSituationBrief(
      briefId: map['briefId'] as String? ?? '',
      studyAreaName: map['studyAreaName'] as String? ?? '',
      situationContext: map['situationContext'] as String? ?? 'actual_observed',
      location: GeoLocation(
        latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
        longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      ),
      horizon: ForecastHorizon.fromMap(
        map['horizon'] as Map<String, dynamic>,
      ),
      advisoryAttentionLevel: attention,
      evidentiaryBriefing: EvidentiaryBriefing(
        briefingId: 'ev-brief-${map['briefId']}',
        dataCompletenessRatio: 1.0,
      ),
      scientificStatus: status,
      schemaVersion: map['schemaVersion'] as int? ?? currentSchemaVersion,
      metadata: (map['metadata'] as Map<String, dynamic>?) ?? const {},
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResearchSituationBrief &&
          runtimeType == other.runtimeType &&
          briefId == other.briefId &&
          studyAreaName == other.studyAreaName &&
          situationContext == other.situationContext &&
          location == other.location &&
          horizon == other.horizon &&
          advisoryAttentionLevel == other.advisoryAttentionLevel &&
          evidentiaryBriefing == other.evidentiaryBriefing &&
          scientificStatus == other.scientificStatus &&
          schemaVersion == other.schemaVersion &&
          listEquals(activeForecasts, other.activeForecasts) &&
          listEquals(compoundEvents, other.compoundEvents) &&
          listEquals(impactAssessments, other.impactAssessments);

  @override
  int get hashCode => Object.hash(
        briefId,
        studyAreaName,
        situationContext,
        location,
        horizon,
        advisoryAttentionLevel,
        evidentiaryBriefing,
        scientificStatus,
        schemaVersion,
      );
}
