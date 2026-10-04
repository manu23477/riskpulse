import 'package:flutter/foundation.dart';

/// Immutable domain model representing time-series hydrograph results (rainfall, loss, excess, routed discharge) and validation metrics.
@immutable
class HydrographResult {
  static const int currentSchemaVersion = 1;

  final String hydrographId;
  final String runId;

  final List<double> timeSeriesHours;
  final List<double> rainfallMm;
  final List<double> lossMm;
  final List<double> excessMm;
  final List<double> dischargeM3s;

  final double peakDischargeM3s;
  final double timeToPeakHours;
  final double totalRunoffVolumeM3;
  final double massBalanceErrorPercent;

  final double? nseScore; // Nash-Sutcliffe Efficiency (-inf to 1.0)
  final double? rmseScore; // Root Mean Square Error
  final double? kgeScore; // Kling-Gupta Efficiency

  final Map<String, dynamic> provenance;

  HydrographResult({
    required this.hydrographId,
    required this.runId,
    required List<double> timeSeriesHours,
    required List<double> rainfallMm,
    required List<double> lossMm,
    required List<double> excessMm,
    required List<double> dischargeM3s,
    required this.peakDischargeM3s,
    required this.timeToPeakHours,
    required this.totalRunoffVolumeM3,
    this.massBalanceErrorPercent = 0.0,
    this.nseScore,
    this.rmseScore,
    this.kgeScore,
    Map<String, dynamic>? provenance,
  })  : timeSeriesHours = List<double>.unmodifiable(timeSeriesHours),
        rainfallMm = List<double>.unmodifiable(rainfallMm),
        lossMm = List<double>.unmodifiable(lossMm),
        excessMm = List<double>.unmodifiable(excessMm),
        dischargeM3s = List<double>.unmodifiable(dischargeM3s),
        provenance = Map<String, dynamic>.unmodifiable(provenance ?? const {}) {
    if (hydrographId.trim().isEmpty) {
      throw ArgumentError('HydrographResult.hydrographId cannot be empty.');
    }
    if (runId.trim().isEmpty) {
      throw ArgumentError('HydrographResult.runId cannot be empty.');
    }
    if (dischargeM3s.isEmpty) {
      throw ArgumentError('dischargeM3s cannot be empty.');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'hydrographId': hydrographId,
      'runId': runId,
      'timeSeriesHours': timeSeriesHours,
      'rainfallMm': rainfallMm,
      'lossMm': lossMm,
      'excessMm': excessMm,
      'dischargeM3s': dischargeM3s,
      'peakDischargeM3s': peakDischargeM3s,
      'timeToPeakHours': timeToPeakHours,
      'totalRunoffVolumeM3': totalRunoffVolumeM3,
      'massBalanceErrorPercent': massBalanceErrorPercent,
      'nseScore': nseScore,
      'rmseScore': rmseScore,
      'kgeScore': kgeScore,
      'provenance': provenance,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HydrographResult &&
          runtimeType == other.runtimeType &&
          hydrographId == other.hydrographId;

  @override
  int get hashCode => hydrographId.hashCode;
}
