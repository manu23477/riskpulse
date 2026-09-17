import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/environmental_health/health_outcome_category.dart';

/// Immutable domain model representing a privacy-safe aggregated spatial health observation.
///
/// SCIENTIFIC & PRIVACY GOVERNANCE:
/// Contains ZERO patient-level personally identifiable information (PII).
/// Stores aggregated case counts or incidence rates per spatial unit (district, block, grid cell).
@immutable
class HealthOutcomeRecord {
  final String recordId;
  final String spatialUnitId; // e.g. 'Mandi_District_01'
  final GeoLocation location;
  final HealthOutcomeCategory healthCategory;
  final int caseCount;
  final int populationAtRisk;
  final double incidenceRatePer100k;
  final String observationPeriod;
  final Map<String, dynamic> metadata;

  HealthOutcomeRecord({
    required this.recordId,
    required this.spatialUnitId,
    required this.location,
    required this.healthCategory,
    required this.caseCount,
    required this.populationAtRisk,
    double? incidenceRatePer100k,
    required this.observationPeriod,
    this.metadata = const {},
  }) : incidenceRatePer100k = incidenceRatePer100k ??
            (populationAtRisk > 0 ? (caseCount / populationAtRisk) * 100000.0 : 0.0) {
    if (recordId.trim().isEmpty) {
      throw ArgumentError('recordId cannot be empty.');
    }
    if (caseCount < 0) {
      throw ArgumentError('caseCount cannot be negative.');
    }
    if (populationAtRisk < 0) {
      throw ArgumentError('populationAtRisk cannot be negative.');
    }
  }
}
