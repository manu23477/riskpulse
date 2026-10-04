import 'package:flutter/foundation.dart';

/// Immutable domain model representing a physics-based hydrological model execution setup and parameters.
@immutable
class HydroModelRun {
  static const int currentSchemaVersion = 1;

  final String runId;
  final String modelName; // 'RISKPULSE_HYDRO_ENGINE'
  final String modelVersion; // '1.5.0'
  final String watershedId;
  final String demVersion; // 'Copernicus-GLO30'

  final double curveNumber; // SCS-CN: 30.0 to 100.0
  final double lagTimeHours; // SCS Unit Hydrograph lag time
  final double muskingumK; // Routing travel time (hours)
  final double muskingumX; // Routing weighting factor (0.0 to 0.5)
  final double timeStepMinutes; // 60.0

  final DateTime runTimestamp;
  final String calibrationStatus; // 'UNVALIDATED', 'CALIBRATED', 'VALIDATED'
  final Map<String, dynamic> provenance;

  HydroModelRun({
    required this.runId,
    this.modelName = 'RISKPULSE_HYDRO_ENGINE',
    this.modelVersion = '1.5.0',
    required this.watershedId,
    this.demVersion = 'Copernicus-GLO30',
    this.curveNumber = 75.0,
    this.lagTimeHours = 2.5,
    this.muskingumK = 3.0,
    this.muskingumX = 0.20,
    this.timeStepMinutes = 60.0,
    DateTime? runTimestamp,
    this.calibrationStatus = 'CALIBRATED',
    Map<String, dynamic>? provenance,
  })  : runTimestamp = runTimestamp ?? DateTime.now().toUtc(),
        provenance = Map<String, dynamic>.unmodifiable(provenance ?? const {}) {
    if (runId.trim().isEmpty) {
      throw ArgumentError('HydroModelRun.runId cannot be empty.');
    }
    if (watershedId.trim().isEmpty) {
      throw ArgumentError('HydroModelRun.watershedId cannot be empty.');
    }
    if (curveNumber < 30.0 || curveNumber > 100.0) {
      throw ArgumentError('curveNumber must be between 30 and 100.');
    }
    if (muskingumX < 0.0 || muskingumX > 0.5) {
      throw ArgumentError('muskingumX must be between 0.0 and 0.5.');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'runId': runId,
      'modelName': modelName,
      'modelVersion': modelVersion,
      'watershedId': watershedId,
      'demVersion': demVersion,
      'curveNumber': curveNumber,
      'lagTimeHours': lagTimeHours,
      'muskingumK': muskingumK,
      'muskingumX': muskingumX,
      'timeStepMinutes': timeStepMinutes,
      'runTimestamp': runTimestamp.toIso8601String(),
      'calibrationStatus': calibrationStatus,
      'provenance': provenance,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HydroModelRun &&
          runtimeType == other.runtimeType &&
          runId == other.runId;

  @override
  int get hashCode => runId.hashCode;
}
