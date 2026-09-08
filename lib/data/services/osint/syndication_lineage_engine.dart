import 'dart:math' as math;
import 'package:riskpulse/domain/osint/osint_evidence.dart';
import 'package:riskpulse/domain/osint/evidence_relationship.dart';
import 'package:riskpulse/domain/osint/syndication_match_result.dart';
import 'package:riskpulse/domain/osint/syndication_cluster.dart';
import 'package:riskpulse/data/services/osint/osint_normalizer.dart';

/// Pure-Dart, provider-neutral engine for evidence syndication, duplicate detection, and lineage analysis.
///
/// Operates on [OSINTEvidence] domain objects without deleting source evidence, generating claims,
/// or inferring disaster events.
class SyndicationLineageEngine {
  /// Near-duplicate content similarity threshold for substantial text (>= 8 words).
  static const double nearDuplicateThreshold = 0.80;

  /// Higher threshold for very short text (< 8 words) to prevent false-positive duplicate matches on generic headlines.
  static const double shortContentThreshold = 0.90;

  /// Minimum text similarity required to evaluate syndication lineage signals.
  static const double syndicationThreshold = 0.55;

  /// Compares two [OSINTEvidence] records ($A$ and $B$) and evaluates duplicate, near-duplicate, or syndication lineage relationships.
  SyndicationMatchResult compareEvidence(OSINTEvidence a, OSINTEvidence b) {
    if (a.evidenceId == b.evidenceId) {
      throw ArgumentError(
        'Cannot compare evidence record with itself: ${a.evidenceId}.',
      );
    }

    // 1. Exact SHA-256 Content Fingerprint Match
    if (a.contentFingerprint != null &&
        b.contentFingerprint != null &&
        a.contentFingerprint == b.contentFingerprint) {
      final relationship = EvidenceRelationship(
        relationshipId: 'rel-dup-${a.evidenceId}-${b.evidenceId}',
        sourceEntityId: a.evidenceId,
        targetEntityId: b.evidenceId,
        relationshipType: RelationshipType.duplicates,
        notes:
            'Exact SHA-256 content fingerprint match (${a.contentFingerprint}).',
      );

      return SyndicationMatchResult(
        evidenceAId: a.evidenceId,
        evidenceBId: b.evidenceId,
        matchType: SyndicationMatchType.exactContentMatch,
        contentSimilarity: 1.0,
        isDuplicate: true,
        isSyndicated: false,
        relationships: [relationship],
        rationale:
            'Exact SHA-256 content fingerprint match (${a.contentFingerprint}).',
      );
    }

    // 2. Same Source & Same Canonical URL Match
    if (a.canonicalUrl != null &&
        b.canonicalUrl != null &&
        a.canonicalUrl == b.canonicalUrl &&
        a.sourceId == b.sourceId) {
      final relationship = EvidenceRelationship(
        relationshipId: 'rel-url-dup-${a.evidenceId}-${b.evidenceId}',
        sourceEntityId: a.evidenceId,
        targetEntityId: b.evidenceId,
        relationshipType: RelationshipType.duplicates,
        notes: 'Identical source ID and canonical URL (${a.canonicalUrl}).',
      );

      return SyndicationMatchResult(
        evidenceAId: a.evidenceId,
        evidenceBId: b.evidenceId,
        matchType: SyndicationMatchType.exactContentMatch,
        contentSimilarity: 1.0,
        isDuplicate: true,
        isSyndicated: false,
        relationships: [relationship],
        rationale: 'Identical source ID and canonical URL (${a.canonicalUrl}).',
      );
    }

    // 3. Substantive Text & Jaccard Token / 3-Gram Similarity
    final normTextA = OSINTNormalizer.normalizeText(a.extractedText);
    final normTextB = OSINTNormalizer.normalizeText(b.extractedText);

    final wordsA = normTextA
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    final wordsB = normTextB
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();

    final int minWords = math.min(wordsA.length, wordsB.length);
    final bool isVeryShortContent = minWords < 8;

    final double tokenSim = _computeJaccardTokenSimilarity(
      normTextA,
      normTextB,
    );
    final double gramSim = _computeJaccard3GramSimilarity(normTextA, normTextB);
    final double compositeSimilarity = math.max(
      tokenSim,
      (tokenSim + gramSim) / 2.0,
    );

    // Short content safeguard check (< 8 words)
    if (isVeryShortContent) {
      if (compositeSimilarity < shortContentThreshold) {
        return SyndicationMatchResult(
          evidenceAId: a.evidenceId,
          evidenceBId: b.evidenceId,
          matchType: SyndicationMatchType.distinctContent,
          contentSimilarity: compositeSimilarity,
          isDuplicate: false,
          isSyndicated: false,
          rationale:
              'Very short content ($minWords words) did not meet $shortContentThreshold threshold for duplicate classification.',
        );
      }
    }

    final requiredThreshold = isVeryShortContent
        ? shortContentThreshold
        : nearDuplicateThreshold;
    final bool hasAttribution =
        _hasAttributionSignal(a.extractedText) ||
        _hasAttributionSignal(b.extractedText);
    final bool datesDiffer =
        a.publishedAt != null &&
        b.publishedAt != null &&
        a.publishedAt != b.publishedAt;

    // 4. Directional Syndication Lineage Classification
    if (compositeSimilarity >= syndicationThreshold &&
        (hasAttribution || (a.sourceId != b.sourceId && datesDiffer))) {
      final bool aIsEarlier = _isEarlier(a.publishedAt, b.publishedAt);
      final earlier = aIsEarlier ? a : b;
      final later = aIsEarlier ? b : a;

      final relationship = EvidenceRelationship(
        relationshipId: 'rel-syn-${later.evidenceId}-${earlier.evidenceId}',
        sourceEntityId: later.evidenceId,
        targetEntityId: earlier.evidenceId,
        relationshipType: RelationshipType.syndicatedFrom,
        notes:
            'Evidence ${later.evidenceId} appears syndicated from earlier publication ${earlier.evidenceId}.',
      );

      return SyndicationMatchResult(
        evidenceAId: a.evidenceId,
        evidenceBId: b.evidenceId,
        matchType: SyndicationMatchType.syndicatedLineageMatch,
        contentSimilarity: compositeSimilarity,
        isDuplicate: true,
        isSyndicated: true,
        inferredSourceId: earlier.sourceId,
        relationships: [relationship],
        rationale:
            'Syndication lineage detected: ${later.evidenceId} syndicated from earlier publication ${earlier.evidenceId}.',
      );
    }

    // 5. Near-Duplicate Classification
    if (compositeSimilarity >= requiredThreshold) {
      final relationship = EvidenceRelationship(
        relationshipId: 'rel-near-dup-${a.evidenceId}-${b.evidenceId}',
        sourceEntityId: a.evidenceId,
        targetEntityId: b.evidenceId,
        relationshipType: RelationshipType.duplicates,
        notes:
            'Near-duplicate content similarity: ${(compositeSimilarity * 100).toStringAsFixed(1)}%.',
      );

      return SyndicationMatchResult(
        evidenceAId: a.evidenceId,
        evidenceBId: b.evidenceId,
        matchType: SyndicationMatchType.nearDuplicateMatch,
        contentSimilarity: compositeSimilarity,
        isDuplicate: true,
        isSyndicated: false,
        relationships: [relationship],
        rationale:
            'Near-duplicate text similarity (${(compositeSimilarity * 100).toStringAsFixed(1)}%) meets $requiredThreshold threshold.',
      );
    }

    // 6. Distinct Content
    return SyndicationMatchResult(
      evidenceAId: a.evidenceId,
      evidenceBId: b.evidenceId,
      matchType: SyndicationMatchType.distinctContent,
      contentSimilarity: compositeSimilarity,
      isDuplicate: false,
      isSyndicated: false,
      rationale:
          'Evidence items contain distinct content (similarity: ${(compositeSimilarity * 100).toStringAsFixed(1)}%).',
    );
  }

