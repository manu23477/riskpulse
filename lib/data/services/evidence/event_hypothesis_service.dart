import 'package:riskpulse/data/repositories/event_hypothesis_repository.dart';
import 'package:riskpulse/domain/evidence/event_hypothesis.dart';
import 'package:riskpulse/domain/evidence/event_hypothesis_query.dart';
import 'package:riskpulse/domain/evidence/event_hypothesis_status.dart';
import 'package:riskpulse/domain/evidence/interpretation_confidence.dart';
import 'package:riskpulse/domain/evidence/interpretation_object.dart';
import 'package:riskpulse/domain/location/geo_location.dart';

/// Result report emitted when registering an Event Hypothesis.
class EventHypothesisRegistrationResult {
  final EventHypothesis hypothesis;
  final bool isValid;
  final List<String> validationErrors;

  const EventHypothesisRegistrationResult({
    required this.hypothesis,
    required this.isValid,
    required this.validationErrors,
  });
}

/// Service managing registration, validation, multi-interpretation fusion, correction,
/// invalidation, lineage, and query operations for Event Hypotheses.
///
/// Strictly bounded: Does NOT create RiskState, Event Graphs, Negative Evidence, or predictive risk models.
class EventHypothesisService {
  final EventHypothesisRepository repository;

  EventHypothesisService({required this.repository});

  /// Registers a new [EventHypothesis].
  Future<EventHypothesisRegistrationResult> registerHypothesis(EventHypothesis hypothesis) async {
    final validationErrors = validateHypothesis(hypothesis);
    final isValid = validationErrors.isEmpty;

    if (!isValid) {
      return EventHypothesisRegistrationResult(
        hypothesis: hypothesis,
        isValid: false,
        validationErrors: validationErrors,
      );
    }

    await repository.create(hypothesis);

    return EventHypothesisRegistrationResult(
      hypothesis: hypothesis,
      isValid: true,
      validationErrors: const [],
    );
  }

  /// Retrieves an [EventHypothesis] by ID.
  Future<EventHypothesis?> retrieveHypothesis(String hypothesisId) async {
    return repository.getById(hypothesisId);
  }

  /// Validates an [EventHypothesis] for structural completeness.
  List<String> validateHypothesis(EventHypothesis hypothesis) {
    final errors = <String>[];

    if (hypothesis.hypothesisId.trim().isEmpty) {
      errors.add('Hypothesis ID cannot be empty.');
    }
    if (hypothesis.interpretationIds.isEmpty) {
      errors.add('EventHypothesis requires at least one parent Interpretation ID in interpretationIds.');
    }
    if (hypothesis.title.trim().isEmpty) {
      errors.add('Title cannot be empty.');
    }
    if (hypothesis.confidence.value < 0.0 || hypothesis.confidence.value > 1.0) {
      errors.add('Confidence value must be between 0.0 and 1.0.');
    }

    return errors;
  }

  /// Fuses multiple [InterpretationObject] records into a candidate [EventHypothesis].
  ///
  /// Preserves all parent interpretation IDs without deleting them. Calculates structured confidence metrics.
  Future<EventHypothesisRegistrationResult> fuseInterpretations({
    required String hypothesisId,
    required String eventType,
    required String hazardCategory,
    required String title,
    required String description,
    required List<InterpretationObject> interpretations,
    GeoLocation? location,
    Map<String, dynamic>? geometry,
    EventHypothesisStatus status = EventHypothesisStatus.candidate,
  }) async {
    if (interpretations.isEmpty) {
      throw ArgumentError('fuseInterpretations requires at least one InterpretationObject.');
    }

    final List<String> interpIds = interpretations.map((i) => i.interpretationId).toList();
    final String primaryId = interpretations.first.interpretationId;

    // Calculate fused confidence without simplistic averaging
    double maxConf = 0.0;
    for (final interp in interpretations) {
      if (interp.confidence.value > maxConf) {
        maxConf = interp.confidence.value;
      }
    }
    final double fusedConfValue = (maxConf + 1.0) / 2.0; // Fused Bayesian boost bound <= 1.0
    final double finalConfScore = fusedConfValue > 1.0 ? 1.0 : fusedConfValue;

    final GeoLocation? fusedLoc = location ?? interpretations.firstWhere((i) => i.inferredPoint != null, orElse: () => interpretations.first).inferredPoint;
    final Map<String, dynamic>? fusedGeom = geometry ?? interpretations.firstWhere((i) => i.inferredGeometry != null, orElse: () => interpretations.first).inferredGeometry;

    final hypothesis = EventHypothesis(
      hypothesisId: hypothesisId,
      eventType: eventType,
      hazardCategory: hazardCategory,
      title: title,
      description: description,
      interpretationIds: interpIds,
      primaryInterpretationId: primaryId,
      location: fusedLoc,
      geometry: fusedGeom,
      confidence: InterpretationConfidence(
        value: finalConfScore,
        method: 'MULTI_INTERPRETATION_BAYESIAN_FUSION',
        basis: 'Fused from ${interpretations.length} interpretation objects: ${interpIds.join(', ')}',
        isCalibrated: false,
      ),
      status: status,
      provenance: {
        'fusedInterpretationCount': interpretations.length,
        'fusedInterpretationIds': interpIds,
        'fusionEngine': 'EventHypothesisService.fuseInterpretations',
      },
    );

    return registerHypothesis(hypothesis);
  }

  /// Records an event hypothesis correction, preserving historical hypotheses.
  Future<EventHypothesis> correctHypothesis({
    required String originalHypothesisId,
    required EventHypothesis correctionHypothesis,
  }) async {
    await repository.addCorrection(originalHypothesisId, correctionHypothesis);
    return correctionHypothesis;
  }

  /// Supersedes an event hypothesis.
  Future<void> supersedeHypothesis({
    required String originalHypothesisId,
    required EventHypothesis newHypothesis,
  }) async {
    await repository.addCorrection(originalHypothesisId, newHypothesis);
  }

  /// Records an event hypothesis invalidation, preserving historical hypotheses.
  Future<void> invalidateHypothesis({
    required String originalHypothesisId,
    required String invalidationReason,
  }) async {
    await repository.addInvalidation(originalHypothesisId, invalidationReason);
  }

  /// Retrieves full hypothesis lineage.
  Future<List<EventHypothesis>> getHypothesisLineage(String hypothesisId) async {
    return repository.getLineage(hypothesisId);
  }

  /// Retrieves hypotheses for an Interpretation ID.
  Future<List<EventHypothesis>> getHypothesesForInterpretation(String interpretationId) async {
    return repository.getByInterpretationId(interpretationId);
  }

  /// Queries hypotheses.
  Future<List<EventHypothesis>> queryHypotheses(EventHypothesisQuery query) async {
    return repository.query(query);
  }
}
