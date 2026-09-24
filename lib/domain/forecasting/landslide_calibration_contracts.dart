import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/location/geo_location.dart';

/// Immutable domain record representing an observed or historical landslide event for calibration.
@immutable
class LandslideEventRecord {
  final String eventId;
  final DateTime eventDate;
  final GeoLocation location;
  final String district;
  final String state;
  final String landslideType;
  final String source;
  final String? sourceUrl;
  final bool isSynthetic;

  const LandslideEventRecord({
    required this.eventId,
    required this.eventDate,
    required this.location,
    required this.district,
    required this.state,
    this.landslideType = 'Shallow Landslide / Debris Flow',
    required this.source,
    this.sourceUrl,
    this.isSynthetic = false,
  })  : assert(eventId.length > 0, 'eventId cannot be empty.'),
        assert(district.length > 0, 'district cannot be empty.'),
        assert(state.length > 0, 'state cannot be empty.');
}

/// Immutable domain record representing an observed rainfall station time-series sample for calibration.
@immutable
class RainfallStationRecord {
  final String stationId;
  final String stationName;
  final GeoLocation location;
  final double elevationMeters;
  final DateTime observationTime;
  final double rainfallAmountMm;
  final double accumulationPeriodHours;
  final String dataQuality;
  final bool isSynthetic;

  const RainfallStationRecord({
    required this.stationId,
    required this.stationName,
    required this.location,
    this.elevationMeters = 0.0,
    required this.observationTime,
    required this.rainfallAmountMm,
    required this.accumulationPeriodHours,
    this.dataQuality = 'valid_qc_passed',
    this.isSynthetic = false,
  })  : assert(stationId.length > 0, 'stationId cannot be empty.'),
        assert(rainfallAmountMm >= 0.0, 'rainfallAmountMm cannot be negative.'),
        assert(accumulationPeriodHours > 0.0, 'accumulationPeriodHours must be strictly positive.');

  double get rainfallIntensityMmHour => rainfallAmountMm / accumulationPeriodHours;
}

/// Immutable calibration dataset contract containing landslide events and rainfall station records.
@immutable
class LandslideCalibrationDataset {
  final String datasetId;
  final String datasetName;
  final List<LandslideEventRecord> landslideEvents;
  final List<RainfallStationRecord> rainfallRecords;
  final String geographicScope;
  final String provenance;
  final bool isSyntheticDataset;

  const LandslideCalibrationDataset({
    required this.datasetId,
    required this.datasetName,
    required this.landslideEvents,
    required this.rainfallRecords,
    required this.geographicScope,
    required this.provenance,
    this.isSyntheticDataset = false,
  });

  int get totalLandslideEvents => landslideEvents.length;
  int get totalRainfallRecords => rainfallRecords.length;

  /// Evaluates dataset sufficiency for empirical calibration.
  bool get isSufficientForCalibration =>
      totalLandslideEvents >= 5 && totalRainfallRecords >= 10 && !isSyntheticDataset;
}
