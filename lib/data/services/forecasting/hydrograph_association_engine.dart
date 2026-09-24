import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/forecasting/flood_calibration_contracts.dart';

/// Immutable value object representing a matched event-gauge hydrograph observation pair.
@immutable
class GaugeHydrographPair {
  final String eventId;
  final String stationId;
  final double distanceKm;
  final double peakObservedDischargeM3s;
  final double peakObservedLevelMeters;
  final DateTime peakTimestamp;
  final int observationCount;
  final bool isSynthetic;

  const GaugeHydrographPair({
    required this.eventId,
    required this.stationId,
    required this.distanceKm,
    required this.peakObservedDischargeM3s,
    required this.peakObservedLevelMeters,
    required this.peakTimestamp,
    required this.observationCount,
    this.isSynthetic = false,
  });
}

/// Service engine associating flood events with stream-gauge station time-series observations.
class HydrographAssociationEngine {
  final double maxSearchDistanceKm;
  final int temporalSearchWindowHours;

  const HydrographAssociationEngine({
    this.maxSearchDistanceKm = 35.0,
    this.temporalSearchWindowHours = 72,
  });

  /// Associates flood events with the nearest stream-gauge station within [maxSearchDistanceKm].
  List<GaugeHydrographPair> associateEventsWithHydrographs(FloodCalibrationDataset dataset) {
    final List<GaugeHydrographPair> pairs = [];

    for (final event in dataset.floodEvents) {
      GaugeStationRecord? nearestStation;
      double minDistance = double.infinity;

      for (final station in dataset.gaugeStations) {
        final dist = _haversineKm(event.location, station.location);
        if (dist <= maxSearchDistanceKm && dist < minDistance) {
          minDistance = dist;
          nearestStation = station;
        }
      }

      if (nearestStation != null) {
        // Find matching station observations within temporal window
        final stationObs = dataset.observations.where((o) {
          if (o.stationId != nearestStation!.stationId) return false;
          if (o.qualityState == 'invalid') return false;

          final windowStart = event.eventDate.subtract(Duration(hours: temporalSearchWindowHours));
          final windowEnd = event.eventDate.add(Duration(hours: temporalSearchWindowHours));
          return o.timestamp.isAfter(windowStart) && o.timestamp.isBefore(windowEnd);
        }).toList();

        if (stationObs.isNotEmpty) {
          double maxQ = 0.0;
          double maxH = 0.0;
          DateTime peakTime = event.eventDate;

          for (final obs in stationObs) {
            if (obs.hasDischarge && obs.dischargeM3s! > maxQ) {
              maxQ = obs.dischargeM3s!;
              peakTime = obs.timestamp;
            }
            if (obs.hasStage && obs.waterLevelMeters! > maxH) {
              maxH = obs.waterLevelMeters!;
            }
          }

          pairs.add(
            GaugeHydrographPair(
              eventId: event.eventId,
              stationId: nearestStation.stationId,
              distanceKm: minDistance,
              peakObservedDischargeM3s: maxQ,
              peakObservedLevelMeters: maxH,
              peakTimestamp: peakTime,
              observationCount: stationObs.length,
              isSynthetic: event.isSynthetic || nearestStation.isSynthetic || dataset.isSyntheticDataset,
            ),
          );
        }
      }
    }

    return pairs;
  }

  static double _haversineKm(GeoLocation a, GeoLocation b) {
    const r = 6371.0;
    final dLat = (b.latitude - a.latitude) * math.pi / 180.0;
    final dLon = (b.longitude - a.longitude) * math.pi / 180.0;
    final lat1 = a.latitude * math.pi / 180.0;
    final lat2 = b.latitude * math.pi / 180.0;

    final sinDlat = math.sin(dLat / 2);
    final sinDlon = math.sin(dLon / 2);

    final h = sinDlat * sinDlat + math.cos(lat1) * math.cos(lat2) * sinDlon * sinDlon;
    final c = 2 * math.asin(math.sqrt(h));
    return r * c;
  }
}
