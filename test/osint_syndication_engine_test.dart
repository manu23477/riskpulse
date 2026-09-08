import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/domain/osint/osint_evidence.dart';
import 'package:riskpulse/domain/osint/evidence_relationship.dart';
import 'package:riskpulse/domain/osint/syndication_match_result.dart';
import 'package:riskpulse/data/services/osint/osint_normalizer.dart';
import 'package:riskpulse/data/services/osint/syndication_lineage_engine.dart';

void main() {
  final now = DateTime(2026, 9, 7, 12, 0, 0);
  final engine = SyndicationLineageEngine();

  OSINTEvidence makeEvidence({
    required String id,
    required String sourceId,
    String? title,
    required String text,
    String? url,
    DateTime? publishedAt,
  }) {
    final fingerprint = OSINTNormalizer.computeContentFingerprint(title, text);
    return OSINTEvidence(
      evidenceId: id,
      sourceId: sourceId,
      contentFingerprint: fingerprint,
      title: title,
      extractedText: text,
      canonicalUrl: url,
      publishedAt: publishedAt,
      retrievedAt: now,
    );
  }

  group('Stage 2.4 Syndication, Duplicate Detection & Lineage Engine Tests', () {
    test('1. Exact same SHA-256 fingerprint produces exactContentMatch and duplicates relationship', () {
      final evA = makeEvidence(
        id: 'ev-A',
        sourceId: 'src-1',
        title: 'Landslide Blocks Highway',
        text: 'A heavy landslide triggered by continuous rain has blocked traffic on NH-21 near Mandi.',
      );

      final evB = makeEvidence(
        id: 'ev-B',
        sourceId: 'src-2',
        title: 'Landslide Blocks Highway',
        text: 'A heavy landslide triggered by continuous rain has blocked traffic on NH-21 near Mandi.',
      );

      final match = engine.compareEvidence(evA, evB);

      expect(match.matchType, equals(SyndicationMatchType.exactContentMatch));
      expect(match.contentSimilarity, equals(1.0));
      expect(match.isDuplicate, isTrue);
      expect(match.relationships.length, equals(1));
      expect(match.relationships.first.relationshipType, equals(RelationshipType.duplicates));
    });

    test('2. Whitespace variation yields same fingerprint and exactContentMatch', () {
      final evA = makeEvidence(
        id: 'ev-A',
        sourceId: 'src-1',
        title: 'Landslide Alert',
        text: 'Heavy   rainfall triggered   landslide on highway.',
      );

      final evB = makeEvidence(
        id: 'ev-B',
        sourceId: 'src-2',
        title: 'Landslide Alert',
        text: 'Heavy rainfall triggered landslide on highway.',
      );

      expect(evA.contentFingerprint, equals(evB.contentFingerprint));

      final match = engine.compareEvidence(evA, evB);
      expect(match.matchType, equals(SyndicationMatchType.exactContentMatch));
      expect(match.isDuplicate, isTrue);
    });

    test('3. False-Positive Safeguard: Same title but different substantive body is NOT classified as duplicate', () {
      final evA = makeEvidence(
        id: 'ev-A',
        sourceId: 'src-1',
        title: 'Heavy Rainfall Warning',
        text: 'Mandi district expects 100mm rainfall over the next 24 hours with flood risks in low areas.',
      );

      final evB = makeEvidence(
        id: 'ev-B',
        sourceId: 'src-2',
        title: 'Heavy Rainfall Warning',
        text: 'Shimla and Solan districts face moderate precipitation with localized urban drainage blockages.',
      );

      final match = engine.compareEvidence(evA, evB);

      expect(match.matchType, equals(SyndicationMatchType.distinctContent));
      expect(match.isDuplicate, isFalse);
    });

    test('4. Short Content Safeguard (< 8 words) prevents false-positive duplicate matches on generic headlines', () {
      final evA = makeEvidence(
        id: 'ev-short-1',
        sourceId: 'src-1',
        title: 'Flash Flood Alert',
        text: 'Flash flood Kangra.',
      );

      final evB = makeEvidence(
        id: 'ev-short-2',
        sourceId: 'src-2',
        title: 'Flash Flood Alert',
        text: 'Flash flood Beas.',
      );

      final match = engine.compareEvidence(evA, evB);

      expect(match.matchType, equals(SyndicationMatchType.distinctContent));
      expect(match.isDuplicate, isFalse);
    });

    test('5. Near-duplicate match (>= 0.80 similarity) identifies minor rephrasing', () {
      final evA = makeEvidence(
        id: 'ev-A',
        sourceId: 'src-1',
        title: 'Major Landslide on NH-21',
        text: 'A major landslide triggered by continuous rain has blocked traffic movement on NH-21 highway near Mandi town in Himachal Pradesh.',
      );

      final evB = makeEvidence(
        id: 'ev-B',
        sourceId: 'src-2',
        title: 'Major Landslide on NH-21 Highway',
        text: 'A major landslide triggered by continuous rains has blocked traffic movement on NH-21 highway near Mandi town in Himachal Pradesh state.',
      );

      final match = engine.compareEvidence(evA, evB);

      expect(match.matchType, equals(SyndicationMatchType.nearDuplicateMatch));
      expect(match.contentSimilarity, greaterThanOrEqualTo(0.80));
      expect(match.isDuplicate, isTrue);
    });

    test('6. Directional syndication lineage identifies earlier publication as source', () {
      final tJan15 = DateTime.utc(2026, 1, 15, 10, 0, 0);
      final tJan16 = DateTime.utc(2026, 1, 15, 14, 0, 0);

      final evEarlier = makeEvidence(
        id: 'ev-orig',
        sourceId: 'src-primary-news',
        title: 'Bridge Damage Reported in Kullu',
        text: 'Local bridge near Kullu damaged after flash flood according to emergency services.',
        publishedAt: tJan15,
      );

      final evLater = makeEvidence(
        id: 'ev-repub',
        sourceId: 'src-secondary-aggregator',
        title: 'Bridge Damage Reported in Kullu (via Primary News)',
        text: 'Local bridge near Kullu damaged after flash flood according to emergency services. Reported by Primary News.',
        publishedAt: tJan16,
      );

      final match = engine.compareEvidence(evEarlier, evLater);

      expect(match.isSyndicated, isTrue);
      expect(match.relationships.length, equals(1));

      final rel = match.relationships.first;
      expect(rel.relationshipType, equals(RelationshipType.syndicatedFrom));
      expect(rel.sourceEntityId, equals('ev-repub')); // Later syndicated from earlier
      expect(rel.targetEntityId, equals('ev-orig'));
    });

    test('7. Evidence Preservation: Clustering groups duplicates without deleting any evidence record', () {
      final ev1 = makeEvidence(id: 'e1', sourceId: 's1', title: 'Landslide', text: 'Landslide blocked road near Mandi highway.');
      final ev2 = makeEvidence(id: 'e2', sourceId: 's2', title: 'Landslide', text: 'Landslide blocked road near Mandi highway.');
      final ev3 = makeEvidence(id: 'e3', sourceId: 's3', title: 'Landslide', text: 'Landslide blocked road near Mandi highway.');
      final ev4 = makeEvidence(id: 'e4', sourceId: 's4', title: 'Flood Alert', text: 'Heavy floods expected in Yamuna river basin.');

      final evidenceList = [ev1, ev2, ev3, ev4];
      final clusters = engine.clusterEvidence(evidenceList);

      // Total evidence count preserved = 4
      final totalClusteredMembers = clusters.fold<int>(0, (sum, c) => sum + c.memberCount);
      expect(totalClusteredMembers, equals(4));

      // Cluster 1 (Duplicates e1, e2, e3) has memberCount = 3
      final dupCluster = clusters.firstWhere((c) => c.memberEvidenceIds.contains('e1'));
      expect(dupCluster.memberCount, equals(3));
      expect(dupCluster.memberEvidenceIds, containsAll(['e1', 'e2', 'e3']));

      // Cluster 2 (Distinct e4) has memberCount = 1
      final distinctCluster = clusters.firstWhere((c) => c.memberEvidenceIds.contains('e4'));
      expect(distinctCluster.memberCount, equals(1));
    });

    test('8. Immutability: Comparing evidence records leaves original objects 100% untouched', () {
      final evA = makeEvidence(id: 'e1', sourceId: 's1', text: 'Landslide on road.');
      final evB = makeEvidence(id: 'e2', sourceId: 's2', text: 'Landslide on road.');

      final textABefore = evA.extractedText;
      engine.compareEvidence(evA, evB);

      expect(evA.extractedText, equals(textABefore));
      expect(evA.evidenceId, equals('e1'));
    });
  });
}
