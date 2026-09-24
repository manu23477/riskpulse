import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/forecasting/landslide_calibration_contracts.dart';

/// Immutable value object representing a matched event-rainfall observation pair.
@immutable
class EventRainfallPair {
  final String eventId;
  final String stationId;
  final double distanceKm;
  final double durationHours;
  final double totalRainfallMm;
  final double rainfallIntensityMmHour;
  final double antecedentRainfallMm;
  final bool isSynthetic;

  const EventRainfallPair({
    required this.eventId,
    required this.stationId,
    required this.distanceKm,
    required this.durationHours,
    required this.totalRainfallMm,
    required this.rainfallIntensityMmHour,
    this.antecedentRainfallMm = 0.0,
    this.isSynthetic = false,
  });
}

/// Service engine associating landslide events with spatial rainfall station observations.
class EventRainfallAssociationEngine {
  final double maxSearchDistanceKm;
  final int antecedentWindowHours;

  const EventRainfallAssociationEngine({
    this.maxSearchDistanceKm = 25.0,
    this.antecedentWindowHours = 48,
  });

  /// Associates landslide events with the nearest rainfall station within [maxSearchDistanceKm].
  List<EventRainfallPair> associateEventsWithRainfall(LandslideCalibrationDataset dataset) {
    final List<EventRainfallPair> pairs = [];

    for (final event in dataset.landslideEvents) {
      RainfallStationRecord? nearestStation;
      double minDistance = double.infinity;

      for (final station in dataset.rainfallRecords) {
        if (station.dataQuality == 'invalid') continue;

        final dist = _haversineKm(event.location, station.location);
        if (dist <= maxSearchDistanceKm && dist < minDistance) {
          minDistance = dist;
          nearestStation = station;
        }
      }

      if (nearestStation != null) {
        final duration = nearestStation.accumulationPeriodHours;
        final intensity = nearestStation.rainfallIntensityMmHour;

        pairs.add(
          EventRainfallPair(
            eventId: event.eventId,
            stationId: nearestStation.stationId,
            distanceKm: minDistance,
            durationHours: duration,
            totalRainfallMm: nearestStation.rainfallAmountMm,
            rainfallIntensityMmHour: intensity,
            isSynthetic: event.isSynthetic || nearestStation.isSynthetic || dataset.isSyntheticDataset,
          ),
        );
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
