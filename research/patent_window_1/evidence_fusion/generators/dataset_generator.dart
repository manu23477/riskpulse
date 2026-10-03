import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';

/// PATENT WINDOW 1C-1A Deterministic Dataset Generator
/// Generates PW1C1-DATA-v1.0 (Visible) and PW1C1-GT-v1.0 (Hidden Ground Truth)
void main() {
  print('============================================================');
  print('PATENT WINDOW 1C-1A DATASET GENERATOR STARTING');
  print('============================================================');

  const datasetVersion = 'PW1C1-DATA-v1.0';
  const groundTruthVersion = 'PW1C1-GT-v1.0';
  const generatorVersion = '1.0.0';
  const schemaVersion = '1.0.0';
  const randomSeed = 20260929;
  const generationTimestamp = '2026-09-29T12:00:00Z';

  final random = Random(randomSeed);

  final List<Map<String, dynamic>> visibleEvidenceObjects = [];
  final List<Map<String, dynamic>> groundTruthCases = [];
  final List<Map<String, dynamic>> evidenceTruthRecords = [];
  final List<Map<String, dynamic>> arrivalOrderControls = [];

  int globalEvidenceIdCounter = 1;

  // Case definitions: 50 Cases total
  // Hazard Distribution:
  // Landslide: 10 (Cases 1..10)
  // Flash flood: 8 (Cases 11..18)
  // Flood: 7 (Cases 19..25)
  // Cloudburst: 6 (Cases 26..31)
  // Forest fire: 6 (Cases 32..37)
  // Avalanche: 5 (Cases 38..42)
  // Earthquake: 4 (Cases 43..46)
  // Road blockage/infrastructure disruption: 4 (Cases 47..50)

  // Family Distribution:
  // A. independent_corroboration (1..6)
  // B. repost_echo_amplification (7..12)
  // C. mixed_lineage (13..18)
  // D. spatial_ambiguity (19..24)
  // E. conflicting_locations (25..29)
  // F. temporal_ambiguity (30..34)
  // G. nearby_separate_events (35..39)
  // H. sequential_late_evidence (40..45)
  // I. cross_modal_evidence (46..50)

  final caseSpecs = _getCaseSpecs();

  assert(caseSpecs.length == 50, 'Must have exactly 50 case specs');

  for (final spec in caseSpecs) {
    final caseId = spec['caseId'] as String;
    final family = spec['family'] as String;
    final difficulty = spec['difficulty'] as int;
    final hazard = spec['hazard'] as String;
    final numEvents = spec['numEvents'] as int;
    final evidenceCount = spec['evidenceCount'] as int;

    final caseEvidenceIds = <String>[];
    final eventEvidenceMap = <String, List<String>>{};
    final eventLineageMap = <String, List<String>>{};
    final eventConflictMap = <String, List<String>>{};

    final events = <Map<String, dynamic>>[];

    // Generate events for this case
    for (int e = 0; e < numEvents; e++) {
      final trueEventId = 'EVT-$caseId-${String.fromCharCode(65 + e)}';
      eventEvidenceMap[trueEventId] = [];
      eventLineageMap[trueEventId] = [];
      eventConflictMap[trueEventId] = [];

      final lat = 31.0 + (random.nextDouble() * 1.5) + (e * 0.05);
      final lng = 77.0 + (random.nextDouble() * 1.5) + (e * 0.05);

      events.add({
        'trueEventId': trueEventId,
        'hazardType': hazard,
        'geometry': {
          'type': 'Point',
          'coordinates': [double.parse(lng.toStringAsFixed(4)), double.parse(lat.toStringAsFixed(4))]
        },
        'eventStart': '2026-08-15T${(08 + e * 2).toString().padLeft(2, '0')}:00:00Z',
        'eventEnd': '2026-08-15T${(18 + e * 2).toString().padLeft(2, '0')}:00:00Z',
        'trueEventState': 'active',
        'evidenceIds': eventEvidenceMap[trueEventId]!,
        'independentLineageIds': eventLineageMap[trueEventId]!,
        'conflictingEvidenceIds': eventConflictMap[trueEventId]!
      });
    }

    // Generate evidence objects for this case
    for (int i = 0; i < evidenceCount; i++) {
      final evidenceId = 'EVID-${globalEvidenceIdCounter.toString().padLeft(4, '0')}';
      globalEvidenceIdCounter++;
      caseEvidenceIds.add(evidenceId);

      // Determine event assignment
      final targetEventIndex = (numEvents > 1 && i >= (evidenceCount / numEvents).floor())
          ? random.nextInt(numEvents)
          : 0;
      final targetEvent = events[targetEventIndex];
      final trueEventId = targetEvent['trueEventId'] as String;

      // Lineage calculation based on family
      String lineageId;
      String relationshipType;

      if (family == 'repost_echo_amplification') {
        lineageId = 'L1'; // All reposts share original lineage
        relationshipType = i == 0 ? 'primary_observation' : (i % 2 == 0 ? 'repost' : 'duplicate');
      } else if (family == 'independent_corroboration') {
        lineageId = 'L${i + 1}'; // Every report is independent lineage
        relationshipType = i == 0 ? 'primary_observation' : 'corroborating';
      } else if (family == 'mixed_lineage') {
        if (i == 0) {
          lineageId = 'L1';
          relationshipType = 'primary_observation';
        } else if (i == evidenceCount - 1) {
          lineageId = 'L_CONF';
          relationshipType = 'contradicting';
          eventConflictMap[trueEventId]!.add(evidenceId);
        } else if (i % 2 == 0) {
          lineageId = 'L1';
          relationshipType = 'repost';
        } else {
          lineageId = 'L${i + 1}';
          relationshipType = 'corroborating';
        }
      } else if (family == 'nearby_separate_events') {
        lineageId = 'L_EVT_${targetEventIndex + 1}_$i';
        relationshipType = i % 2 == 0 ? 'primary_observation' : 'corroborating';
      } else {
        lineageId = 'L${(i % 3) + 1}';
        relationshipType = i == 0 ? 'primary_observation' : (i == evidenceCount - 1 && family == 'conflicting_locations' ? 'contradicting' : 'corroborating');
        if (relationshipType == 'contradicting') {
          eventConflictMap[trueEventId]!.add(evidenceId);
        }
      }

      eventEvidenceMap[trueEventId]!.add(evidenceId);
      if (!eventLineageMap[trueEventId]!.contains(lineageId)) {
        eventLineageMap[trueEventId]!.add(lineageId);
      }

      // Media type based on cross_modal or general
      String mediaType = 'text';
      if (family == 'cross_modal_evidence') {
        final mediaTypes = ['text', 'image', 'document', 'sensor_telemetry', 'field_reporter'];
        mediaType = mediaTypes[i % mediaTypes.length];
      }

      // Source type
      final sourceTypes = [
        'social_post',
        'news_outlet',
        'official_bulletin',
        'weather_station',
        'field_reporter',
        'remote_sensor',
        'community_report'
      ];
      final sourceType = mediaType == 'sensor_telemetry'
          ? 'remote_sensor'
          : mediaType == 'document'
              ? 'official_bulletin'
              : sourceTypes[random.nextInt(sourceTypes.length)];

      final sourceId = 'SRC-${sourceType.toUpperCase().substring(0, 3)}-${(random.nextInt(899) + 100)}';
      final pubTime = DateTime.utc(2026, 8, 15, 8, i * 12).toIso8601String();
      final acqTime = DateTime.utc(2026, 8, 15, 8, (i * 12) + 2).toIso8601String();

      // Raw text generator with appropriate ambiguities
      final rawText = _generateSyntheticRawText(
        hazard: hazard,
        family: family,
        index: i,
        targetEventIndex: targetEventIndex,
        mediaType: mediaType,
      );

      final statedLoc = _generateStatedLocation(family, targetEventIndex, i);
      final statedTime = _generateStatedTime(family, i);

      // Visible evidence object - NO HIDDEN GROUND TRUTH FIELDS!
      final visibleObj = {
        'evidenceId': evidenceId,
        'caseId': caseId,
        'sourceId': sourceId,
        'sourceType': sourceType,
        'sourceLineageId': lineageId,
        'publicationTimestamp': pubTime,
        'acquisitionTimestamp': acqTime,
        'rawText': rawText,
        'mediaType': mediaType == 'field_reporter' ? 'text' : mediaType,
        'mediaReference': mediaType != 'text' ? 'ref_${caseId.toLowerCase()}_$i.dat' : '',
        'statedLocation': statedLoc,
        'statedTime': statedTime,
        'extractedHazardHint': hazard.replaceAll('_', ' '),
        'sourceReliabilityInput': double.parse((0.65 + (random.nextDouble() * 0.30)).toStringAsFixed(2)),
        'arrivalSequence': i + 1
      };

      visibleEvidenceObjects.add(visibleObj);

      // Evidence truth record
      evidenceTruthRecords.add({
        'evidenceId': evidenceId,
        'trueEventId': trueEventId,
        'trueLineageId': lineageId,
        'relationshipType': relationshipType
      });
    }

    // Ground truth case
    groundTruthCases.add({
      'caseId': caseId,
      'difficultyLevel': difficulty,
      'family': family,
      'events': events
    });

    // Arrival order controls for sequential/late evidence cases (Family H) and selected others
    if (family == 'sequential_late_evidence' || spec['caseId'] == 'CASE-01' || spec['caseId'] == 'CASE-35') {
      final permA = List<String>.from(caseEvidenceIds);
      final permB = List<String>.from(caseEvidenceIds)..shuffle(Random(randomSeed + 1));
      final permC = List<String>.from(caseEvidenceIds)..reverse();

      arrivalOrderControls.add({
        'caseId': caseId,
        'permutations': {
          'sequenceA_chronological': permA,
          'sequenceB_shuffled': permB,
          'sequenceC_reverse': permC
        }
      });
    }
  }

  // Ensure directories exist
  final visibleDir = Directory('research/patent_window_1/evidence_fusion/dataset/visible');
  final groundTruthDir = Directory('research/patent_window_1/evidence_fusion/dataset/ground_truth');
  final manifestDir = Directory('research/patent_window_1/evidence_fusion/dataset/manifest');

  visibleDir.createSync(recursive: true);
  groundTruthDir.createSync(recursive: true);
  manifestDir.createSync(recursive: true);

  final encoder = const JsonEncoder.withIndent('  ');

  // Write files
  final visibleFile = File('research/patent_window_1/evidence_fusion/dataset/visible/evidence_objects.json');
  final gtCasesFile = File('research/patent_window_1/evidence_fusion/dataset/ground_truth/ground_truth_cases.json');
  final gtEvidenceFile = File('research/patent_window_1/evidence_fusion/dataset/ground_truth/evidence_truth.json');
  final arrivalControlsFile = File('research/patent_window_1/evidence_fusion/dataset/ground_truth/arrival_order_controls.json');

  visibleFile.writeAsStringSync(encoder.convert(visibleEvidenceObjects));
  gtCasesFile.writeAsStringSync(encoder.convert(groundTruthCases));
  gtEvidenceFile.writeAsStringSync(encoder.convert(evidenceTruthRecords));
  arrivalControlsFile.writeAsStringSync(encoder.convert(arrivalOrderControls));

  // Compute Hashes
  final visibleHash = sha256.convert(visibleFile.readAsBytesSync()).toString();
  final gtCasesHash = sha256.convert(gtCasesFile.readAsBytesSync()).toString();
  final gtEvidenceHash = sha256.convert(gtEvidenceFile.readAsBytesSync()).toString();
  final arrivalControlsHash = sha256.convert(arrivalControlsFile.readAsBytesSync()).toString();

  final manifestObj = {
    'datasetVersion': datasetVersion,
    'groundTruthVersion': groundTruthVersion,
    'generatorVersion': generatorVersion,
    'schemaVersion': schemaVersion,
    'randomSeed': randomSeed,
    'caseCount': groundTruthCases.length,
    'evidenceCount': visibleEvidenceObjects.length,
    'generationTimestamp': generationTimestamp,
    'files': [
      {'path': 'visible/evidence_objects.json', 'sha256': visibleHash},
      {'path': 'ground_truth/ground_truth_cases.json', 'sha256': gtCasesHash},
      {'path': 'ground_truth/evidence_truth.json', 'sha256': gtEvidenceHash},
      {'path': 'ground_truth/arrival_order_controls.json', 'sha256': arrivalControlsHash}
    ]
  };

  final manifestFile = File('research/patent_window_1/evidence_fusion/dataset/manifest/dataset_manifest.json');
  manifestFile.writeAsStringSync(encoder.convert(manifestObj));

  print('Dataset generation completed successfully!');
  print('Total Cases: ${groundTruthCases.length}');
  print('Total Visible Evidence Objects: ${visibleEvidenceObjects.length}');
  print('Total Evidence Truth Records: ${evidenceTruthRecords.length}');
  print('Manifest Hash computed and saved.');
}

