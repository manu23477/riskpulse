import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/hydroai/hydroai_execution_mode.dart';

/// Enumeration of explicit HydroAI solver execution statuses.
enum HydroAiExecutionStatus {
  notStarted,
  running,
  succeeded,
  failed,
  timeout,
  cancelled,
  outputInvalid,
  unavailable,
}

/// Enumeration of explicit HydroAI input data modes.
enum HydroAiInputDataMode {
  realObserved,
  realForecast,
  realRemoteSensing,
  liveGee,
  localRealData,
  syntheticFixture,
  mock,
  unknown,
}

/// Enumeration of explicit HydroAI operational promotion statuses.
enum HydroAiOperationalStatus {
  researchOnly,
  pendingReview,
  promotionEligible,
  operationallyApproved,
  rejected,
}

/// Immutable domain contract representing canonical HydroAI / HEC-RAS execution provenance & governance state.
///
/// SCIENTIFIC GOVERNANCE:
/// 1. Enforces end-to-end execution-mode propagation (`nativeHecRas` vs `simulatedHydroAi`).
/// 2. Preserves parent-child execution lineage (e.g. failed native parent -> succeeded simulated child).
/// 3. Validates provenance completeness prior to Research GIS export or ControlledPromotionGate review.
@immutable
class HydroAiExecutionContract {
  static const int currentSchemaVersion = 1;

  final String executionId;
  final String scenarioId;
  final String analysisId;
  final String modelId;
  final String modelVersion;
  final String solverId;
  final String solverName;
  final String solverVersion;
  final HydroAiExecutionMode executionMode;
  final HydroAiInputDataMode inputDataMode;
  final HydroAiExecutionStatus executionStatus;
  final String scientificStatus;
  final HydroAiOperationalStatus operationalStatus;
  final DateTime timestamp;
  final String? parentExecutionId;
  final String provenanceId;
  final String? fallbackReason;
  final List<String> inputReferences;
  final List<String> outputReferences;
  final int schemaVersion;

  const HydroAiExecutionContract({
    required this.executionId,
    required this.scenarioId,
    required this.analysisId,
    required this.modelId,
    this.modelVersion = '1.0.0',
    required this.solverId,
    required this.solverName,
    this.solverVersion = 'HEC-RAS 6.x / Pure-Dart Fallback',
    required this.executionMode,
    this.inputDataMode = HydroAiInputDataMode.syntheticFixture,
    required this.executionStatus,
    this.scientificStatus = 'SOFTWARE_VALIDATED',
    this.operationalStatus = HydroAiOperationalStatus.researchOnly,
    required this.timestamp,
    this.parentExecutionId,
    required this.provenanceId,
    this.fallbackReason,
    this.inputReferences = const [],
    this.outputReferences = const [],
    this.schemaVersion = currentSchemaVersion,
  })  : assert(executionId.length > 0, 'executionId cannot be empty.'),
        assert(scenarioId.length > 0, 'scenarioId cannot be empty.');

  /// Validates provenance completeness prior to export or promotion gate review.
  bool get isProvenanceComplete =>
      executionId.trim().isNotEmpty &&
      scenarioId.trim().isNotEmpty &&
      modelId.trim().isNotEmpty &&
      solverId.trim().isNotEmpty &&
      provenanceId.trim().isNotEmpty &&
      schemaVersion > 0;

  Map<String, dynamic> toMap() {
    return {
      'executionId': executionId,
      'scenarioId': scenarioId,
      'analysisId': analysisId,
      'modelId': modelId,
      'modelVersion': modelVersion,
      'solverId': solverId,
      'solverName': solverName,
      'solverVersion': solverVersion,
      'executionMode': executionMode.name,
      'inputDataMode': inputDataMode.name,
      'executionStatus': executionStatus.name,
      'scientificStatus': scientificStatus,
      'operationalStatus': operationalStatus.name,
      'timestamp': timestamp.toIso8601String(),
      'parentExecutionId': parentExecutionId,
      'provenanceId': provenanceId,
      'fallbackReason': fallbackReason,
      'inputReferences': inputReferences,
      'outputReferences': outputReferences,
      'schemaVersion': schemaVersion,
    };
  }

  factory HydroAiExecutionContract.fromMap(Map<String, dynamic> map) {
    return HydroAiExecutionContract(
      executionId: map['executionId'] as String? ?? '',
      scenarioId: map['scenarioId'] as String? ?? '',
      analysisId: map['analysisId'] as String? ?? '',
      modelId: map['modelId'] as String? ?? '',
      modelVersion: map['modelVersion'] as String? ?? '1.0.0',
      solverId: map['solverId'] as String? ?? '',
      solverName: map['solverName'] as String? ?? '',
      solverVersion: map['solverVersion'] as String? ?? '',
      executionMode: HydroAiExecutionMode.values.firstWhere(
        (e) => e.name == map['executionMode'],
        orElse: () => HydroAiExecutionMode.simulated,
      ),
      inputDataMode: HydroAiInputDataMode.values.firstWhere(
        (e) => e.name == map['inputDataMode'],
        orElse: () => HydroAiInputDataMode.syntheticFixture,
      ),
      executionStatus: HydroAiExecutionStatus.values.firstWhere(
        (e) => e.name == map['executionStatus'],
        orElse: () => HydroAiExecutionStatus.succeeded,
      ),
      scientificStatus: map['scientificStatus'] as String? ?? 'SOFTWARE_VALIDATED',
      operationalStatus: HydroAiOperationalStatus.values.firstWhere(
        (e) => e.name == map['operationalStatus'],
        orElse: () => HydroAiOperationalStatus.researchOnly,
      ),
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp'] as String)
          : DateTime.now().toUtc(),
      parentExecutionId: map['parentExecutionId'] as String?,
      provenanceId: map['provenanceId'] as String? ?? '',
      fallbackReason: map['fallbackReason'] as String?,
      inputReferences: (map['inputReferences'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
      outputReferences: (map['outputReferences'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
      schemaVersion: map['schemaVersion'] as int? ?? currentSchemaVersion,
    );
  }
}
