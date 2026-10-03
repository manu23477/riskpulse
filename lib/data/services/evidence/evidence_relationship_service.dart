import 'package:riskpulse/data/repositories/evidence_relationship_repository.dart';
import 'package:riskpulse/domain/evidence/evidence_relationship.dart';
import 'package:riskpulse/domain/evidence/evidence_relationship_query.dart';
import 'package:riskpulse/domain/evidence/evidence_relationship_type.dart';
import 'package:riskpulse/domain/evidence/relationship_status.dart';

/// Result report emitted when registering an Evidence Relationship.
class RelationshipRegistrationResult {
  final EvidenceRelationship relationship;
  final bool isDuplicate;
  final String? duplicateOfRelationshipId;
  final bool isValid;
  final List<String> validationErrors;

  const RelationshipRegistrationResult({
    required this.relationship,
    required this.isDuplicate,
    this.duplicateOfRelationshipId,
    required this.isValid,
    required this.validationErrors,
  });
}

/// Service managing the registration, validation, duplicate detection, correction,
/// invalidation, withdrawal, lineage, and query operations for Evidence Relationships.
///
/// Strictly bounded: Does NOT mutate target EventHypotheses, propagate confidence,
/// or create Negative Evidence constructs.
class EvidenceRelationshipService {
  final EvidenceRelationshipRepository repository;

  EvidenceRelationshipService({required this.repository});

  /// Registers a new [EvidenceRelationship] with duplicate fingerprint detection.
  Future<RelationshipRegistrationResult> registerRelationship(EvidenceRelationship relationship) async {
    final validationErrors = validateRelationship(relationship);
    final isValid = validationErrors.isEmpty;

    if (!isValid) {
      return RelationshipRegistrationResult(
        relationship: relationship,
        isDuplicate: false,
        isValid: false,
        validationErrors: validationErrors,
      );
    }

    // Deterministic duplicate check by fingerprint key
    final existingSourceMatches = await repository.getBySource(relationship.sourceId);
    String? dupId;

    for (final existing in existingSourceMatches) {
      if (existing.duplicateFingerprintKey == relationship.duplicateFingerprintKey &&
          existing.status == RelationshipStatus.active) {
        dupId = existing.relationshipId;
        break;
      }
    }

    final bool isDup = dupId != null;
    final EvidenceRelationship finalRel = isDup
        ? relationship.copyWith(
            status: RelationshipStatus.superseded,
            attributes: {
              ...relationship.attributes,
              'duplicateOfRelationshipId': dupId,
            },
          )
        : relationship;

    await repository.create(finalRel);

    return RelationshipRegistrationResult(
      relationship: finalRel,
      isDuplicate: isDup,
      duplicateOfRelationshipId: dupId,
      isValid: true,
      validationErrors: const [],
    );
  }

  /// Retrieves an [EvidenceRelationship] by ID.
  Future<EvidenceRelationship?> retrieveRelationship(String relationshipId) async {
    return repository.getById(relationshipId);
  }

  /// Validates an [EvidenceRelationship] for structural completeness.
  List<String> validateRelationship(EvidenceRelationship relationship) {
    final errors = <String>[];

    if (relationship.relationshipId.trim().isEmpty) {
      errors.add('Relationship ID cannot be empty.');
    }
    if (relationship.sourceId.trim().isEmpty) {
      errors.add('Source ID cannot be empty.');
    }
    if (relationship.targetId.trim().isEmpty) {
      errors.add('Target ID cannot be empty.');
    }
    if (relationship.relationshipDescription.trim().isEmpty) {
      errors.add('Relationship Description cannot be empty.');
    }

    return errors;
  }

  /// Records a relationship correction, preserving historical relationship.
  Future<EvidenceRelationship> correctRelationship({
    required String originalRelationshipId,
    required EvidenceRelationship correctionRelationship,
  }) async {
    await repository.addCorrection(originalRelationshipId, correctionRelationship);
    return correctionRelationship;
  }

  /// Marks a relationship as invalidated, preserving historical relationship.
  Future<void> invalidateRelationship({
    required String originalRelationshipId,
    required String invalidationReason,
  }) async {
    await repository.addInvalidation(originalRelationshipId, invalidationReason);
  }

  /// Marks a relationship as withdrawn, preserving historical relationship.
  Future<void> withdrawRelationship({
    required String originalRelationshipId,
    required String withdrawalReason,
  }) async {
    final original = await repository.getById(originalRelationshipId);
    if (original != null) {
      final updated = original.copyWith(
        status: RelationshipStatus.withdrawn,
        correctionReason: withdrawalReason,
      );
      await repository.create(updated);
    }
  }

  /// Retrieves relationships originating from a source ID.
  Future<List<EvidenceRelationship>> getBySourceId(String sourceId) async {
    return repository.getBySource(sourceId);
  }

  /// Retrieves relationships targeting a target ID.
  Future<List<EvidenceRelationship>> getByTargetId(String targetId) async {
    return repository.getByTarget(targetId);
  }

  /// Retrieves relationships by relationship type (e.g. SUPPORTS, CONTRADICTS).
  Future<List<EvidenceRelationship>> getByRelationshipType(EvidenceRelationshipType type) async {
    return repository.getByRelationshipType(type);
  }

  /// Retrieves full relationship lineage.
  Future<List<EvidenceRelationship>> getLineage(String relationshipId) async {
    return repository.getLineage(relationshipId);
  }

  /// Queries relationships.
  Future<List<EvidenceRelationship>> queryRelationships(EvidenceRelationshipQuery query) async {
    return repository.query(query);
  }
}
