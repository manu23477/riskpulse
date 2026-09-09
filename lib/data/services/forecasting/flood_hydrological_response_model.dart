import 'package:riskpulse/domain/gis/analytical_step.dart';
import 'package:riskpulse/domain/forecasting/forecast_model_record.dart';
import 'package:riskpulse/domain/forecasting/forecast_input.dart';
import 'package:riskpulse/domain/forecasting/hazard_forecast.dart';
import 'package:riskpulse/domain/forecasting/forecast_uncertainty.dart';
import 'package:riskpulse/domain/forecasting/hazard_time_series.dart';
import 'package:riskpulse/data/services/forecasting/forecast_model.dart';
import 'package:riskpulse/data/services/forecasting/unit_conversion_engine.dart';
import 'package:riskpulse/data/services/forecasting/landslide_rainfall_threshold_model.dart';

/// Provider-neutral empirical Flood Catchment Hydrological Response Model.
///
/// SCIENTIFIC FORMULATION:
/// Estimates peak discharge $Q$ ($m^3/s$) using the Rational Catchment Response Formula:
/// $$Q = \frac{C \cdot i \cdot A}{3.6}$$
/// where:
/// - $C$: Runoff coefficient ($0.0 \dots 1.0$) representing catchment permeability/slope
/// - $i$: Peak precipitation intensity ($mm/h$)
/// - $A$: Catchment drainage area ($km^2$)
///
/// SCIENTIFIC BOUNDARIES:
/// 1. Outputs peak discharge intensity $Q$ ($m^3/s$) and threshold exceedance ratio $R_Q = \frac{Q}{Q_{\text{threshold}}}$.
/// 2. Does NOT convert discharge estimation into an uncalibrated event probability.
/// 3. Distinguishes historical flood response from future flood response forecasts.
/// 4. Does NOT perform silent data imputation.
class FloodHydrologicalResponseModel implements ForecastModel {
  final double runoffCoefficientC;
  final double catchmentAreaKm2;
  final double dischargeThresholdM3s;
  final ScientificStatus scientificStatus;
  final UnitConversionEngine unitConverter;

  FloodHydrologicalResponseModel({
    this.runoffCoefficientC = 0.65, // Steep mountainous/rocky catchment default
    this.catchmentAreaKm2 = 120.0,
    this.dischargeThresholdM3s = 150.0,
    this.scientificStatus = ScientificStatus.provisional,
    this.unitConverter = const UnitConversionEngine(),
  }) {
    if (runoffCoefficientC <= 0.0 || runoffCoefficientC > 1.0 || runoffCoefficientC.isNaN) {
      throw ArgumentError('runoffCoefficientC must be between 0.0 and 1.0.');
    }
    if (catchmentAreaKm2 <= 0.0 || catchmentAreaKm2.isNaN) {
      throw ArgumentError('catchmentAreaKm2 must be strictly positive.');
    }
    if (dischargeThresholdM3s <= 0.0 || dischargeThresholdM3s.isNaN) {
      throw ArgumentError('dischargeThresholdM3s must be strictly positive.');
    }
  }

  @override
  ForecastModelRecord get modelRecord => ForecastModelRecord(
        modelId: 'flood-hydrological-response',
        modelName: 'Flood Catchment Hydrological Response Model',
        modelVersion: '1.0.0',
        algorithmClass: 'hydrological_response',
        trainingPeriod: 'Rational Catchment Hydrograph Response (Chow et al. 1988)',
        calibrationParameters: {
          'runoff_coefficient_C': runoffCoefficientC,
          'catchment_area_km2': catchmentAreaKm2,
          'discharge_threshold_m3s': dischargeThresholdM3s,
          'scientific_status': scientificStatus.name,
        },
        featureDefinitions: const ['rainfall_mm', 'river_discharge_m3s', 'catchment_area_km2'],
        softwareBuild: 'riskpulse-stage-3.5',
        gitCommit: 'eeaac29',
      );

  @override
  String get modelId => modelRecord.modelId;

  @override
  String get modelVersion => modelRecord.modelVersion;

