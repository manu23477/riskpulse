import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/administrative/administrative_context.dart';
import 'package:riskpulse/domain/location/geo_location.dart';

/// Immutable domain model representing a Risk Intelligence research session/context bridging Risk Map and Research GIS.
///
/// Serves as the authoritative bridge referencing EventHypothesis, SpatialState, AdministrativeState, and DynamicRiskState.
@immutable
class RiskResearchSession {
  static const int currentSchemaVersion = 1;

  final String sessionId;
  final String? riskObjectId;
  final String riskObjectType; // 'EventHypothesis', 'Hazard', 'DynamicRiskState', 'FREE_RESEARCH'
  final String mode; // 'RISK_CENTRIC' or 'FREE_RESEARCH'

  /// Authoritative Domain State References
  final String? eventHypothesisId;
  final int? hypothesisVersion;
  final String? spatialStateId;
  final int? spatialStateVersion;
  final String? administrativeStateId;
  final int? administrativeStateVersion;
  final String? dynamicRiskStateId;
  final int? dynamicRiskStateVersion;

  /// Hazard & Title Context
  final String hazardCategory;
  final String title;
  final String description;

  /// Spatial & Study Area Context
  final GeoLocation? targetLocation;
  final Map<String, dynamic>? targetGeometry;
  final String crs; // 'EPSG:4326'
  final Map<String, dynamic>? studyAreaGeometry;
  final double? bufferMeters;

  /// Temporal & Administrative Context
  final DateTime? observedAt;
  final DateTime? effectiveFrom;
  final DateTime? effectiveTo;
  final AdministrativeContext? administrativeContext;

  /// Evidence & Lineage
  final List<String> evidenceIds;
  final List<String> interpretationIds;
  final String originatingScreen; // 'RiskMap', 'ResearchGIS', 'AIAssistant'
  final DateTime createdAt;
  final String sessionStatus; // 'ACTIVE', 'COMPLETED', 'CLOSED'
  final Map<String, dynamic> provenance;

  RiskResearchSession({
    required this.sessionId,
    this.riskObjectId,
    this.riskObjectType = 'EventHypothesis',
    this.mode = 'RISK_CENTRIC',
    this.eventHypothesisId,
    this.hypothesisVersion,
    this.spatialStateId,
    this.spatialStateVersion,
    this.administrativeStateId,
    this.administrativeStateVersion,
    this.dynamicRiskStateId,
    this.dynamicRiskStateVersion,
    required this.hazardCategory,
    required this.title,
    this.description = '',
    this.targetLocation,
    this.targetGeometry,
    this.crs = 'EPSG:4326',
    this.studyAreaGeometry,
    this.bufferMeters,
    this.observedAt,
    this.effectiveFrom,
    this.effectiveTo,
    this.administrativeContext,
    List<String>? evidenceIds,
    List<String>? interpretationIds,
    this.originatingScreen = 'RiskMap',
    DateTime? createdAt,
    this.sessionStatus = 'ACTIVE',
    Map<String, dynamic>? provenance,
  })  : evidenceIds = List<String>.unmodifiable(evidenceIds ?? const []),
        interpretationIds = List<String>.unmodifiable(interpretationIds ?? const []),
        createdAt = createdAt ?? DateTime.now().toUtc(),
        provenance = Map<String, dynamic>.unmodifiable(provenance ?? const {}) {
    if (sessionId.trim().isEmpty) {
      throw ArgumentError('RiskResearchSession.sessionId cannot be empty.');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'riskObjectId': riskObjectId,
      'riskObjectType': riskObjectType,
      'mode': mode,
      'eventHypothesisId': eventHypothesisId,
      'hypothesisVersion': hypothesisVersion,
      'spatialStateId': spatialStateId,
      'spatialStateVersion': spatialStateVersion,
      'administrativeStateId': administrativeStateId,
      'administrativeStateVersion': administrativeStateVersion,
      'dynamicRiskStateId': dynamicRiskStateId,
      'dynamicRiskStateVersion': dynamicRiskStateVersion,
      'hazardCategory': hazardCategory,
      'title': title,
      'description': description,
      'latitude': targetLocation?.latitude,
      'longitude': targetLocation?.longitude,
      'targetGeometry': targetGeometry,
      'crs': crs,
      'studyAreaGeometry': studyAreaGeometry,
      'bufferMeters': bufferMeters,
      'observedAt': observedAt?.toIso8601String(),
      'effectiveFrom': effectiveFrom?.toIso8601String(),
      'effectiveTo': effectiveTo?.toIso8601String(),
      'primaryDistrict': administrativeContext?.district?.name,
      'evidenceIds': evidenceIds,
      'interpretationIds': interpretationIds,
      'originatingScreen': originatingScreen,
      'createdAt': createdAt.toIso8601String(),
      'sessionStatus': sessionStatus,
      'provenance': provenance,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RiskResearchSession &&
          runtimeType == other.runtimeType &&
          sessionId == other.sessionId;

  @override
  int get hashCode => sessionId.hashCode;
}
