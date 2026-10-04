import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/exposure/exposure_asset_type.dart';

/// Immutable domain model representing spatial intersection results between a hazard footprint and an exposure asset.
@immutable
class ExposureResult {
  static const int currentSchemaVersion = 1;

  final String exposureResultId;
  final String hazardFootprintId;
  final int hazardFootprintVersion;

  final String assetId;
  final ExposureAssetType assetType;
  final String intersectionType; // 'POINT_INSIDE', 'LINE_INTERSECT', 'POLYGON_OVERLAP', 'NEARBY'

  final double? exposedAreaKm2;
  final double? exposedLengthKm;
  final double? exposedPopulationCount;
  final double? overlapPercentage;
  final double? distanceToHazardMeters;
  final String? administrativeUnitId;

  final Map<String, dynamic> provenance;

  ExposureResult({
    required this.exposureResultId,
    required this.hazardFootprintId,
    this.hazardFootprintVersion = 1,
    required this.assetId,
    required this.assetType,
    this.intersectionType = 'POINT_INSIDE',
    this.exposedAreaKm2,
    this.exposedLengthKm,
    this.exposedPopulationCount,
    this.overlapPercentage = 100.0,
    this.distanceToHazardMeters = 0.0,
    this.administrativeUnitId = 'HP-06',
    Map<String, dynamic>? provenance,
  }) : provenance = Map<String, dynamic>.unmodifiable(provenance ?? const {}) {
    if (exposureResultId.trim().isEmpty) {
      throw ArgumentError('ExposureResult.exposureResultId cannot be empty.');
    }
    if (hazardFootprintId.trim().isEmpty) {
      throw ArgumentError('ExposureResult.hazardFootprintId cannot be empty.');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'exposureResultId': exposureResultId,
      'hazardFootprintId': hazardFootprintId,
      'hazardFootprintVersion': hazardFootprintVersion,
      'assetId': assetId,
      'assetType': assetType.name,
      'intersectionType': intersectionType,
      'exposedAreaKm2': exposedAreaKm2,
      'exposedLengthKm': exposedLengthKm,
      'exposedPopulationCount': exposedPopulationCount,
      'overlapPercentage': overlapPercentage,
      'distanceToHazardMeters': distanceToHazardMeters,
      'administrativeUnitId': administrativeUnitId,
      'provenance': provenance,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExposureResult &&
          runtimeType == other.runtimeType &&
          exposureResultId == other.exposureResultId;

  @override
  int get hashCode => exposureResultId.hashCode;
}
