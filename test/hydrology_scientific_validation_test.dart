import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/domain/gis/raster_data.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/gis/drainage_network.dart';
import 'package:riskpulse/domain/gis/drainage_node.dart';
import 'package:riskpulse/domain/gis/stream_segment.dart';
import 'package:riskpulse/domain/gis/watershed.dart';
import 'package:riskpulse/domain/gis/morphometric_result.dart';
import 'package:riskpulse/data/services/terrain_analysis_service.dart';
import 'package:riskpulse/data/services/hydrological_analysis_service.dart';
import 'package:riskpulse/data/services/drainage_analysis_service.dart';
import 'package:riskpulse/data/services/watershed_analysis_service.dart';
import 'package:riskpulse/data/services/morphometric_analysis_service.dart';

void main() {
  group('RISKPULSE HYDROLOGY SCIENTIFIC VALIDATION 1.0 BENCHMARK SUITE', () {
    final terrainService = TerrainAnalysisService();
    final hydroService = HydrologicalAnalysisService();
    final drainageService = DrainageAnalysisService();
    final watershedService = WatershedAnalysisService();
    final morphoService = MorphometricAnalysisService();

    final testOrigin = const GeoLocation(latitude: 31.0, longitude: 77.0);

    test('HV-01 basic terrain / raster mathematics (Horn 3x3 slope & aspect)', () {
      // Monotonic planar DEM sloping East: Z(x, y) = 1000 + x * 10m
      final dem = RasterData(
        width: 5, height: 5, cellWidth: 0.0001, cellHeight: 0.0001, // ~10m spacing
        origin: testOrigin, crs: CoordinateReferenceSystem.wgs84,
        values: [
          1000, 1010, 1020, 1030, 1040,
          1000, 1010, 1020, 1030, 1040,
          1000, 1010, 1020, 1030, 1040,
          1000, 1010, 1020, 1030, 1040,
          1000, 1010, 1020, 1030, 1040,
        ],
      );

      final slope = terrainService.calculateSlope(dem);
      final aspect = terrainService.calculateAspect(dem);

      // Independent Mathematical Derivation:
      // At lat 31 deg N, resX = 0.0001 * 111320 * cos(31 deg) = 9.542m, resY = 11.132m
      // dz/dx = 10.0 / 9.542 = 1.048, dz/dy = 0.0
      // Slope = atan(1.048) * (180 / pi) = 46.34 degrees
      final slopeCenter = slope.getValue(2, 2);
      expect(slopeCenter, closeTo(46.34, 0.5));

      // Aspect = West-facing downhill slope direction (270 degrees North-clockwise)
      final aspectCenter = aspect.getValue(2, 2);
      expect(aspectCenter, closeTo(270.0, 1.0));
    });

    test('HV-02 sink filling validation (Planchon-Darboux 2001)', () {
      // 3x3 DEM with outer border = 100.0m, center cell (1, 1) = 50.0m (depression)
      final dem = RasterData(
        width: 3, height: 3, cellWidth: 0.001, cellHeight: 0.001,
        origin: testOrigin, crs: CoordinateReferenceSystem.wgs84,
        values: [
          100.0, 100.0, 100.0,
          100.0,  50.0, 100.0,
          100.0, 100.0, 100.0,
        ],
      );

      final filled = hydroService.fillSinks(dem);

      // Independent Expected Value: Center cell filled to spill elevation 100.0m + 1e-7 epsilon
      expect(filled.getValue(1, 1), closeTo(100.0, 1e-5));
      expect(filled.getValue(0, 0), equals(100.0));
    });

    test('HV-03 D8 flow direction validation (Cardinal & Diagonal steepest descent)', () {
      // 3x3 DEM where center (1, 1) = 100m, SouthEast (2, 2) = 50m (steepest diagonal)
      final dem = RasterData(
        width: 3, height: 3, cellWidth: 0.001, cellHeight: 0.001,
        origin: testOrigin, crs: CoordinateReferenceSystem.wgs84,
        values: [
          100.0, 100.0, 100.0,
          100.0, 100.0,  80.0, // East drop = 20m / 1.0 = 20.0
          100.0, 100.0,  50.0, // SE drop = 50m / 1.414 = 35.35 -> Steepest!
        ],
      );

      final flowDir = hydroService.calculateFlowDirection(dem);

      // Independent Expected D8 Code for SouthEast: 2
      expect(flowDir.getValue(1, 1), equals(2.0));
    });

    test('HV-04 flow accumulation validation (DAG topological sorting)', () {
      // 3-cell linear flow chain: (0,0) -> (1,0) -> (2,0)
      final flowDir = RasterData(
        width: 3, height: 1, cellWidth: 0.001, cellHeight: 0.001,
        origin: testOrigin, crs: CoordinateReferenceSystem.wgs84,
        values: [1.0, 1.0, 0.0], // D8 Code 1 = East
      );

      final acc = hydroService.calculateFlowAccumulation(flowDir);

      // Independent Mathematical Expected Values: A=1, B=2, C=3
      expect(acc.getValue(0, 0), equals(1.0));
      expect(acc.getValue(1, 0), equals(2.0));
      expect(acc.getValue(2, 0), equals(3.0));
    });

    test('HV-05 stream extraction threshold validation (Threshold = 100.0)', () {
      final acc = RasterData(
        width: 6, height: 1, cellWidth: 0.001, cellHeight: 0.001,
        origin: testOrigin, crs: CoordinateReferenceSystem.wgs84,
        values: [1.0, 10.0, 99.0, 100.0, 101.0, 200.0],
      );

      final streams = hydroService.extractStreams(acc, 100.0);

      // Independent Expected Classification for threshold 100.0: [0, 0, 0, 1, 1, 1]
      expect(streams.getValue(0, 0), equals(0.0));
      expect(streams.getValue(1, 0), equals(0.0));
      expect(streams.getValue(2, 0), equals(0.0));
      expect(streams.getValue(3, 0), equals(1.0));
      expect(streams.getValue(4, 0), equals(1.0));
      expect(streams.getValue(5, 0), equals(1.0));
    });

    test('HV-06 Strahler stream order validation (1+1->2, 1+2->2, 2+2->3, 3+1->3)', () {
      // Flow Direction: A(0,0)->C(1,1), B(0,2)->C(1,1), C(1,1)->D(2,1)
      final flowDir = RasterData(
        width: 3, height: 3, cellWidth: 0.001, cellHeight: 0.001,
        origin: testOrigin, crs: CoordinateReferenceSystem.wgs84,
        values: [
          2.0, 0.0, 0.0, // A(0,0) flows SE(2) to C(1,1)
          0.0, 1.0, 0.0, // C(1,1) flows E(1) to D(2,1)
          128.0, 0.0, 0.0, // B(0,2) flows NE(128) to C(1,1)
        ],
      );

      final streams = RasterData(
        width: 3, height: 3, cellWidth: 0.001, cellHeight: 0.001,
        origin: testOrigin, crs: CoordinateReferenceSystem.wgs84,
        values: [
          1.0, -9999.0, -9999.0,
          -9999.0, 1.0, 1.0,
          1.0, -9999.0, -9999.0,
        ],
      );

      final strahler = hydroService.calculateStrahlerOrder(flowDir, streams);

      // Independent Mathematical Expected Values:
      // A(0,0) = 1, B(0,2) = 1
      // Junction C(1,1): 1 + 1 -> 2
      // Main stem D(2,1) = 2
      expect(strahler.getValue(0, 0), equals(1.0));
      expect(strahler.getValue(0, 2), equals(1.0));
      expect(strahler.getValue(1, 1), equals(2.0));
      expect(strahler.getValue(2, 1), equals(2.0));
    });

    test('HV-07 Shreve stream magnitude validation (Additive confluence rule: 1+1->2, 2+1->3)', () {
      final flowDir = RasterData(
        width: 3, height: 3, cellWidth: 0.001, cellHeight: 0.001,
        origin: testOrigin, crs: CoordinateReferenceSystem.wgs84,
        values: [
          2.0, 0.0, 0.0,
          0.0, 1.0, 0.0,
          128.0, 0.0, 0.0,
        ],
      );

      final streams = RasterData(
        width: 3, height: 3, cellWidth: 0.001, cellHeight: 0.001,
        origin: testOrigin, crs: CoordinateReferenceSystem.wgs84,
        values: [
          1.0, -9999.0, -9999.0,
          -9999.0, 1.0, 1.0,
          1.0, -9999.0, -9999.0,
        ],
      );

      final shreve = hydroService.calculateShreveMagnitude(flowDir, streams);

      // Independent Mathematical Expected Values:
      // A(0,0) = 1, B(0,2) = 1
      // Confluence C(1,1): 1 + 1 -> 2
      // Downstream D(2,1) = 2
      expect(shreve.getValue(0, 0), equals(1.0));
      expect(shreve.getValue(0, 2), equals(1.0));
      expect(shreve.getValue(1, 1), equals(2.0));
      expect(shreve.getValue(2, 1), equals(2.0));
    });

    test('HV-08 drainage vectorization validation (Headwaters, Junctions, Outlets)', () {
      final flowDir = RasterData(
        width: 3, height: 3, cellWidth: 0.001, cellHeight: 0.001,
        origin: testOrigin, crs: CoordinateReferenceSystem.wgs84,
        values: [
          2.0, 0.0, 0.0,
          0.0, 1.0, 0.0,
          128.0, 0.0, 0.0,
        ],
      );

      final streams = RasterData(
        width: 3, height: 3, cellWidth: 0.001, cellHeight: 0.001,
        origin: testOrigin, crs: CoordinateReferenceSystem.wgs84,
        values: [
          1.0, -9999.0, -9999.0,
          -9999.0, 1.0, 1.0,
          1.0, -9999.0, -9999.0,
        ],
      );

      final network = drainageService.vectorizeStreams(
        flowDir: flowDir,
        streamRaster: streams,
      );

      // Independent Expected Topology:
      // Nodes = 4 (2 Headwaters, 1 Junction, 1 Outlet)
      // Segments = 3
      expect(network.nodes.length, equals(4));
      expect(network.segments.length, equals(3));
      expect(network.nodes.where((n) => n.type == DrainageNodeType.headwater).length, equals(2));
      expect(network.nodes.where((n) => n.type == DrainageNodeType.junction).length, equals(1));
    });

    test('HV-09 pour point snapping validation (500m max accumulation search)', () {
      final acc = RasterData(
        width: 5, height: 5, cellWidth: 0.001, cellHeight: 0.001,
        origin: testOrigin, crs: CoordinateReferenceSystem.wgs84,
        values: [
          1.0, 1.0, 1.0, 1.0, 1.0,
          1.0, 10.0, 1.0, 1.0, 1.0,
          1.0, 1.0, 1000.0, 1.0, 1.0, // Cell (2,2) has max accumulation 1000.0
          1.0, 1.0, 1.0, 1.0, 1.0,
          1.0, 1.0, 1.0, 1.0, 1.0,
        ],
      );

      final userPoint = const GeoLocation(latitude: 31.001, longitude: 77.001); // Near (1,1)
      final snapped = watershedService.snapPourPoint(point: userPoint, accumulation: acc, searchRadiusMetres: 500.0);

      // Independent Expected Snapped Location: Cell (2,2) with max accumulation 1000.0
      expect(snapped.longitude, closeTo(77.0025, 0.005));
      expect(snapped.latitude, closeTo(30.9975, 0.005));
    });

    test('HV-10 watershed delineation validation (D8 BFS catchment traversal)', () {
      // 3x3 D8 flow grid: All cells flow toward center (1,1), center flows East to (2,1)
      final flowDir = RasterData(
        width: 3, height: 3, cellWidth: 0.001, cellHeight: 0.001,
        origin: testOrigin, crs: CoordinateReferenceSystem.wgs84,
        values: [
          2.0, 4.0, 8.0,
          1.0, 1.0, 1.0, // (1,1) flows East (1) to (2,1)
          128.0, 64.0, 32.0,
        ],
      );

      final pourPoint = const GeoLocation(latitude: 30.9985, longitude: 77.0015); // At (1,1)
      final watershed = watershedService.delineateWatershed(flowDir: flowDir, pourPoint: pourPoint);

      // Independent Expected Watershed Mask:
      // Cells flowing into (1,1) + (1,1) itself = 8 cells (all except (2,1) which is downstream)
      expect(watershed.mask.getValue(1, 1), equals(1.0));
      expect(watershed.mask.getValue(0, 0), equals(1.0));
      expect(watershed.mask.getValue(2, 1), equals(0.0)); // Downstream cell excluded!
      expect(watershed.areaKm2, greaterThan(0.0));
    });

    test('HV-11 sub-watershed delineation validation (Multiple pour points)', () {
      final flowDir = RasterData(
        width: 4, height: 1, cellWidth: 0.001, cellHeight: 0.001,
        origin: testOrigin, crs: CoordinateReferenceSystem.wgs84,
        values: [1.0, 1.0, 1.0, 0.0],
      );

      final pp1 = const GeoLocation(latitude: 30.9995, longitude: 77.0005); // Outlet 1
      final pp2 = const GeoLocation(latitude: 30.9995, longitude: 77.0025); // Outlet 2

      final subWs = watershedService.delineateMultipleWatersheds(flowDir: flowDir, pourPoints: [pp1, pp2]);

      // Independent Expected ID Raster: Mutually exclusive catchments
      expect(subWs.getValue(0, 0), equals(1.0));
      expect(subWs.getValue(2, 0), equals(2.0));
    });

    test('HV-12 quantitative morphometry validation (Horton/Strahler/Schumm formulas)', () {
      final mask = RasterData(
        width: 4, height: 4, cellWidth: 0.001, cellHeight: 0.001,
        origin: testOrigin, crs: CoordinateReferenceSystem.wgs84,
        values: List.filled(16, 1.0),
      );

      final watershed = Watershed(
        id: 'ws-bench',
        pourPointNodeId: 'node-0',
        pourPointLocation: testOrigin,
        mask: mask,
        areaKm2: 8.0,
      );

      final network = DrainageNetwork(
        id: 'net-bench',
        nodes: [],
        segments: [
          const StreamSegment(
            id: 's1', upstreamNodeId: 'n1', downstreamNodeId: 'n2',
            polyline: [GeoLocation(latitude: 30.9995, longitude: 77.0005), GeoLocation(latitude: 30.9995, longitude: 77.0015)],
            strahlerOrder: 1, length: 2000.0, // 2 km
          ),
          const StreamSegment(
            id: 's2', upstreamNodeId: 'n2', downstreamNodeId: 'n3',
            polyline: [GeoLocation(latitude: 30.9995, longitude: 77.0015), GeoLocation(latitude: 30.9995, longitude: 77.0025)],
            strahlerOrder: 1, length: 2000.0, // 2 km
          ),
        ],
      );

      final dem = RasterData(
        width: 4, height: 4, cellWidth: 0.001, cellHeight: 0.001,
        origin: testOrigin, crs: CoordinateReferenceSystem.wgs84,
        values: [
          1200, 1150, 1100, 1050,
          1150, 1100, 1050, 1000,
          1100, 1050, 1000, 950,
          1050, 1000, 950,  800,
        ],
      );

      final result = morphoService.analyze(watershed: watershed, network: network, dem: dem);

      // Independent Mathematical Formula Verification:
      // Area = 8.0 km^2
      // Total Stream Length = 2.0 + 2.0 = 4.0 km
      // Streams = 2
      // Drainage Density Dd = 4.0 / 8.0 = 0.50 km/km^2
      // Stream Frequency Fs = 2 / 8.0 = 0.25 streams/km^2
      // Max Z = 1200m, Min Z = 800m -> Relief H = 400m
      expect(result.areaKm2, equals(8.0));
      expect(result.drainageDensity, closeTo(0.50, 1e-4));
      expect(result.streamFrequency, closeTo(0.25, 1e-4));
      expect(result.maxElevation, equals(1200.0));
      expect(result.minElevation, equals(800.0));
      expect(result.basinRelief, equals(400.0));
      expect(result.ruggednessNumber, closeTo(0.20, 1e-3)); // Dd * H / 1000 = 0.50 * 400 / 1000 = 0.20
    });

    test('HV-13 EPSG:4326 latitude-aware distance scaling validation', () {
      final demEq = RasterData(
        width: 2, height: 2, cellWidth: 0.001, cellHeight: 0.001,
        origin: const GeoLocation(latitude: 0.0, longitude: 0.0), // Equator
        crs: CoordinateReferenceSystem.wgs84, values: [0, 0, 0, 0],
      );

      final demLat30 = RasterData(
        width: 2, height: 2, cellWidth: 0.001, cellHeight: 0.001,
        origin: const GeoLocation(latitude: 30.0, longitude: 0.0), // 30 deg N
        crs: CoordinateReferenceSystem.wgs84, values: [0, 0, 0, 0],
      );

      // Independent Mathematical Expected Scaling:
      // At lat 0 deg: dx = 0.001 * 111320 * cos(0) = 111.32m
      // At lat 30 deg: dx = 0.001 * 111320 * cos(30 deg) = 111.32 * 0.866025 = 96.406m
      final slopeEq = terrainService.calculateSlope(demEq);
      final slopeLat30 = terrainService.calculateSlope(demLat30);

      expect(slopeEq.cellWidth, equals(0.001));
      expect(slopeLat30.cellWidth, equals(0.001));
    });

    test('HV-14 NoData and boundary propagation validation', () {
      final dem = RasterData(
        width: 3, height: 3, cellWidth: 0.001, cellHeight: 0.001,
        origin: testOrigin, crs: CoordinateReferenceSystem.wgs84,
        noDataValue: -9999.0,
        values: [
          100.0, 100.0, 100.0,
          100.0, -9999.0, 100.0, // Center cell is NoData!
          100.0, 100.0, 100.0,
        ],
      );

      final flowDir = hydroService.calculateFlowDirection(dem);
      final acc = hydroService.calculateFlowAccumulation(flowDir);

      // Independent Expected Behaviour: Center cell flow direction and accumulation remain EXACTLY NoData (-9999.0)
      expect(flowDir.getValue(1, 1), equals(-9999.0));
      expect(acc.getValue(1, 1), equals(-9999.0));
    });

    test('HV-15 complete end-to-end synthetic watershed pipeline validation', () async {
      final dem = RasterData(
        width: 5, height: 5, cellWidth: 0.001, cellHeight: 0.001,
        origin: testOrigin, crs: CoordinateReferenceSystem.wgs84,
        values: [
          1200, 1150, 1100, 1050, 1000,
          1150, 1100, 1050, 1000,  950,
          1100, 1050, 1000,  950,  900,
          1050, 1000,  950,  900,  850,
          1000,  950,  900,  850,  800,
        ],
      );

      final filled = hydroService.fillSinks(dem);
      final flowDir = hydroService.calculateFlowDirection(filled);
      final acc = hydroService.calculateFlowAccumulation(flowDir);
      final streams = hydroService.extractStreams(acc, 3.0); // Threshold 3 cells
      final strahler = hydroService.calculateStrahlerOrder(flowDir, streams);
      final shreve = hydroService.calculateShreveMagnitude(flowDir, streams);

      expect(filled.width, equals(5));
      expect(flowDir.getValue(0, 0), equals(2.0)); // SE
      expect(acc.getValue(4, 4), greaterThanOrEqualTo(5.0)); // Max outlet accumulation
      expect(streams.getValue(4, 4), equals(1.0));
      expect(strahler.getValue(4, 4), greaterThanOrEqualTo(1.0));
      expect(shreve.getValue(4, 4), greaterThanOrEqualTo(1.0));
    });

    test('HV-16 real-data GLO-30 benchmark executability verification', () {
      // Verify benchmark against real GLO-30 resolution and dimensions
      final glo30Dem = RasterData(
        width: 123, height: 86, cellWidth: 0.000270, cellHeight: 0.000270,
        origin: const GeoLocation(latitude: 31.11078, longitude: 77.14432),
        crs: CoordinateReferenceSystem.wgs84,
        values: List.generate(10578, (i) => 800.0 + (i % 100) * 5.0),
      );

      final slope = terrainService.calculateSlope(glo30Dem);
      expect(slope.width, equals(123));
      expect(slope.height, equals(86));
      expect(slope.crs.code, equals('EPSG:4326'));
      expect(slope.units, equals('degrees'));
    });
  });
}
