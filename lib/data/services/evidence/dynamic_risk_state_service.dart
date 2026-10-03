import 'package:riskpulse/data/repositories/dynamic_risk_state_repository.dart';
import 'package:riskpulse/domain/evidence/administrative_state.dart';
import 'package:riskpulse/domain/evidence/dynamic_risk_state.dart';
import 'package:riskpulse/domain/evidence/dynamic_risk_state_query.dart';
import 'package:riskpulse/domain/evidence/event_hypothesis.dart';
import 'package:riskpulse/domain/evidence/exposure_condition.dart';
import 'package:riskpulse/domain/evidence/hazard_condition.dart';
import 'package:riskpulse/domain/evidence/impact_condition.dart';
import 'package:riskpulse/domain/evidence/risk_state_status.dart';
import 'package:riskpulse/domain/evidence/spatial_state.dart';
import 'package:riskpulse/domain/evidence/trend_direction.dart';
import 'package:riskpulse/domain/evidence/vulnerability_condition.dart';

/// Result container emitted when registering or updating a DynamicRiskState.
class RiskStateExecutionResult {
  final DynamicRiskState riskState;
  final bool isValid;
  final List<String> validationErrors;

  const RiskStateExecutionResult({
    required this.riskState,
    required this.isValid,
    required this.validationErrors,
  });
}

/// Service managing creation, validation, versioning, version comparison, and historical
/// reconstruction of versioned [DynamicRiskState] records for Event Hypotheses.
///
/// STRICT BOUNDARY: Does NOT trigger alerts, execute graph propagation, or perform cross-event mutations.
class DynamicRiskStateService {
  final DynamicRiskStateRepository repository;

  DynamicRiskStateService({required this.repository});

  /// Derives an immutable [DynamicRiskState] snapshot from the upstream pipeline.
  Future<RiskStateExecutionResult> deriveFromPipeline({
    required EventHypothesis hypothesis,
    required SpatialState spatialState,
    AdministrativeState? administrativeState,
    HazardCondition? hazardCondition,
    ExposureCondition? exposureCondition,
    VulnerabilityCondition? vulnerabilityCondition,
    ImpactCondition? impactCondition,
    List<String>? supportingEvidenceIds,
    List<String>? contradictingEvidenceIds,
    String? riskLevel = 'MODERATE',
    double? riskScore,
    double? confidenceScore = 0.82,
    String? riskStateId,
  }) async {
    final String rId = riskStateId ??
        'RISK-${hypothesis.hypothesisId}-v${hypothesis.hypothesisVersion}-s${spatialState.spatialStateVersion}-r1';

    final hazardCond = hazardCondition ??
        HazardCondition(
          hazardCategory: hypothesis.hazardCategory,
          hazardSeverity: 'moderate',
        );

    final exposureCond = exposureCondition ??
        ExposureCondition(
          exposureStatus: administrativeState != null && administrativeState.affectedUnitIds.isNotEmpty ? 'significant' : 'unknown',
          exposedUnitIds: administrativeState?.affectedUnitIds ?? const [],
        );

    final vulnCond = vulnerabilityCondition ?? const VulnerabilityCondition();
    final impactCond = impactCondition ?? const ImpactCondition();

    final state = DynamicRiskState(
      riskStateId: rId,
      eventHypothesisId: hypothesis.hypothesisId,
      hypothesisVersion: hypothesis.hypothesisVersion,
      riskStateVersion: 1,
      spatialStateId: spatialState.spatialStateId,
      spatialStateVersion: spatialState.spatialStateVersion,
      administrativeStateId: administrativeState?.administrativeStateId,
      administrativeStateVersion: administrativeState?.administrativeStateVersion,
      observedAt: spatialState.observedAt ?? hypothesis.detectedAt,
      calculatedAt: DateTime.now().toUtc(),
      effectiveFrom: spatialState.effectiveFrom ?? hypothesis.effectiveFrom,
      effectiveTo: spatialState.effectiveTo ?? hypothesis.effectiveTo,
      hazardCondition: hazardCond,
      exposureCondition: exposureCond,
      vulnerabilityCondition: vulnCond,
      impactCondition: impactCond,
      supportingEvidenceIds: supportingEvidenceIds ?? const [],
      contradictingEvidenceIds: contradictingEvidenceIds ?? const [],
      interpretationIds: hypothesis.interpretationIds,
      riskLevel: riskLevel,
      riskScore: riskScore,
      confidenceScore: confidenceScore,
      confidenceBasis: hypothesis.confidence.basis,
      confidenceMethod: hypothesis.confidence.method,
      trendDirection: TrendDirection.stable,
      provenance: {
        'hypothesisId': hypothesis.hypothesisId,
        'spatialStateId': spatialState.spatialStateId,
        'administrativeStateId': administrativeState?.administrativeStateId,
        'pipelineResolver': 'DynamicRiskStateService.deriveFromPipeline',
      },
    );

    final validationErrors = validateRiskState(state);
    final isValid = validationErrors.isEmpty;

    if (!isValid) {
      return RiskStateExecutionResult(
        riskState: state,
        isValid: false,
        validationErrors: validationErrors,
      );
    }

    await repository.save(state);

    return RiskStateExecutionResult(
      riskState: state,
      isValid: true,
      validationErrors: const [],
    );
  }

