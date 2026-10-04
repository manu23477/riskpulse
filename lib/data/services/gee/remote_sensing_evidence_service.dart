import 'package:riskpulse/data/services/evidence/evidence_fusion_service.dart';
import 'package:riskpulse/domain/evidence/event_hypothesis.dart';
import 'package:riskpulse/domain/evidence/evidence_fusion_assessment.dart';
import 'package:riskpulse/domain/evidence/evidence_object.dart';
import 'package:riskpulse/domain/evidence/evidence_provenance.dart';
import 'package:riskpulse/domain/evidence/evidence_source.dart';
import 'package:riskpulse/domain/evidence/evidence_type.dart';
import 'package:riskpulse/domain/gis/remote_sensing_indicator.dart';
import 'package:riskpulse/domain/gis/remote_sensing_observation.dart';

/// Result container emitted upon satellite remote sensing analysis.
class RemoteSensingAnalysisResultContainer {
  final RemoteSensingObservation observation;
  final RemoteSensingIndicator indicator;
  final EvidenceObject evidenceObject;

  const RemoteSensingAnalysisResultContainer({
    required this.observation,
    required this.indicator,
    required this.evidenceObject,
  });
}

/// Gateway service managing satellite remote sensing scientific processing (Sentinel-2, Sentinel-1, Copernicus DEM),
/// cloud masking, physical variable extraction, EvidenceObject conversion, and V1.1 fusion submission.
///
/// STRICT BOUNDARY: SATELLITE SIGNAL IS EVIDENCE, NOT TRUTH. Derived physical variables enter V1.1 fusion
/// and P2.2 revision machinery without bypassing validation gates.
class RemoteSensingEvidenceService {
  /// Calculates Sentinel-2 NDVI index `(B8 - B4) / (B8 + B4)` at 10m spatial resolution.
  RemoteSensingIndicator calculateNdvi({
    required RemoteSensingObservation observation,
    double b4Red = 0.12,
    double b8Nir = 0.48,
    String? indicatorId,
  }) {
    if (observation.cloudCoverageFraction > 0.80) {
      return RemoteSensingIndicator(
        indicatorId: indicatorId ?? 'IND-NDVI-${observation.observationId}',
        observationId: observation.observationId,
        indicatorType: 'NDVI',
        noDataFraction: observation.cloudCoverageFraction,
        methodology: 'Sentinel-2 L2A NDVI (B8-B4)/(B8+B4) [HIGH_CLOUD_MASKED]',
      );
    }

    final double ndvi = (b8Nir - b4Red) / (b8Nir + b4Red);

    return RemoteSensingIndicator(
      indicatorId: indicatorId ?? 'IND-NDVI-${observation.observationId}',
      observationId: observation.observationId,
      indicatorType: 'NDVI',
      meanValue: ndvi,
      noDataFraction: observation.cloudCoverageFraction,
      methodology: 'Sentinel-2 L2A NDVI (B8-B4)/(B8+B4)',
      provenance: {
        'sensor': 'Sentinel-2',
        'bandNIR': 'B8',
        'bandRed': 'B4',
        'scaleFactor': 0.0001,
      },
    );
  }

  /// Calculates Sentinel-2 NDWI index `(B3 - B8) / (B3 + B8)` for surface water detection.
  RemoteSensingIndicator calculateNdwi({
    required RemoteSensingObservation observation,
    double b3Green = 0.25,
    double b8Nir = 0.10,
    String? indicatorId,
  }) {
    final double ndwi = (b3Green - b8Nir) / (b3Green + b8Nir);

    return RemoteSensingIndicator(
      indicatorId: indicatorId ?? 'IND-NDWI-${observation.observationId}',
      observationId: observation.observationId,
      indicatorType: 'NDWI',
      meanValue: ndwi,
      noDataFraction: observation.cloudCoverageFraction,
      methodology: 'Sentinel-2 L2A NDWI (B3-B8)/(B3+B8)',
    );
  }

  /// Calculates Sentinel-2 NBR index `(B8 - B12) / (B8 + B12)` for burn scar detection.
  RemoteSensingIndicator calculateNbr({
    required RemoteSensingObservation observation,
    double b8Nir = 0.35,
    double b12Swir = 0.15,
    String? indicatorId,
  }) {
    final double nbr = (b8Nir - b12Swir) / (b8Nir + b12Swir);

    return RemoteSensingIndicator(
      indicatorId: indicatorId ?? 'IND-NBR-${observation.observationId}',
      observationId: observation.observationId,
      indicatorType: 'NBR',
      meanValue: nbr,
      noDataFraction: observation.cloudCoverageFraction,
      methodology: 'Sentinel-2 L2A NBR (B8-B12)/(B8+B12)',
    );
  }

  /// Calculates Sentinel-1 SAR VV/VH backscatter change between pre and post acquisitions.
  RemoteSensingIndicator calculateSarBackscatterChange({
    required RemoteSensingObservation preObservation,
    required RemoteSensingObservation postObservation,
    double preVV = -12.5,
    double postVV = -18.2,
    String? indicatorId,
  }) {
    final double diffDb = postVV - preVV;

    return RemoteSensingIndicator(
      indicatorId: indicatorId ?? 'IND-SAR-${postObservation.observationId}',
      observationId: postObservation.observationId,
      indicatorType: 'SAR_BACKSCATTER_CHANGE',
      preEventTimestamp: preObservation.acquisitionTimestamp,
      postEventTimestamp: postObservation.acquisitionTimestamp,
      changeFraction: diffDb,
      noDataFraction: 0.0,
      methodology: 'Sentinel-1 GRD VV Backscatter Difference (dB)',
    );
  }

  /// Converts derived physical indicator into a canonical [EvidenceObject].
  EvidenceObject convertToEvidenceObject(
    RemoteSensingIndicator indicator,
    RemoteSensingObservation observation,
  ) {
    return EvidenceObject(
      evidenceId: 'EVID-RS-${indicator.indicatorId}',
      observationId: indicator.indicatorId,
      evidenceType: EvidenceType.remoteSensing,
      source: EvidenceSource(
        sourceSystem: observation.datasetName,
        sourceId: observation.sceneId,
        sourceName: 'European Space Agency ${observation.datasetName}',
      ),
      sourceId: observation.sceneId,
      sourceName: 'ESA ${observation.datasetName}',
      sourcePublisher: 'ESA ${observation.datasetName}',
      description: 'Satellite Remote Sensing Physical Measurement: ${indicator.indicatorType} (${indicator.methodology})',
      observedAt: observation.acquisitionTimestamp,
      publishedAt: observation.acquisitionTimestamp,
      geometry: observation.bounds,
      isModelOutput: true,
      modelName: indicator.methodology,
      provenance: EvidenceProvenance(
        sourceSystem: observation.datasetName,
        sourceId: observation.sceneId,
      ),
    );
  }

  /// Submits remote sensing EvidenceObject to V1.1 EvidenceFusionService.
  Future<EvidenceFusionAssessment> submitToFusionPipeline({
    required EvidenceObject rsEvidence,
    required EventHypothesis hypothesis,
    required EvidenceFusionService fusionService,
  }) async {
    return fusionService.evaluateEvidenceFusion(
      hypothesis: hypothesis,
      evidenceList: [rsEvidence],
    );
  }
}
