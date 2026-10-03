import 'model_output_contract.dart';

/// Single Version in the immutable EventStateHistory.
class EventStateVersion {
  final int versionNumber; // 1, 2, 3, 4...
  final String versionTimestamp;
  final String? triggeringMutationId;
  final List<String> evidenceIds;
  final List<String> supportingEvidenceIds;
  final List<String> conflictingEvidenceIds;
  final List<ExperimentEventHypothesis> hypotheses;
  final bool isCurrentVersion;

  const EventStateVersion({
    required this.versionNumber,
    required this.versionTimestamp,
    this.triggeringMutationId,
    required this.evidenceIds,
    required this.supportingEvidenceIds,
    required this.conflictingEvidenceIds,
    required this.hypotheses,
    required this.isCurrentVersion,
  });

  Map<String, dynamic> toJson() => {
        'versionNumber': versionNumber,
        'versionTimestamp': versionTimestamp,
        'triggeringMutationId': triggeringMutationId,
        'evidenceIds': evidenceIds,
        'supportingEvidenceIds': supportingEvidenceIds,
        'conflictingEvidenceIds': conflictingEvidenceIds,
        'hypotheses': hypotheses.map((h) => h.toJson()).toList(),
        'isCurrentVersion': isCurrentVersion,
      };

  factory EventStateVersion.fromJson(Map<String, dynamic> json) {
    return EventStateVersion(
      versionNumber: json['versionNumber'] as int,
      versionTimestamp: json['versionTimestamp'] as String,
      triggeringMutationId: json['triggeringMutationId'] as String?,
      evidenceIds: (json['evidenceIds'] as List<dynamic>).cast<String>(),
      supportingEvidenceIds: (json['supportingEvidenceIds'] as List<dynamic>).cast<String>(),
      conflictingEvidenceIds: (json['conflictingEvidenceIds'] as List<dynamic>).cast<String>(),
      hypotheses: (json['hypotheses'] as List<dynamic>)
          .map((h) => ExperimentEventHypothesis.fromJson(h as Map<String, dynamic>))
          .toList(),
      isCurrentVersion: json['isCurrentVersion'] as bool,
    );
  }
}

/// Master Event State History retaining immutable prior state versions (V1, V2, V3, V4...).
class EventStateHistory {
  final String historyId;
  final String caseId;
  final List<EventStateVersion> versions;

  const EventStateHistory({
    required this.historyId,
    required this.caseId,
    required this.versions,
  });

  EventStateVersion get currentVersion =>
      versions.firstWhere((v) => v.isCurrentVersion, orElse: () => versions.last);

  Map<String, dynamic> toJson() => {
        'historyId': historyId,
        'caseId': caseId,
        'versions': versions.map((v) => v.toJson()).toList(),
      };

  factory EventStateHistory.fromJson(Map<String, dynamic> json) {
    return EventStateHistory(
      historyId: json['historyId'] as String,
      caseId: json['caseId'] as String,
      versions: (json['versions'] as List<dynamic>)
          .map((v) => EventStateVersion.fromJson(v as Map<String, dynamic>))
          .toList(),
    );
  }
}
