import 'package:flutter/foundation.dart';

/// Immutable domain model representing a scientific research analysis result produced in Research GIS.
///
/// Preserves processing parameters, input datasets, methodology, output layer, and provenance.
@immutable
class ResearchAnalysisResult {
  static const int currentSchemaVersion = 1;

  final String resultId;
  final String originatingSessionId;
  final String? riskObjectId;
  final String analysisType; // 'NDVI_CHANGE_DETECTION', 'SAR_FLOOD_MAPPING', 'TERRAIN_SLOPE'

  final List<String> inputLayerIds;
  final Map<String, dynamic> parameters;
  final Map<String, dynamic>? spatialExtent;
  final Map<String, dynamic>? outputGeoJson;
  final String crs;

  final String methodology;
  final String modelName;
  final String modelVersion;
  final DateTime processedAt;
  final Map<String, dynamic> provenance;
  final String? uncertainty;
  final List<String> limitations;

  ResearchAnalysisResult({
    required this.resultId,
    required this.originatingSessionId,
    this.riskObjectId,
    required this.analysisType,
    List<String>? inputLayerIds,
    Map<String, dynamic>? parameters,
    this.spatialExtent,
    this.outputGeoJson,
    this.crs = 'EPSG:4326',
    required this.methodology,
    this.modelName = 'RISKPULSE_GIS_RS_ENGINE',
    this.modelVersion = '2.0.0',
    DateTime? processedAt,
    Map<String, dynamic>? provenance,
    this.uncertainty,
    List<String>? limitations,
  })  : inputLayerIds = List<String>.unmodifiable(inputLayerIds ?? const []),
        parameters = Map<String, dynamic>.unmodifiable(parameters ?? const {}),
        processedAt = processedAt ?? DateTime.now().toUtc(),
        provenance = Map<String, dynamic>.unmodifiable(provenance ?? const {}),
        limitations = List<String>.unmodifiable(limitations ?? const []) {
    if (resultId.trim().isEmpty) {
      throw ArgumentError('ResearchAnalysisResult.resultId cannot be empty.');
    }
    if (originatingSessionId.trim().isEmpty) {
      throw ArgumentError('ResearchAnalysisResult.originatingSessionId cannot be empty.');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'resultId': resultId,
      'originatingSessionId': originatingSessionId,
      'riskObjectId': riskObjectId,
      'analysisType': analysisType,
      'inputLayerIds': inputLayerIds,
      'parameters': parameters,
      'spatialExtent': spatialExtent,
      'outputGeoJson': outputGeoJson,
      'crs': crs,
      'methodology': methodology,
      'modelName': modelName,
      'modelVersion': modelVersion,
      'processedAt': processedAt.toIso8601String(),
      'provenance': provenance,
      'uncertainty': uncertainty,
      'limitations': limitations,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResearchAnalysisResult &&
          runtimeType == other.runtimeType &&
          resultId == other.resultId;

  @override
  int get hashCode => resultId.hashCode;
}
