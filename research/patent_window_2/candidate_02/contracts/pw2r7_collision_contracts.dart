/// PW2R7 Atomic Feature Contract (M01 through M30)
class PW2R7AtomicFeature {
  final String featureId; // M01..M30
  final String description;
  final bool isCoreToK10;

  const PW2R7AtomicFeature({
    required this.featureId,
    required this.description,
    required this.isCoreToK10,
  });

  Map<String, dynamic> toJson() => {
        'featureId': featureId,
        'description': description,
        'isCoreToK10': isCoreToK10,
      };
}

/// Evaluation record for a single reference against M01..M30
class SingleReferenceEvaluation {
  final String referenceId;
  final String publicationNumber;
  final String title;
  final String assignee;
  final Map<String, String> featureMappings; // M01: D, I, A, U
  final String classification; // COMPLETE_SINGLE_REFERENCE, PARTIAL_SINGLE_REFERENCE, BACKGROUND_ONLY, NOT_RELEVANT
  final bool disclosesCompleteK10;

  const SingleReferenceEvaluation({
    required this.referenceId,
    required this.publicationNumber,
    required this.title,
    required this.assignee,
    required this.featureMappings,
    required this.classification,
    required this.disclosesCompleteK10,
  });

  Map<String, dynamic> toJson() => {
        'referenceId': referenceId,
        'publicationNumber': publicationNumber,
        'title': title,
        'assignee': assignee,
        'featureMappings': featureMappings,
        'classification': classification,
        'disclosesCompleteK10': disclosesCompleteK10,
      };
}

/// Evaluation record for combinations K01 through K10
class CombinationEvaluation {
  final String combinationId; // K01..K10
  final String description;
  final List<String> includedComponents;
  final bool singleReferenceDisclosed;
  final bool multiReferenceMosaicDisclosed;
  final List<String> disclosingReferences;
  final String missingCouplingRelationship;

  const CombinationEvaluation({
    required this.combinationId,
    required this.description,
    required this.includedComponents,
    required this.singleReferenceDisclosed,
    required this.multiReferenceMosaicDisclosed,
    required this.disclosingReferences,
    required this.missingCouplingRelationship,
  });

  Map<String, dynamic> toJson() => {
        'combinationId': combinationId,
        'description': description,
        'includedComponents': includedComponents,
        'singleReferenceDisclosed': singleReferenceDisclosed,
        'multiReferenceMosaicDisclosed': multiReferenceMosaicDisclosed,
        'disclosingReferences': disclosingReferences,
        'missingCouplingRelationship': missingCouplingRelationship,
      };
}
