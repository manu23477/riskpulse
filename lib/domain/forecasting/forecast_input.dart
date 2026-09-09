import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/forecasting/forecast_horizon.dart';

/// Immutable contract identifying all input data references, parameters, and spatial-temporal constraints
/// supplied to a forecast execution.
@immutable
class ForecastInput {
  static const int currentSchemaVersion = 1;

  final String inputId;
  final List<String> timeSeriesIds;
  final List<String> staticGisDatasetIds;
  final List<String> remoteSensingProductIds;
  final List<String> osintEventIds;
  final ForecastHorizon targetHorizon;
  final Map<String, dynamic> parameters;
  final MapExtent? spatialDomain;
  final String? snapshotIdentifier;
  final int schemaVersion;

  ForecastInput({
    required this.inputId,
    this.timeSeriesIds = const [],
    this.staticGisDatasetIds = const [],
    this.remoteSensingProductIds = const [],
    this.osintEventIds = const [],
    required this.targetHorizon,
    this.parameters = const {},
    this.spatialDomain,
    this.snapshotIdentifier,
    this.schemaVersion = currentSchemaVersion,
  }) {
    if (inputId.trim().isEmpty) {
      throw ArgumentError('inputId cannot be empty.');
    }
    if (schemaVersion <= 0) {
      throw ArgumentError('schemaVersion must be positive.');
    }

    final hasDataRefs = timeSeriesIds.isNotEmpty ||
        staticGisDatasetIds.isNotEmpty ||
        remoteSensingProductIds.isNotEmpty ||
        osintEventIds.isNotEmpty;

    if (!hasDataRefs && spatialDomain == null) {
      throw ArgumentError(
        'ForecastInput must specify at least one dataset reference or a valid spatial domain.',
      );
    }
  }

  ForecastInput copyWith({
    String? inputId,
    List<String>? timeSeriesIds,
    List<String>? staticGisDatasetIds,
    List<String>? remoteSensingProductIds,
    List<String>? osintEventIds,
    ForecastHorizon? targetHorizon,
    Map<String, dynamic>? parameters,
    MapExtent? spatialDomain,
    bool clearSpatialDomain = false,
    String? snapshotIdentifier,
    bool clearSnapshotIdentifier = false,
    int? schemaVersion,
  }) {
    return ForecastInput(
      inputId: inputId ?? this.inputId,
      timeSeriesIds: timeSeriesIds ?? this.timeSeriesIds,
      staticGisDatasetIds: staticGisDatasetIds ?? this.staticGisDatasetIds,
      remoteSensingProductIds:
          remoteSensingProductIds ?? this.remoteSensingProductIds,
      osintEventIds: osintEventIds ?? this.osintEventIds,
      targetHorizon: targetHorizon ?? this.targetHorizon,
      parameters: parameters ?? this.parameters,
      spatialDomain:
          clearSpatialDomain ? null : (spatialDomain ?? this.spatialDomain),
      snapshotIdentifier: clearSnapshotIdentifier
          ? null
          : (snapshotIdentifier ?? this.snapshotIdentifier),
      schemaVersion: schemaVersion ?? this.schemaVersion,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'inputId': inputId,
      'timeSeriesIds': timeSeriesIds,
      'staticGisDatasetIds': staticGisDatasetIds,
      'remoteSensingProductIds': remoteSensingProductIds,
      'osintEventIds': osintEventIds,
      'targetHorizon': targetHorizon.toMap(),
      'parameters': parameters,
      'snapshotIdentifier': snapshotIdentifier,
      'schemaVersion': schemaVersion,
    };
  }

  factory ForecastInput.fromMap(Map<String, dynamic> map) {
    return ForecastInput(
      inputId: map['inputId'] as String? ?? '',
      timeSeriesIds:
          (map['timeSeriesIds'] as List<dynamic>?)?.cast<String>() ?? const [],
      staticGisDatasetIds:
          (map['staticGisDatasetIds'] as List<dynamic>?)?.cast<String>() ??
              const [],
      remoteSensingProductIds:
          (map['remoteSensingProductIds'] as List<dynamic>?)?.cast<String>() ??
              const [],
      osintEventIds:
          (map['osintEventIds'] as List<dynamic>?)?.cast<String>() ?? const [],
      targetHorizon: ForecastHorizon.fromMap(
        map['targetHorizon'] as Map<String, dynamic>,
      ),
      parameters: (map['parameters'] as Map<String, dynamic>?) ?? const {},
      snapshotIdentifier: map['snapshotIdentifier'] as String?,
      schemaVersion: map['schemaVersion'] as int? ?? currentSchemaVersion,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ForecastInput &&
          runtimeType == other.runtimeType &&
          inputId == other.inputId &&
          targetHorizon == other.targetHorizon &&
          snapshotIdentifier == other.snapshotIdentifier &&
          schemaVersion == other.schemaVersion &&
          listEquals(timeSeriesIds, other.timeSeriesIds) &&
          listEquals(staticGisDatasetIds, other.staticGisDatasetIds) &&
          listEquals(remoteSensingProductIds, other.remoteSensingProductIds) &&
          listEquals(osintEventIds, other.osintEventIds) &&
          mapEquals(parameters, other.parameters);

  @override
  int get hashCode => Object.hash(
        inputId,
        targetHorizon,
        snapshotIdentifier,
        schemaVersion,
        Object.hashAll(timeSeriesIds),
        Object.hashAll(staticGisDatasetIds),
        Object.hashAll(remoteSensingProductIds),
        Object.hashAll(osintEventIds),
      );
}
