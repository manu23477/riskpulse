import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';

/// Immutable domain contract representing Sentinel-1 SAR acquisition metadata & reference parameters.
@immutable
class SarInundationContract {
  final String sceneId;
  final String mission;
  final String platform;
  final String instrument;
  final String productType; // GRD, SLC
  final DateTime acquisitionStart;
  final DateTime acquisitionEnd;
  final String orbitDirection; // Ascending, Descending
  final int relativeOrbit;
  final String polarization; // VV, VH, HH, HV
  final CoordinateReferenceSystem crs;
  final MapExtent spatialExtent;
  final double pixelSpacingMeters;
  final String provider;
  final bool isSynthetic;

  const SarInundationContract({
    required this.sceneId,
    this.mission = 'Sentinel-1',
    this.platform = 'Sentinel-1A/B',
    this.instrument = 'C-SAR',
    this.productType = 'GRD',
    required this.acquisitionStart,
    required this.acquisitionEnd,
    this.orbitDirection = 'Descending',
    this.relativeOrbit = 1,
    this.polarization = 'VV+VH',
    required this.crs,
    required this.spatialExtent,
    this.pixelSpacingMeters = 10.0,
    this.provider = 'ESA / Copernicus Open Access Hub',
    this.isSynthetic = false,
  })  : assert(sceneId.length > 0, 'sceneId cannot be empty.'),
        assert(pixelSpacingMeters > 0.0, 'pixelSpacingMeters must be strictly positive.');

  DateTime get sceneMidpointTime =>
      acquisitionStart.add(Duration(milliseconds: acquisitionEnd.difference(acquisitionStart).inMilliseconds ~/ 2));
}

/// Immutable domain contract representing a 2D SAR inundation validation evaluation result.
@immutable
class SarValidationResultContract {
  static const int currentSchemaVersion = 1;

  final String validationId;
  final String eventId;
  final String modelExecutionId;
  final String sarSceneId;
  final String referenceMaskId;
  final String comparisonCrs;
  final MapExtent comparisonExtent;
  final int validPixelCount;
  final int truePositiveCells;
  final int trueNegativeCells;
  final int falsePositiveCells;
  final int falseNegativeCells;
  final double? criticalSuccessIndex;
  final double? probabilityOfDetection;
  final double? falseAlarmRatio;
  final double? intersectionOverUnion;
  final double? precision;
  final double? recall;
  final double? f1Score;
  final double observedAreaKm2;
  final double predictedAreaKm2;
  final double areaDifferenceKm2;
  final String methodVersion;
  final String executionMode;
  final String scientificStatus;
  final String validationStatus;
  final bool isSynthetic;
  final String provenanceId;
  final DateTime timestamp;
  final int schemaVersion;

  const SarValidationResultContract({
    required this.validationId,
    required this.eventId,
    required this.modelExecutionId,
    required this.sarSceneId,
    required this.referenceMaskId,
    this.comparisonCrs = 'EPSG:4326',
    required this.comparisonExtent,
    required this.validPixelCount,
    required this.truePositiveCells,
    required this.trueNegativeCells,
    required this.falsePositiveCells,
    required this.falseNegativeCells,
    this.criticalSuccessIndex,
    this.probabilityOfDetection,
    this.falseAlarmRatio,
    this.intersectionOverUnion,
    this.precision,
    this.recall,
    this.f1Score,
    required this.observedAreaKm2,
    required this.predictedAreaKm2,
    required this.areaDifferenceKm2,
    this.methodVersion = '1.0.0',
    this.executionMode = 'SIMULATED',
    this.scientificStatus = 'SOFTWARE_VALIDATED',
    this.validationStatus = 'COMPARISON_COMPLETED',
    this.isSynthetic = false,
    required this.provenanceId,
    required this.timestamp,
    this.schemaVersion = currentSchemaVersion,
  })  : assert(validationId.length > 0, 'validationId cannot be empty.'),
        assert(modelExecutionId.length > 0, 'modelExecutionId cannot be empty.'),
        assert(sarSceneId.length > 0, 'sarSceneId cannot be empty.');

  Map<String, dynamic> toMap() {
    return {
      'validationId': validationId,
      'eventId': eventId,
      'modelExecutionId': modelExecutionId,
      'sarSceneId': sarSceneId,
      'referenceMaskId': referenceMaskId,
      'comparisonCrs': comparisonCrs,
      'validPixelCount': validPixelCount,
      'truePositiveCells': truePositiveCells,
      'trueNegativeCells': trueNegativeCells,
      'falsePositiveCells': falsePositiveCells,
      'falseNegativeCells': falseNegativeCells,
      'criticalSuccessIndex': criticalSuccessIndex,
      'probabilityOfDetection': probabilityOfDetection,
      'falseAlarmRatio': falseAlarmRatio,
      'intersectionOverUnion': intersectionOverUnion,
      'precision': precision,
      'recall': recall,
      'f1Score': f1Score,
      'observedAreaKm2': observedAreaKm2,
      'predictedAreaKm2': predictedAreaKm2,
      'areaDifferenceKm2': areaDifferenceKm2,
      'methodVersion': methodVersion,
      'executionMode': executionMode,
      'scientificStatus': scientificStatus,
      'validationStatus': validationStatus,
      'isSynthetic': isSynthetic,
      'provenanceId': provenanceId,
      'timestamp': timestamp.toIso8601String(),
      'schemaVersion': schemaVersion,
    };
  }
}
