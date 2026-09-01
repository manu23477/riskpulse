import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/domain/gis/map_composition.dart';
import 'package:riskpulse/domain/gis/gis_layer.dart';
import 'package:riskpulse/domain/gis/data_source_type.dart';
import 'package:riskpulse/domain/gis/map_metadata.dart';
import 'package:riskpulse/domain/gis/cartographic_element_config.dart';

void main() {
  group('MapComposition Domain Model Tests', () {
    final testLayers = [
      const GisLayer(
        id: 'l1', name: 'DEM', type: GisLayerType.terrain, 
        dataType: SpatialDataType.raster, dataSourceType: DataSourceType.terrain,
        zIndex: 10,
      ),
      const GisLayer(
        id: 'l2', name: 'Streams', type: GisLayerType.research, 
        dataType: SpatialDataType.vector, dataSourceType: DataSourceType.cloudProcessing,
        zIndex: 20,
      ),
    ];

    test('Should initialize with defaults', () {
      final composition = MapComposition(
        id: 'comp-001',
        title: 'Himalayan Study',
        layers: testLayers,
      );

      expect(composition.title, 'Himalayan Study');
      expect(composition.layers.length, 2);
      expect(composition.scaleBar.isVisible, isTrue);
      expect(composition.grid.isVisible, isFalse);
    });

    test('copyWith should preserve immutability and handle overrides', () {
      final composition = MapComposition(
        id: 'comp-001',
        title: 'Initial Title',
        layers: testLayers,
      );

      final updated = composition.copyWith(
        title: 'New Title',
        grid: const CoordinateGridConfig(isVisible: true),
      );

      expect(composition.title, 'Initial Title');
      expect(updated.title, 'New Title');
      expect(updated.grid.isVisible, isTrue);
      expect(composition.grid.isVisible, isFalse);
    });

    test('orderedLayers should return layers sorted by zIndex', () {
      final shuffledLayers = [
        const GisLayer(
          id: 'top', name: 'Top', type: GisLayerType.research, 
          dataType: SpatialDataType.vector, dataSourceType: DataSourceType.cloudProcessing,
          zIndex: 100,
        ),
        const GisLayer(
          id: 'bottom', name: 'Bottom', type: GisLayerType.terrain, 
          dataType: SpatialDataType.raster, dataSourceType: DataSourceType.terrain,
          zIndex: 0,
        ),
      ];

      final composition = MapComposition(
        id: 'test',
        title: 'Sort Test',
        layers: shuffledLayers,
      );

      final ordered = composition.orderedLayers;
      expect(ordered.first.id, 'bottom');
      expect(ordered.last.id, 'top');
    });

    test('Should preserve research metadata correctly', () {
      final metadata = MapMetadata(
        author: 'Researcher A',
        dataSource: 'OpenTopography',
        acquisitionDate: DateTime(2026, 1, 1),
        processingDate: DateTime.now(),
      );

      final composition = MapComposition(
        id: 'test-meta',
        title: 'Meta Test',
        layers: [],
        researchMetadata: metadata,
      );

      expect(composition.researchMetadata?.author, 'Researcher A');
      expect(composition.researchMetadata?.dataSource, 'OpenTopography');
    });
  });
}