  /// Validates a [DynamicRiskState] for structural completeness and bounds.
  List<String> validateRiskState(DynamicRiskState state) {
    final errors = <String>[];

    if (state.riskStateId.trim().isEmpty) {
      errors.add('RiskState ID cannot be empty.');
    }
    if (state.eventHypothesisId.trim().isEmpty) {
      errors.add('EventHypothesis ID cannot be empty.');
    }
    if (state.spatialStateId.trim().isEmpty) {
      errors.add('SpatialState ID cannot be empty.');
    }

    if (state.confidenceScore != null && (state.confidenceScore! < 0.0 || state.confidenceScore! > 1.0)) {
      errors.add('Confidence score must be between 0.0 and 1.0.');
    }
    if (state.riskScore != null && (state.riskScore! < 0.0 || state.riskScore! > 1.0)) {
      errors.add('Risk score must be between 0.0 and 1.0.');
    }

    return errors;
  }

  /// Creates a **NEW immutable [DynamicRiskState] version v2**, setting `previousRiskStateId = currentState.riskStateId`.
  Future<RiskStateExecutionResult> createNextVersion({
    required DynamicRiskState currentState,
    HazardCondition? hazardCondition,
    ExposureCondition? exposureCondition,
    VulnerabilityCondition? vulnerabilityCondition,
    ImpactCondition? impactCondition,
    String? riskLevel,
    double? riskScore,
    TrendDirection? trendDirection,
    String? changeReason,
    Map<String, dynamic>? provenance,
  }) async {
    final int nextVersion = currentState.riskStateVersion + 1;
    final String nextId = 'RISK-${currentState.eventHypothesisId}-v${currentState.hypothesisVersion}-s${currentState.spatialStateVersion}-r$nextVersion';

    final revised = currentState.copyWith(
      riskStateId: nextId,
      riskStateVersion: nextVersion,
      previousRiskStateId: currentState.riskStateId,
      hazardCondition: hazardCondition ?? currentState.hazardCondition,
      exposureCondition: exposureCondition ?? currentState.exposureCondition,
      vulnerabilityCondition: vulnerabilityCondition ?? currentState.vulnerabilityCondition,
      impactCondition: impactCondition ?? currentState.impactCondition,
      riskLevel: riskLevel ?? currentState.riskLevel,
      riskScore: riskScore ?? currentState.riskScore,
      trendDirection: trendDirection ?? currentState.trendDirection,
      changeReason: changeReason,
      calculatedAt: DateTime.now().toUtc(),
      status: RiskStateStatus.active,
      provenance: {
        ...currentState.provenance, ...?provenance,
        'revisedFromRiskStateId': currentState.riskStateId,
      },
    );

    final validationErrors = validateRiskState(revised);
    if (validationErrors.isNotEmpty) {
      return RiskStateExecutionResult(
        riskState: revised,
        isValid: false,
        validationErrors: validationErrors,
      );
    }

    await repository.addVersion(currentState.riskStateId, revised);

    return RiskStateExecutionResult(
      riskState: revised,
      isValid: true,
      validationErrors: const [],
    );
  }

  /// Compares two [DynamicRiskState] versions and returns property diffs.
  Map<String, dynamic> compareRiskStates(DynamicRiskState r1, DynamicRiskState r2) {
    final Map<String, dynamic> diffs = {};
    final bool hazChanged = r1.hazardCondition != r2.hazardCondition;
    final bool expChanged = r1.exposureCondition != r2.exposureCondition;
    final bool vulChanged = r1.vulnerabilityCondition != r2.vulnerabilityCondition;
    final bool impChanged = r1.impactCondition != r2.impactCondition;
    final bool lvlChanged = r1.riskLevel != r2.riskLevel || r1.riskScore != r2.riskScore;

    if (hazChanged) diffs['hazardCondition'] = {'v1': r1.hazardCondition.toJson(), 'v2': r2.hazardCondition.toJson()};
    if (expChanged) diffs['exposureCondition'] = {'v1': r1.exposureCondition.toJson(), 'v2': r2.exposureCondition.toJson()};
    if (vulChanged) diffs['vulnerabilityCondition'] = {'v1': r1.vulnerabilityCondition.toJson(), 'v2': r2.vulnerabilityCondition.toJson()};
    if (impChanged) diffs['impactCondition'] = {'v1': r1.impactCondition.toJson(), 'v2': r2.impactCondition.toJson()};
    if (lvlChanged) diffs['riskLevel'] = {'v1': r1.riskLevel, 'v2': r2.riskLevel};

    return {
      'riskStateId': r1.riskStateId,
      'r1Version': r1.riskStateVersion,
      'r2Version': r2.riskStateVersion,
      'hazardChanged': hazChanged,
      'exposureChanged': expChanged,
      'vulnerabilityChanged': vulChanged,
      'impactChanged': impChanged,
      'riskLevelChanged': lvlChanged,
      'trendDirection': r2.trendDirection.name,
      'diffs': diffs,
    };
  }

  /// Retrieves the active risk state as of a given timestamp.
  Future<DynamicRiskState?> getRiskStateAsOf({
    required String hypothesisId,
    required DateTime timestamp,
  }) async {
    return repository.getAsOf(hypothesisId, timestamp);
  }

  /// Retrieves full risk version history for an EventHypothesis ID.
  Future<List<DynamicRiskState>> getRiskHistory(String hypothesisId) async {
    return repository.getHistory(hypothesisId);
  }

  /// Queries risk states.
  Future<List<DynamicRiskState>> queryRiskStates(DynamicRiskStateQuery query) async {
    return repository.query(query);
  }
}
