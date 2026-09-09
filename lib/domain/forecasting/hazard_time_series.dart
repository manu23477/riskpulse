import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/forecasting/hazard_observation.dart';

/// Immutable collection of chronological [HazardObservation] records for a single parameter.
///
/// This collection explicitly retains observed timeline gaps. Missing observations MUST remain
/// missing—silent interpolation, zero-filling, or forward-carrying is strictly forbidden at
/// the domain level.
@immutable
class HazardTimeSeries {
  static const int currentSchemaVersion = 1;

  final String timeSeriesId;
  final String parameterId;
  final String unit;
  final List<HazardObservation> observations;
  final Map<String, dynamic> metadata;
  final int schemaVersion;

  HazardTimeSeries({
    required this.timeSeriesId,
    required this.parameterId,
    required this.unit,
    List<HazardObservation> observations = const [],
    this.metadata = const {},
    this.schemaVersion = currentSchemaVersion,
  }) : observations = List.unmodifiable(observations) {
    if (timeSeriesId.trim().isEmpty) {
      throw ArgumentError('timeSeriesId cannot be empty.');
    }
    if (parameterId.trim().isEmpty) {
      throw ArgumentError('parameterId cannot be empty.');
    }
    if (unit.trim().isEmpty) {
      throw ArgumentError('unit cannot be empty.');
    }
    if (schemaVersion <= 0) {
      throw ArgumentError('schemaVersion must be positive.');
    }

    final seenIds = <String>{};
    for (final obs in observations) {
      if (!seenIds.add(obs.observationId)) {
        throw ArgumentError(
          'Duplicate observation ID in HazardTimeSeries: ${obs.observationId}.',
        );
      }
      if (obs.parameterId != parameterId) {
        throw ArgumentError(
          'Observation parameterId (${obs.parameterId}) does not match time series parameterId ($parameterId).',
        );
      }
    }
  }

  /// Returns observations sorted strictly in chronological order.
  List<HazardObservation> get chronologicalObservations {
    final list = List<HazardObservation>.from(observations);
    list.sort((a, b) {
      final tComp = a.observationTime.compareTo(b.observationTime);
      if (tComp != 0) return tComp;
      return a.observationId.compareTo(b.observationId);
    });
    return List.unmodifiable(list);
  }

  int get length => observations.length;
  bool get isEmpty => observations.isEmpty;
  bool get isNotEmpty => observations.isNotEmpty;

  /// Start time of the temporal sequence, or null if empty.
  DateTime? get startTime {
    if (observations.isEmpty) return null;
    DateTime minTime = observations.first.observationTime;
    for (final obs in observations.skip(1)) {
      if (obs.observationTime.isBefore(minTime)) {
        minTime = obs.observationTime;
      }
    }
    return minTime;
  }

  /// End time of the temporal sequence, or null if empty.
  DateTime? get endTime {
    if (observations.isEmpty) return null;
    DateTime maxTime = observations.first.observationTime;
    for (final obs in observations.skip(1)) {
      if (obs.observationTime.isAfter(maxTime)) {
        maxTime = obs.observationTime;
      }
    }
    return maxTime;
  }

  /// Duration spanning the earliest and latest observations, or null if empty.
  Duration? get timeSpan {
    final start = startTime;
    final end = endTime;
    if (start == null || end == null) return null;
    return end.difference(start);
  }

  /// Finds an observation by its unique identifier.
  HazardObservation? byId(String observationId) {
    for (final obs in observations) {
      if (obs.observationId == observationId) return obs;
    }
    return null;
  }

  /// Returns a new [HazardTimeSeries] with an added [HazardObservation].
  HazardTimeSeries add(HazardObservation observation) {
    if (byId(observation.observationId) != null) {
      throw ArgumentError(
        'Observation with ID ${observation.observationId} already exists in series.',
      );
    }
    if (observation.parameterId != parameterId) {
      throw ArgumentError(
        'Cannot add observation with parameterId ${observation.parameterId} to series with parameterId $parameterId.',
      );
    }

    return HazardTimeSeries(
      timeSeriesId: timeSeriesId,
      parameterId: parameterId,
      unit: unit,
      observations: [...observations, observation],
      metadata: metadata,
      schemaVersion: schemaVersion,
    );
  }

  /// Returns a new [HazardTimeSeries] with an observation removed by ID.
  HazardTimeSeries remove(String observationId) {
    return HazardTimeSeries(
      timeSeriesId: timeSeriesId,
      parameterId: parameterId,
      unit: unit,
      observations:
          observations.where((o) => o.observationId != observationId).toList(),
      metadata: metadata,
      schemaVersion: schemaVersion,
    );
  }

  HazardTimeSeries copyWith({
    String? timeSeriesId,
    String? parameterId,
    String? unit,
    List<HazardObservation>? observations,
    Map<String, dynamic>? metadata,
    int? schemaVersion,
  }) {
    return HazardTimeSeries(
      timeSeriesId: timeSeriesId ?? this.timeSeriesId,
      parameterId: parameterId ?? this.parameterId,
      unit: unit ?? this.unit,
      observations: observations ?? this.observations,
      metadata: metadata ?? this.metadata,
      schemaVersion: schemaVersion ?? this.schemaVersion,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HazardTimeSeries &&
          runtimeType == other.runtimeType &&
          timeSeriesId == other.timeSeriesId &&
          parameterId == other.parameterId &&
          unit == other.unit &&
          schemaVersion == other.schemaVersion &&
          listEquals(observations, other.observations);

  @override
  int get hashCode => Object.hash(
        timeSeriesId,
        parameterId,
        unit,
        schemaVersion,
        Object.hashAll(observations),
      );
}
