import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/domain/gis/raster_data.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/gis/drainage_node.dart';
import 'package:riskpulse/data/services/drainage_analysis_service.dart';

void main() {
  group('DrainageAnalysisService Tests', () {
    late DrainageAnalysisService service;
    late CoordinateReferenceSystem utm;

    setUp(() {
      service = DrainageAnalysisService();
      utm = const CoordinateReferenceSystem(code: 'EPSG:32643', name: 'UTM 43N');
    });

    test('Vectorization: Single stream Headwater -> Outlet', () {
      // 3x1 raster: Cell 0 (Headwater) -> Cell 1 (Link) -> Cell 2 (Outlet)
      // D8 Code for East is 1.
      final flowDir = RasterData(
        width: 3, height: 1, cellWidth: 30, cellHeight: 30,
        origin: const GeoLocation(latitude: 31, longitude: 77),
        crs: utm,
        values: [1, 1, 0],
      );
      final streamRaster = RasterData(
        width: 3, height: 1, cellWidth: 30, cellHeight: 30,
        origin: const GeoLocation(latitude: 31, longitude: 77),
        crs: utm,
        values: [1, 1, 1],
      );

      final network = service.vectorizeStreams(
        flowDir: flowDir,
        streamRaster: streamRaster,
      );

      expect(network.nodes.length, 2); // Headwater and Outlet
      expect(network.segments.length, 1);
      expect(network.headwaters.length, 1);
      expect(network.outlets.length, 1);

      final seg = network.segments.first;
      expect(seg.polyline.length, 3);
      expect(seg.length, closeTo(60.0, 0.1));
    });

    test('Vectorization: Y-Junction', () {
      // 3x3 Raster
      // 0 1 2
      // 3 4 5
      // 6 7 8
      // Cell 0 -> 4 (SE: 2)
      // Cell 2 -> 4 (SW: 8)
      // Cell 4 -> 7 (S: 4)
      final flowDir = RasterData(
        width: 3, height: 3, cellWidth: 30, cellHeight: 30,
        origin: const GeoLocation(latitude: 31, longitude: 77),
        crs: utm,
        values: [
          2, 0, 8,
          0, 4, 0,
          0, 0, 0
        ],
      );
      final streamRaster = RasterData(
        width: 3, height: 3, cellWidth: 30, cellHeight: 30,
        origin: const GeoLocation(latitude: 31, longitude: 77),
        crs: utm,
        values: [
          1, 0, 1,
          0, 1, 0,
          0, 1, 0
        ],
      );

      final network = service.vectorizeStreams(
        flowDir: flowDir,
        streamRaster: streamRaster,
      );

      // Nodes: 0 (H), 2 (H), 4 (J), 7 (O)
      expect(network.nodes.length, 4);
      expect(network.headwaters.length, 2);
      expect(network.junctions.length, 1);
      expect(network.outlets.length, 1);

      // Segments: 0->4, 2->4, 4->7
      expect(network.segments.length, 3);
    });

    test('Metric Length: WGS84 Scaling', () {
      final wgs84 = CoordinateReferenceSystem.wgs84;
      // 1 degree latitude at 31N is ~111km.
      // 0.001 degrees is ~111m.
      final flowDir = RasterData(
        width: 2, height: 1, cellWidth: 0.001, cellHeight: 0.001,
        origin: const GeoLocation(latitude: 31, longitude: 77),
        crs: wgs84,
        values: [1, 0],
      );
      final streamRaster = RasterData(
        width: 2, height: 1, cellWidth: 0.001, cellHeight: 0.001,
        origin: const GeoLocation(latitude: 31, longitude: 77),
        crs: wgs84,
        values: [1, 1],
      );

      final network = service.vectorizeStreams(
        flowDir: flowDir,
        streamRaster: streamRaster,
      );

      final seg = network.segments.first;
      // At 31N, 1 deg lon is ~111320 * cos(31) = 95.4km.
      // 0.001 deg lon is ~95.4m.
      expect(seg.length, closeTo(95.4, 1.0));
    });

    test('NoData Barrier: Should remain disconnected', () {
      // 3x1 Raster: 0 (H) -> 1 (NoData) -> 2 (Stream)
      final flowDir = RasterData(
        width: 3, height: 1, cellWidth: 30, cellHeight: 30,
        origin: const GeoLocation(latitude: 31, longitude: 77),
        crs: utm,
        values: [1, 1, 0],
      );
      final streamRaster = RasterData(
        width: 3, height: 1, cellWidth: 30, cellHeight: 30,
        origin: const GeoLocation(latitude: 31, longitude: 77),
        crs: utm,
        values: [1, -9999.0, 1], // Cell 1 is NoData
        noDataValue: -9999.0,
      );

      final network = service.vectorizeStreams(
        flowDir: flowDir,
        streamRaster: streamRaster,
      );

      // Only 0 and 2 are stream cells.
      // 0 has no downstream stream cell (1 is NoData). So 0 is an Outlet.
      // 2 has no upstream stream cell. So 2 is a Headwater.
      // Wait, if a cell has no outgoing path, it's an Outlet.
      // If it has no incoming path, it's a Headwater.
      // Cell 0: up=0, down=0 (because 1 is not in streamIndex) -> H + O
      // Cell 2: up=0, down=0 -> H + O

      expect(network.nodes.length, 2);
      expect(network.segments.length, 0);
    });
  });
}
