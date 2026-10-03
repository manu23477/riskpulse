import 'package:flutter/foundation.dart';

/// Immutable model capturing structured hazard condition metrics separately from risk, exposure, or alert level.
@immutable
class HazardCondition {
  final String hazardCategory; // 'landslide', 'flood', 'cloudburst', 'glof'
  final String hazardSeverity; // 'high', 'moderate', 'low'
  final double? hazardIntensity;
  final String hazardStatus; // 'active', 'monitoring', 'resolved'

  const HazardCondition({
    required this.hazardCategory,
    this.hazardSeverity = 'moderate',
    this.hazardIntensity,
    this.hazardStatus = 'active',
  });

  Map<String, dynamic> toJson() {
    return {
      'hazardCategory': hazardCategory,
      'hazardSeverity': hazardSeverity,
      'hazardIntensity': hazardIntensity,
      'hazardStatus': hazardStatus,
    };
  }

  factory HazardCondition.fromJson(Map<String, dynamic> json) {
    return HazardCondition(
      hazardCategory: json['hazardCategory'] as String? ?? 'hazard',
      hazardSeverity: json['hazardSeverity'] as String? ?? 'moderate',
      hazardIntensity: (json['hazardIntensity'] as num?)?.toDouble(),
      hazardStatus: json['hazardStatus'] as String? ?? 'active',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HazardCondition &&
          runtimeType == other.runtimeType &&
          hazardCategory == other.hazardCategory &&
          hazardSeverity == other.hazardSeverity;

  @override
  int get hashCode => Object.hash(hazardCategory, hazardSeverity);
}
