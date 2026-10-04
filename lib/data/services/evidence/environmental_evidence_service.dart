import 'package:riskpulse/data/repositories/environmental_repository.dart';
import 'package:riskpulse/data/services/evidence/evidence_fusion_service.dart';
import 'package:riskpulse/domain/evidence/environmental_indicator.dart';
import 'package:riskpulse/domain/evidence/environmental_observation_category.dart';
import 'package:riskpulse/domain/evidence/environmental_raw_observation.dart';
import 'package:riskpulse/domain/evidence/event_hypothesis.dart';
import 'package:riskpulse/domain/evidence/evidence_fusion_assessment.dart';
import 'package:riskpulse/domain/evidence/evidence_object.dart';
import 'package:riskpulse/domain/evidence/evidence_provenance.dart';
import 'package:riskpulse/domain/evidence/evidence_source.dart';
import 'package:riskpulse/domain/evidence/evidence_type.dart';

/// Result container emitted upon environmental observation processing.
class EnvironmentalProcessingResultContainer {
  final EnvironmentalRawObservation rawObservation;
  final List<EnvironmentalIndicator> indicators;
  final List<EvidenceObject> evidenceObjects;

  const EnvironmentalProcessingResultContainer({
    required this.rawObservation,
    required this.indicators,
    required this.evidenceObjects,
  });
}

/// Gateway service managing automated meteorological & hydrological observation processing,
/// accumulation window calculations, EvidenceObject conversion, and V1.1 fusion submission.
///
/// STRICT BOUNDARY: OBSERVES ENVIRONMENTAL CONDITIONS, DOES NOT MODEL HYDROLOGICAL RESPONSE (V1.5).
class EnvironmentalEvidenceService {
  final EnvironmentalRepository repository;

  EnvironmentalEvidenceService({required this.repository});

  /// Ingests a raw meteorological/river observation, calculates derived indicators, and converts to EvidenceObjects.
  Future<EnvironmentalProcessingResultContainer> ingestObservation(EnvironmentalRawObservation raw) async {
    await repository.saveRawObservation(raw);

    final List<EnvironmentalIndicator> indicators = [];
    final List<EvidenceObject> evidenceList = [];

    // 1. Process Precipitation variables
    if (raw.variables.containsKey('precipitation_24h_mm')) {
      final double val = (raw.variables['precipitation_24h_mm'] as num).toDouble();
      final ind = EnvironmentalIndicator(
        indicatorId: 'IND-PRECIP24H-${raw.rawObservationId}',
        rawObservationId: raw.rawObservationId,
        variableName: 'PRECIPITATION_24H',
        accumulationWindowHours: 24.0,
        numericValue: val,
        unit: 'mm',
        isForecast: raw.category == EnvironmentalObservationCategory.forecast,
        methodology: '24-hour precipitation accumulation sum',
      );
      indicators.add(ind);
      await repository.saveIndicator(ind);
      evidenceList.add(convertToEvidenceObject(ind, raw));
    }

    // 2. Process River Stage variables
    if (raw.variables.containsKey('river_stage_m')) {
      final double val = (raw.variables['river_stage_m'] as num).toDouble();
      final double? prevVal = raw.variables['previous_river_stage_m'] != null
          ? (raw.variables['previous_river_stage_m'] as num).toDouble()
          : null;
      final String trend = (prevVal != null && val > prevVal)
          ? 'RISING'
          : ((prevVal != null && val < prevVal) ? 'FALLING' : 'STABLE');

      final ind = EnvironmentalIndicator(
        indicatorId: 'IND-STAGE-${raw.rawObservationId}',
        rawObservationId: raw.rawObservationId,
        variableName: 'RIVER_STAGE',
        numericValue: val,
        unit: 'm',
        trend: trend,
        methodology: 'River gauge water level measurement',
      );
      indicators.add(ind);
      await repository.saveIndicator(ind);
      evidenceList.add(convertToEvidenceObject(ind, raw));
    }

    // 3. Fallback general weather observation if no specific variables match
    if (indicators.isEmpty && raw.variables.containsKey('temperature_c')) {
      final double val = (raw.variables['temperature_c'] as num).toDouble();
      final ind = EnvironmentalIndicator(
        indicatorId: 'IND-TEMP-${raw.rawObservationId}',
        rawObservationId: raw.rawObservationId,
        variableName: 'TEMPERATURE',
        numericValue: val,
        unit: 'C',
        methodology: 'Ambient surface temperature observation',
      );
      indicators.add(ind);
      await repository.saveIndicator(ind);
      evidenceList.add(convertToEvidenceObject(ind, raw));
    }

    return EnvironmentalProcessingResultContainer(
      rawObservation: raw,
      indicators: indicators,
      evidenceObjects: evidenceList,
    );
  }

  /// Converts an [EnvironmentalIndicator] into a canonical [EvidenceObject].
  EvidenceObject convertToEvidenceObject(
    EnvironmentalIndicator indicator,
    EnvironmentalRawObservation raw,
  ) {
    final EvidenceType type = indicator.variableName.startsWith('RIVER')
        ? EvidenceType.riverGauge
        : EvidenceType.weather;

    return EvidenceObject(
      evidenceId: 'EVID-ENV-${indicator.indicatorId}',
      observationId: raw.rawObservationId,
      evidenceType: type,
      source: EvidenceSource(
        sourceSystem: raw.sourceSystem,
        sourceId: raw.stationId,
        sourceName: raw.stationName,
      ),
      sourceId: raw.stationId,
      sourceName: raw.stationName,
      sourcePublisher: raw.sourceSystem,
      description: 'Environmental Measurement (${indicator.variableName}): ${indicator.numericValue ?? 0.0} ${indicator.unit} [Trend: ${indicator.trend}]',
      observedAt: raw.observedAt,
      receivedAt: raw.receivedAt,
      geometry: raw.location != null
          ? {
              'type': 'Point',
              'coordinates': [raw.location!.longitude, raw.location!.latitude]
            }
          : null,
      provenance: EvidenceProvenance(
        sourceSystem: raw.sourceSystem,
        sourceId: raw.stationId,
      ),
    );
  }

  /// Submits environmental EvidenceObject to V1.1 EvidenceFusionService.
  Future<EvidenceFusionAssessment> submitToFusionPipeline({
    required EvidenceObject envEvidence,
    required EventHypothesis hypothesis,
    required EvidenceFusionService fusionService,
  }) async {
    return fusionService.evaluateEvidenceFusion(
      hypothesis: hypothesis,
      evidenceList: [envEvidence],
    );
  }
}
