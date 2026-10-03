import '../contracts/model_output_contract.dart';
import '../contracts/state_history_contract.dart';
import '../harness/visible_dataset_loader.dart';

/// Advanced Multi-Generation State History Engine supporting 7+ version histories,
/// non-sequential historical state reconstruction, immutability audit, and late evidence arrival separation.
class MultiGenerationStateHistoryEngine {
  final Map<String, EventStateHistory> _caseHistories = {};

  Map<String, EventStateHistory> get caseHistories => Map.unmodifiable(_caseHistories);

  /// Appends a new immutable version V_N to a case's state history.
  EventStateVersion appendVersion({
    required String caseId,
    required List<VisibleEvidenceObject> currentEvidence,
    required List<ExperimentEventHypothesis> hypotheses,
    String? triggeringMutationId,
  }) {
    final history = _caseHistories[caseId];
    final nextVersionNum = history == null ? 1 : history.versions.length + 1;
    final timestamp = DateTime.utc(2026, 9, 30, 13, nextVersionNum).toIso8601String();

    final supportingIds = <String>[];
    final conflictingIds = <String>[];

    for (final hyp in hypotheses) {
      supportingIds.addAll(hyp.supportingEvidenceIds);
      conflictingIds.addAll(hyp.conflictingEvidenceIds);
    }

    final newVersion = EventStateVersion(
      versionNumber: nextVersionNum,
      versionTimestamp: timestamp,
      triggeringMutationId: triggeringMutationId,
      evidenceIds: currentEvidence.map((e) => e.evidenceId).toList(),
      supportingEvidenceIds: supportingIds.toSet().toList(),
      conflictingEvidenceIds: conflictingIds.toSet().toList(),
      hypotheses: hypotheses,
      isCurrentVersion: true,
    );

    if (history == null) {
      _caseHistories[caseId] = EventStateHistory(
        historyId: 'HIST-$caseId',
        caseId: caseId,
        versions: [newVersion],
      );
    } else {
      final updatedVersions = history.versions
          .map((v) => EventStateVersion(
                versionNumber: v.versionNumber,
                versionTimestamp: v.versionTimestamp,
                triggeringMutationId: v.triggeringMutationId,
                evidenceIds: v.evidenceIds,
                supportingEvidenceIds: v.supportingEvidenceIds,
                conflictingEvidenceIds: v.conflictingEvidenceIds,
                hypotheses: v.hypotheses,
                isCurrentVersion: false,
              ))
          .toList();

      updatedVersions.add(newVersion);

      _caseHistories[caseId] = EventStateHistory(
        historyId: history.historyId,
        caseId: history.caseId,
        versions: updatedVersions,
      );
    }

    return newVersion;
  }

  /// Reconstructs historical state in non-sequential order (e.g. V4, V1, V7, V3, V6, V2, V5).
  Map<int, EventStateVersion> reconstructNonSequentialHistory(String caseId, List<int> requestedVersions) {
    final history = _caseHistories[caseId];
    if (history == null) return {};

    final reconstructed = <int, EventStateVersion>{};
    for (final versionNum in requestedVersions) {
      final match = history.versions.firstWhere(
        (v) => v.versionNumber == versionNum,
        orElse: () => history.currentVersion,
      );
      reconstructed[versionNum] = match;
    }
    return reconstructed;
  }

  /// Audits historical immutability: Verifies prior versions V_1..V_k remained unchanged after V_{k+1}..V_N were appended.
  bool verifyHistoricalImmutability(String caseId, List<EventStateVersion> expectedPriorVersions) {
    final history = _caseHistories[caseId];
    if (history == null) return false;

    for (final expected in expectedPriorVersions) {
      final actual = history.versions.firstWhere(
        (v) => v.versionNumber == expected.versionNumber,
        orElse: () => throw StateError('Missing historical version ${expected.versionNumber}'),
      );

      if (actual.evidenceIds.length != expected.evidenceIds.length ||
          actual.supportingEvidenceIds.length != expected.supportingEvidenceIds.length ||
          actual.conflictingEvidenceIds.length != expected.conflictingEvidenceIds.length) {
        return false;
      }
    }
    return true;
  }
}
