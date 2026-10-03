import 'package:riskpulse/data/services/administrative/administrative_join_engine.dart';
import 'package:riskpulse/data/services/administrative/thematic_classification_engine.dart';
import 'package:riskpulse/domain/administrative/administrative_unit.dart';
import 'package:riskpulse/domain/administrative/thematic_dataset.dart';
import 'package:riskpulse/domain/gis/classification_scheme.dart';
import 'package:riskpulse/domain/gis/color_ramp.dart';
import 'package:riskpulse/domain/gis/data_source_type.dart';
import 'package:riskpulse/domain/gis/gis_layer.dart';
import 'package:riskpulse/domain/gis/gis_style.dart';

/// Immutable result container holding choropleth classification & color mapping per administrative unit.
class ThematicChoroplethResult {
  final ThematicDataset dataset;
  final AdministrativeJoinResult joinResult;
  final ClassificationScheme classificationScheme;

  /// Deterministic mapping of administrativeUnit.internalId -> Hex Color string ("#RRGGBB").
  final Map<String, String> choroplethColorMap;

  /// Default No Data neutral grey color hex code.
  static const String noDataColorHex = '#E2E8F0';

  const ThematicChoroplethResult({
    required this.dataset,
    required this.joinResult,
    required this.classificationScheme,
    required this.choroplethColorMap,
  });

  int get totalMatchedUnits => joinResult.totalMatchedUnits;
  int get totalMissingUnits => joinResult.totalMissingUnits;
  int get totalUnmatchedInput => joinResult.totalUnmatchedInput;
}

/// Orchestration service that joins [ThematicDataset] observations with [AdministrativeUnit]s,
/// classifies valid numeric observations using [ThematicClassificationEngine], and generates
/// a dedicated thematic choropleth [GisLayer] and color mapping.
class AdministrativeThematicService {
  final AdministrativeJoinEngine joinEngine;
  final ThematicClassificationEngine classificationEngine;

  const AdministrativeThematicService({
    this.joinEngine = const AdministrativeJoinEngine(),
    this.classificationEngine = const ThematicClassificationEngine(),
  });

  /// Processes a [ThematicDataset], joins it to [targetUnits], computes class breaks,
  /// and returns a [ThematicChoroplethResult] with a dedicated thematic [GisLayer].
  ThematicChoroplethResult processThematicChoropleth({
    required ThematicDataset dataset,
    required List<AdministrativeUnit> targetUnits,
    required ClassificationMethod classificationMethod,
    int requestedClassCount = 5,
    ColorRamp? colorRamp,
    List<ClassBreak>? manualBreaks,
  }) {
    // 1. Join Dataset to Target Administrative Units
    final joinResult = joinEngine.joinDataset(dataset: dataset, targetUnits: targetUnits);

    // 2. Extract Valid Numeric Values for Classification
    final List<double> validValues = [];
    for (final record in joinResult.joinedRecords) {
      if (record.isMatched && record.observation != null && record.observation!.isValidNumeric) {
        validValues.add(record.observation!.numericValue);
      }
    }

    // 3. Compute Classification Scheme
    final classificationScheme = classificationEngine.classifyDataset(
      numericValues: validValues,
      method: classificationMethod,
      requestedClassCount: requestedClassCount,
      colorRamp: colorRamp,
      manualBreaks: manualBreaks,
    );

    // 4. Map Each Administrative Unit to ClassBreak Color or No Data
    final Map<String, String> colorMap = {};

    for (final record in joinResult.joinedRecords) {
      final unit = record.unit;

      if (record.isMatched && record.observation != null && record.observation!.isValidNumeric) {
        final double val = record.observation!.numericValue;
        String? matchedColor;

        for (int i = 0; i < classificationScheme.breaks.length; i++) {
          final b = classificationScheme.breaks[i];
          final isLast = i == classificationScheme.breaks.length - 1;

          if (b.contains(val, isLast: isLast)) {
            matchedColor = b.colorHex;
            break;
          }
        }

        colorMap[unit.internalId] = matchedColor ?? ThematicChoroplethResult.noDataColorHex;
      } else {
        // Missing, Duplicate, Invalid, or Unmatched -> No Data Neutral Grey
        colorMap[unit.internalId] = ThematicChoroplethResult.noDataColorHex;
      }
    }

    return ThematicChoroplethResult(
      dataset: dataset,
      joinResult: joinResult,
      classificationScheme: classificationScheme,
      choroplethColorMap: Map.unmodifiable(colorMap),
    );
  }

  /// Creates a dedicated, independently toggleable thematic [GisLayer] from a [ThematicChoroplethResult].
  GisLayer createThematicLayer(ThematicChoroplethResult choroplethResult) {
    final dataset = choroplethResult.dataset;
    final layerId = 'thematic-choropleth-${dataset.id}-${DateTime.now().millisecondsSinceEpoch}';
    final layerName = '${dataset.attributeName} (${dataset.unit})';

    return GisLayer(
      id: layerId,
      name: layerName,
      type: GisLayerType.boundary,
      dataType: SpatialDataType.vector,
      dataSourceType: DataSourceType.local,
      isVisible: true,
      style: const VectorStyle(
        strokeColor: '#334155',
        strokeWidth: 1.8,
        fillColor: '#FD8D3C',
      ),
      metadata: {
        'isThematicChoropleth': true,
        'datasetId': dataset.id,
        'attributeName': dataset.attributeName,
        'unit': dataset.unit,
        'administrativeLevel': dataset.administrativeLevel.code,
        'sourceName': dataset.sourceName,
        'classificationMethod': choroplethResult.classificationScheme.method.name,
        'classCount': choroplethResult.classificationScheme.breaks.length,
        'colorMap': choroplethResult.choroplethColorMap,
        'classificationScheme': choroplethResult.classificationScheme,
      },
    );
  }
}
