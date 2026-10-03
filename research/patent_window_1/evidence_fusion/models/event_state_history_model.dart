import '../contracts/model_output_contract.dart';
import '../contracts/state_history_contract.dart';
import '../harness/visible_dataset_loader.dart';

/// Experimental Engine managing immutable EventStateHistory across successive evidence arrivals and mutations.
class EventStateHistoryManager {
  final Map<String, EventStateHistory> _caseHistories = {};

  Map<String, EventStateHistory> get caseHistories => Map.unmodifiable(_caseHistories);

  /// Initializes or updates the state history for a case with a new version V_N.
  /// Preserves all prior state versions without overwriting.
  EventStateVersion appendStateVersion({
    required String caseId,
    required List<VisibleEvidenceObject> currentEvidence,
    required List<ExperimentEventHypothesis> hypotheses,
    String? triggeringMutationId,
  }) {
    final history = _caseHistories[caseId];
    final nextVersionNum = history == null ? 1 : history.versions.length + 1;
    final timestamp = DateTime.utc(2026, 9, 30, 12, nextVersionNum).toIso8601String();

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
      // Mark previous current version as false, append new version
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

  /// Reconstructs state at a historical version number V_k.
  EventStateVersion? getHistoricalVersion(String caseId, int versionNumber) {
    final history = _caseHistories[caseId];
    if (history == null) return null;

    return history.versions.firstWhere(
      (v) => v.versionNumber == versionNumber,
      orElse: () => history.currentVersion,
    );
  }
}
