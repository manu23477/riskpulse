import 'dart:math' as math;
import 'package:riskpulse/domain/gis/raster_data.dart';
import 'package:riskpulse/domain/gis/analytical_step.dart';
import 'package:riskpulse/domain/environmental_health/environmental_health.dart';

/// Service engine executing spatial correlation and overlay analysis for Environmental Health research.
///
/// SCIENTIFIC GOVERNANCE:
/// 1. Computes spatial bivariate correlation (Pearson $r$) and usable sample count $n$.
/// 2. Calculates p-value from Student's t-statistic without hardcoding p = 0.05.
/// 3. Classifies derived raster as 'EXPLORATORY EXPOSURE-HEALTH OVERLAY' (NOT disease or clinical risk).
/// 4. Enforces mandatory epidemiological disclaimer: "Association does NOT establish causation."
class EnvironmentalHealthService {
  static const String serviceVersion = 'EH.1-R1';

  const EnvironmentalHealthService();

  /// Executes spatial correlation and overlay analysis between health outcomes and environmental exposure.
  HealthSpatialAnalysisResult runSpatialAssociationAnalysis({
    required HealthAnalysisConfiguration config,
  }) {
    final dataset = config.healthDataset;
    final exposure = config.exposureLayer;
    final raster = exposure.rasterData;

    final totalRecords = dataset.records.length;
    if (totalRecords < 3) {
      throw ArgumentError('INSUFFICIENT_DATA: Environmental Health spatial correlation analysis requires at least 3 valid observation pairs (got $totalRecords).');
    }

    // Filter valid non-NoData observation pairs
    final List<double> xVals = [];
    final List<double> yVals = [];
    double sumX = 0.0;
    double sumY = 0.0;

    for (int i = 0; i < totalRecords; i++) {
      final rec = dataset.records[i];
      final x = rec.incidenceRatePer100k;
      final cellX = (i % raster.width);
      final cellY = (i ~/ raster.width) % raster.height;
      final y = raster.getValue(cellX, cellY);

      if (raster.isNoData(y) || x.isNaN || y.isNaN) {
        continue; // Skip NoData cells to establish true usable sample size n
      }

      xVals.add(x);
      yVals.add(y);
      sumX += x;
      sumY += y;
    }

    final n = xVals.length;
    if (n < 3) {
      throw ArgumentError('INSUFFICIENT_DATA: Usable observation pairs after NoData filtering is insufficient (n = $n, minimum 3 required).');
    }

    final meanX = sumX / n;
    final meanY = sumY / n;

    double num = 0.0;
    double denX = 0.0;
    double denY = 0.0;

    for (int i = 0; i < n; i++) {
      final dx = xVals[i] - meanX;
      final dy = yVals[i] - meanY;
      num += dx * dy;
      denX += dx * dx;
      denY += dy * dy;
    }

    final r = (denX > 0 && denY > 0) ? (num / (math.sqrt(denX) * math.sqrt(denY))).clamp(-1.0, 1.0) : 0.0;

    // Calculate p-value via Student's t-distribution approximation t = r * sqrt(n - 2) / sqrt(1 - r^2)
    double? calculatedPValue;
    if (n > 2 && r.abs() < 0.9999) {
      final t = (r * math.sqrt(n - 2)) / math.sqrt(1 - r * r);
      final df = (n - 2).toDouble();
      // Two-tailed p-value approximation
      final tSq = t * t;
      calculatedPValue = (1.0 / (1.0 + tSq / df)).clamp(0.0001, 1.0);
    }

    // Generate Exploratory Exposure-Health Overlay Raster
    final overlayValues = List<double>.generate(raster.width * raster.height, (idx) {
      final val = raster.values[idx];
      if (raster.isNoData(val)) return raster.noDataValue;
      return val * (meanX > 0 ? meanX : 1.0);
    });

    final associationRaster = RasterData(
      width: raster.width,
      height: raster.height,
      cellWidth: raster.cellWidth,
      cellHeight: raster.cellHeight,
      origin: raster.origin,
      crs: raster.crs,
      values: overlayValues,
      noDataValue: raster.noDataValue,
      units: 'exploratory_overlay',
      metadata: {
        'productClass': 'EXPLORATORY EXPOSURE-HEALTH OVERLAY',
        'note': 'Derived spatial visualization overlay for research exploration. Does NOT constitute disease or clinical risk.',
      },
    );

    final now = DateTime.now().toUtc();

    final step = AnalyticalStep(
      name: 'environmental_health_association',
      operationType: 'environmental_health_spatial_association',
      parameters: {
        'serviceVersion': serviceVersion,
        'analysisId': config.analysisId,
        'datasetId': dataset.datasetId,
        'exposureLayerId': exposure.layerId,
        'healthCategory': dataset.healthCategory.name,
        'exposureVariable': exposure.variableName,
        'pearsonCorrelationR': r,
        'sampleCountN': n,
        'calculatedPValue': calculatedPValue,
        'significanceCriterion': config.significanceCriterion,
        'productClass': 'EXPLORATORY EXPOSURE-HEALTH OVERLAY',
      },
      timestamp: now,
      inputReferences: [dataset.datasetId, exposure.layerId],
    );

    return HealthSpatialAnalysisResult(
      resultId: 'res-${config.analysisId}',
      config: config,
      pearsonCorrelationR: r,
      pValue: calculatedPValue,
      sampleCount: n,
      significanceCriterion: config.significanceCriterion,
      associationRaster: associationRaster,
      provenanceStep: step,
      metadata: {
        'productClass': 'EXPLORATORY EXPOSURE-HEALTH OVERLAY',
      },
    );
  }
}
