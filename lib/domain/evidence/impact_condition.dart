import 'package:flutter/foundation.dart';

/// Immutable model capturing structured impact metrics separately from risk score or alert status.
@immutable
class ImpactCondition {
  final String impactStatus; // 'none_reported', 'minor_disruption', 'severe_damage', 'unknown'
  final double? estimatedDamageCost;
  final String? affectedInfrastructureSummary;

  const ImpactCondition({
    this.impactStatus = 'unknown',
    this.estimatedDamageCost,
    this.affectedInfrastructureSummary,
  });

  Map<String, dynamic> toJson() {
    return {
      'impactStatus': impactStatus,
      'estimatedDamageCost': estimatedDamageCost,
      'affectedInfrastructureSummary': affectedInfrastructureSummary,
    };
  }

  factory ImpactCondition.fromJson(Map<String, dynamic> json) {
    return ImpactCondition(
      impactStatus: json['impactStatus'] as String? ?? 'unknown',
      estimatedDamageCost: (json['estimatedDamageCost'] as num?)?.toDouble(),
      affectedInfrastructureSummary: json['affectedInfrastructureSummary'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImpactCondition &&
          runtimeType == other.runtimeType &&
          impactStatus == other.impactStatus &&
          estimatedDamageCost == other.estimatedDamageCost;

  @override
  int get hashCode => Object.hash(impactStatus, estimatedDamageCost);
}
