import 'package:flutter/foundation.dart';

/// Immutable model registry metadata for predictive models registered in RiskPulse.
@immutable
class PredictionModel {
  final String modelId;
  final String modelName;
  final String modelVersion;
  final String domain; // 'HYDROLOGY', 'REMOTE_SENSING', 'EXPOSURE'
  final String calibrationStatus; // 'EXPERIMENTAL', 'UNCALIBRATED', 'CALIBRATED', 'VALIDATED'
  final Map<String, dynamic> provenance;

  PredictionModel({
    required this.modelId,
    required this.modelName,
    required this.modelVersion,
    required this.domain,
    this.calibrationStatus = 'CALIBRATED',
    Map<String, dynamic>? provenance,
  }) : provenance = Map<String, dynamic>.unmodifiable(provenance ?? const {}) {
    if (modelId.trim().isEmpty) {
      throw ArgumentError('PredictionModel.modelId cannot be empty.');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'modelId': modelId,
      'modelName': modelName,
      'modelVersion': modelVersion,
      'domain': domain,
      'calibrationStatus': calibrationStatus,
      'provenance': provenance,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PredictionModel &&
          runtimeType == other.runtimeType &&
          modelId == other.modelId;

  @override
  int get hashCode => modelId.hashCode;
}
