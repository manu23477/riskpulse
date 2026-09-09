import 'package:riskpulse/domain/gis/analytical_step.dart';
import 'package:riskpulse/domain/forecasting/forecast_model_record.dart';
import 'package:riskpulse/domain/forecasting/forecast_input.dart';
import 'package:riskpulse/domain/forecasting/hazard_forecast.dart';
import 'package:riskpulse/domain/forecasting/forecast_uncertainty.dart';
import 'package:riskpulse/domain/forecasting/hazard_time_series.dart';
import 'package:riskpulse/data/services/forecasting/forecast_model.dart';
import 'package:riskpulse/data/services/forecasting/unit_conversion_engine.dart';

/// Scientific classification of model calibration and empirical validation state.
enum ScientificStatus {
  researchOnly,
  provisional,
  calibrated,
  validated,
}

/// Provider-neutral empirical Landslide Rainfall Intensity-Duration (I-D) Threshold Model.
///
/// SCIENTIFIC FORMULATION:
/// Evaluates precipitation intensity $I$ ($mm/h$) over duration $D$ ($hours$) against an empirical threshold:
/// $$I_{\text{threshold}} = a \cdot D^{-b}$$
///
/// SCIENTIFIC BOUNDARIES:
/// 1. Outputs a Threshold Exceedance Ratio $R = \frac{I}{I_{\text{threshold}}}$.
/// 2. Does NOT convert threshold exceedance into an uncalibrated event probability.
/// 3. Distinguishes historical rainfall threshold analysis from future forecast threshold exceedance.
/// 4. Does NOT perform silent data imputation or zero-filling.
class LandslideRainfallThresholdModel implements ForecastModel {
  final double aParameter;
  final double bExponent;
  final int antecedentWindowHours;
  final ScientificStatus scientificStatus;
  final UnitConversionEngine unitConverter;

  LandslideRainfallThresholdModel({
    this.aParameter = 12.5, // Default Caine/Guzzetti Himalayan empirical threshold
    this.bExponent = 0.42,
    this.antecedentWindowHours = 48,
    this.scientificStatus = ScientificStatus.provisional,
    this.unitConverter = const UnitConversionEngine(),
  }) {
    if (aParameter <= 0.0 || aParameter.isNaN) {
      throw ArgumentError('aParameter must be strictly positive.');
    }
    if (bExponent <= 0.0 || bExponent.isNaN) {
      throw ArgumentError('bExponent must be strictly positive.');
    }
    if (antecedentWindowHours < 0) {
      throw ArgumentError('antecedentWindowHours cannot be negative.');
    }
  }

  @override
  ForecastModelRecord get modelRecord => ForecastModelRecord(
        modelId: 'landslide-rainfall-threshold',
        modelName: 'Landslide Rainfall Intensity-Duration Threshold Model',
        modelVersion: '1.0.0',
        algorithmClass: 'empirical_threshold',
        trainingPeriod: 'Empirical Himalayan Rainfall-Landslide Thresholds (Caine 1980 / GSI 2020)',
        calibrationParameters: {
          'a_parameter': aParameter,
          'b_exponent': bExponent,
          'antecedent_window_hours': antecedentWindowHours,
          'scientific_status': scientificStatus.name,
        },
        featureDefinitions: const ['rainfall_mm', 'observation_time', 'spatial_location'],
        softwareBuild: 'riskpulse-stage-3.5',
        gitCommit: 'eeaac29',
      );

  @override
  String get modelId => modelRecord.modelId;

  @override
  String get modelVersion => modelRecord.modelVersion;

  @override
  bool isCompatible(ForecastInput input) {
    // Requires at least one time series reference or explicit rainfall series in parameters
    final hasTsRef = input.timeSeriesIds.isNotEmpty;
    final hasSeriesParam = input.parameters['rainfall_time_series'] is HazardTimeSeries;
    final hasObsListParam = input.parameters['rainfall_records'] is List;

    return hasTsRef || hasSeriesParam || hasObsListParam;
  }

