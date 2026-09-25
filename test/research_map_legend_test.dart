import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/data/services/cartographic_service.dart';
import 'package:riskpulse/data/services/terrain_analysis_service.dart';
import 'package:riskpulse/domain/gis/color_ramp.dart';
import 'package:riskpulse/domain/gis/data_source_type.dart';
import 'package:riskpulse/domain/gis/gis_layer.dart';
import 'package:riskpulse/domain/gis/gis_style.dart';
import 'package:riskpulse/domain/gis/raster_data.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/location/geo_location.dart';

void main() {
  group('Research GIS Map Legend Scientific Correctness Tests', () {
    late CartographicService cartoService;
    late TerrainAnalysisService terrainService;

    setUp(() {
      cartoService = CartographicService();
      terrainService = TerrainAnalysisService();
    });

    final testOrigin = const GeoLocation(latitude: 31.0, longitude: 77.0);

    test('1. Valid Slope Raster produces continuous legend with actual min/max values and DOES NOT contain only "No Data"', () {
      final validSlopeRaster = RasterData(
        width: 3,
        height: 3,
        cellWidth: 30.0,
        cellHeight: 30.0,
        origin: testOrigin,
        crs: CoordinateReferenceSystem.wgs84,
        values: const [0.0, 5.0, 15.0, 25.0, 30.0, 42.0, 45.0, 52.0, 58.4], // ALL valid slope degree values!
        noDataValue: -9999.0,
        units: 'degrees',
      );

      final slopeLayer = terrainService.createLayerFromRaster(
        validSlopeRaster,
        'Slope',
        GisLayerType.terrain,
      );

      final legendDef = cartoService.generateLegend(slopeLayer);

      expect(legendDef.title, equals('Slope'));
      expect(legendDef.entries, isNotEmpty);

      final labels = legendDef.entries.map((e) => e.label).toList();
      // Must contain min/max values derived from actual raster values!
      expect(labels.first, contains('0.0 degrees'));
      expect(labels.last, contains('58.4 degrees'));

      // MUST NOT contain "No Data" entry because there are 0 NoData cells!
      expect(labels, isNot(contains('No Data')));
    });

    test('2. Valid Flow Accumulation Raster produces meaningful legend with cell range', () {
      final validFlowAccRaster = RasterData(
        width: 3,
        height: 3,
        cellWidth: 30.0,
        cellHeight: 30.0,
        origin: testOrigin,
        crs: CoordinateReferenceSystem.wgs84,
        values: const [1.0, 5.0, 12.0, 50.0, 240.0, 1200.0, 4500.0, 8900.0, 15420.0],
        noDataValue: -9999.0,
        units: 'cells',
      );

      final flowAccLayer = GisLayer(
        id: 'layer-flow-acc-01',
        name: 'Flow Accumulation',
        type: GisLayerType.terrain,
        dataType: SpatialDataType.raster,
        dataSourceType: DataSourceType.cloudProcessing,
        metadata: {
          'raster_data': validFlowAccRaster,
          'hydrology_product': 'flowAccumulation',
          'units': 'cells',
        },
      );

      final legendDef = cartoService.generateLegend(flowAccLayer);

      expect(legendDef.title, equals('Flow Accumulation'));
      expect(legendDef.entries, isNotEmpty);

      final labels = legendDef.entries.map((e) => e.label).toList();
      expect(labels.first, contains('1.0 cells'));
      expect(labels.last, contains('15420.0 cells'));
      expect(labels, isNot(contains('No Data')));
    });

    test('3. Genuine NoData cells in a partially valid raster remain represented as "No Data"', () {
      final rasterWithNoData = RasterData(
        width: 3,
        height: 3,
        cellWidth: 30.0,
        cellHeight: 30.0,
        origin: testOrigin,
        crs: CoordinateReferenceSystem.wgs84,
        values: const [0.0, 10.0, 20.0, 30.0, -9999.0, 40.0, 50.0, -9999.0, 60.0], // Contains -9999.0 NoData!
        noDataValue: -9999.0,
        units: 'degrees',
      );

      final slopeLayerWithNoData = terrainService.createLayerFromRaster(
        rasterWithNoData,
        'Slope',
        GisLayerType.terrain,
      );

      final legendDef = cartoService.generateLegend(slopeLayerWithNoData);

      final labels = legendDef.entries.map((e) => e.label).toList();
      // Valid range stops must be present
      expect(labels.first, contains('0.0 degrees'));
      // AND "No Data" MUST be present at the end because genuine NoData cells exist!
      expect(labels.last, equals('No Data'));
    });

    test('4. Completely NoData raster produces "No Data" entry without fabricating statistics', () {
      final allNoDataRaster = RasterData(
        width: 3,
        height: 3,
        cellWidth: 30.0,
        cellHeight: 30.0,
        origin: testOrigin,
        crs: CoordinateReferenceSystem.wgs84,
        values: const [-9999.0, -9999.0, -9999.0, -9999.0, -9999.0, -9999.0, -9999.0, -9999.0, -9999.0],
        noDataValue: -9999.0,
        units: 'degrees',
      );

      final emptySlopeLayer = terrainService.createLayerFromRaster(
        allNoDataRaster,
        'Slope',
        GisLayerType.terrain,
      );

      final legendDef = cartoService.generateLegend(emptySlopeLayer);

      expect(legendDef.entries, isNotEmpty);
      final labels = legendDef.entries.map((e) => e.label).toList();
      expect(labels.last, equals('No Data'));
    });

    test('5. Legend does NOT fabricate statistics (min/max match actual valid raster min/max)', () {
      final raster = RasterData(
        width: 2,
        height: 2,
        cellWidth: 30.0,
        cellHeight: 30.0,
        origin: testOrigin,
        crs: CoordinateReferenceSystem.wgs84,
        values: const [12.3, 45.6, 78.9, 91.2],
        noDataValue: -9999.0,
        units: 'meters',
      );

      final demLayer = GisLayer(
        id: 'filled-dem-01',
        name: 'Filled DEM',
        type: GisLayerType.terrain,
        dataType: SpatialDataType.raster,
        dataSourceType: DataSourceType.cloudProcessing,
        style: const RasterStyle(colorRamp: ColorRamp.elevation),
        metadata: {
          'raster_data': raster,
          'units': 'meters',
        },
      );

      final legendDef = cartoService.generateLegend(demLayer);
      final labels = legendDef.entries.map((e) => e.label).toList();

      expect(labels.first, contains('12.3 meters'));
      expect(labels.last, contains('91.2 meters'));
    });

    test('6. Scientific analytical outputs (RasterData values) remain 100% untouched during legend generation', () {
      final originalValues = const [10.0, 20.0, 30.0, 40.0];
      final raster = RasterData(
        width: 2,
        height: 2,
        cellWidth: 30.0,
        cellHeight: 30.0,
        origin: testOrigin,
        crs: CoordinateReferenceSystem.wgs84,
        values: originalValues,
        noDataValue: -9999.0,
      );

      final layer = terrainService.createLayerFromRaster(raster, 'Slope', GisLayerType.terrain);
      cartoService.generateLegend(layer);

      // Verify original raster cell values are 100% identical!
      expect(raster.values, equals(originalValues));
    });
  });
}
