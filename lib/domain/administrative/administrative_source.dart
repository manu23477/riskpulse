import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/administrative/administrative_level.dart';

/// Provenance and metadata specification for an authoritative Administrative Dataset Source.
///
/// Implements the RiskPulse P1.2 Administrative Source contract.
@immutable
class AdministrativeSource {
  /// RiskPulse-internal source identifier (e.g. "src-soi-hp-districts-2024").
  final String sourceId;

  /// External/original dataset name or publisher identifier (e.g. "SimplyGIS / Survey of India Derivative").
  final String sourceName;

  /// Government or authoritative issuing body (e.g. "Survey of India / LGD").
  final String authority;

  /// Human-readable dataset designation (e.g. "Himachal Pradesh Official District Boundaries").
  final String datasetName;

  /// Dataset release or revision version (e.g. "2024.1").
  final String datasetVersion;

  /// Date when this dataset artifact was acquired and ingested into RiskPulse.
  final DateTime acquisitionDate;

  /// Optional official publication or release date by the issuing authority.
  final DateTime? publicationDate;

  /// Optional source URL, portal endpoint, or distribution URI.
  final String? sourceUri;

  /// Terms of use, copyright, or distribution license (e.g. "Open Government Data License").
  final String license;

  /// Declared Spatial Coordinate Reference System (defaults to "EPSG:4326").
  final String declaredCrs;

  /// Description of spatial coverage (e.g. "Himachal Pradesh, IN").
  final String geographicCoverage;

  /// Primary administrative hierarchy level represented by this source.
  final AdministrativeLevel authoritativeLevel;

  /// SHA-256 or cryptographic integrity checksum of the raw asset.
  final String checksum;

  /// Lineage, processing, and metadata provenance dictionary.
  final Map<String, dynamic> provenance;

  AdministrativeSource({
    required this.sourceId,
    required this.sourceName,
    required this.authority,
    required this.datasetName,
    required this.datasetVersion,
    DateTime? acquisitionDate,
    this.publicationDate,
    this.sourceUri,
    required this.license,
    this.declaredCrs = 'EPSG:4326',
    required this.geographicCoverage,
    required this.authoritativeLevel,
    required this.checksum,
    Map<String, dynamic>? provenance,
  })  : acquisitionDate = acquisitionDate ?? DateTime.now().toUtc(),
        provenance = Map<String, dynamic>.unmodifiable(provenance ?? const {}) {
    if (sourceId.trim().isEmpty) {
      throw ArgumentError('AdministrativeSource.sourceId cannot be empty.');
    }
    if (sourceName.trim().isEmpty) {
      throw ArgumentError('AdministrativeSource.sourceName cannot be empty.');
    }
    if (authority.trim().isEmpty) {
      throw ArgumentError('AdministrativeSource.authority cannot be empty.');
    }
    if (datasetName.trim().isEmpty) {
      throw ArgumentError('AdministrativeSource.datasetName cannot be empty.');
    }
    if (datasetVersion.trim().isEmpty) {
      throw ArgumentError('AdministrativeSource.datasetVersion cannot be empty.');
    }
  }

  /// Creates a copy of this [AdministrativeSource] with updated fields.
  AdministrativeSource copyWith({
    String? sourceId,
    String? sourceName,
    String? authority,
    String? datasetName,
    String? datasetVersion,
    DateTime? acquisitionDate,
    DateTime? publicationDate,
    String? sourceUri,
    String? license,
    String? declaredCrs,
    String? geographicCoverage,
    AdministrativeLevel? authoritativeLevel,
    String? checksum,
    Map<String, dynamic>? provenance,
  }) {
    return AdministrativeSource(
      sourceId: sourceId ?? this.sourceId,
      sourceName: sourceName ?? this.sourceName,
      authority: authority ?? this.authority,
      datasetName: datasetName ?? this.datasetName,
      datasetVersion: datasetVersion ?? this.datasetVersion,
      acquisitionDate: acquisitionDate ?? this.acquisitionDate,
      publicationDate: publicationDate ?? this.publicationDate,
      sourceUri: sourceUri ?? this.sourceUri,
      license: license ?? this.license,
      declaredCrs: declaredCrs ?? this.declaredCrs,
      geographicCoverage: geographicCoverage ?? this.geographicCoverage,
      authoritativeLevel: authoritativeLevel ?? this.authoritativeLevel,
      checksum: checksum ?? this.checksum,
      provenance: provenance ?? this.provenance,
    );
  }

  /// Serializes this [AdministrativeSource] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'sourceId': sourceId,
      'sourceName': sourceName,
      'authority': authority,
      'datasetName': datasetName,
      'datasetVersion': datasetVersion,
      'acquisitionDate': acquisitionDate.toIso8601String(),
      'publicationDate': publicationDate?.toIso8601String(),
      'sourceUri': sourceUri,
      'license': license,
      'declaredCrs': declaredCrs,
      'geographicCoverage': geographicCoverage,
      'authoritativeLevel': authoritativeLevel.code,
      'checksum': checksum,
      'provenance': provenance,
    };
  }

  /// Deserializes an [AdministrativeSource] from a JSON map.
  factory AdministrativeSource.fromJson(Map<String, dynamic> json) {
    return AdministrativeSource(
      sourceId: json['sourceId'] as String,
      sourceName: json['sourceName'] as String,
      authority: json['authority'] as String,
      datasetName: json['datasetName'] as String,
      datasetVersion: json['datasetVersion'] as String,
      acquisitionDate: json['acquisitionDate'] != null
          ? DateTime.parse(json['acquisitionDate'] as String)
          : null,
      publicationDate: json['publicationDate'] != null
          ? DateTime.parse(json['publicationDate'] as String)
          : null,
      sourceUri: json['sourceUri'] as String?,
      license: json['license'] as String? ?? 'Open Government Data / Public',
      declaredCrs: json['declaredCrs'] as String? ?? 'EPSG:4326',
      geographicCoverage: json['geographicCoverage'] as String? ?? 'Himachal Pradesh, IN',
      authoritativeLevel: AdministrativeLevel.fromCode(json['authoritativeLevel'] as String),
      checksum: json['checksum'] as String? ?? '',
      provenance: json['provenance'] as Map<String, dynamic>?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdministrativeSource &&
          runtimeType == other.runtimeType &&
          sourceId == other.sourceId &&
          datasetVersion == other.datasetVersion &&
          checksum == other.checksum;

  @override
  int get hashCode => Object.hash(sourceId, datasetVersion, checksum);

  @override
  String toString() {
    return 'AdministrativeSource(id: $sourceId, name: $datasetName v$datasetVersion, authority: $authority)';
  }
}