  /// Groups pairwise duplicate and syndicated evidence into deterministic [SyndicationCluster] objects.
  ///
  /// Preserves ALL evidence records without deleting or mutating source evidence.
  List<SyndicationCluster> clusterEvidence(List<OSINTEvidence> evidenceList) {
    if (evidenceList.isEmpty) return const [];

    final Map<String, Set<String>> adj = {};
    final Map<String, List<EvidenceRelationship>> relationshipsMap = {};

    for (final e in evidenceList) {
      adj[e.evidenceId] = {e.evidenceId};
      relationshipsMap[e.evidenceId] = [];
    }

    final Map<String, OSINTEvidence> evidenceMap = {
      for (final e in evidenceList) e.evidenceId: e,
    };

    for (int i = 0; i < evidenceList.length; i++) {
      for (int j = i + 1; j < evidenceList.length; j++) {
        final a = evidenceList[i];
        final b = evidenceList[j];

        final match = compareEvidence(a, b);
        if (match.isDuplicate || match.isSyndicated) {
          adj[a.evidenceId]!.add(b.evidenceId);
          adj[b.evidenceId]!.add(a.evidenceId);

          relationshipsMap[a.evidenceId]!.addAll(match.relationships);
          relationshipsMap[b.evidenceId]!.addAll(match.relationships);
        }
      }
    }

    final visited = <String>{};
    final List<SyndicationCluster> clusters = [];

    for (final e in evidenceList) {
      final id = e.evidenceId;
      if (visited.contains(id)) continue;

      final component = <String>{};
      final componentRels = <EvidenceRelationship>[];
      _dfs(id, adj, visited, component, componentRels, relationshipsMap);

      final memberIds = component.toList()..sort();

      // Select primary evidence ID as the earliest published record (or first alphabetically if equal/null)
      memberIds.sort((idA, idB) {
        final dateA = evidenceMap[idA]?.publishedAt;
        final dateB = evidenceMap[idB]?.publishedAt;

        if (dateA != null && dateB != null) {
          final cmp = dateA.compareTo(dateB);
          if (cmp != 0) return cmp;
        } else if (dateA != null) {
          return -1;
        } else if (dateB != null) {
          return 1;
        }
        return idA.compareTo(idB);
      });

      final primaryId = memberIds.first;

      final uniqueRelsMap = <String, EvidenceRelationship>{};
      for (final rel in componentRels) {
        uniqueRelsMap[rel.relationshipId] = rel;
      }

      clusters.add(
        SyndicationCluster(
          clusterId: 'cluster-$primaryId',
          primaryEvidenceId: primaryId,
          memberEvidenceIds: memberIds,
          relationships: uniqueRelsMap.values.toList(),
        ),
      );
    }

    return List.unmodifiable(clusters);
  }

