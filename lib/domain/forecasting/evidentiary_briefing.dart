import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/gis/analytical_step.dart';

/// Immutable domain summary capturing contributing evidence, data completeness, calibration warnings, and uncertainty.
@immutable
class EvidentiaryBriefing {
  static const int currentSchemaVersion = 1;

  final String briefingId;
  final List<String> contributingEvidenceIds;
  final List<String> contributingModelIds;
  final double dataCompletenessRatio;
  final String calibrationStatusNotice;
  final List<String> uncertaintyWarnings;
  final List<AnalyticalStep> provenanceSteps;
  final Map<String, dynamic> metadata;
  final int schemaVersion;

  EvidentiaryBriefing({
    required this.briefingId,
    this.contributingEvidenceIds = const [],
    this.contributingModelIds = const [],
    required this.dataCompletenessRatio,
    this.calibrationStatusNotice = 'PROVISIONAL / UNCALIBRATED FOR REGION',
    this.uncertaintyWarnings = const [],
    this.provenanceSteps = const [],
    this.metadata = const {},
    this.schemaVersion = currentSchemaVersion,
  }) {
    if (briefingId.trim().isEmpty) {
      throw ArgumentError('briefingId cannot be empty.');
    }
    if (dataCompletenessRatio.isNaN ||
        dataCompletenessRatio < 0.0 ||
        dataCompletenessRatio > 1.0) {
      throw ArgumentError(
        'dataCompletenessRatio must be bounded within [0.0, 1.0] (got $dataCompletenessRatio).',
      );
    }
    if (schemaVersion <= 0) {
      throw ArgumentError('schemaVersion must be positive.');
    }
  }

  EvidentiaryBriefing copyWith({
    String? briefingId,
    List<String>? contributingEvidenceIds,
    List<String>? contributingModelIds,
    double? dataCompletenessRatio,
    String? calibrationStatusNotice,
    List<String>? uncertaintyWarnings,
    List<AnalyticalStep>? provenanceSteps,
    Map<String, dynamic>? metadata,
    int? schemaVersion,
  }) {
    return EvidentiaryBriefing(
      briefingId: briefingId ?? this.briefingId,
      contributingEvidenceIds:
          contributingEvidenceIds ?? this.contributingEvidenceIds,
      contributingModelIds: contributingModelIds ?? this.contributingModelIds,
      dataCompletenessRatio:
          dataCompletenessRatio ?? this.dataCompletenessRatio,
      calibrationStatusNotice:
          calibrationStatusNotice ?? this.calibrationStatusNotice,
      uncertaintyWarnings: uncertaintyWarnings ?? this.uncertaintyWarnings,
      provenanceSteps: provenanceSteps ?? this.provenanceSteps,
      metadata: metadata ?? this.metadata,
      schemaVersion: schemaVersion ?? this.schemaVersion,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'briefingId': briefingId,
      'evidenceCount': contributingEvidenceIds.length,
      'modelCount': contributingModelIds.length,
      'dataCompletenessRatio': dataCompletenessRatio,
      'calibrationStatusNotice': calibrationStatusNotice,
      'uncertaintyWarningCount': uncertaintyWarnings.length,
      'schemaVersion': schemaVersion,
      'metadata': metadata,
    };
  }

  factory EvidentiaryBriefing.fromMap(Map<String, dynamic> map) {
    return EvidentiaryBriefing(
      briefingId: map['briefingId'] as String? ?? '',
      dataCompletenessRatio:
          (map['dataCompletenessRatio'] as num?)?.toDouble() ?? 1.0,
      calibrationStatusNotice: map['calibrationStatusNotice'] as String? ??
          'PROVISIONAL / UNCALIBRATED FOR REGION',
      uncertaintyWarnings:
          (map['uncertaintyWarnings'] as List<dynamic>?)?.cast<String>() ??
              const [],
      schemaVersion: map['schemaVersion'] as int? ?? currentSchemaVersion,
      metadata: (map['metadata'] as Map<String, dynamic>?) ?? const {},
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EvidentiaryBriefing &&
          runtimeType == other.runtimeType &&
          briefingId == other.briefingId &&
          dataCompletenessRatio == other.dataCompletenessRatio &&
          calibrationStatusNotice == other.calibrationStatusNotice &&
          schemaVersion == other.schemaVersion &&
          listEquals(contributingEvidenceIds, other.contributingEvidenceIds) &&
          listEquals(contributingModelIds, other.contributingModelIds) &&
          listEquals(uncertaintyWarnings, other.uncertaintyWarnings);

  @override
  int get hashCode => Object.hash(
        briefingId,
        dataCompletenessRatio,
        calibrationStatusNotice,
        schemaVersion,
        Object.hashAll(contributingEvidenceIds),
        Object.hashAll(contributingModelIds),
        Object.hashAll(uncertaintyWarnings),
      );
}
