import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/osint/evidence_relationship.dart';

/// Categories of evidence similarity and syndication matches.
enum SyndicationMatchType {
  exactContentMatch,
  nearDuplicateMatch,
  syndicatedLineageMatch,
  distinctContent,
  insufficientEvidence,
}

/// Immutable result of comparing two OSINTEvidence records for duplicates or syndication lineage.
@immutable
class SyndicationMatchResult {
  final String evidenceAId;
  final String evidenceBId;
  final SyndicationMatchType matchType;
  final double contentSimilarity;
  final bool isDuplicate;
  final bool isSyndicated;
  final String? inferredSourceId;
  final List<EvidenceRelationship> relationships;
  final String rationale;

  SyndicationMatchResult({
    required this.evidenceAId,
    required this.evidenceBId,
    required this.matchType,
    required this.contentSimilarity,
    required this.isDuplicate,
    required this.isSyndicated,
    this.inferredSourceId,
    List<EvidenceRelationship> relationships = const [],
    required this.rationale,
  }) : relationships = List.unmodifiable(relationships);

  bool get isValid =>
      evidenceAId.trim().isNotEmpty &&
      evidenceBId.trim().isNotEmpty &&
      evidenceAId != evidenceBId &&
      contentSimilarity >= 0.0 &&
      contentSimilarity <= 1.0;

  Map<String, dynamic> toMap() {
    return {
      'evidenceAId': evidenceAId,
      'evidenceBId': evidenceBId,
      'matchType': matchType.name,
      'contentSimilarity': contentSimilarity,
      'isDuplicate': isDuplicate,
      'isSyndicated': isSyndicated,
      'inferredSourceId': inferredSourceId,
      'relationships': relationships.map((r) => r.toMap()).toList(),
      'rationale': rationale,
    };
  }

  factory SyndicationMatchResult.fromMap(Map<String, dynamic> map) {
    return SyndicationMatchResult(
      evidenceAId: map['evidenceAId'] as String? ?? '',
      evidenceBId: map['evidenceBId'] as String? ?? '',
      matchType: SyndicationMatchType.values.firstWhere(
        (e) => e.name == map['matchType'],
        orElse: () => SyndicationMatchType.insufficientEvidence,
      ),
      contentSimilarity: (map['contentSimilarity'] as num?)?.toDouble() ?? 0.0,
      isDuplicate: map['isDuplicate'] as bool? ?? false,
      isSyndicated: map['isSyndicated'] as bool? ?? false,
      inferredSourceId: map['inferredSourceId'] as String?,
      relationships:
          (map['relationships'] as List<dynamic>?)
              ?.map(
                (r) => EvidenceRelationship.fromMap(r as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      rationale: map['rationale'] as String? ?? '',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyndicationMatchResult &&
          runtimeType == other.runtimeType &&
          evidenceAId == other.evidenceAId &&
          evidenceBId == other.evidenceBId &&
          matchType == other.matchType &&
          contentSimilarity == other.contentSimilarity;

  @override
  int get hashCode =>
      Object.hash(evidenceAId, evidenceBId, matchType, contentSimilarity);
}
