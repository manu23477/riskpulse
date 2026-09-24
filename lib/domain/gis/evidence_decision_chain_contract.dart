import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/hydroai/hydroai_execution_mode.dart';
import 'package:riskpulse/domain/hydroai/hydroai_execution_contract.dart';

/// Enumeration of explicit evidence independence states.
enum EvidenceIndependenceStatus {
  independent,
  syndicated,
  unknown,
}

/// Enumeration of human review states along the decision chain.
enum EvidenceHumanReviewStatus {
  notRequired,
  pending,
  reviewed,
  accepted,
  rejected,
  returnedForReview,
}

/// Immutable canonical contract representing the end-to-end Evidence-to-Decision Intelligence Chain.
///
/// SCIENTIFIC GOVERNANCE:
/// 1. Links raw evidence -> quality assessment -> fusion -> hazard/impact -> exposure -> decision support -> priority -> review -> promotion gate.
/// 2. Preserves execution mode, input data mode, scientific status, and conflict records across chained analytics.
/// 3. Prevents automatic conversion of synthetic/simulated evidence into confirmed operational evidence.
@immutable
class EvidenceDecisionChainContract {
  static const int currentSchemaVersion = 1;

  final String chainId;
  final String eventId;
  final String scenarioId;
  final String analysisId;

  final List<String> inputEvidenceIds;
  final List<String> derivedEvidenceIds;
  final List<String> analyticalResultIds;
  final List<String> exposureResultIds;
  final List<String> decisionSupportResultIds;
  final String? priorityResultId;

  final List<String> sourceReferences;
  final List<String> provenanceReferences;

  final String evidenceStatus; // valid, partial, incomplete, stale, conflicted, unverified
  final String evidenceQuality;
  final EvidenceIndependenceStatus evidenceIndependence;

  final String scientificStatus; // SOFTWARE_VALIDATED, UNCALIBRATED, PROVISIONAL
  final HydroAiOperationalStatus operationalStatus;
  final EvidenceHumanReviewStatus humanReviewStatus;

  final HydroAiExecutionMode executionMode;
  final HydroAiInputDataMode inputDataMode;

  final String modelId;
  final String modelVersion;
  final String parameterSetId;
  final String parameterVersion;
  final String uncertaintyState; // UNQUANTIFIED, BOUNDED_RANGE

  final List<String> assumptionReferences;
  final List<String> limitationReferences;
  final List<String> conflictReferences;

  final DateTime createdAt;
  final DateTime updatedAt;

  final bool isSynthetic;
  final bool isSimulated;
  final bool isMock;
  final int schemaVersion;

  const EvidenceDecisionChainContract({
    required this.chainId,
    required this.eventId,
    required this.scenarioId,
    required this.analysisId,
    this.inputEvidenceIds = const [],
    this.derivedEvidenceIds = const [],
    this.analyticalResultIds = const [],
    this.exposureResultIds = const [],
    this.decisionSupportResultIds = const [],
    this.priorityResultId,
    this.sourceReferences = const [],
    this.provenanceReferences = const [],
    this.evidenceStatus = 'valid',
    this.evidenceQuality = 'standard',
    this.evidenceIndependence = EvidenceIndependenceStatus.unknown,
    this.scientificStatus = 'SOFTWARE_VALIDATED',
    this.operationalStatus = HydroAiOperationalStatus.researchOnly,
    this.humanReviewStatus = EvidenceHumanReviewStatus.pending,
    this.executionMode = HydroAiExecutionMode.simulated,
    this.inputDataMode = HydroAiInputDataMode.syntheticFixture,
    required this.modelId,
    this.modelVersion = '1.0.0',
    this.parameterSetId = 'default-params',
    this.parameterVersion = '1.0.0',
    this.uncertaintyState = 'UNQUANTIFIED',
    this.assumptionReferences = const [],
    this.limitationReferences = const [],
    this.conflictReferences = const [],
    required this.createdAt,
    required this.updatedAt,
    this.isSynthetic = false,
    this.isSimulated = true,
    this.isMock = false,
    this.schemaVersion = currentSchemaVersion,
  })  : assert(chainId.length > 0, 'chainId cannot be empty.'),
        assert(eventId.length > 0, 'eventId cannot be empty.'),
        assert(modelId.length > 0, 'modelId cannot be empty.');

  /// Validates provenance completeness prior to export or promotion gate review.
  bool get isChainProvenanceComplete =>
      chainId.trim().isNotEmpty &&
      eventId.trim().isNotEmpty &&
      scenarioId.trim().isNotEmpty &&
      modelId.trim().isNotEmpty &&
      provenanceReferences.isNotEmpty &&
      schemaVersion > 0;

