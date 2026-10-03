import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/administrative/administrative_context.dart';

/// Status classification for event administrative attributions.
enum EventAttributionStatus {
  authoritative,
  derived,
  partial,
  unresolved,
  warning,
}

/// Immutable value object representing authoritative, provenance-preserving administrative attribution for an event.
///
/// Uses composition over inheritance by holding an [AdministrativeContext].
@immutable
class EventAdministrativeAttribution {
  /// Unique identifier of the attributed event.
  final String eventId;

  /// The composed [AdministrativeContext] containing Revenue and Development hierarchy units.
  final AdministrativeContext administrativeContext;

  /// Spatial relation basis (e.g. 'point', 'polygon', 'intersection', 'containment', 'overlap').
  final String spatialBasis;

  /// Temporal basis metadata map (e.g. eventTime, administrativeEffectiveDate, datasetVersion).
  final Map<String, dynamic> temporalBasis;

  /// Provenance lineage dictionary (source authorities, source IDs, internal IDs).
  final Map<String, dynamic> provenance;

  /// Attribution confidence status.
  final EventAttributionStatus status;

  /// Explicit status warnings (e.g. 'HISTORICAL_BOUNDARY_DATA_UNAVAILABLE', 'OUTSIDE_COVERAGE').
  final List<String> warnings;

  /// Optional estimated affected area in square kilometers for polygon/corridor events.
  final double? intersectionAreaKm2;

  /// Optional intersection ratio (0.0 to 1.0) for polygon events.
  final double? intersectionRatio;

  /// Timestamp when this attribution was created.
  final DateTime attributionCreatedAt;

  EventAdministrativeAttribution({
    required this.eventId,
    required this.administrativeContext,
    required this.spatialBasis,
    required Map<String, dynamic> temporalBasis,
    required Map<String, dynamic> provenance,
    this.status = EventAttributionStatus.authoritative,
    List<String>? warnings,
    this.intersectionAreaKm2,
    this.intersectionRatio,
    DateTime? attributionCreatedAt,
  })  : temporalBasis = Map<String, dynamic>.unmodifiable(temporalBasis),
        provenance = Map<String, dynamic>.unmodifiable(provenance),
        warnings = List<String>.unmodifiable(warnings ?? const []),
        attributionCreatedAt = attributionCreatedAt ?? DateTime.now().toUtc() {
    if (eventId.trim().isEmpty) {
      throw ArgumentError('EventAdministrativeAttribution.eventId cannot be empty.');
    }
  }

  /// Converts this [EventAdministrativeAttribution] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'administrativeContext': administrativeContext.toJson(),
      'spatialBasis': spatialBasis,
      'temporalBasis': temporalBasis,
      'provenance': provenance,
      'status': status.name,
      'warnings': warnings,
      'intersectionAreaKm2': intersectionAreaKm2,
      'intersectionRatio': intersectionRatio,
      'attributionCreatedAt': attributionCreatedAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventAdministrativeAttribution &&
          runtimeType == other.runtimeType &&
          eventId == other.eventId &&
          spatialBasis == other.spatialBasis &&
          status == other.status &&
          administrativeContext == other.administrativeContext;

  @override
  int get hashCode => Object.hash(
        eventId,
        spatialBasis,
        status,
        administrativeContext,
      );

  @override
  String toString() {
    return 'EventAdministrativeAttribution(eventId: $eventId, status: ${status.name}, district: ${administrativeContext.district?.name}, tehsil: ${administrativeContext.tehsil?.name}, warnings: $warnings)';
  }
}
