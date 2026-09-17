import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/environmental_health/health_outcome_category.dart';
import 'package:riskpulse/domain/environmental_health/health_outcome_record.dart';

/// Immutable domain model container for a dataset of spatial health outcome records.
@immutable
class HealthOutcomeDataset {
  final String datasetId;
  final String datasetName;
  final HealthOutcomeCategory healthCategory;
  final List<HealthOutcomeRecord> records;
  final String spatialUnitName; // 'District', 'Block', 'Grid_Cell'
  final String sourceAgency;
  final Map<String, dynamic> metadata;

  HealthOutcomeDataset({
    required this.datasetId,
    required this.datasetName,
    required this.healthCategory,
    required this.records,
    this.spatialUnitName = 'District',
    this.sourceAgency = 'Health Research Registry',
    this.metadata = const {},
  }) {
    if (datasetId.trim().isEmpty) {
      throw ArgumentError('datasetId cannot be empty.');
    }
  }

  int get recordCount => records.length;
}
