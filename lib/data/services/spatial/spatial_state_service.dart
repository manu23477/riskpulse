import 'package:riskpulse/data/repositories/spatial_state_repository.dart';
import 'package:riskpulse/data/services/administrative/administrative_geometry_validator.dart';
import 'package:riskpulse/domain/evidence/spatial_basis.dart';
import 'package:riskpulse/domain/evidence/spatial_representation_type.dart';
import 'package:riskpulse/domain/evidence/spatial_state.dart';
import 'package:riskpulse/domain/evidence/spatial_state_query.dart';
import 'package:riskpulse/domain/evidence/spatial_state_status.dart';
import 'package:riskpulse/domain/evidence/spatial_uncertainty.dart';
import 'package:riskpulse/domain/location/geo_location.dart';

/// Result container emitted when registering or updating a SpatialState.
class SpatialStateExecutionResult {
  final SpatialState spatialState;
  final bool isValid;
  final List<String> validationErrors;

  const SpatialStateExecutionResult({
    required this.spatialState,
    required this.isValid,
    required this.validationErrors,
  });
}

/// Service managing creation, validation, versioning, version comparison, and historical
/// reconstruction of versioned [SpatialState] records for Event Hypotheses.
///
/// STRICT BOUNDARY: Does NOT mutate Dynamic Risk State, trigger alerts, or execute cross-event state propagation.
class SpatialStateService {
  final SpatialStateRepository repository;

  SpatialStateService({required this.repository});

  /// Creates and validates a new immutable [SpatialState].
  Future<SpatialStateExecutionResult> createSpatialState({
    required String eventHypothesisId,
    int hypothesisVersion = 1,
    SpatialRepresentationType representationType = SpatialRepresentationType.point,
    GeoLocation? location,
    Map<String, dynamic>? geometry,
    List<double>? boundingBox,
    String crs = 'EPSG:4326',
    SpatialBasis spatialBasis = SpatialBasis.derived,
    DateTime? observedAt,
    DateTime? effectiveFrom,
    DateTime? effectiveTo,
    DateTime? createdAt,
    String derivationMethod = 'DETERMINISTIC_SPATIAL_STATE_RESOLVER',
    SpatialUncertainty uncertainty = const SpatialUncertainty(),
    List<String>? sourceEvidenceIds,
    List<String>? sourceInterpretationIds,
    Map<String, dynamic>? provenance,
    Map<String, dynamic>? attributes,
    String? spatialStateId,
  }) async {
    final String sId = spatialStateId ?? 'SPAT-${eventHypothesisId}-v$hypothesisVersion-s1';

    final state = SpatialState(
      spatialStateId: sId,
      eventHypothesisId: eventHypothesisId,
      hypothesisVersion: hypothesisVersion,
      spatialStateVersion: 1,
      representationType: representationType,
      location: location,
      geometry: geometry,
      boundingBox: boundingBox,
      crs: crs,
      spatialBasis: spatialBasis,
      observedAt: observedAt,
      effectiveFrom: effectiveFrom,
      effectiveTo: effectiveTo,
      createdAt: createdAt,
      derivationMethod: derivationMethod,
      uncertainty: uncertainty,
      sourceEvidenceIds: sourceEvidenceIds,
      sourceInterpretationIds: sourceInterpretationIds,
      provenance: provenance,
      attributes: attributes,
    );

    final validationErrors = validateSpatialState(state);
    final isValid = validationErrors.isEmpty;

    if (!isValid) {
      return SpatialStateExecutionResult(
        spatialState: state,
        isValid: false,
        validationErrors: validationErrors,
      );
    }

    await repository.save(state);

    return SpatialStateExecutionResult(
      spatialState: state,
      isValid: true,
      validationErrors: const [],
    );
  }

  /// Validates a [SpatialState] for coordinate bounds and geometry integrity.
  List<String> validateSpatialState(SpatialState state) {
    final errors = <String>[];

    if (state.spatialStateId.trim().isEmpty) {
      errors.add('SpatialState ID cannot be empty.');
    }
    if (state.eventHypothesisId.trim().isEmpty) {
      errors.add('EventHypothesis ID cannot be empty.');
    }
    if (state.crs.trim().isEmpty) {
      errors.add('CRS cannot be empty.');
    }

    if (state.location != null) {
      final lat = state.location!.latitude;
      final lon = state.location!.longitude;
      if (lat < -90.0 || lat > 90.0 || lon < -180.0 || lon > 180.0) {
        errors.add('Invalid coordinate bounds: lat=$lat, lon=$lon.');
      }
    }

    if (state.geometry != null) {
      final geomVal = AdministrativeGeometryValidator.validate(state.geometry!);
      if (!geomVal.isValid) {
        errors.addAll(geomVal.errors);
      }
    }

    return errors;
  }

