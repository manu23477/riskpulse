/// Contract representing an active evidence mutation event in Patent Window 1C-2B.
/// Operates on frozen evidence objects without altering the underlying dataset files.
class EvidenceMutationEvent {
  final String mutationId;
  final String targetEvidenceId;
  final String targetCaseId;
  final String mutationType; // evidence_invalidation, support_to_contradiction, spatial_location_revision, etc.
  final String mutationTimestamp;
  final Map<String, dynamic> attributeChanges;
  final String description;
  final bool isNegativeControl;

  const EvidenceMutationEvent({
    required this.mutationId,
    required this.targetEvidenceId,
    required this.targetCaseId,
    required this.mutationType,
    required this.mutationTimestamp,
    required this.attributeChanges,
    required this.description,
    this.isNegativeControl = false,
  });

  Map<String, dynamic> toJson() => {
        'mutationId': mutationId,
        'targetEvidenceId': targetEvidenceId,
        'targetCaseId': targetCaseId,
        'mutationType': mutationType,
        'mutationTimestamp': mutationTimestamp,
        'attributeChanges': attributeChanges,
        'description': description,
        'isNegativeControl': isNegativeControl,
      };

  factory EvidenceMutationEvent.fromJson(Map<String, dynamic> json) {
    return EvidenceMutationEvent(
      mutationId: json['mutationId'] as String,
      targetEvidenceId: json['targetEvidenceId'] as String,
      targetCaseId: json['targetCaseId'] as String,
      mutationType: json['mutationType'] as String,
      mutationTimestamp: (json['mutationTimestamp'] as String?) ?? '2026-09-30T12:50:00Z',
      attributeChanges: (json['attributeChanges'] as Map<String, dynamic>?) ?? {},
      description: (json['description'] as String?) ?? '',
      isNegativeControl: (json['isNegativeControl'] as bool?) ?? false,
    );
  }
}
