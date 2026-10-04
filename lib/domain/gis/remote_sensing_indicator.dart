import 'package:flutter/foundation.dart';

/// Immutable domain model representing a derived physical remote sensing variable / index (NDVI, NDWI, NBR, SAR Change, DEM Slope).
@immutable
class RemoteSensingIndicator {
  static const int currentSchemaVersion = 1;

  final String indicatorId;
  final String observationId;
  final String indicatorType; // 'NDVI', 'NDWI', 'NBR', 'SAR_BACKSCATTER_CHANGE', 'DEM_SLOPE'

  final DateTime? preEventTimestamp;
  final DateTime? postEventTimestamp;

  final double? meanValue;
  final double? changeFraction;
  final Map<String, dynamic>? qualityMask;
  final double noDataFraction; // 0.0 to 1.0
  final bool isCalibrated;
  final String methodology;
  final Map<String, dynamic> provenance;

  RemoteSensingIndicator({
    required this.indicatorId,
    required this.observationId,
    required this.indicatorType,
    this.preEventTimestamp,
    this.postEventTimestamp,
    this.meanValue,
    this.changeFraction,
    this.qualityMask,
    this.noDataFraction = 0.02,
    this.isCalibrated = false,
    required this.methodology,
    Map<String, dynamic>? provenance,
  }) : provenance = Map<String, dynamic>.unmodifiable(provenance ?? const {}) {
    if (indicatorId.trim().isEmpty) {
      throw ArgumentError('RemoteSensingIndicator.indicatorId cannot be empty.');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'indicatorId': indicatorId,
      'observationId': observationId,
      'indicatorType': indicatorType,
      'preEventTimestamp': preEventTimestamp?.toIso8601String(),
      'postEventTimestamp': postEventTimestamp?.toIso8601String(),
      'meanValue': meanValue,
      'changeFraction': changeFraction,
      'qualityMask': qualityMask,
      'noDataFraction': noDataFraction,
      'isCalibrated': isCalibrated,
      'methodology': methodology,
      'provenance': provenance,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RemoteSensingIndicator &&
          runtimeType == other.runtimeType &&
          indicatorId == other.indicatorId;

  @override
  int get hashCode => indicatorId.hashCode;
}