  /// Creates a **NEW immutable [SpatialState] version v2**, setting `previousSpatialStateId = currentState.spatialStateId`.
  ///
  /// Original v1 remains 100% untouched and queryable.
  Future<SpatialStateExecutionResult> createNextVersion({
    required SpatialState currentState,
    GeoLocation? location,
    Map<String, dynamic>? geometry,
    List<double>? boundingBox,
    SpatialRepresentationType? representationType,
    SpatialUncertainty? uncertainty,
    String? derivationMethod,
    Map<String, dynamic>? provenance,
  }) async {
    final int nextVersion = currentState.spatialStateVersion + 1;
    final String nextId = 'SPAT-${currentState.eventHypothesisId}-v${currentState.hypothesisVersion}-s$nextVersion';

    final revised = currentState.copyWith(
      spatialStateId: nextId,
      spatialStateVersion: nextVersion,
      previousSpatialStateId: currentState.spatialStateId,
      location: location ?? currentState.location,
      geometry: geometry ?? currentState.geometry,
      boundingBox: boundingBox ?? currentState.boundingBox,
      representationType: representationType ?? currentState.representationType,
      uncertainty: uncertainty ?? currentState.uncertainty,
      derivationMethod: derivationMethod ?? currentState.derivationMethod,
      createdAt: DateTime.now().toUtc(),
      status: SpatialStateStatus.active,
      provenance: {
        ...currentState.provenance, ...?provenance,
        'revisedFromSpatialStateId': currentState.spatialStateId,
      },
    );

    final validationErrors = validateSpatialState(revised);
    if (validationErrors.isNotEmpty) {
      return SpatialStateExecutionResult(
        spatialState: revised,
        isValid: false,
        validationErrors: validationErrors,
      );
    }

    await repository.addVersion(currentState.spatialStateId, revised);

    return SpatialStateExecutionResult(
      spatialState: revised,
      isValid: true,
      validationErrors: const [],
    );
  }

  /// Compares two [SpatialState] versions and returns detailed property diffs.
  Map<String, dynamic> compareSpatialStates(SpatialState s1, SpatialState s2) {
    final Map<String, dynamic> diffs = {};
    final bool geomChanged = s1.geometry != s2.geometry || s1.location != s2.location;
    final bool repChanged = s1.representationType != s2.representationType;
    final bool crsChanged = s1.crs != s2.crs;
    final bool uncChanged = s1.uncertainty != s2.uncertainty;

    if (geomChanged) diffs['geometry'] = {'v1': s1.geometry, 'v2': s2.geometry};
    if (repChanged) diffs['representationType'] = {'v1': s1.representationType.name, 'v2': s2.representationType.name};
    if (crsChanged) diffs['crs'] = {'v1': s1.crs, 'v2': s2.crs};
    if (uncChanged) diffs['uncertainty'] = {'v1': s1.uncertainty.toJson(), 'v2': s2.uncertainty.toJson()};

    return {
      'spatialStateId': s1.spatialStateId,
      's1Version': s1.spatialStateVersion,
      's2Version': s2.spatialStateVersion,
      'geometryChanged': geomChanged,
      'representationChanged': repChanged,
      'crsChanged': crsChanged,
      'uncertaintyChanged': uncChanged,
      'diffs': diffs,
    };
  }

  /// Retrieves the active spatial state as of a given timestamp.
  Future<SpatialState?> getSpatialStateAsOf({
    required String hypothesisId,
    required DateTime timestamp,
  }) async {
    return repository.getAsOf(hypothesisId, timestamp);
  }

  /// Retrieves full spatial version history for an EventHypothesis ID.
  Future<List<SpatialState>> getSpatialHistory(String hypothesisId) async {
    return repository.getHistory(hypothesisId);
  }

  /// Queries spatial states.
  Future<List<SpatialState>> querySpatialStates(SpatialStateQuery query) async {
    return repository.query(query);
  }
}
