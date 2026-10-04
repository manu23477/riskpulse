import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/exposure/exposure_asset_type.dart';
import 'package:riskpulse/domain/location/geo_location.dart';

/// Immutable domain model representing a physical exposure asset or population reference dataset.
@immutable
class ExposureAsset {
  static const int currentSchemaVersion = 1;

  final String assetId;
  final String sourceSystem; // e.g. 'OSM', 'CENSUS_2011', 'HP_PWD'
  final String sourceId;
  final ExposureAssetType assetType;

  final String name;
  final GeoLocation? location;
  final Map<String, dynamic>? geometry; // Point, LineString, Polygon, MultiPolygon
  final String crs; // 'EPSG:4326'

  final String datasetVersion; // e.g. 'Census-2011', 'OSM-2026.1'
  final int referenceYear; // e.g. 2011 or 2026

  final double? populationCount;
  final double? lengthKm;
  final double? areaKm2;
  final Map<String, dynamic> provenance;

  ExposureAsset({
    required this.assetId,
    required this.sourceSystem,
    required this.sourceId,
    required this.assetType,
    required this.name,
    this.location,
    this.geometry,
    this.crs = 'EPSG:4326',
    this.datasetVersion = 'OSM-2026.1',
    this.referenceYear = 2026,
    this.populationCount,
    this.lengthKm,
    this.areaKm2,
    Map<String, dynamic>? provenance,
  }) : provenance = Map<String, dynamic>.unmodifiable(provenance ?? const {}) {
    if (assetId.trim().isEmpty) {
      throw ArgumentError('ExposureAsset.assetId cannot be empty.');
    }
    if (name.trim().isEmpty) {
      throw ArgumentError('ExposureAsset.name cannot be empty.');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'assetId': assetId,
      'sourceSystem': sourceSystem,
      'sourceId': sourceId,
      'assetType': assetType.name,
      'name': name,
      'latitude': location?.latitude,
      'longitude': location?.longitude,
      'geometry': geometry,
      'crs': crs,
      'datasetVersion': datasetVersion,
      'referenceYear': referenceYear,
      'populationCount': populationCount,
      'lengthKm': lengthKm,
      'areaKm2': areaKm2,
      'provenance': provenance,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExposureAsset &&
          runtimeType == other.runtimeType &&
          assetId == other.assetId;

  @override
  int get hashCode => assetId.hashCode;
}
