import 'package:riskpulse/domain/gis/analytical_step.dart';
import 'package:riskpulse/domain/forecasting/forecast_model_record.dart';
import 'package:riskpulse/domain/forecasting/forecast_input.dart';
import 'package:riskpulse/domain/forecasting/hazard_forecast.dart';
import 'package:riskpulse/domain/forecasting/forecast_uncertainty.dart';
import 'package:riskpulse/domain/forecasting/hazard_time_series.dart';
import 'package:riskpulse/domain/forecasting/landslide_threshold_profile.dart';
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
/// Evaluates precipitation intensity $I$ ($mm/h$) over duration $D$ ($hours$) against an empirical threshold profile:
/// $$I_{\text{threshold}} = a \cdot D^{-b}$$
///
/// SCIENTIFIC PROVENANCE CORRECTION (Stage 3.5-R):
/// 1. Default threshold profile is [LandslideThresholdProfile.caine1980Global]: $I = 14.82 D^{-0.39}$.
/// 2. Profile is explicitly classified as Global Empirical Reference (Uncalibrated for Himachal Pradesh).
/// 3. Antecedent rainfall window ($48$-hour default) is explicitly separated from the primary I-D equation.
/// 4. Outputs Threshold Exceedance Ratio $R = \frac{I}{I_{\text{threshold}}}$.
/// 5. Does NOT convert threshold exceedance into an uncalibrated event probability.
class LandslideRainfallThresholdModel implements ForecastModel {
  final LandslideThresholdProfile profile;
  final int antecedentWindowHours;
  final ScientificStatus scientificStatus;
  final UnitConversionEngine unitConverter;

  LandslideRainfallThresholdModel({
    this.profile = LandslideThresholdProfile.caine1980Global,
    this.antecedentWindowHours = 48,
    this.scientificStatus = ScientificStatus.provisional,
    this.unitConverter = const UnitConversionEngine(),
  }) {
    if (antecedentWindowHours < 0) {
      throw ArgumentError('antecedentWindowHours cannot be negative.');
    }
  }

  double get aParameter => profile.coefficientA;
  double get bExponent => profile.exponentB;

  @override
  ForecastModelRecord get modelRecord => ForecastModelRecord(
        modelId: 'landslide-rainfall-threshold',
        modelName: 'Landslide Rainfall Intensity-Duration Threshold Model',
        modelVersion: '1.1.0',
        algorithmClass: 'empirical_threshold',
        trainingPeriod: profile.sourceCitation,
        calibrationParameters: {
          'threshold_profile_id': profile.profileId,
          'threshold_profile_name': profile.name,
          'coefficient_a': profile.coefficientA,
          'exponent_b': profile.exponentB,
          'geographic_scope': profile.geographicScope,
          'source_citation': profile.sourceCitation,
          'antecedent_window_hours': antecedentWindowHours,
          'antecedent_window_attribution':
              'Model-Specific Additional Configuration (Explicitly Separated from I-D Equation)',
          'calibration_status': profile.calibrationStatus.name,
          'scientific_status': scientificStatus.name,
        },
        featureDefinitions: const ['rainfall_mm', 'observation_time', 'spatial_location'],
        softwareBuild: 'riskpulse-stage-3.5-r',
        gitCommit: 'eeaac29',
      );

  @override
  String get modelId => modelRecord.modelId;

  @override
  String get modelVersion => modelRecord.modelVersion;

  @override
  bool isCompatible(ForecastInput input) {
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
    // 1. Extract rainfall series
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
    if (durationHours < profile.durationMinHours) {
      durationHours = profile.durationMinHours;
    }

    // 4. Calculate intensity I = totalRain / duration
    final double intensityMmHour = totalEventRainMm / durationHours;

    // 5. Calculate threshold intensity I_thresh using LandslideThresholdProfile
    final double thresholdIntensity = profile.calculateThresholdIntensity(durationHours);

    // 6. Calculate Threshold Exceedance Ratio R = I / I_thresh
    final double exceedanceRatio = profile.calculateExceedanceRatio(
      intensityMmHour: intensityMmHour,
      durationHours: durationHours,
    );

    // 7. Calculate Antecedent Rainfall Condition (Explicitly Separated from I-D Equation)
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
        'profileId': profile.profileId,
        'profileName': profile.name,
        'coefficientA': profile.coefficientA,
        'exponentB': profile.exponentB,
        'sourceCitation': profile.sourceCitation,
        'durationHours': durationHours,
        'totalEventRainMm': totalEventRainMm,
        'intensityMmHour': intensityMmHour,
        'thresholdIntensityMmHour': thresholdIntensity,
        'exceedanceRatio': exceedanceRatio,
        'antecedentWindowHours': antecedentWindowHours,
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
        'profileId': profile.profileId,
        'profileName': profile.name,
        'coefficientA': profile.coefficientA,
        'exponentB': profile.exponentB,
        'geographicScope': profile.geographicScope,
        'sourceCitation': profile.sourceCitation,
        'durationHours': durationHours,
        'totalEventRainMm': totalEventRainMm,
        'intensityMmHour': intensityMmHour,
        'thresholdIntensityMmHour': thresholdIntensity,
        'exceedanceRatio': exceedanceRatio,
        'antecedentWindowHours': antecedentWindowHours,
        'antecedentRainMm': antecedentRainMm,
        'isFutureForecast': isFutureForecast,
      },
    );
  }
}
