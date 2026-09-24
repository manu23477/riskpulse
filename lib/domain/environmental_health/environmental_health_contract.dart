import 'package:flutter/foundation.dart';

/// Immutable domain contract representing Environmental Health spatial correlation & overlay analysis results.
///
/// SCIENTIFIC GOVERNANCE:
/// 1. Bivariate correlation ($r$, $p$-value) constitutes statistical association, NOT causal proof.
/// 2. [productClass] remains strictly `EXPLORATORY EXPOSURE-HEALTH OVERLAY`.
/// 3. Enforces mandatory epidemiological disclaimer: "Association does NOT establish causation."
@immutable
class EnvironmentalHealthContract {
  final String analysisId;
  final String healthCategory;
  final String exposureVariable;
  final double pearsonCorrelationR;
  final int sampleCountN;
  final double? pValue;
  final double significanceCriterion;
  final String productClass;
  final String causalDisclaimer;
  final DateTime analysisTimestamp;
  final bool isSynthetic;

  const EnvironmentalHealthContract({
    required this.analysisId,
    required this.healthCategory,
    required this.exposureVariable,
    required this.pearsonCorrelationR,
    required this.sampleCountN,
    this.pValue,
    this.significanceCriterion = 0.05,
    this.productClass = 'EXPLORATORY EXPOSURE-HEALTH OVERLAY',
    this.causalDisclaimer = 'Association does NOT establish causation. Derived spatial visualization overlay for research exploration.',
    required this.analysisTimestamp,
    this.isSynthetic = false,
  })  : assert(analysisId.length > 0, 'analysisId cannot be empty.'),
        assert(sampleCountN >= 3, 'Sample size n must be at least 3 for spatial correlation analysis.'),
        assert(pearsonCorrelationR >= -1.0 && pearsonCorrelationR <= 1.0, 'Pearson r must be between -1.0 and +1.0.');

  bool get isStatisticallySignificant => pValue != null && pValue! < significanceCriterion;
}
