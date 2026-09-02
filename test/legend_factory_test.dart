import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/domain/gis/gis_layer.dart';
import 'package:riskpulse/domain/gis/gis_style.dart';
import 'package:riskpulse/domain/gis/color_ramp.dart';
import 'package:riskpulse/domain/gis/classification_scheme.dart';
import 'package:riskpulse/domain/gis/data_source_type.dart';
import 'package:riskpulse/domain/gis/legend_definition.dart';
import 'package:riskpulse/data/services/cartographic_service.dart';

void main() {
  group('Legend Factory Tests', () {
    late CartographicService service;

    setUp(() {
      service = CartographicService();
    });

    test('Should generate legend for continuous raster', () {
      final layer = GisLayer(
        id: 'l1', name: 'Elevation', type: GisLayerType.terrain,
        dataType: SpatialDataType.raster, dataSourceType: DataSourceType.terrain,
        style: const RasterStyle(colorRamp: ColorRamp.elevation),
      );

      final legend = service.generateLegend(layer);
      expect(legend.title, 'Elevation');
      expect(legend.entries.any((e) => e.type == LegendEntryType.gradient), isTrue);
    });

    test('Should generate legend for classified raster', () {
      final scheme = ClassificationScheme(
        method: ClassificationMethod.manual,
        breaks: [
          ClassBreak(minValue: 0, maxValue: 10, label: 'Low', colorHex: '#00FF00'),
          ClassBreak(minValue: 10, maxValue: 20, label: 'High', colorHex: '#FF0000'),
        ],
      );
      final layer = GisLayer(
        id: 'l2', name: 'Slope', type: GisLayerType.terrain,
        dataType: SpatialDataType.raster, dataSourceType: DataSourceType.terrain,
        style: RasterStyle(classificationScheme: scheme),
      );

      final legend = service.generateLegend(layer);
      expect(legend.entries.length, 3); // 2 breaks + 1 No Data
      expect(legend.entries[0].label, 'Low');
      expect(legend.entries[1].label, 'High');
    });

    test('Should generate legend for Strahler stream hierarchy', () {
      const style = VectorStyle(useStrahlerWidth: true, strokeColor: '#0000FF');
      final layer = GisLayer(
        id: 'l3', name: 'Streams', type: GisLayerType.research,
        dataType: SpatialDataType.vector, dataSourceType: DataSourceType.cloudProcessing,
        style: style,
      );

      final legend = service.generateLegend(layer);
      expect(legend.entries.any((e) => e.label.contains('Order 1')), isTrue);
      expect(legend.entries.any((e) => e.type == LegendEntryType.line), isTrue);
      
      // Order 2 should be thicker than Order 1
      final o1 = legend.entries.firstWhere((e) => e.label == 'Order 1');
      final o2 = legend.entries.firstWhere((e) => e.label == 'Order 2');
      expect(o2.strokeWidth, greaterThan(o1.strokeWidth));
    });

    test('Should include No Data for research layers', () {
      final layer = GisLayer(
        id: 'l4', name: 'Test', type: GisLayerType.research,
        dataType: SpatialDataType.raster, dataSourceType: DataSourceType.terrain,
        style: const RasterStyle(),
      );

      final legend = service.generateLegend(layer);
      expect(legend.entries.any((e) => e.label == 'No Data'), isTrue);
    });
  });
}
