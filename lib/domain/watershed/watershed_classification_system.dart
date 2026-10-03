import 'package:flutter/foundation.dart';

/// Immutable domain entity representing an official or analytical Watershed Classification System.
///
/// Supports multi-system coexistence (e.g. SLUSI 2012 vs India-WRIS CWC 2019) without code merging.
@immutable
class WatershedClassificationSystem {
  /// Unique classification system ID (e.g. "slusi_2012" or "india_wris_2019").
  final String id;

  /// Official publishing agency / system name (e.g. "SLUSI Watershed Atlas of India").
  final String name;

  /// Publishing institution or agency (e.g. "Soil & Land Use Survey of India").
  final String publisher;

  /// Dataset / scheme release version (e.g. "2012.1").
  final String version;

  /// Effective date of this classification release.
  final DateTime effectiveDate;

  /// Ordered list of hierarchy level names (e.g. ["Region", "Basin", "Catchment", "Sub-Catchment", "Watershed", "Micro-Watershed"]).
  final List<String> hierarchyLevels;

  /// Regular expression pattern for code validation (e.g. "^[1-6][A-Z][0-9]{1,2}[A-Z][0-9]{1,2}[a-z]$").
  final String codeGrammarPattern;

  /// Licensing and redistribution terms (e.g. "OGDL India").
  final String license;

  /// Metadata lineage and documentation references.
  final Map<String, dynamic> provenance;

  WatershedClassificationSystem({
    required this.id,
    required this.name,
    required this.publisher,
    required this.version,
    required this.effectiveDate,
    required List<String> hierarchyLevels,
    required this.codeGrammarPattern,
    this.license = 'Open Government Data License (OGDL India)',
    Map<String, dynamic>? provenance,
  })  : hierarchyLevels = List<String>.unmodifiable(hierarchyLevels),
        provenance = Map<String, dynamic>.unmodifiable(provenance ?? const {}) {
    if (id.trim().isEmpty) {
      throw ArgumentError('WatershedClassificationSystem.id cannot be empty.');
    }
    if (name.trim().isEmpty) {
      throw ArgumentError('WatershedClassificationSystem.name cannot be empty.');
    }
    if (version.trim().isEmpty) {
      throw ArgumentError('WatershedClassificationSystem.version cannot be empty.');
    }
    if (hierarchyLevels.isEmpty) {
      throw ArgumentError('WatershedClassificationSystem.hierarchyLevels cannot be empty.');
    }
  }

  /// Converts this [WatershedClassificationSystem] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'publisher': publisher,
      'version': version,
      'effectiveDate': effectiveDate.toIso8601String(),
      'hierarchyLevels': hierarchyLevels,
      'codeGrammarPattern': codeGrammarPattern,
      'license': license,
      'provenance': provenance,
    };
  }

  /// Factory constructor to parse a [WatershedClassificationSystem] from JSON.
  factory WatershedClassificationSystem.fromJson(Map<String, dynamic> json) {
    return WatershedClassificationSystem(
      id: json['id'] as String,
      name: json['name'] as String,
      publisher: json['publisher'] as String,
      version: json['version'] as String,
      effectiveDate: DateTime.parse(json['effectiveDate'] as String),
      hierarchyLevels: (json['hierarchyLevels'] as List).cast<String>(),
      codeGrammarPattern: json['codeGrammarPattern'] as String,
      license: (json['license'] as String?) ?? 'Open Government Data License (OGDL India)',
      provenance: json['provenance'] as Map<String, dynamic>?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WatershedClassificationSystem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          version == other.version;

  @override
  int get hashCode => Object.hash(id, version);

  @override
  String toString() {
    return 'WatershedClassificationSystem(id: $id, name: $name, version: $version)';
  }
}
