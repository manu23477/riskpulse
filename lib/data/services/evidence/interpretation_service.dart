import 'package:riskpulse/data/repositories/interpretation_repository.dart';
import 'package:riskpulse/domain/evidence/evidence_interpretation_link.dart';
import 'package:riskpulse/domain/evidence/interpretation_object.dart';
import 'package:riskpulse/domain/evidence/interpretation_query.dart';

/// Result report emitted when registering an Interpretation Object.
class InterpretationRegistrationResult {
  final InterpretationObject interpretation;
  final bool isValid;
  final List<String> validationErrors;

  const InterpretationRegistrationResult({
    required this.interpretation,
    required this.isValid,
    required this.validationErrors,
  });
}

/// Service managing the registration, validation, evidence linkage, correction,
/// invalidation, lineage, and query operations for Interpretation Objects.
///
/// Strictly bounded: Does NOT create EventHypotheses, RiskState, or perform predictive risk modelling.
class InterpretationService {
  final InterpretationRepository repository;
  final List<EvidenceInterpretationLink> _evidenceLinks = [];

  InterpretationService({required this.repository});

  /// Registers a new [InterpretationObject].
  Future<InterpretationRegistrationResult> registerInterpretation(InterpretationObject interpretation) async {
    final validationErrors = validateInterpretation(interpretation);
    final isValid = validationErrors.isEmpty;

    if (!isValid) {
      return InterpretationRegistrationResult(
        interpretation: interpretation,
        isValid: false,
        validationErrors: validationErrors,
      );
    }

    await repository.create(interpretation);

    // Record evidence-to-interpretation links
    for (final evId in interpretation.evidenceIds) {
      _evidenceLinks.add(
        EvidenceInterpretationLink(
          evidenceId: evId,
          interpretationId: interpretation.interpretationId,
          relationshipType: 'INTERPRETED_AS',
        ),
      );
    }

    return InterpretationRegistrationResult(
      interpretation: interpretation,
      isValid: true,
      validationErrors: const [],
    );
  }

  /// Retrieves an [InterpretationObject] by ID.
  Future<InterpretationObject?> retrieveInterpretation(String interpretationId) async {
    return repository.getById(interpretationId);
  }

  /// Validates an [InterpretationObject] for structural completeness.
  List<String> validateInterpretation(InterpretationObject interpretation) {
    final errors = <String>[];

    if (interpretation.interpretationId.trim().isEmpty) {
      errors.add('Interpretation ID cannot be empty.');
    }
    if (interpretation.evidenceIds.isEmpty) {
      errors.add('Interpretation requires at least one parent Evidence ID in evidenceIds.');
    }
    if (interpretation.interpretationText.trim().isEmpty) {
      errors.add('Interpretation Text cannot be empty.');
    }
    if (interpretation.confidence.value < 0.0 || interpretation.confidence.value > 1.0) {
      errors.add('Confidence value must be between 0.0 and 1.0.');
    }

    return errors;
  }

  /// Links an Evidence Object to an Interpretation Object.
  Future<EvidenceInterpretationLink> linkEvidence({
    required String evidenceId,
    required String interpretationId,
    String relationshipType = 'INTERPRETED_AS',
  }) async {
    final link = EvidenceInterpretationLink(
      evidenceId: evidenceId,
      interpretationId: interpretationId,
      relationshipType: relationshipType,
    );
    _evidenceLinks.add(link);
    return link;
  }

  /// Records an interpretation correction, preserving historical interpretation.
  Future<InterpretationObject> correctInterpretation({
    required String originalInterpretationId,
    required InterpretationObject correctionInterpretation,
  }) async {
    await repository.addCorrection(originalInterpretationId, correctionInterpretation);
    return correctionInterpretation;
  }

  /// Records an interpretation invalidation, preserving historical interpretation.
  Future<void> invalidateInterpretation({
    required String originalInterpretationId,
    required String invalidationReason,
  }) async {
    await repository.addInvalidation(originalInterpretationId, invalidationReason);
  }

  /// Retrieves full interpretation lineage.
  Future<List<InterpretationObject>> getInterpretationLineage(String interpretationId) async {
    return repository.getLineage(interpretationId);
  }

  /// Retrieves interpretations for an Evidence ID.
  Future<List<InterpretationObject>> getInterpretationsForEvidence(String evidenceId) async {
    return repository.getByEvidenceId(evidenceId);
  }

  /// Queries interpretations.
  Future<List<InterpretationObject>> queryInterpretations(InterpretationQuery query) async {
    return repository.query(query);
  }
}
