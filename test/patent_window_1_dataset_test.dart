import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PATENT WINDOW 1C-1A — Synthetic Evidence Dataset & Ground Truth Validation Suite', () {
    late List<dynamic> visibleEvidence;
    late List<dynamic> groundTruthCases;
    late List<dynamic> evidenceTruth;
    late List<dynamic> arrivalControls;
    late Map<String, dynamic> manifest;

    setUpAll(() {
      final visibleFile = File('research/patent_window_1/evidence_fusion/dataset/visible/evidence_objects.json');
      final gtCasesFile = File('research/patent_window_1/evidence_fusion/dataset/ground_truth/ground_truth_cases.json');
      final gtEvidenceFile = File('research/patent_window_1/evidence_fusion/dataset/ground_truth/evidence_truth.json');
      final arrivalControlsFile = File('research/patent_window_1/evidence_fusion/dataset/ground_truth/arrival_order_controls.json');
      final manifestFile = File('research/patent_window_1/evidence_fusion/dataset/manifest/dataset_manifest.json');

      expect(visibleFile.existsSync(), isTrue, reason: 'Visible evidence objects file must exist');
      expect(gtCasesFile.existsSync(), isTrue, reason: 'Ground truth cases file must exist');
      expect(gtEvidenceFile.existsSync(), isTrue, reason: 'Evidence truth file must exist');
      expect(arrivalControlsFile.existsSync(), isTrue, reason: 'Arrival order controls file must exist');
      expect(manifestFile.existsSync(), isTrue, reason: 'Dataset manifest file must exist');

      visibleEvidence = jsonDecode(visibleFile.readAsStringSync()) as List<dynamic>;
      groundTruthCases = jsonDecode(gtCasesFile.readAsStringSync()) as List<dynamic>;
      evidenceTruth = jsonDecode(gtEvidenceFile.readAsStringSync()) as List<dynamic>;
      arrivalControls = jsonDecode(arrivalControlsFile.readAsStringSync()) as List<dynamic>;
      manifest = jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
    });

    test('Check 1: Exactly 50 cases exist', () {
      expect(groundTruthCases.length, equals(50));
    });

    test('Check 2: Exactly correct hazard distribution (50 total cases)', () {
      final hazardCounts = <String, int>{};
      for (final c in groundTruthCases) {
        final events = c['events'] as List<dynamic>;
        final hazard = events.first['hazardType'] as String;
        hazardCounts[hazard] = (hazardCounts[hazard] ?? 0) + 1;
      }

      expect(hazardCounts['landslide'], equals(10));
      expect(hazardCounts['flash_flood'], equals(8));
      expect(hazardCounts['flood'], equals(7));
      expect(hazardCounts['cloudburst'], equals(6));
      expect(hazardCounts['forest_fire'], equals(6));
      expect(hazardCounts['avalanche'], equals(5));
      expect(hazardCounts['earthquake'], equals(4));
      expect(hazardCounts['road_blockage_infrastructure'], equals(4));
    });

    test('Check 3: Correct family distribution', () {
      final familyCounts = <String, int>{};
      for (final c in groundTruthCases) {
        final family = c['family'] as String;
        familyCounts[family] = (familyCounts[family] ?? 0) + 1;
      }

      expect(familyCounts['independent_corroboration'], equals(6));
      expect(familyCounts['repost_echo_amplification'], equals(6));
      expect(familyCounts['mixed_lineage'], equals(6));
      expect(familyCounts['spatial_ambiguity'], equals(6));
      expect(familyCounts['conflicting_locations'], equals(5));
      expect(familyCounts['temporal_ambiguity'], equals(5));
      expect(familyCounts['nearby_separate_events'], equals(5));
      expect(familyCounts['sequential_late_evidence'], equals(6));
      expect(familyCounts['cross_modal_evidence'], equals(5));
    });

    test('Check 4: Every case has a valid difficulty level (1, 2, 3)', () {
      for (final c in groundTruthCases) {
        final diff = c['difficultyLevel'] as int;
        expect(diff, isIn([1, 2, 3]));
      }
    });

    test('Check 5 & 13: Every evidenceId is unique', () {
      final ids = <String>{};
      for (final e in visibleEvidence) {
        final id = e['evidenceId'] as String;
        expect(ids.contains(id), isFalse, reason: 'Duplicate evidenceId found: $id');
        ids.add(id);
      }
      expect(ids.length, equals(visibleEvidence.length));
    });

    test('Check 6: Every caseId is unique', () {
      final caseIds = <String>{};
      for (final c in groundTruthCases) {
        final id = c['caseId'] as String;
        expect(caseIds.contains(id), isFalse, reason: 'Duplicate caseId found: $id');
        caseIds.add(id);
      }
      expect(caseIds.length, equals(50));
    });

    test('Check 7: Every evidence record belongs to a valid case', () {
      final validCaseIds = groundTruthCases.map((c) => c['caseId'] as String).toSet();
      for (final e in visibleEvidence) {
        final caseId = e['caseId'] as String;
        expect(validCaseIds.contains(caseId), isTrue, reason: 'Evidence belongs to invalid caseId: $caseId');
      }
    });

    test('Check 8 & 9 & 14 & 15: Every visible evidence record maps to hidden truth (No Orphans)', () {
      final visibleIds = visibleEvidence.map((e) => e['evidenceId'] as String).toSet();
      final truthIds = evidenceTruth.map((t) => t['evidenceId'] as String).toSet();

      expect(visibleIds, equals(truthIds), reason: 'Visible evidence and hidden evidence truth sets must match exactly');
    });

    test('Check 10: Every true event references valid evidence', () {
      final visibleIds = visibleEvidence.map((e) => e['evidenceId'] as String).toSet();
      for (final c in groundTruthCases) {
        final events = c['events'] as List<dynamic>;
        for (final evt in events) {
          final evIds = (evt['evidenceIds'] as List<dynamic>).cast<String>();
          expect(evIds.isNotEmpty, isTrue, reason: 'True event must reference at least one evidenceId');
          for (final id in evIds) {
            expect(visibleIds.contains(id), isTrue, reason: 'True event references invalid evidenceId: $id');
          }
        }
      }
    });

    test('Check 11: Every lineage reference is valid', () {
      for (final t in evidenceTruth) {
        final lineage = t['trueLineageId'] as String;
        expect(lineage.isNotEmpty, isTrue, reason: 'True lineage ID must not be empty');
      }
    });

    test('Check 12: FORENSIC LEAKAGE SCAN — Zero ground truth fields in visible evidence', () {
      final forbiddenKeys = [
        'trueEventId',
        'trueCoordinates',
        'trueHazard',
        'trueLineage',
        'trueRelationship',
        'trueEventTime',
        'trueEventState',
        'true_event_id',
        'true_coordinates',
        'true_hazard',
        'geometry',
        'events'
      ];

      for (final e in visibleEvidence) {
        final record = e as Map<String, dynamic>;
        for (final forbidden in forbiddenKeys) {
          expect(record.containsKey(forbidden), isFalse, reason: 'FORBIDDEN LEAKAGE: Visible record ${record['evidenceId']} contains $forbidden');
        }
      }
    });

    test('Check 16: Every case contains at least one true event', () {
      for (final c in groundTruthCases) {
        final events = c['events'] as List<dynamic>;
        expect(events.isNotEmpty, isTrue, reason: 'Case ${c['caseId']} must contain at least 1 true event');
      }
    });

    test('Check 17 & 19: Nearby-separate-event controls exist (Family G)', () {
      final familyGCases = groundTruthCases.where((c) => c['family'] == 'nearby_separate_events').toList();
      expect(familyGCases.length, equals(5));

      for (final c in familyGCases) {
        final events = c['events'] as List<dynamic>;
        expect(events.length, greaterThanOrEqualTo(2), reason: 'Nearby-separate-event cases must contain >=2 distinct events');
      }
    });

    test('Check 18: Positive controls exist (Family A)', () {
      final familyACases = groundTruthCases.where((c) => c['family'] == 'independent_corroboration').toList();
      expect(familyACases.length, equals(6));
    });

    test('Check 20: Arrival-order controls exist', () {
      expect(arrivalControls.isNotEmpty, isTrue);
      for (final ctrl in arrivalControls) {
        final perms = ctrl['permutations'] as Map<String, dynamic>;
        expect(perms.containsKey('sequenceA_chronological'), isTrue);
        expect(perms.containsKey('sequenceB_shuffled'), isTrue);
        expect(perms.containsKey('sequenceC_reverse'), isTrue);
      }
    });

    test('Check 21: Repost lineage exists (Family B)', () {
      final repostTruths = evidenceTruth.where((t) => t['relationshipType'] == 'repost').toList();
      expect(repostTruths.isNotEmpty, isTrue, reason: 'Repost lineage relationship must exist');
    });

    test('Check 22: Independent lineage exists (Family A)', () {
      final familyACaseIds = groundTruthCases.where((c) => c['family'] == 'independent_corroboration').map((c) => c['caseId'] as String).toSet();
      final familyAEvidence = visibleEvidence.where((e) => familyACaseIds.contains(e['caseId'] as String)).toList();

      final lineages = familyAEvidence.map((e) => e['sourceLineageId'] as String).toSet();
      expect(lineages.length, greaterThan(10), reason: 'Independent corroboration cases must have multiple distinct lineages');
    });

    test('Check 23: Contradictory evidence exists', () {
      final contradictingTruths = evidenceTruth.where((t) => t['relationshipType'] == 'contradicting').toList();
      expect(contradictingTruths.isNotEmpty, isTrue, reason: 'Contradicting evidence relationships must exist');
    });

    test('Check 24: Spatial ambiguity exists (Family D)', () {
      final familyDCases = groundTruthCases.where((c) => c['family'] == 'spatial_ambiguity').toList();
      expect(familyDCases.length, equals(6));
    });

    test('Check 25: Temporal ambiguity exists (Family F)', () {
      final familyFCases = groundTruthCases.where((c) => c['family'] == 'temporal_ambiguity').toList();
      expect(familyFCases.length, equals(5));
    });

    test('Check 26: Cross-modal evidence exists (Family I)', () {
      final familyICases = groundTruthCases.where((c) => c['family'] == 'cross_modal_evidence').toList();
      expect(familyICases.length, equals(5));

      final familyICaseIds = familyICases.map((c) => c['caseId'] as String).toSet();
      final familyIEvidence = visibleEvidence.where((e) => familyICaseIds.contains(e['caseId'] as String)).toList();
      final mediaTypes = familyIEvidence.map((e) => e['mediaType'] as String).toSet();

      expect(mediaTypes.contains('text'), isTrue);
      expect(mediaTypes.contains('image'), isTrue);
      expect(mediaTypes.contains('document'), isTrue);
      expect(mediaTypes.contains('sensor_telemetry'), isTrue);
    });

    test('Manifest verification', () {
      expect(manifest['datasetVersion'], equals('PW1C1-DATA-v1.0'));
      expect(manifest['groundTruthVersion'], equals('PW1C1-GT-v1.0'));
      expect(manifest['caseCount'], equals(50));
      expect(manifest['evidenceCount'], equals(visibleEvidence.length));
    });
  });
}