  void _dfs(
    String curr,
    Map<String, Set<String>> adj,
    Set<String> visited,
    Set<String> component,
    List<EvidenceRelationship> componentRels,
    Map<String, List<EvidenceRelationship>> relationshipsMap,
  ) {
    visited.add(curr);
    component.add(curr);
    componentRels.addAll(relationshipsMap[curr] ?? const []);

    for (final neighbor in adj[curr] ?? const <String>{}) {
      if (!visited.contains(neighbor)) {
        _dfs(
          neighbor,
          adj,
          visited,
          component,
          componentRels,
          relationshipsMap,
        );
      }
    }
  }

  static double _computeJaccardTokenSimilarity(String textA, String textB) {
    final tokensA = textA
        .toLowerCase()
        .split(RegExp(r'\W+'))
        .where((t) => t.length > 2)
        .toSet();
    final tokensB = textB
        .toLowerCase()
        .split(RegExp(r'\W+'))
        .where((t) => t.length > 2)
        .toSet();

    if (tokensA.isEmpty && tokensB.isEmpty) return 1.0;
    if (tokensA.isEmpty || tokensB.isEmpty) return 0.0;

    final intersection = tokensA.intersection(tokensB).length;
    final union = tokensA.union(tokensB).length;

    return union == 0 ? 0.0 : intersection / union;
  }

  static double _computeJaccard3GramSimilarity(String textA, String textB) {
    final gramsA = _extract3Grams(textA.toLowerCase());
    final gramsB = _extract3Grams(textB.toLowerCase());

    if (gramsA.isEmpty && gramsB.isEmpty) return 1.0;
    if (gramsA.isEmpty || gramsB.isEmpty) return 0.0;

    final intersection = gramsA.intersection(gramsB).length;
    final union = gramsA.union(gramsB).length;

    return union == 0 ? 0.0 : intersection / union;
  }

  static Set<String> _extract3Grams(String text) {
    final words = text
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.length < 3) return {text};

    final grams = <String>{};
    for (int i = 0; i <= words.length - 3; i++) {
      grams.add('${words[i]} ${words[i + 1]} ${words[i + 2]}');
    }
    return grams;
  }

  static bool _hasAttributionSignal(String text) {
    final lower = text.toLowerCase();
    return lower.contains('via ') ||
        lower.contains('reported by') ||
        lower.contains('according to') ||
        lower.contains('courtesy:') ||
        lower.contains('reprinted from');
  }

  static bool _isEarlier(DateTime? dateA, DateTime? dateB) {
    if (dateA != null && dateB != null) {
      return dateA.isBefore(dateB);
    }
    if (dateA != null) return true;
    return false;
  }
}