extension ReverseList<T> on List<T> {
  void reverse() {
    for (int i = 0, j = length - 1; i < j; i++, j--) {
      final temp = this[i];
      this[i] = this[j];
      this[j] = temp;
    }
  }
}

List<Map<String, dynamic>> _getCaseSpecs() {
  final specs = <Map<String, dynamic>>[];

  // 50 Cases breakdown:
  // Cases 1..6: Family A (independent_corroboration) - Landslide
  for (int i = 1; i <= 6; i++) {
    specs.add({
      'caseId': 'CASE-${i.toString().padLeft(2, '0')}',
      'family': 'independent_corroboration',
      'difficulty': (i % 3) + 1,
      'hazard': 'landslide',
      'numEvents': 1,
      'evidenceCount': 10 + (i % 4)
    });
  }

  // Cases 7..10: Family B (repost_echo_amplification) - Landslide
  for (int i = 7; i <= 10; i++) {
    specs.add({
      'caseId': 'CASE-${i.toString().padLeft(2, '0')}',
      'family': 'repost_echo_amplification',
      'difficulty': (i % 3) + 1,
      'hazard': 'landslide',
      'numEvents': 1,
      'evidenceCount': 12 + (i % 5)
    });
  }

  // Cases 11..12: Family B (repost_echo_amplification) - Flash flood
  for (int i = 11; i <= 12; i++) {
    specs.add({
      'caseId': 'CASE-${i.toString().padLeft(2, '0')}',
      'family': 'repost_echo_amplification',
      'difficulty': (i % 3) + 1,
      'hazard': 'flash_flood',
      'numEvents': 1,
      'evidenceCount': 11 + (i % 4)
    });
  }

  // Cases 13..18: Family C (mixed_lineage) - Flash flood
  for (int i = 13; i <= 18; i++) {
    specs.add({
      'caseId': 'CASE-${i.toString().padLeft(2, '0')}',
      'family': 'mixed_lineage',
      'difficulty': (i % 3) + 1,
      'hazard': 'flash_flood',
      'numEvents': 1,
      'evidenceCount': 13 + (i % 4)
    });
  }

  // Cases 19..24: Family D (spatial_ambiguity) - Flood
  for (int i = 19; i <= 24; i++) {
    specs.add({
      'caseId': 'CASE-${i.toString().padLeft(2, '0')}',
      'family': 'spatial_ambiguity',
      'difficulty': (i % 3) + 1,
      'hazard': 'flood',
      'numEvents': 1,
      'evidenceCount': 11 + (i % 5)
    });
  }

  // Case 25: Family E (conflicting_locations) - Flood
  specs.add({
    'caseId': 'CASE-25',
    'family': 'conflicting_locations',
    'difficulty': 2,
    'hazard': 'flood',
    'numEvents': 1,
    'evidenceCount': 14
  });

  // Cases 26..29: Family E (conflicting_locations) - Cloudburst
  for (int i = 26; i <= 29; i++) {
    specs.add({
      'caseId': 'CASE-${i.toString().padLeft(2, '0')}',
      'family': 'conflicting_locations',
      'difficulty': (i % 3) + 1,
      'hazard': 'cloudburst',
      'numEvents': i % 2 == 0 ? 2 : 1, // Some conflicts are 2 separate events!
      'evidenceCount': 12 + (i % 4)
    });
  }

  // Cases 30..31: Family F (temporal_ambiguity) - Cloudburst
  for (int i = 30; i <= 31; i++) {
    specs.add({
      'caseId': 'CASE-${i.toString().padLeft(2, '0')}',
      'family': 'temporal_ambiguity',
      'difficulty': (i % 3) + 1,
      'hazard': 'cloudburst',
      'numEvents': 1,
      'evidenceCount': 10 + (i % 4)
    });
  }

  // Cases 32..34: Family F (temporal_ambiguity) - Forest fire
  for (int i = 32; i <= 34; i++) {
    specs.add({
      'caseId': 'CASE-${i.toString().padLeft(2, '0')}',
      'family': 'temporal_ambiguity',
      'difficulty': (i % 3) + 1,
      'hazard': 'forest_fire',
      'numEvents': 1,
      'evidenceCount': 12 + (i % 3)
    });
  }

  // Cases 35..37: Family G (nearby_separate_events) - Forest fire
  for (int i = 35; i <= 37; i++) {
    specs.add({
      'caseId': 'CASE-${i.toString().padLeft(2, '0')}',
      'family': 'nearby_separate_events',
      'difficulty': (i % 3) + 1,
      'hazard': 'forest_fire',
      'numEvents': 2, // Mandatory negative control: 2 nearby events!
      'evidenceCount': 14 + (i % 4)
    });
  }

  // Cases 38..39: Family G (nearby_separate_events) - Avalanche
  for (int i = 38; i <= 39; i++) {
    specs.add({
      'caseId': 'CASE-${i.toString().padLeft(2, '0')}',
      'family': 'nearby_separate_events',
      'difficulty': (i % 3) + 1,
      'hazard': 'avalanche',
      'numEvents': 2, // Mandatory negative control: 2 nearby events!
      'evidenceCount': 13 + (i % 3)
    });
  }

  // Cases 40..42: Family H (sequential_late_evidence) - Avalanche
  for (int i = 40; i <= 42; i++) {
    specs.add({
      'caseId': 'CASE-${i.toString().padLeft(2, '0')}',
      'family': 'sequential_late_evidence',
      'difficulty': (i % 3) + 1,
      'hazard': 'avalanche',
      'numEvents': 1,
      'evidenceCount': 12 + (i % 4)
    });
  }

  // Cases 43..45: Family H (sequential_late_evidence) - Earthquake
  for (int i = 43; i <= 45; i++) {
    specs.add({
      'caseId': 'CASE-${i.toString().padLeft(2, '0')}',
      'family': 'sequential_late_evidence',
      'difficulty': (i % 3) + 1,
      'hazard': 'earthquake',
      'numEvents': 1,
      'evidenceCount': 14 + (i % 3)
    });
  }

  // Case 46: Family I (cross_modal_evidence) - Earthquake
  specs.add({
    'caseId': 'CASE-46',
    'family': 'cross_modal_evidence',
    'difficulty': 1,
    'hazard': 'earthquake',
    'numEvents': 1,
    'evidenceCount': 12
  });

  // Cases 47..50: Family I (cross_modal_evidence) - Road blockage/infrastructure disruption
  for (int i = 47; i <= 50; i++) {
    specs.add({
      'caseId': 'CASE-${i.toString().padLeft(2, '0')}',
      'family': 'cross_modal_evidence',
      'difficulty': (i % 3) + 1,
      'hazard': 'road_blockage_infrastructure',
      'numEvents': 1,
      'evidenceCount': 13 + (i % 4)
    });
  }

  return specs;
}