  @override
  bool isCompatible(ForecastInput input) {
    final hasTsRef = input.timeSeriesIds.isNotEmpty;
    final hasSeriesParam = input.parameters['rainfall_time_series'] is HazardTimeSeries ||
        input.parameters['discharge_time_series'] is HazardTimeSeries;

    return hasTsRef || hasSeriesParam;
  }

  @override
  Future<HazardForecast> predict({
    required ForecastInput input,
    required DateTime initializationTime,
  }) async {
    // 1. Extract rainfall series or discharge series
    HazardTimeSeries? rainSeries;
    final paramSeries = input.parameters['rainfall_time_series'];
    if (paramSeries is HazardTimeSeries) {
      rainSeries = paramSeries;
    }

    if (rainSeries == null || rainSeries.isEmpty) {
      throw ArgumentError('ForecastInput lacks valid rainfall HazardTimeSeries inputs for flood response analysis.');
    }

    // 2. Filter observations and convert to mm
    final sortedObs = rainSeries.chronologicalObservations;
    if (sortedObs.isEmpty) {
      throw ArgumentError('Rainfall time series contains zero observations.');
    }

    double maxIntensityMmHour = 0.0;
    double totalRainMm = 0.0;

    for (final obs in sortedObs) {
      if (obs.qualityState == 'invalid') {
        throw ArgumentError('Time series contains invalid observations (QC failed ID: ${obs.observationId}).');
      }
      final conv = unitConverter.convertObservation(obs, 'mm');
      totalRainMm += conv.value;
      if (conv.value > maxIntensityMmHour) {
        maxIntensityMmHour = conv.value;
      }
    }

    // 3. Compute Rational Formula Peak Discharge Q = (C * i * A) / 3.6
    final double peakDischargeM3s = (runoffCoefficientC * maxIntensityMmHour * catchmentAreaKm2) / 3.6;

    // 4. Calculate Discharge Exceedance Ratio R_Q = Q / Q_threshold
    final double exceedanceRatio = peakDischargeM3s / dischargeThresholdM3s;

    // 5. Distinguish Historical Analysis vs Forecast
    final bool isFutureForecast = input.targetHorizon.validFrom.isAfter(initializationTime) ||
        input.targetHorizon.validTo.isAfter(initializationTime);

    final String category = isFutureForecast
        ? 'Forecast Flood Hydrological Response'
        : 'Historical Flood Hydrological Analysis';

    final String label = exceedanceRatio >= 1.0 ? 'High Discharge Response' : 'Normal Response';

    final step = AnalyticalStep(
      name: 'rational_flood_discharge_calculation',
      operationType: 'hydrological_response_eval',
      parameters: {
        'runoffCoefficientC': runoffCoefficientC,
        'catchmentAreaKm2': catchmentAreaKm2,
        'peakIntensityMmHour': maxIntensityMmHour,
        'peakDischargeM3s': peakDischargeM3s,
        'dischargeThresholdM3s': dischargeThresholdM3s,
        'exceedanceRatio': exceedanceRatio,
        'isFutureForecast': isFutureForecast,
      },
      timestamp: DateTime.now().toUtc(),
      inputReferences: [rainSeries.timeSeriesId],
    );

    return HazardForecast(
      forecastId: 'fcst-flood-${initializationTime.millisecondsSinceEpoch}',
      parameterId: 'flood_peak_discharge',
      category: category,
      initializationTime: initializationTime,
      horizon: input.targetHorizon,
      outputType: ForecastOutputType.intensity,
      primaryValue: peakDischargeM3s,
      categoricalLabel: label,
      uncertainty: ForecastUncertainty(
        uncalibratedScore: (exceedanceRatio / 2.0).clamp(0.0, 1.0),
        modelConfidence: 0.65,
      ),
      location: sortedObs.first.location,
      modelId: modelId,
      modelVersion: modelVersion,
      provenanceSteps: [step],
      metadata: {
        'scientificStatus': scientificStatus.name,
        'runoffCoefficientC': runoffCoefficientC,
        'catchmentAreaKm2': catchmentAreaKm2,
        'peakIntensityMmHour': maxIntensityMmHour,
        'peakDischargeM3s': peakDischargeM3s,
        'dischargeThresholdM3s': dischargeThresholdM3s,
        'exceedanceRatio': exceedanceRatio,
        'isFutureForecast': isFutureForecast,
      },
    );
  }
}
