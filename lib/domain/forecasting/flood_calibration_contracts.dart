import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/location/geo_location.dart';

/// Immutable domain record representing an observed flood event for catchment calibration.
@immutable
class FloodEventRecord {
  final String eventId;
  final DateTime eventDate;
  final DateTime? eventStartTime;
  final DateTime? eventEndTime;
  final GeoLocation location;
  final String basin;
  final String riverName;
  final String floodCategory;
  final String source;
  final String? sourceUrl;
  final bool isSynthetic;

  const FloodEventRecord({
    required this.eventId,
    required this.eventDate,
    this.eventStartTime,
    this.eventEndTime,
    required this.location,
    required this.basin,
    required this.riverName,
    this.floodCategory = 'Flash Flood / Riverine Surge',
    required this.source,
    this.sourceUrl,
    this.isSynthetic = false,
  })  : assert(eventId.length > 0, 'eventId cannot be empty.'),
        assert(basin.length > 0, 'basin cannot be empty.'),
        assert(riverName.length > 0, 'riverName cannot be empty.');
}

/// Immutable domain record representing a stream-gauge station.
@immutable
class GaugeStationRecord {
  final String stationId;
  final String stationName;
  final GeoLocation location;
  final double elevationMeters;
  final String riverName;
  final String basinName;
  final String managingAgency;
  final String source;
  final String datumInformation;
  final bool isSynthetic;

  const GaugeStationRecord({
    required this.stationId,
    required this.stationName,
    required this.location,
    this.elevationMeters = 0.0,
    required this.riverName,
    required this.basinName,
    this.managingAgency = 'CWC / HP Irrigation & Public Health',
    required this.source,
    this.datumInformation = 'MSL (Mean Sea Level)',
    this.isSynthetic = false,
  })  : assert(stationId.length > 0, 'stationId cannot be empty.'),
        assert(stationName.length > 0, 'stationName cannot be empty.');
}

/// Immutable domain record representing a time-series gauge observation (stage and/or discharge).
@immutable
class GaugeObservationRecord {
  final String observationId;
  final String stationId;
  final DateTime timestamp;
  final double? waterLevelMeters; // Stage in meters
  final double? dischargeM3s;     // Discharge in m3/s
  final String qualityState;
  final bool isSynthetic;

  const GaugeObservationRecord({
    required this.observationId,
    required this.stationId,
    required this.timestamp,
    this.waterLevelMeters,
    this.dischargeM3s,
    this.qualityState = 'valid_qc_passed',
    this.isSynthetic = false,
  })  : assert(observationId.length > 0, 'observationId cannot be empty.'),
        assert(stationId.length > 0, 'stationId cannot be empty.'),
        assert(
          waterLevelMeters != null || dischargeM3s != null,
          'GaugeObservationRecord must contain at least waterLevelMeters or dischargeM3s.',
        );

  bool get hasDischarge => dischargeM3s != null && !dischargeM3s!.isNaN && dischargeM3s! >= 0.0;
  bool get hasStage => waterLevelMeters != null && !waterLevelMeters!.isNaN && waterLevelMeters! >= 0.0;
}

/// Immutable calibration dataset contract containing flood events, gauge stations, and time-series observations.
@immutable
class FloodCalibrationDataset {
  final String datasetId;
  final String datasetName;
  final List<FloodEventRecord> floodEvents;
  final List<GaugeStationRecord> gaugeStations;
  final List<GaugeObservationRecord> observations;
  final String geographicScope;
  final String provenance;
  final bool isSyntheticDataset;

  const FloodCalibrationDataset({
    required this.datasetId,
    required this.datasetName,
    required this.floodEvents,
    required this.gaugeStations,
    required this.observations,
    required this.geographicScope,
    required this.provenance,
    this.isSyntheticDataset = false,
  });

  int get totalEvents => floodEvents.length;
  int get totalStations => gaugeStations.length;
  int get totalObservations => observations.length;

  /// Evaluates dataset sufficiency for hydrological calibration.
  bool get isSufficientForCalibration =>
      totalEvents >= 5 && totalObservations >= 10 && !isSyntheticDataset;
}
