import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/gis/data_source_record.dart';
import 'package:riskpulse/domain/forecasting/exposure_element.dart';

/// Immutable domain metadata record describing an exposure dataset.
@immutable
class ExposureDatasetRecord {
  static const int currentSchemaVersion = 1;

  final String datasetId;
  final String datasetName;
  final ExposureCategory category;
  final String geographicCoverage;
  final int referenceYear;
  final String spatialResolution;
  final int totalElementCount;
  final DataSourceRecord? dataSource;
  final String limitations;
  final int schemaVersion;

  ExposureDatasetRecord({
    required this.datasetId,
    required this.datasetName,
    required this.category,
    required this.geographicCoverage,
    required this.referenceYear,
    this.spatialResolution = 'unspecified',
    this.totalElementCount = 0,
    this.dataSource,
    this.limitations = '',
    this.schemaVersion = currentSchemaVersion,
  }) {
    if (datasetId.trim().isEmpty) {
      throw ArgumentError('datasetId cannot be empty.');
    }
    if (datasetName.trim().isEmpty) {
      throw ArgumentError('datasetName cannot be empty.');
    }
    if (totalElementCount < 0) {
      throw ArgumentError('totalElementCount cannot be negative.');
    }
    if (schemaVersion <= 0) {
      throw ArgumentError('schemaVersion must be positive.');
    }
  }

  ExposureDatasetRecord copyWith({
    String? datasetId,
    String? datasetName,
    ExposureCategory? category,
    String? geographicCoverage,
    int? referenceYear,
    String? spatialResolution,
    int? totalElementCount,
    DataSourceRecord? dataSource,
    bool clearDataSource = false,
    String? limitations,
    int? schemaVersion,
  }) {
    return ExposureDatasetRecord(
      datasetId: datasetId ?? this.datasetId,
      datasetName: datasetName ?? this.datasetName,
      category: category ?? this.category,
      geographicCoverage: geographicCoverage ?? this.geographicCoverage,
      referenceYear: referenceYear ?? this.referenceYear,
      spatialResolution: spatialResolution ?? this.spatialResolution,
      totalElementCount: totalElementCount ?? this.totalElementCount,
      dataSource: clearDataSource ? null : (dataSource ?? this.dataSource),
      limitations: limitations ?? this.limitations,
      schemaVersion: schemaVersion ?? this.schemaVersion,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'datasetId': datasetId,
      'datasetName': datasetName,
      'category': category.name,
      'geographicCoverage': geographicCoverage,
      'referenceYear': referenceYear,
      'spatialResolution': spatialResolution,
      'totalElementCount': totalElementCount,
      'limitations': limitations,
      'schemaVersion': schemaVersion,
    };
  }

  factory ExposureDatasetRecord.fromMap(Map<String, dynamic> map) {
    final catName = map['category'] as String? ?? 'other';
    final cat = ExposureCategory.values.firstWhere(
      (e) => e.name == catName,
      orElse: () => ExposureCategory.other,
    );

    return ExposureDatasetRecord(
      datasetId: map['datasetId'] as String? ?? '',
      datasetName: map['datasetName'] as String? ?? '',
      category: cat,
      geographicCoverage: map['geographicCoverage'] as String? ?? '',
      referenceYear: map['referenceYear'] as int? ?? 2026,
      spatialResolution: map['spatialResolution'] as String? ?? 'unspecified',
      totalElementCount: map['totalElementCount'] as int? ?? 0,
      limitations: map['limitations'] as String? ?? '',
      schemaVersion: map['schemaVersion'] as int? ?? currentSchemaVersion,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExposureDatasetRecord &&
          runtimeType == other.runtimeType &&
          datasetId == other.datasetId &&
          datasetName == other.datasetName &&
          category == other.category &&
          geographicCoverage == other.geographicCoverage &&
          referenceYear == other.referenceYear &&
          spatialResolution == other.spatialResolution &&
          totalElementCount == other.totalElementCount &&
          schemaVersion == other.schemaVersion;

  @override
  int get hashCode => Object.hash(
        datasetId,
        datasetName,
        category,
        geographicCoverage,
        referenceYear,
        spatialResolution,
        totalElementCount,
        schemaVersion,
      );
}
