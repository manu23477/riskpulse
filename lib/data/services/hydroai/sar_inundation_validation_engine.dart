import 'package:riskpulse/domain/gis/raster_data.dart';
import 'package:riskpulse/domain/gis/analytical_step.dart';
import 'package:riskpulse/domain/forecasting/validation_dataset_record.dart';
import 'package:riskpulse/domain/hydroai/hydroai.dart';

/// Status enum for spatial validation-grid compatibility checks.
enum SpatialValidationGridStatus {
  spatiallyCompatible,
  crsMismatch,
  dimensionMismatch,
  pixelSizeMismatch,
  originShiftMismatch,
  spatiallyIncompatible,
}

/// Service engine responsible for 2D spatial inundation evaluation against Sentinel-1 SAR observations.
///
/// SCIENTIFIC GOVERNANCE:
/// 1. Enforces explicit Common Validation Grid compatibility (CRS, dimensions, cell size, origin/bounds).
/// 2. NO silent reprojection, resampling, cropping, or warping inside core validation calculations.
/// 3. Computes spatial Critical Success Index ($CSI = \frac{TP}{TP + FP + FN}$), $POD$, $FAR$, $F_1$, $IoU$, $BIAS$, and $ACC$.
/// 4. Spatial evaluation output is an evaluation metric, NOT an automatic certification or operational promotion.
class SarInundationValidationEngine {
  static const String engineVersion = '0.1.10-R1';

  const SarInundationValidationEngine();

  /// Evaluates spatial validation-grid compatibility between model and SAR reference rasters.
  SpatialValidationGridStatus evaluateGridCompatibility(RasterData modelRaster, RasterData sarRaster) {
    if (modelRaster.crs.code != sarRaster.crs.code) {
      return SpatialValidationGridStatus.crsMismatch;
    }
    if (modelRaster.width != sarRaster.width || modelRaster.height != sarRaster.height) {
      return SpatialValidationGridStatus.dimensionMismatch;
    }
    if ((modelRaster.cellWidth - sarRaster.cellWidth).abs() > 1e-6 ||
        (modelRaster.cellHeight - sarRaster.cellHeight).abs() > 1e-6) {
      return SpatialValidationGridStatus.pixelSizeMismatch;
    }
    if ((modelRaster.origin.latitude - sarRaster.origin.latitude).abs() > 1e-6 ||
        (modelRaster.origin.longitude - sarRaster.origin.longitude).abs() > 1e-6) {
      return SpatialValidationGridStatus.originShiftMismatch;
    }
    return SpatialValidationGridStatus.spatiallyCompatible;
  }

  /// Computes a spatial binary [SpatialConfusionMatrix] comparing modeled flood extent mask against SAR reference flood mask.
  SpatialConfusionMatrix computeConfusionMatrix({
    required RasterData modelExtentMask,
    required RasterData sarFloodMask,
  }) {
    final gridStatus = evaluateGridCompatibility(modelExtentMask, sarFloodMask);

    if (gridStatus != SpatialValidationGridStatus.spatiallyCompatible) {
      throw ArgumentError(
        'SPATIAL INCOMPATIBILITY (${gridStatus.name}): Model and SAR reference masks must share an identical Common Validation Grid (CRS, dimensions, resolution, and origin). Explicit harmonisation required.',
      );
    }

    int tp = 0;
    int fp = 0;
    int fn = 0;
    int tn = 0;

    final totalCells = modelExtentMask.width * modelExtentMask.height;

    for (int i = 0; i < totalCells; i++) {
      final modelVal = modelExtentMask.values[i];
      final sarVal = sarFloodMask.values[i];

      if (modelExtentMask.isNoData(modelVal) || sarFloodMask.isNoData(sarVal)) {
        continue; // Exclude unobservable / NoData cells
      }

      final isModelFlooded = modelVal > 0.5;
      final isSarFlooded = sarVal > 0.5;

      if (isModelFlooded && isSarFlooded) {
        tp++;
      } else if (isModelFlooded && !isSarFlooded) {
        fp++;
      } else if (!isModelFlooded && isSarFlooded) {
        fn++;
      } else {
        tn++;
      }
    }

    return SpatialConfusionMatrix(
      truePositives: tp,
      falsePositives: fp,
      falseNegatives: fn,
      trueNegatives: tn,
    );
  }

  /// Evaluates a [HydrodynamicResult] against an independent [SarInundationRecord].
  InundationValidationRecord evaluateInundationResult({
    required HydrodynamicResult hydrodynamicResult,
    required SarInundationRecord sarRecord,
    required double depthThresholdMeters,
    String? criterionRationale,
  }) {
    if (depthThresholdMeters <= 0.0 || depthThresholdMeters.isNaN) {
      throw ArgumentError('depthThresholdMeters must be positive for spatial extent derivation.');
    }

    // 1. Derive binary inundation extent mask from max depth raster
    final modelMask = hydrodynamicResult.maxDepthRaster.deriveInundationExtentMask(
      depthThresholdMeters: depthThresholdMeters,
      criterionRationale: criterionRationale,
    );

    if (modelMask == null) {
      throw StateError('FLOOD EXTENT CRITERION: NOT ESTABLISHED. Failed to derive inundation extent mask.');
    }

    // 2. Compute spatial confusion matrix against SAR reference mask
    final matrix = computeConfusionMatrix(
      modelExtentMask: modelMask,
      sarFloodMask: sarRecord.sarFloodMask,
    );

    final now = DateTime.now().toUtc();

    final step = AnalyticalStep(
      name: 'sar_inundation_validation',
      operationType: 'sar_csi_evaluation',
      parameters: {
        'engineVersion': engineVersion,
        'resultId': hydrodynamicResult.resultId,
        'sarDatasetId': sarRecord.datasetId,
        'depthThresholdMeters': depthThresholdMeters,
        'criterionRationale': criterionRationale ?? 'Explicit Researcher Criterion',
        'csi': matrix.csi,
        'pod': matrix.pod,
        'far': matrix.far,
        'f1Score': matrix.f1Score,
        'iou': matrix.iou,
        'bias': matrix.bias,
        'accuracy': matrix.accuracy,
        'tp': matrix.truePositives,
        'fp': matrix.falsePositives,
        'fn': matrix.falseNegatives,
        'tn': matrix.trueNegatives,
      },
      timestamp: now,
      inputReferences: [hydrodynamicResult.resultId, sarRecord.datasetId],
    );

    return InundationValidationRecord(
      validationId: 'val-${hydrodynamicResult.resultId}-${sarRecord.datasetId}',
      resultId: hydrodynamicResult.resultId,
      sarRecord: sarRecord,
      depthThresholdMeters: depthThresholdMeters,
      criterionRationale: criterionRationale ?? 'Explicit Researcher Criterion',
      confusionMatrix: matrix,
      evaluationTimestamp: now,
      provenanceStep: step,
      scientificStatus: ScientificValidationStatus.provisionalSoftwareOnly,
    );
  }
}
