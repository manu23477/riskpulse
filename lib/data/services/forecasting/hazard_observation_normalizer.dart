import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/gis/data_source_record.dart';
import 'package:riskpulse/domain/gis/analytical_step.dart';
import 'package:riskpulse/domain/forecasting/hazard_observation.dart';
import 'package:riskpulse/data/services/forecasting/observation_adapter.dart';
import 'package:riskpulse/data/services/forecasting/observation_qc_engine.dart';

/// Provider-neutral normalizer converting external JSON/Map records into [HazardObservation] instances.
class HazardObservationNormalizer implements ObservationAdapter {
  final ObservationQualityControlEngine qcEngine;

  const HazardObservationNormalizer({
    this.qcEngine = const ObservationQualityControlEngine(),
  });

  @override
  HazardObservation normalizeRecord(
    Map<String, dynamic> rawRecord, {
    String? defaultProvider,
  }) {
    final obsId = (rawRecord['observationId'] ?? rawRecord['id'] ?? '') as String;
    final paramId = (rawRecord['parameterId'] ?? rawRecord['parameter'] ?? rawRecord['type'] ?? '') as String;
    final unit = (rawRecord['unit'] ?? '') as String;
    final val = (rawRecord['value'] as num?)?.toDouble() ?? double.nan;

    DateTime obsTime;
    final rawTime = rawRecord['observationTime'] ?? rawRecord['timestamp'] ?? rawRecord['time'];
    if (rawTime is String) {
      obsTime = DateTime.parse(rawTime);
    } else if (rawTime is int) {
      obsTime = DateTime.fromMillisecondsSinceEpoch(rawTime, isUtc: true);
    } else {
      obsTime = DateTime.now().toUtc();
    }

    GeoLocation? loc;
    final lat = (rawRecord['latitude'] ?? rawRecord['lat']) as num?;
    final lon = (rawRecord['longitude'] ?? rawRecord['lon'] ?? rawRecord['lng']) as num?;
    if (lat != null && lon != null) {
      loc = GeoLocation(latitude: lat.toDouble(), longitude: lon.toDouble());
    }

    final provider = (rawRecord['provider'] ?? defaultProvider ?? 'GenericStationNetwork') as String;
    final dataset = (rawRecord['datasetName'] ?? rawRecord['dataset'] ?? 'EnvironmentalTelemetry') as String;

    final dataSource = DataSourceRecord(
      provider: provider,
      datasetName: dataset,
      datasetId: rawRecord['datasetId'] as String?,
      sourceUrl: rawRecord['sourceUrl'] as String?,
      acquisitionDate: obsTime,
      accessDate: DateTime.now().toUtc(),
    );

    final uncertainty = (rawRecord['uncertainty'] as num?)?.toDouble();
    final qualityState = (rawRecord['qualityState'] as String?) ?? 'observed';

    final now = DateTime.now().toUtc();
    final step = AnalyticalStep(
      name: 'observation_normalization',
      operationType: 'ingestion_normalization',
      parameters: {
        'provider': provider,
        'datasetName': dataset,
        'rawKeys': rawRecord.keys.toList(),
      },
      timestamp: now,
    );

    final rawObs = HazardObservation(
      observationId: obsId.isNotEmpty ? obsId : 'obs-${now.millisecondsSinceEpoch}',
      parameterId: paramId,
      value: val,
      unit: unit,
      observationTime: obsTime,
      location: loc,
      dataSource: dataSource,
      qualityState: qualityState,
      uncertainty: uncertainty,
      provenanceSteps: [step],
      metadata: Map<String, dynamic>.from(rawRecord),
    );

    // Apply QC engine
    final qcResult = qcEngine.performQc(rawObs);
    return qcResult.observation;
  }

  @override
  List<HazardObservation> normalizeBatch(
    List<Map<String, dynamic>> rawRecords, {
    String? defaultProvider,
  }) {
    return rawRecords
        .map((rec) => normalizeRecord(rec, defaultProvider: defaultProvider))
        .toList();
  }
}
