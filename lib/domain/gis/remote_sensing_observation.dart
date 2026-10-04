import 'package:flutter/foundation.dart';

/// Immutable domain model representing a satellite / Earth observation scene dataset acquisition.
///
/// Preserves exact dataset provenance, scene ID, acquisition timestamp, spatial resolution, and band configuration.
@immutable
class RemoteSensingObservation {
  static const int currentSchemaVersion = 1;

  final String observationId;
  final String datasetName; // 'Sentinel-2', 'Sentinel-1', 'Copernicus-GLO30'
  final String sceneId;
  final DateTime acquisitionTimestamp;
  final Map<String, dynamic>? bounds;

  final double cloudCoverageFraction; // 0.0 to 1.0
  final double spatialResolutionMeters; // 10.0
  final String crs; // 'EPSG:4326'
  final List<String> bands;
  final String processingLevel; // 'L2A', 'GRD', 'DEM'
  final Map<String, dynamic> provenance;

  RemoteSensingObservation({
    required this.observationId,
    required this.datasetName,
    required this.sceneId,
    required this.acquisitionTimestamp,
    this.bounds,
    this.cloudCoverageFraction = 0.05,
    this.spatialResolutionMeters = 10.0,
    this.crs = 'EPSG:4326',
    List<String>? bands,
    this.processingLevel = 'L2A',
    Map<String, dynamic>? provenance,
  })  : bands = List<String>.unmodifiable(bands ?? const ['B2', 'B3', 'B4', 'B8']),
        provenance = Map<String, dynamic>.unmodifiable(provenance ?? const {}) {
    if (observationId.trim().isEmpty) {
      throw ArgumentError('RemoteSensingObservation.observationId cannot be empty.');
    }
    if (sceneId.trim().isEmpty) {
      throw ArgumentError('RemoteSensingObservation.sceneId cannot be empty.');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'observationId': observationId,
      'datasetName': datasetName,
      'sceneId': sceneId,
      'acquisitionTimestamp': acquisitionTimestamp.toIso8601String(),
      'bounds': bounds,
      'cloudCoverageFraction': cloudCoverageFraction,
      'spatialResolutionMeters': spatialResolutionMeters,
      'crs': crs,
      'bands': bands,
      'processingLevel': processingLevel,
      'provenance': provenance,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RemoteSensingObservation &&
          runtimeType == other.runtimeType &&
          observationId == other.observationId;

  @override
  int get hashCode => observationId.hashCode;
}
