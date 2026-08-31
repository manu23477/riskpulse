import 'dart:math' as math;
import 'package:riskpulse/domain/gis/raster_data.dart';
import 'package:riskpulse/domain/gis/drainage_node.dart';
import 'package:riskpulse/domain/gis/stream_segment.dart';
import 'package:riskpulse/domain/gis/drainage_network.dart';
import 'package:riskpulse/domain/location/geo_location.dart';

class DrainageAnalysisService {

  DrainageNetwork vectorizeStreams({
    required RasterData flowDir,
    required RasterData streamRaster,
    RasterData? strahler,
    RasterData? shreve,
  }) {
    final int width = flowDir.width;
    final int height = flowDir.height;

    // 1. Identify all stream cells and their topology
    final List<int> streamIndices = [];
    final Map<int, List<int>> upstreamMap = {}; // index -> list of upstream stream cell indices
    final Map<int, int> downstreamMap = {}; // index -> downstream stream cell index

    for (int i = 0; i < width * height; i++) {
      if (streamRaster.values[i] == 1.0) {
        streamIndices.add(i);

        final int nextIdx = _getDownstreamIndex(i, flowDir.values[i].toInt(), width, height);
        if (nextIdx != -1 && streamRaster.values[nextIdx] == 1.0) {
          downstreamMap[i] = nextIdx;
          upstreamMap.putIfAbsent(nextIdx, () => []).add(i);
        }
      }
    }

    // 2. Node Detection
    final Map<int, DrainageNode> nodesByIdx = {};
    final Set<int> segmentStartPoints = {}; // Headwaters and Junctions

    for (final int idx in streamIndices) {
      final int upCount = upstreamMap[idx]?.length ?? 0;
      final bool isOutlet = !downstreamMap.containsKey(idx);

      DrainageNodeType? type;
      if (upCount == 0) {
        type = DrainageNodeType.headwater;
        segmentStartPoints.add(idx);
      } else if (upCount > 1) {
        type = DrainageNodeType.junction;
        segmentStartPoints.add(idx);
      } else if (isOutlet) {
        type = DrainageNodeType.outlet;
      }

      if (type != null) {
        nodesByIdx[idx] = DrainageNode(
          id: 'node-$idx',
          type: type,
          location: _getCellLocation(idx, flowDir),
        );
      }
    }

    // 3. Segment Tracing
    final List<StreamSegment> segments = [];
    final Set<int> visitedAsSegmentInterior = {};

    for (final int startIdx in segmentStartPoints) {
      // For each start point, find its downstream paths
      // Actually, a Junction can have multiple segments entering it, but only one exiting it.
      // So we start segments FROM Headwaters and FROM Junctions (downstream).

      int? currentIdx = downstreamMap[startIdx];
      if (currentIdx == null) continue; // Single cell stream case

      final List<GeoLocation> polyline = [_getCellLocation(startIdx, flowDir)];
      final double sOrder = strahler?.values[startIdx] ?? 1.0;
      final double sMag = shreve?.values[startIdx] ?? 1.0;

      while (currentIdx != null) {
        polyline.add(_getCellLocation(currentIdx, flowDir));

        // Check if currentIdx is a node (Junction or Outlet)
        if (nodesByIdx.containsKey(currentIdx)) {
          segments.add(StreamSegment(
            id: 'seg-$startIdx-$currentIdx',
            upstreamNodeId: nodesByIdx[startIdx]!.id,
            downstreamNodeId: nodesByIdx[currentIdx]!.id,
            polyline: polyline,
            strahlerOrder: sOrder,
            shreveMagnitude: sMag,
            length: _calculatePolylineLength(polyline, flowDir),
          ));
          break;
        }

        visitedAsSegmentInterior.add(currentIdx);
        currentIdx = downstreamMap[currentIdx];
      }
    }

    return DrainageNetwork(
      id: 'drainage-${DateTime.now().millisecondsSinceEpoch}',
      nodes: nodesByIdx.values.toList(),
      segments: segments,
    );
  }

  // --- HELPERS ---

  static const List<int> _dx = [1, 1, 0, -1, -1, -1, 0, 1];
  static const List<int> _dy = [0, 1, 1, 1, 0, -1, -1, -1];
  static const List<int> _d8Codes = [1, 2, 4, 8, 16, 32, 64, 128];

  int _getDownstreamIndex(int idx, int code, int w, int h) {
    int x = idx % w;
    int y = idx ~/ w;
    int dirIdx = -1;
    for (int i = 0; i < 8; i++) {
      if (code == _d8Codes[i]) {
        dirIdx = i;
        break;
      }
    }
    if (dirIdx == -1) return -1;
    int nx = x + _dx[dirIdx];
    int ny = y + _dy[dirIdx];
    if (nx < 0 || nx >= w || ny < 0 || ny >= h) return -1;
    return ny * w + nx;
  }

  GeoLocation _getCellLocation(int idx, RasterData raster) {
    int x = idx % raster.width;
    int y = idx ~/ raster.width;
    return GeoLocation(
      longitude: raster.origin.longitude + (x * raster.cellWidth),
      latitude: raster.origin.latitude - (y * raster.cellHeight),
    );
  }

  double _calculatePolylineLength(List<GeoLocation> polyline, RasterData raster) {
    double total = 0.0;
    for (int i = 0; i < polyline.length - 1; i++) {
      total += _distance(polyline[i], polyline[i+1], raster);
    }
    return total;
  }

  double _distance(GeoLocation p1, GeoLocation p2, RasterData raster) {
    if (raster.crs.code == 'EPSG:4326') {
      final double latMid = (p1.latitude + p2.latitude) / 2.0;
      final double dy = (p1.latitude - p2.latitude).abs() * 111320;
      final double dx = (p1.longitude - p2.longitude).abs() * 111320 * math.cos(latMid * math.pi / 180.0);
      return math.sqrt(dx * dx + dy * dy);
    }
    // Simple Euclidean for projected CRS (assumed meters)
    final double dx = p1.longitude - p2.longitude;
    final double dy = p1.latitude - p2.latitude;
    return math.sqrt(dx * dx + dy * dy);
  }
}