String _generateSyntheticRawText({
  required String hazard,
  required String family,
  required int index,
  required int targetEventIndex,
  required String mediaType,
}) {
  final hazardClean = hazard.replaceAll('_', ' ');

  if (family == 'repost_echo_amplification' && index > 0) {
    if (index % 2 == 0) {
      return 'RT @news_alert: Synthetic report of $hazardClean incident observed near valley section. See original thread.';
    } else {
      return '"Heavy $hazardClean reported earlier in the district." - Quoting official source.';
    }
  }

  if (family == 'spatial_ambiguity') {
    final descriptions = [
      'Reports of $hazardClean near a small settlement above the main highway.',
      'Slope instability and $hazardClean observed downstream from the bridge.',
      'Unconfirmed $hazardClean in the upper catchment valley.',
      'Debris and $hazardClean near the local bazaar intersection.'
    ];
    return descriptions[index % descriptions.length];
  }

  if (family == 'temporal_ambiguity') {
    final times = [
      'Severe $hazardClean occurred earlier today around noon.',
      'Disruption caused by $hazardClean reported late last night.',
      'Fresh $hazardClean witnessed this morning by local travelers.',
      'Ongoing $hazardClean activity observed over the past several hours.'
    ];
    return times[index % times.length];
  }

  if (family == 'nearby_separate_events') {
    return 'Event Site #${targetEventIndex + 1}: Synthetic observation of $hazardClean activity near Sector ${targetEventIndex + 1}.';
  }

  if (mediaType == 'sensor_telemetry') {
    return 'TELEMETRY_ALERT: $hazardClean threshold exceeded at station SENS-${index + 100}. Value: ${(randomValue() * 100).toStringAsFixed(1)}';
  } else if (mediaType == 'document') {
    return 'OFFICIAL BULLETIN #${index + 1}: Confirmed $hazardClean incident impacting local transport route.';
  }

  return 'Synthetic field report #${index + 1}: Active $hazardClean observed causing localized disruption.';
}

double randomValue() {
  return 0.82;
}

String _generateStatedLocation(String family, int targetEventIndex, int index) {
  if (family == 'spatial_ambiguity') {
    return 'Near settlement, Upper Valley, Sector ${index + 1}';
  }
  if (family == 'conflicting_locations') {
    return index % 2 == 0 ? 'NH-05 Km 42 near Aut' : 'State Highway 12 near Rampur Bazaar';
  }
  if (family == 'nearby_separate_events') {
    return 'Locality ${targetEventIndex == 0 ? "North Bank" : "South Ridge"} near Aut Bridge';
  }
  return 'NH-05 Sector ${index + 1}, Himachal Pradesh';
}

String _generateStatedTime(String family, int index) {
  if (family == 'temporal_ambiguity') {
    final vague = ['This morning', 'Around noon', 'Last night', 'Earlier today'];
    return vague[index % vague.length];
  }
  return '2026-08-15 08:${(index * 12).toString().padLeft(2, '0')} IST';
}
