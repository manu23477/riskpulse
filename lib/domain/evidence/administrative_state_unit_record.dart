import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/administrative/administrative_level.dart';
import 'package:riskpulse/domain/evidence/attribution_basis.dart';

/// Immutable record capturing single administrative unit attribution within an AdministrativeState.
@immutable
class AdministrativeStateUnitRecord {
  final String internalId;
  final String sourceId;
  final String sourceSystem;
  final String name;
  final AdministrativeLevel level;
  final double? intersectionAreaSqKm;
  final double? intersectionRatio; // 0.0 to 1.0
  final double? affectedAreaSqKm;
  final AttributionBasis attributionBasis;
  final String hierarchyType; // 'revenue', 'development', 'both'

  AdministrativeStateUnitRecord({
    required this.internalId,
    required this.sourceId,
    this.sourceSystem = 'LGD',
    required this.name,
    required this.level,
    this.intersectionAreaSqKm,
    this.intersectionRatio,
    this.affectedAreaSqKm,
    this.attributionBasis = AttributionBasis.polygonIntersection,
    this.hierarchyType = 'revenue',
  })  : assert(internalId.trim().isNotEmpty, 'internalId cannot be empty.'),
        assert(intersectionRatio == null || (intersectionRatio >= 0.0 && intersectionRatio <= 1.0), 'intersectionRatio must be between 0.0 and 1.0');

  Map<String, dynamic> toJson() {
    return {
      'internalId': internalId,
      'sourceId': sourceId,
      'sourceSystem': sourceSystem,
      'name': name,
      'level': level.code,
      'intersectionAreaSqKm': intersectionAreaSqKm,
      'intersectionRatio': intersectionRatio,
      'affectedAreaSqKm': affectedAreaSqKm,
      'attributionBasis': attributionBasis.name,
      'hierarchyType': hierarchyType,
    };
  }

  factory AdministrativeStateUnitRecord.fromJson(Map<String, dynamic> json) {
    return AdministrativeStateUnitRecord(
      internalId: json['internalId'] as String? ?? '',
      sourceId: json['sourceId'] as String? ?? '',
      sourceSystem: json['sourceSystem'] as String? ?? 'LGD',
      name: json['name'] as String? ?? '',
      level: AdministrativeLevel.fromCode(json['level'] as String? ?? 'L4'),
      intersectionAreaSqKm: (json['intersectionAreaSqKm'] as num?)?.toDouble(),
      intersectionRatio: (json['intersectionRatio'] as num?)?.toDouble(),
      affectedAreaSqKm: (json['affectedAreaSqKm'] as num?)?.toDouble(),
      attributionBasis: AttributionBasis.fromCode(json['attributionBasis'] as String? ?? 'derived'),
      hierarchyType: json['hierarchyType'] as String? ?? 'revenue',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdministrativeStateUnitRecord &&
          runtimeType == other.runtimeType &&
          internalId == other.internalId &&
          hierarchyType == other.hierarchyType;

  @override
  int get hashCode => Object.hash(internalId, hierarchyType);
}
