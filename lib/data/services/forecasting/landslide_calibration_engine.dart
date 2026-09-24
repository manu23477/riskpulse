import 'dart:math' as math;
import 'package:riskpulse/domain/forecasting/landslide_threshold_profile.dart';
import 'package:riskpulse/domain/forecasting/landslide_calibration_contracts.dart';
import 'package:riskpulse/data/services/forecasting/event_rainfall_association_engine.dart';

/// Result structure produced by [LandslideCalibrationEngine].
class CalibrationResult {
  final LandslideThresholdProfile profile;
  final double rSquared;
  final int sampleCount;
  final bool isSynthetic;
  final String statusNotes;

  const CalibrationResult({
    required this.profile,
    required this.rSquared,
    required this.sampleCount,
    required this.isSynthetic,
    required this.statusNotes,
  });
}

/// Scientific engine fitting Intensity-Duration power-law parameters I = a * D^(-b) via OLS log-linear regression.
///
/// SCIENTIFIC GOVERNANCE:
/// 1. Fits log-linear regression ln(I) = ln(a) - b * ln(D) across paired event-rainfall observations.
/// 2. MANDATORY GOVERNANCE RULE: Synthetic test datasets or sample size n < 5 MUST NOT upgrade profile status to calibratedRegional.
class LandslideCalibrationEngine {
  final EventRainfallAssociationEngine associationEngine;

  const LandslideCalibrationEngine({
    this.associationEngine = const EventRainfallAssociationEngine(),
  });

  /// Fits a calibrated [LandslideThresholdProfile] from input [dataset].
  CalibrationResult calibrateProfile({
    required LandslideCalibrationDataset dataset,
    required String profileId,
    required String profileName,
    required String geographicScope,
  }) {
    final pairs = associationEngine.associateEventsWithRainfall(dataset);
    final n = pairs.length;

    if (n < 3) {
      throw ArgumentError('INSUFFICIENT_DATA: Landslide threshold calibration requires at least 3 matched event-rainfall observation pairs (got $n).');
    }

    final isSynthetic = dataset.isSyntheticDataset || pairs.any((p) => p.isSynthetic);

    // OLS Log-linear regression: Y = ln(I), X = ln(D)
    final List<double> x = [];
    final List<double> y = [];
    double sumX = 0.0;
    double sumY = 0.0;

    for (final p in pairs) {
      if (p.durationHours <= 0.0 || p.rainfallIntensityMmHour <= 0.0) continue;
      final lnD = math.log(p.durationHours);
      final lnI = math.log(p.rainfallIntensityMmHour);
      x.add(lnD);
      y.add(lnI);
      sumX += lnD;
      sumY += lnI;
    }

    final count = x.length;
    if (count < 3) {
      throw ArgumentError('INSUFFICIENT_DATA: Valid positive duration/intensity pairs count is $count (minimum 3 required).');
    }

    final meanX = sumX / count;
    final meanY = sumY / count;

    double num = 0.0;
    double denX = 0.0;
    double denY = 0.0;

    for (int i = 0; i < count; i++) {
      final dx = x[i] - meanX;
      final dy = y[i] - meanY;
      num += dx * dy;
      denX += dx * dx;
      denY += dy * dy;
    }

    // Y = Intercept + Slope * X -> ln(I) = ln(a) - b * ln(D)
    final slope = denX > 0.0 ? num / denX : 0.0;
    final intercept = meanY - (slope * meanX);

    final aCoeff = math.exp(intercept);
    final bExponent = -slope; // b = -slope

    // R-squared
    final rSquared = (denX > 0.0 && denY > 0.0) ? (num * num) / (denX * denY) : 0.0;

    // MANDATORY SCIENTIFIC STATUS GOVERNANCE RULE:
    // Synthetic datasets or small sample sizes (count < 5) CANNOT become calibratedRegional.
    final ThresholdCalibrationStatus status = (isSynthetic || count < 5)
        ? ThresholdCalibrationStatus.uncalibrated
        : ThresholdCalibrationStatus.calibratedRegional;

    final notes = isSynthetic
        ? 'Synthetic test dataset calibration. Intended for software architecture verification. Uncalibrated for regional operations.'
        : (status == ThresholdCalibrationStatus.calibratedRegional
            ? 'Locally calibrated power-law threshold profile fitted via OLS log-linear regression across $count HP event pairs.'
            : 'Uncalibrated profile due to sample size n=$count (< 5 required).');

    final profile = LandslideThresholdProfile(
      profileId: profileId,
      name: profileName,
      coefficientA: aCoeff,
      exponentB: bExponent,
      durationMinHours: 0.1,
      durationMaxHours: 500.0,
      geographicScope: geographicScope,
      landslideType: 'Shallow Landslides / Debris Flows',
      sourceCitation: 'RiskPulse Regional Calibration Engine (Dataset: ${dataset.datasetId})',
      publicationYear: DateTime.now().year,
      calibrationStatus: status,
      notesAndLimitations: notes,
    );

    return CalibrationResult(
      profile: profile,
      rSquared: rSquared,
      sampleCount: count,
      isSynthetic: isSynthetic,
      statusNotes: notes,
    );
  }
}
