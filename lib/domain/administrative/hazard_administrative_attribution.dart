import 'package:flutter/foundation.dart';
import 'package:riskpulse/data/services/administrative/contracts/administrative_hazard_attribution_contract.dart';
import 'package:riskpulse/domain/administrative/administrative_context.dart';
import 'package:riskpulse/domain/administrative/event_administrative_attribution.dart';

/// Immutable domain value object representing authoritative administrative attribution for physical hazard layers/products.
///
/// Supports 7 primary hazard types: Landslide, Flood, Cloudburst, GLOF, Earthquake, Avalanche, Forest Fire.
@immutable
class HazardAdministrativeAttribution {
  /// Unique hazard footprint or product identifier.
  final String hazardId;

  /// Hazard classification category (e.g. 'landslide', 'flood', 'cloudburst', 'glof', 'earthquake', 'avalanche', 'forest_fire').
  final String hazardCategory;

  /// Human-readable hazard title (e.g. 'Kotropi Landslide Polygon 2017').
  final String hazardTitle;

  /// Raw spatial extent geometry map (GeoJSON Polygon or MultiPolygon).
  final Map<String, dynamic> spatialExtent;

  /// List of composed [AdministrativeContext] records covering affected territories.
  final List<AdministrativeContext> affectedContexts;

  /// List of detailed spatial intersection results per administrative unit.
  final List<AdministrativeHazardIntersectionResult> intersectionResults;

  /// Total estimated affected area across all administrative units in square kilometers.
  final double totalAffectedAreaKm2;

  /// Assigned hazard severity level (e.g. 'low', 'moderate', 'high', 'critical').
  final String severityLevel;

  /// Attribution confidence status.
  final EventAttributionStatus attributionStatus;

  /// Explicit status warnings or notes.
  final List<String> warnings;

  /// Dataset version string of the administrative boundaries used.
  final String datasetVersion;

  /// Cryptographic and lineage provenance map.
  final Map<String, dynamic> provenance;

  /// Timestamp when this attribution was derived.
  final DateTime attributionCreatedAt;

  HazardAdministrativeAttribution({
    required this.hazardId,
    required this.hazardCategory,
    required this.hazardTitle,
    required Map<String, dynamic> spatialExtent,
    List<AdministrativeContext>? affectedContexts,
    List<AdministrativeHazardIntersectionResult>? intersectionResults,
    required this.totalAffectedAreaKm2,
    this.severityLevel = 'moderate',
    this.attributionStatus = EventAttributionStatus.authoritative,
    List<String>? warnings,
    required this.datasetVersion,
    Map<String, dynamic>? provenance,
    DateTime? attributionCreatedAt,
  })  : spatialExtent = Map<String, dynamic>.unmodifiable(spatialExtent),
        affectedContexts = List<AdministrativeContext>.unmodifiable(affectedContexts ?? const []),
        intersectionResults = List<AdministrativeHazardIntersectionResult>.unmodifiable(intersectionResults ?? const []),
        warnings = List<String>.unmodifiable(warnings ?? const []),
        provenance = Map<String, dynamic>.unmodifiable(provenance ?? const {}),
        attributionCreatedAt = attributionCreatedAt ?? DateTime.now().toUtc() {
    if (hazardId.trim().isEmpty) {
      throw ArgumentError('HazardAdministrativeAttribution.hazardId cannot be empty.');
    }
    if (hazardCategory.trim().isEmpty) {
      throw ArgumentError('HazardAdministrativeAttribution.hazardCategory cannot be empty.');
    }
  }

  /// Converts this [HazardAdministrativeAttribution] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'hazardId': hazardId,
      'hazardCategory': hazardCategory,
      'hazardTitle': hazardTitle,
      'spatialExtent': spatialExtent,
      'affectedContexts': affectedContexts.map((c) => c.toJson()).toList(),
      'totalAffectedAreaKm2': totalAffectedAreaKm2,
      'severityLevel': severityLevel,
      'attributionStatus': attributionStatus.name,
      'warnings': warnings,
      'datasetVersion': datasetVersion,
      'provenance': provenance,
      'attributionCreatedAt': attributionCreatedAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HazardAdministrativeAttribution &&
          runtimeType == other.runtimeType &&
          hazardId == other.hazardId &&
          hazardCategory == other.hazardCategory &&
          attributionStatus == other.attributionStatus;

  @override
  int get hashCode => Object.hash(hazardId, hazardCategory, attributionStatus);

  @override
  String toString() {
    return 'HazardAdministrativeAttribution(id: $hazardId, cat: $hazardCategory, affectedUnits: ${intersectionResults.length}, area: ${totalAffectedAreaKm2.toStringAsFixed(2)}km2)';
  }
}
