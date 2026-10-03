import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/administrative/administrative_unit.dart';

/// Extensible application profile for an [AdministrativeUnit].
///
/// Contains identity, geometry metrics, hierarchy tree, provenance, and optional future intelligence slots.
@immutable
class AdministrativeProfile {
  /// The primary [AdministrativeUnit].
  final AdministrativeUnit unit;

  /// Direct parent unit.
  final AdministrativeUnit? parent;

  /// Direct child units.
  final List<AdministrativeUnit> children;

  /// Ancestor chain up to Country level.
  final List<AdministrativeUnit> ancestors;

  /// Dataset version string.
  final String datasetVersion;

  /// Publishing authority name.
  final String sourceAuthority;

  /// Optional population count (future slot).
  final int? population;

  /// Optional critical infrastructure count (future slot).
  final int? infrastructureCount;

  /// Optional exposure summary dictionary (future slot).
  final Map<String, dynamic>? exposureSummary;

  /// Optional hazard summary dictionary (future slot).
  final Map<String, dynamic>? hazardSummary;

  /// Optional current composite risk level (future slot).
  final String? currentRiskLevel;

  AdministrativeProfile({
    required this.unit,
    this.parent,
    List<AdministrativeUnit>? children,
    List<AdministrativeUnit>? ancestors,
    required this.datasetVersion,
    required this.sourceAuthority,
    this.population,
    this.infrastructureCount,
    this.exposureSummary,
    this.hazardSummary,
    this.currentRiskLevel,
  })  : children = List<AdministrativeUnit>.unmodifiable(children ?? const []),
        ancestors = List<AdministrativeUnit>.unmodifiable(ancestors ?? const []);

  /// Serializes this [AdministrativeProfile] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'unit': unit.toJson(),
      'parent': parent?.toJson(),
      'children': children.map((c) => c.toJson()).toList(),
      'ancestors': ancestors.map((a) => a.toJson()).toList(),
      'datasetVersion': datasetVersion,
      'sourceAuthority': sourceAuthority,
      'population': population,
      'infrastructureCount': infrastructureCount,
      'exposureSummary': exposureSummary,
      'hazardSummary': hazardSummary,
      'currentRiskLevel': currentRiskLevel,
    };
  }

  @override
  String toString() {
    return 'AdministrativeProfile(unit: ${unit.name}, level: ${unit.level.code}, children: ${children.length}, risk: $currentRiskLevel)';
  }
}
