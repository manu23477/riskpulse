import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/gis/analytical_step.dart';
import 'package:riskpulse/domain/gis/raster_data.dart';
import 'package:riskpulse/domain/environmental_health/health_analysis_configuration.dart';

/// Immutable result container for spatial environmental health analysis.
///
/// SCIENTIFIC & EPIDEMIOLOGICAL GOVERNANCE:
/// Identifies spatial geographic associations ONLY.
/// Does NOT establish medical causality or individual clinical risk.
@immutable
class HealthSpatialAnalysisResult {
  final String resultId;
  final HealthAnalysisConfiguration config;
  final double pearsonCorrelationR;
  final double? pValue; // Nullable calculated p-value (NO default 0.05 assumption)
  final int sampleCount; // Usable observation pairs (n)
  final double? significanceCriterion; // Researcher-selected significance criterion
  final RasterData? associationRaster; // Exploratory exposure-health overlay
  final AnalyticalStep provenanceStep;
  final String causalityDisclaimer;
  final Map<String, dynamic> metadata;

  const HealthSpatialAnalysisResult({
    required this.resultId,
    required this.config,
    required this.pearsonCorrelationR,
    this.pValue,
    required this.sampleCount,
    this.significanceCriterion,
    this.associationRaster,
    required this.provenanceStep,
    this.causalityDisclaimer =
        'Spatial association identified. Further epidemiological investigation is required. Statistical association does NOT establish causation.',
    this.metadata = const {},
  });

  /// Evaluates statistical significance interpretation without imposing universal thresholds.
  String get significanceInterpretation {
    if (pValue == null || significanceCriterion == null) {
      return 'NOT ESTABLISHED';
    }
    if (pValue! <= significanceCriterion!) {
      return 'STATISTICALLY SIGNIFICANT (p = ${pValue!.toStringAsFixed(3)} <= ${significanceCriterion!.toStringAsFixed(2)})';
    }
    return 'NOT STATISTICALLY SIGNIFICANT (p = ${pValue!.toStringAsFixed(3)} > ${significanceCriterion!.toStringAsFixed(2)})';
  }
}
