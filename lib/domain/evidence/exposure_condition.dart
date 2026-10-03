import 'package:flutter/foundation.dart';

/// Immutable model capturing structured exposure condition metrics separately from hazard, vulnerability, or risk.
@immutable
class ExposureCondition {
  final String exposureStatus; // 'significant', 'moderate', 'low', 'unknown', 'insufficientData'
  final int? exposedPopulation;
  final int? exposedAssetCount;
  final List<String> exposedUnitIds;
  final String exposureDatasetVersion;

  const ExposureCondition({
    this.exposureStatus = 'unknown',
    this.exposedPopulation,
    this.exposedAssetCount,
    this.exposedUnitIds = const [],
    this.exposureDatasetVersion = 'Census 2011 MDDS / HP DSS 2024',
  });

  Map<String, dynamic> toJson() {
    return {
      'exposureStatus': exposureStatus,
      'exposedPopulation': exposedPopulation,
      'exposedAssetCount': exposedAssetCount,
      'exposedUnitIds': exposedUnitIds,
      'exposureDatasetVersion': exposureDatasetVersion,
    };
  }

  factory ExposureCondition.fromJson(Map<String, dynamic> json) {
    return ExposureCondition(
      exposureStatus: json['exposureStatus'] as String? ?? 'unknown',
      exposedPopulation: json['exposedPopulation'] as int?,
      exposedAssetCount: json['exposedAssetCount'] as int?,
      exposedUnitIds: (json['exposedUnitIds'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      exposureDatasetVersion: json['exposureDatasetVersion'] as String? ?? 'Census 2011 MDDS / HP DSS 2024',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExposureCondition &&
          runtimeType == other.runtimeType &&
          exposureStatus == other.exposureStatus &&
          exposedPopulation == other.exposedPopulation;

  @override
  int get hashCode => Object.hash(exposureStatus, exposedPopulation);
}
