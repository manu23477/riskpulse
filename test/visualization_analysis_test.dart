import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/domain/gis/raster_data.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/gis/color_ramp.dart';
import 'package:riskpulse/domain/gis/gis_style.dart';
import 'package:riskpulse/domain/gis/gis_layer.dart';
import 'package:riskpulse/domain/gis/data_source_type.dart';
import 'package:riskpulse/data/services/raster_visualization_service.dart';
import 'package:riskpulse/data/services/cartographic_service.dart';

void main() {
  group('Visualization Service Tests', () {
    late RasterVisualizationService rasterService;
    late CartographicService cartoService;
    late RasterData testRaster;

    setUp(() {
      rasterService = RasterVisualizationService();
      cartoService = CartographicService();

      testRaster = RasterData(
        width: 2, height: 2,
        cellWidth: 0.1, cellHeight: 0.1,
        origin: const GeoLocation(latitude: 31.0, longitude: 77.0),
        crs: CoordinateReferenceSystem.wgs84,
        values: [100.0, 200.0, 300.0, 400.0],
      );
    });

    test('Color Mapping: Should map min value to first stop color', () {
      final style = const RasterStyle(colorRamp: ColorRamp.elevation);
      final color = rasterService.mapValueToColor(100.0, testRaster, style);
      expect(color, ColorRamp.elevation.stops.first.colorHex);
    });

    test('Color Mapping: Should map max value to last stop color', () {
      final style = const RasterStyle(colorRamp: ColorRamp.elevation);
      final color = rasterService.mapValueToColor(400.0, testRaster, style);
      expect(color, ColorRamp.elevation.stops.last.colorHex);
    });

    test('Legend Generation: Should contain all color stops', () {
      final style = const RasterStyle(colorRamp: ColorRamp.elevation);
      final layer = GisLayer(
        id: 'l1', name: 'Test Layer', type: GisLayerType.terrain,
        dataType: SpatialDataType.raster, dataSourceType: DataSourceType.terrain,
        style: style,
      );

      final legend = cartoService.generateLegend(layer);
      expect(legend.entries.length, ColorRamp.elevation.stops.length);
      expect(legend.entries.first.colorHex, ColorRamp.elevation.stops.first.colorHex);
    });

    test('Scale Metadata: Should calculate metric pixels correctly', () {
      final extent = MapExtent(
        southWest: const GeoLocation(latitude: 31.0, longitude: 77.0),
        northEast: const GeoLocation(latitude: 31.1, longitude: 77.1),
      );

      final metadata = cartoService.calculateScaleMetadata(extent, 1000.0);
      expect(metadata['segment_pixels'], isPositive);
      expect(metadata['label'], contains('km'));
    });
  });
}
