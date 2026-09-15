import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/gis/analytical_step.dart';
import 'package:riskpulse/domain/forecasting/validation_dataset_record.dart';
import 'package:riskpulse/domain/hydroai/sar_inundation_record.dart';
import 'package:riskpulse/domain/hydroai/spatial_confusion_matrix.dart';

/// Immutable domain record linking HydroAI result, SAR reference observation, explicit threshold, and spatial metrics.
///
/// SCIENTIFIC GOVERNANCE:
/// A spatial evaluation record computes [CSI] for a specific event/dataset.
/// It does NOT automatically convert a model into [ScientificValidationStatus.validatedForStudyArea].
@immutable
class InundationValidationRecord {
  final String validationId;
  final String resultId;
  final SarInundationRecord sarRecord;
  final double depthThresholdMeters;
  final String criterionRationale;
  final SpatialConfusionMatrix confusionMatrix;
  final DateTime evaluationTimestamp;
  final AnalyticalStep provenanceStep;
  final ScientificValidationStatus scientificStatus;
  final Map<String, dynamic> metadata;

  InundationValidationRecord({
    required this.validationId,
    required this.resultId,
    required this.sarRecord,
    required this.depthThresholdMeters,
    this.criterionRationale = 'Researcher Explicit Wetting Threshold',
    required this.confusionMatrix,
    required this.evaluationTimestamp,
    required this.provenanceStep,
    this.scientificStatus = ScientificValidationStatus.provisionalSoftwareOnly,
    this.metadata = const {},
  }) {
    if (validationId.trim().isEmpty) {
      throw ArgumentError('validationId cannot be empty.');
    }
    if (resultId.trim().isEmpty) {
      throw ArgumentError('resultId cannot be empty.');
    }
    if (depthThresholdMeters <= 0.0 || depthThresholdMeters.isNaN) {
      throw ArgumentError('depthThresholdMeters must be positive.');
    }
  }

  double get csi => confusionMatrix.csi;
  double get pod => confusionMatrix.pod;
  double get far => confusionMatrix.far;
  double get iou => confusionMatrix.iou;
}
