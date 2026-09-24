import 'package:flutter/foundation.dart';

/// Enumeration of spatial relationships between hazard footprint and physical exposure assets.
enum ExposureSpatialRelationship {
  intersects,
  within,
  near,
  outside,
  unknown,
}

/// Enumeration of impact evaluation states, preserving the non-negotiable distinction between exposure and confirmed damage.
enum ExposureImpactState {
  exposed,          // Spatial intersection/overlay identified
  potentialImpact,  // Modeled physical susceptibility
  reportedImpact,   // Unverified OSINT or community field report
  observedImpact,   // Verified remote sensing / gauge observation
  confirmedImpact,  // Authoritative ground-truth damage assessment
  unknown,
}

/// Immutable domain contract representing an exposure/impact evaluation record.
///
/// SCIENTIFIC GOVERNANCE:
/// 1. Spatial overlay ([ExposureSpatialRelationship.intersects]) constitutes EXPOSURE, NOT confirmed damage.
/// 2. [exposureState] MUST NOT automatically upgrade from `exposed` to `confirmedImpact` without ground-truth evidence.
@immutable
class ImpactExposureContract {
  final String exposureId;
  final String hazardId;
  final String hazardType;
  final String hazardSource;
  final String hazardExecutionId;
  final String assetId;
  final String assetType;
  final ExposureSpatialRelationship spatialRelationship;
  final ExposureImpactState exposureState;
  final double exposureIndex; // 0.0 to 1.0 relative index
  final DateTime analysisTimestamp;
  final bool isSynthetic;

  const ImpactExposureContract({
    required this.exposureId,
    required this.hazardId,
    required this.hazardType,
    required this.hazardSource,
    required this.hazardExecutionId,
    required this.assetId,
    required this.assetType,
    this.spatialRelationship = ExposureSpatialRelationship.intersects,
    this.exposureState = ExposureImpactState.exposed,
    required this.exposureIndex,
    required this.analysisTimestamp,
    this.isSynthetic = false,
  })  : assert(exposureId.length > 0, 'exposureId cannot be empty.'),
        assert(hazardId.length > 0, 'hazardId cannot be empty.'),
        assert(assetId.length > 0, 'assetId cannot be empty.'),
        assert(exposureIndex >= 0.0 && exposureIndex <= 1.0, 'exposureIndex must be between 0.0 and 1.0.');

  bool get isConfirmedDamage => exposureState == ExposureImpactState.confirmedImpact;
  bool get isSpatialExposureOnly => exposureState == ExposureImpactState.exposed;
}
