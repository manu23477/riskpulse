import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';

/// Representation of a visible OSINT evidence object.
/// Strictly excludes all hidden ground truth fields.
class VisibleEvidenceObject {
  final String evidenceId;
  final String caseId;
  final String sourceId;
  final String sourceType;
  final String sourceLineageId;
  final String publicationTimestamp;
  final String acquisitionTimestamp;
  final String rawText;
  final String mediaType;
  final String mediaReference;
  final String statedLocation;
  final String statedTime;
  final String extractedHazardHint;
  final double sourceReliabilityInput;
  final int arrivalSequence;

  const VisibleEvidenceObject({
    required this.evidenceId,
    required this.caseId,
    required this.sourceId,
    required this.sourceType,
    required this.sourceLineageId,
    required this.publicationTimestamp,
    required this.acquisitionTimestamp,
    required this.rawText,
    required this.mediaType,
    required this.mediaReference,
    required this.statedLocation,
    required this.statedTime,
    required this.extractedHazardHint,
    required this.sourceReliabilityInput,
    required this.arrivalSequence,
  });

  Map<String, dynamic> toJson() => {
        'evidenceId': evidenceId,
        'caseId': caseId,
        'sourceId': sourceId,
        'sourceType': sourceType,
        'sourceLineageId': sourceLineageId,
        'publicationTimestamp': publicationTimestamp,
        'acquisitionTimestamp': acquisitionTimestamp,
        'rawText': rawText,
        'mediaType': mediaType,
        'mediaReference': mediaReference,
        'statedLocation': statedLocation,
        'statedTime': statedTime,
        'extractedHazardHint': extractedHazardHint,
        'sourceReliabilityInput': sourceReliabilityInput,
        'arrivalSequence': arrivalSequence,
      };

  factory VisibleEvidenceObject.fromJson(Map<String, dynamic> json) {
    return VisibleEvidenceObject(
      evidenceId: json['evidenceId'] as String,
      caseId: json['caseId'] as String,
      sourceId: json['sourceId'] as String,
      sourceType: json['sourceType'] as String,
      sourceLineageId: json['sourceLineageId'] as String,
      publicationTimestamp: json['publicationTimestamp'] as String,
      acquisitionTimestamp: json['acquisitionTimestamp'] as String,
      rawText: json['rawText'] as String,
      mediaType: json['mediaType'] as String,
      mediaReference: json['mediaReference'] as String,
      statedLocation: json['statedLocation'] as String,
      statedTime: json['statedTime'] as String,
      extractedHazardHint: json['extractedHazardHint'] as String,
      sourceReliabilityInput: (json['sourceReliabilityInput'] as num).toDouble(),
      arrivalSequence: json['arrivalSequence'] as int,
    );
  }
}

/// Loader for PW1C1-DATA-v1.0 visible evidence dataset.
/// STRICTLY ISOLATED: Cannot access dataset/ground_truth/ files under any circumstances.
class VisibleDatasetLoader {
  final String visiblePath;
  final String manifestPath;

  VisibleDatasetLoader({
    this.visiblePath = 'research/patent_window_1/evidence_fusion/dataset/visible/evidence_objects.json',
    this.manifestPath = 'research/patent_window_1/evidence_fusion/dataset/manifest/dataset_manifest.json',
  });

  /// Loads and validates the visible dataset against expected version and SHA-256 manifest.
  /// Throws StateError if dataset version or hash is invalid (enforcing dataset immutability).
  List<VisibleEvidenceObject> loadAndValidateVisibleDataset() {
    final manifestFile = File(manifestPath);
    if (!manifestFile.existsSync()) {
      throw StateError('Dataset Manifest File Not Found: $manifestPath');
    }

    final manifest = jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
    final expectedVersion = manifest['datasetVersion'] as String;
    if (expectedVersion != 'PW1C1-DATA-v1.0') {
      throw StateError('Dataset Version Mismatch: Expected PW1C1-DATA-v1.0, found $expectedVersion');
    }

    final visibleFile = File(visiblePath);
    if (!visibleFile.existsSync()) {
      throw StateError('Visible Evidence File Not Found: $visiblePath');
    }

    final bytes = visibleFile.readAsBytesSync();
    final computedHash = sha256.convert(bytes).toString();

    final filesList = (manifest['files'] as List<dynamic>).cast<Map<String, dynamic>>();
    final visibleManifestEntry = filesList.firstWhere(
      (f) => (f['path'] as String).contains('evidence_objects.json'),
      orElse: () => throw StateError('Manifest missing entry for visible/evidence_objects.json'),
    );

    final expectedHash = visibleManifestEntry['sha256'] as String;
    if (computedHash != expectedHash) {
      throw StateError('DATASET IMMUTABILITY VIOLATION: visible/evidence_objects.json SHA-256 hash mismatch!\nExpected: $expectedHash\nActual: $computedHash');
    }

    final rawList = jsonDecode(utf8.decode(bytes)) as List<dynamic>;
    return rawList.map((item) => VisibleEvidenceObject.fromJson(item as Map<String, dynamic>)).toList();
  }
}