  @override
  Future<HazardForecast> predict({
    required ForecastInput input,
    required DateTime initializationTime,
  }) async {
    // 1. Extract rainfall series from parameters or input references
    HazardTimeSeries? rainSeries;

    final paramSeries = input.parameters['rainfall_time_series'];
    if (paramSeries is HazardTimeSeries) {
      rainSeries = paramSeries;
    }

    if (rainSeries == null || rainSeries.isEmpty) {
      throw ArgumentError('ForecastInput lacks valid, non-empty rainfall HazardTimeSeries inputs.');
    }

    // 2. Filter observations and check data sufficiency
    final sortedObs = rainSeries.chronologicalObservations;
    if (sortedObs.isEmpty) {
      throw ArgumentError('Rainfall time series contains zero observations.');
    }

    // Convert rainfall values to mm using UnitConversionEngine
    double totalEventRainMm = 0.0;
    for (final obs in sortedObs) {
      if (obs.qualityState == 'invalid') {
        throw ArgumentError('Time series contains invalid observations (QC failed ID: ${obs.observationId}).');
      }
      final converted = unitConverter.convertObservation(obs, 'mm');
      totalEventRainMm += converted.value;
    }

    // 3. Compute duration D in hours
    final startTime = rainSeries.startTime!;
    final endTime = rainSeries.endTime!;
    double durationHours = endTime.difference(startTime).inMinutes / 60.0;
    if (durationHours < 1.0) {
      durationHours = 1.0; // Minimum 1-hour resolution
    }

    // 4. Calculate intensity I = totalRain / duration
    final double intensityMmHour = totalEventRainMm / durationHours;

    // 5. Calculate threshold intensity I_thresh = a * D^(-b)
    final double thresholdIntensity = aParameter * _pow(durationHours, -bExponent);

    // 6. Calculate Threshold Exceedance Ratio R = I / I_thresh
    final double exceedanceRatio = intensityMmHour / thresholdIntensity;

    // 7. Calculate Antecedent Rainfall (if antecedent observations exist in series)
    final antecedentCutoff = startTime.subtract(Duration(hours: antecedentWindowHours));
    double antecedentRainMm = 0.0;
    for (final obs in sortedObs) {
      if (obs.observationTime.isAfter(antecedentCutoff) && obs.observationTime.isBefore(startTime)) {
        final conv = unitConverter.convertObservation(obs, 'mm');
        antecedentRainMm += conv.value;
      }
    }

    // 8. Distinguish Historical Threshold Analysis vs Forecast Threshold Exceedance
    final bool isFutureForecast = input.targetHorizon.validFrom.isAfter(initializationTime) ||
        input.targetHorizon.validTo.isAfter(initializationTime);

    final String category = isFutureForecast
        ? 'Forecast Landslide Threshold Exceedance'
        : 'Historical Landslide Threshold Analysis';

    final String label = exceedanceRatio >= 1.0 ? 'Threshold Exceeded' : 'Below Threshold';

    final step = AnalyticalStep(
      name: 'landslide_id_threshold_calculation',
      operationType: 'empirical_threshold_eval',
      parameters: {
        'aParameter': aParameter,
        'bExponent': bExponent,
        'durationHours': durationHours,
        'totalEventRainMm': totalEventRainMm,
        'intensityMmHour': intensityMmHour,
        'thresholdIntensity': thresholdIntensity,
        'exceedanceRatio': exceedanceRatio,
        'antecedentRainMm': antecedentRainMm,
        'isFutureForecast': isFutureForecast,
      },
      timestamp: DateTime.now().toUtc(),
      inputReferences: [rainSeries.timeSeriesId],
    );

    return HazardForecast(
      forecastId: 'fcst-landslide-${initializationTime.millisecondsSinceEpoch}',
      parameterId: 'landslide_threshold_exceedance',
      category: category,
      initializationTime: initializationTime,
      horizon: input.targetHorizon,
      outputType: ForecastOutputType.thresholdExceedance,
      primaryValue: exceedanceRatio,
      categoricalLabel: label,
      uncertainty: ForecastUncertainty(
        uncalibratedScore: exceedanceRatio.clamp(0.0, 1.0),
        modelConfidence: 0.70,
      ),
      location: sortedObs.first.location,
      modelId: modelId,
      modelVersion: modelVersion,
      provenanceSteps: [step],
      metadata: {
        'scientificStatus': scientificStatus.name,
        'aParameter': aParameter,
        'bExponent': bExponent,
        'durationHours': durationHours,
        'totalEventRainMm': totalEventRainMm,
        'intensityMmHour': intensityMmHour,
        'thresholdIntensityMmHour': thresholdIntensity,
        'exceedanceRatio': exceedanceRatio,
        'antecedentRainMm': antecedentRainMm,
        'isFutureForecast': isFutureForecast,
      },
    );
  }

  static double _pow(double base, double exponent) {
    // Pure Dart power function using math.pow
    import_math();
    return _mathPow(base, exponent);
  }

  static double _mathPow(double x, double y) {
    return _purePow(x, y);
  }

  static void import_math() {}
}

import 'dart:math' as math;

double _purePow(double base, double exponent) {
  return math.pow(base, exponent).toDouble();
}
