import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/environmental_health/health_outcome_dataset.dart';
import 'package:riskpulse/domain/environmental_health/environmental_exposure_layer.dart';

/// Configuration run parameters for spatial environmental health analysis.
///
/// SCIENTIFIC GOVERNANCE:
/// [significanceCriterion] is researcher-selected (e.g. 0.05).
/// If omitted, NO significance threshold is imposed automatically.
@immutable
class HealthAnalysisConfiguration {
  final String analysisId;
  final HealthOutcomeDataset healthDataset;
  final EnvironmentalExposureLayer exposureLayer;
  final String analysisMethod; // 'Spatial Bivariate Correlation (Pearson r)', 'Spatial Overlay'
  final String spatialUnit;
  final double? significanceCriterion; // Explicitly supplied significance criterion (e.g. 0.05)
  final Map<String, dynamic> metadata;

  HealthAnalysisConfiguration({
    required this.analysisId,
    required this.healthDataset,
    required this.exposureLayer,
    this.analysisMethod = 'Spatial Bivariate Correlation (Pearson r)',
    this.spatialUnit = 'District',
    this.significanceCriterion,
    this.metadata = const {},
  }) {
    if (analysisId.trim().isEmpty) {
      throw ArgumentError('analysisId cannot be empty.');
    }
    if (significanceCriterion != null &&
        (significanceCriterion! <= 0.0 || significanceCriterion! >= 1.0 || significanceCriterion!.isNaN)) {
      throw ArgumentError('significanceCriterion must be between 0.0 and 1.0.');
    }
  }
}
