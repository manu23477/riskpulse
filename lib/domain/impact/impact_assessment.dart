import 'package:flutter/foundation.dart';

/// Immutable domain model representing potential or observed impacts on an exposed asset.
///
/// STRICT SCIENTIFIC BOUNDARY: EXPOSURE != IMPACT. POTENTIAL IMPACT != OBSERVED IMPACT.
@immutable
class ImpactAssessment {
  static const int currentSchemaVersion = 1;

  final String assessmentId;
  final String hazardFootprintId;
  final String assetId;

  final String impactCategory; // 'POTENTIAL_DISRUPTION', 'OBSERVED_DAMAGE', 'OBSERVED_CLOSURE', 'REFUTED_DAMAGE'
  final String impactSeverity; // 'MINOR', 'MODERATE', 'SEVERE', 'DESTROYED'
  final List<String> evidenceObjectIds;
  final bool isObserved; // false = Potential (Modelled), true = Observed (Verified by evidence)

  final DateTime assessedAt;
  final String explanation;
  final Map<String, dynamic> provenance;

  ImpactAssessment({
    required this.assessmentId,
    required this.hazardFootprintId,
    required this.assetId,
    this.impactCategory = 'POTENTIAL_DISRUPTION',
    this.impactSeverity = 'MODERATE',
    List<String>? evidenceObjectIds,
    this.isObserved = false,
    DateTime? assessedAt,
    required this.explanation,
    Map<String, dynamic>? provenance,
  })  : evidenceObjectIds = List<String>.unmodifiable(evidenceObjectIds ?? const []),
        assessedAt = assessedAt ?? DateTime.now().toUtc(),
        provenance = Map<String, dynamic>.unmodifiable(provenance ?? const {}) {
    if (assessmentId.trim().isEmpty) {
      throw ArgumentError('ImpactAssessment.assessmentId cannot be empty.');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'assessmentId': assessmentId,
      'hazardFootprintId': hazardFootprintId,
      'assetId': assetId,
      'impactCategory': impactCategory,
      'impactSeverity': impactSeverity,
      'evidenceObjectIds': evidenceObjectIds,
      'isObserved': isObserved,
      'assessedAt': assessedAt.toIso8601String(),
      'explanation': explanation,
      'provenance': provenance,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImpactAssessment &&
          runtimeType == other.runtimeType &&
          assessmentId == other.assessmentId;

  @override
  int get hashCode => assessmentId.hashCode;
}