  Map<String, dynamic> toMap() {
    return {
      'chainId': chainId,
      'eventId': eventId,
      'scenarioId': scenarioId,
      'analysisId': analysisId,
      'inputEvidenceIds': inputEvidenceIds,
      'derivedEvidenceIds': derivedEvidenceIds,
      'analyticalResultIds': analyticalResultIds,
      'exposureResultIds': exposureResultIds,
      'decisionSupportResultIds': decisionSupportResultIds,
      'priorityResultId': priorityResultId,
      'sourceReferences': sourceReferences,
      'provenanceReferences': provenanceReferences,
      'evidenceStatus': evidenceStatus,
      'evidenceQuality': evidenceQuality,
      'evidenceIndependence': evidenceIndependence.name,
      'scientificStatus': scientificStatus,
      'operationalStatus': operationalStatus.name,
      'humanReviewStatus': humanReviewStatus.name,
      'executionMode': executionMode.name,
      'inputDataMode': inputDataMode.name,
      'modelId': modelId,
      'modelVersion': modelVersion,
      'parameterSetId': parameterSetId,
      'parameterVersion': parameterVersion,
      'uncertaintyState': uncertaintyState,
      'assumptionReferences': assumptionReferences,
      'limitationReferences': limitationReferences,
      'conflictReferences': conflictReferences,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isSynthetic': isSynthetic,
      'isSimulated': isSimulated,
      'isMock': isMock,
      'schemaVersion': schemaVersion,
    };
  }

  factory EvidenceDecisionChainContract.fromMap(Map<String, dynamic> map) {
    return EvidenceDecisionChainContract(
      chainId: map['chainId'] as String? ?? '',
      eventId: map['eventId'] as String? ?? '',
      scenarioId: map['scenarioId'] as String? ?? '',
      analysisId: map['analysisId'] as String? ?? '',
      inputEvidenceIds: (map['inputEvidenceIds'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
      derivedEvidenceIds: (map['derivedEvidenceIds'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
      analyticalResultIds: (map['analyticalResultIds'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
      exposureResultIds: (map['exposureResultIds'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
      decisionSupportResultIds: (map['decisionSupportResultIds'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
      priorityResultId: map['priorityResultId'] as String?,
      sourceReferences: (map['sourceReferences'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
      provenanceReferences: (map['provenanceReferences'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
      evidenceStatus: map['evidenceStatus'] as String? ?? 'valid',
      evidenceQuality: map['evidenceQuality'] as String? ?? 'standard',
      evidenceIndependence: EvidenceIndependenceStatus.values.firstWhere(
        (e) => e.name == map['evidenceIndependence'],
        orElse: () => EvidenceIndependenceStatus.unknown,
      ),
      scientificStatus: map['scientificStatus'] as String? ?? 'SOFTWARE_VALIDATED',
      operationalStatus: HydroAiOperationalStatus.values.firstWhere(
        (e) => e.name == map['operationalStatus'],
        orElse: () => HydroAiOperationalStatus.researchOnly,
      ),
      humanReviewStatus: EvidenceHumanReviewStatus.values.firstWhere(
        (e) => e.name == map['humanReviewStatus'],
        orElse: () => EvidenceHumanReviewStatus.pending,
      ),
      executionMode: HydroAiExecutionMode.values.firstWhere(
        (e) => e.name == map['executionMode'],
        orElse: () => HydroAiExecutionMode.simulated,
      ),
      inputDataMode: HydroAiInputDataMode.values.firstWhere(
        (e) => e.name == map['inputDataMode'],
        orElse: () => HydroAiInputDataMode.syntheticFixture,
      ),
      modelId: map['modelId'] as String? ?? '',
      modelVersion: map['modelVersion'] as String? ?? '1.0.0',
      parameterSetId: map['parameterSetId'] as String? ?? 'default-params',
      parameterVersion: map['parameterVersion'] as String? ?? '1.0.0',
      uncertaintyState: map['uncertaintyState'] as String? ?? 'UNQUANTIFIED',
      assumptionReferences: (map['assumptionReferences'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
      limitationReferences: (map['limitationReferences'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
      conflictReferences: (map['conflictReferences'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : DateTime.now().toUtc(),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt'] as String) : DateTime.now().toUtc(),
      isSynthetic: map['isSynthetic'] as bool? ?? false,
      isSimulated: map['isSimulated'] as bool? ?? true,
      isMock: map['isMock'] as bool? ?? false,
      schemaVersion: map['schemaVersion'] as int? ?? currentSchemaVersion,
    );
  }
}
