/// PW2R8 Relationship Definition (R01 through R30)
class PW2R8Relationship {
  final String relationshipId; // R01..R30
  final String description;
  final String upstreamComponent;
  final String transformation;
  final String downstreamComponent;
  final bool isCriticalToK10;

  const PW2R8Relationship({
    required this.relationshipId,
    required this.description,
    required this.upstreamComponent,
    required this.transformation,
    required this.downstreamComponent,
    required this.isCriticalToK10,
  });

  Map<String, dynamic> toJson() => {
        'relationshipId': relationshipId,
        'description': description,
        'upstreamComponent': upstreamComponent,
        'transformation': transformation,
        'downstreamComponent': downstreamComponent,
        'isCriticalToK10': isCriticalToK10,
      };
}

/// Combination Mosaic Evaluation (COMBO-01 through COMBO-10)
class PW2R8CombinationMosaic {
  final String comboId; // COMBO-01..COMBO-10
  final List<String> referencesIncluded;
  final List<String> relationshipsDisclosed;
  final String status; // STATUS_A, STATUS_B, STATUS_C, STATUS_D
  final bool disclosesCompleteK10;
  final String missingCouplingRelationship;

  const PW2R8CombinationMosaic({
    required this.comboId,
    required this.referencesIncluded,
    required this.relationshipsDisclosed,
    required this.status,
    required this.disclosesCompleteK10,
    required this.missingCouplingRelationship,
  });

  Map<String, dynamic> toJson() => {
        'comboId': comboId,
        'referencesIncluded': referencesIncluded,
        'relationshipsDisclosed': relationshipsDisclosed,
        'status': status,
        'disclosesCompleteK10': disclosesCompleteK10,
        'missingCouplingRelationship': missingCouplingRelationship,
      };
}

/// Examiner-Style Technical Reconstruction (E01 through E08)
class ExaminerReconstruction {
  final String reconstructionId; // E01..E08
  final String title;
  final List<String> requiredReferences;
  final List<String> suppliedFeatures;
  final List<String> missingRelationships;
  final bool equalsK10Architecture;
  final bool requiresSubstantialRedesign;

  const ExaminerReconstruction({
    required this.reconstructionId,
    required this.title,
    required this.requiredReferences,
    required this.suppliedFeatures,
    required this.missingRelationships,
    required this.equalsK10Architecture,
    required this.requiresSubstantialRedesign,
  });

  Map<String, dynamic> toJson() => {
        'reconstructionId': reconstructionId,
        'title': title,
        'requiredReferences': requiredReferences,
        'suppliedFeatures': suppliedFeatures,
        'missingRelationships': missingRelationships,
        'equalsK10Architecture': equalsK10Architecture,
        'requiresSubstantialRedesign': requiresSubstantialRedesign,
      };
}

/// Mosaic Distance Metrics (M01 through M07)
class MosaicDistanceMetrics {
  final int m01ReferencesForComponents;
  final int m02ReferencesForRelationships;
  final int m03RelationshipsRequiringMosaic;
  final int m04RelationshipsNotLocatedCompletely;
  final int m05CriticalRelationshipsRequiringRedesign;
  final int m06CriticalRelationshipsRequiringUnstatedAssumptions;
  final int m07ReferencesForClosestReconstruction;

  const MosaicDistanceMetrics({
    required this.m01ReferencesForComponents,
    required this.m02ReferencesForRelationships,
    required this.m03RelationshipsRequiringMosaic,
    required this.m04RelationshipsNotLocatedCompletely,
    required this.m05CriticalRelationshipsRequiringRedesign,
    required this.m06CriticalRelationshipsRequiringUnstatedAssumptions,
    required this.m07ReferencesForClosestReconstruction,
  });

  Map<String, dynamic> toJson() => {
        'm01ReferencesForComponents': m01ReferencesForComponents,
        'm02ReferencesForRelationships': m02ReferencesForRelationships,
        'm03RelationshipsRequiringMosaic': m03RelationshipsRequiringMosaic,
        'm04RelationshipsNotLocatedCompletely': m04RelationshipsNotLocatedCompletely,
        'm05CriticalRelationshipsRequiringRedesign': m05CriticalRelationshipsRequiringRedesign,
        'm06CriticalRelationshipsRequiringUnstatedAssumptions': m06CriticalRelationshipsRequiringUnstatedAssumptions,
        'm07ReferencesForClosestReconstruction': m07ReferencesForClosestReconstruction,
      };
}
