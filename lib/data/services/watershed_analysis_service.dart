import 'dart:collection';
import 'dart:math' as math;
import 'package:riskpulse/domain/gis/raster_data.dart';
import 'package:riskpulse/domain/gis/watershed.dart';
import 'package:riskpulse/domain/location/geo_location.dart';

class WatershedAnalysisService {

  /// Delineates a watershed from a single pour point.
  Watershed delineateWatershed({
    required RasterData flowDir,
    required GeoLocation pourPoint,
    String? id,
  }) {
    final int width = flowDir.width;
    final int height = flowDir.height;

    final int startIdx = _getCellIndex(pourPoint, flowDir);
    if (startIdx == -1 || flowDir.isNoData(flowDir.values[startIdx])) {
      throw Exception('Invalid pour point: Outside raster or NoData cell.');
    }

    final List<double> maskValues = List<double>.filled(width * height, 0.0);
    final Queue<int> queue = Queue<int>()..add(startIdx);
    final Set<int> visited = {startIdx};

    double totalArea = 0.0;

    while (queue.isNotEmpty) {
      final int currIdx = queue.removeFirst();
      maskValues[currIdx] = 1.0;
      totalArea += _getCellArea(currIdx, flowDir);

      int cx = currIdx % width;
      int cy = currIdx ~/ width;

      for (int i = 0; i < 8; i++) {
        int nx = cx + _dx[i];
        int ny = cy + _dy[i];
        if (nx < 0 || nx >= width || ny < 0 || ny >= height) continue;
        int nIdx = ny * width + nx;
        if (visited.contains(nIdx) || flowDir.isNoData(flowDir.values[nIdx])) continue;

        if (_flowsInto(nIdx, flowDir.values[nIdx].toInt(), currIdx, width)) {
          visited.add(nIdx);
          queue.add(nIdx);
        }
      }
    }

    return Watershed(
      id: id ?? 'ws-${DateTime.now().millisecondsSinceEpoch}',
      pourPointNodeId: 'node-$startIdx',
      pourPointLocation: _getCellLocation(startIdx, flowDir),
      mask: RasterData(
        width: width, height: height,
        cellWidth: flowDir.cellWidth, cellHeight: flowDir.cellHeight,
        origin: flowDir.origin, crs: flowDir.crs,
        values: maskValues, noDataValue: -1.0, units: 'binary',
      ),
      areaKm2: totalArea / 1000000.0,
    );
  }

  /// Delineates multiple watersheds into a single ID raster.
  RasterData delineateMultipleWatersheds({
    required RasterData flowDir,
    required List<GeoLocation> pourPoints,
  }) {
    final int w = flowDir.width;
    final int h = flowDir.height;
    final List<double> wsIds = List<double>.filled(w * h, 0.0);

    for (int i = 0; i < pourPoints.length; i++) {
      final int startIdx = _getCellIndex(pourPoints[i], flowDir);
      if (startIdx == -1 || flowDir.isNoData(flowDir.values[startIdx])) continue;

      final double id = (i + 1).toDouble();
      final Queue<int> queue = Queue<int>()..add(startIdx);
      final Set<int> wsVisited = {startIdx};

      while (queue.isNotEmpty) {
        final int currIdx = queue.removeFirst();
        if (wsIds[currIdx] == 0.0) wsIds[currIdx] = id;

        int cx = currIdx % w;
        int cy = currIdx ~/ w;
        for (int j = 0; j < 8; j++) {
          int nx = cx + _dx[j];
          int ny = cy + _dy[j];
          if (nx < 0 || nx >= w || ny < 0 || ny >= h) continue;
          int nIdx = ny * w + nx;
          if (wsVisited.contains(nIdx) || flowDir.isNoData(flowDir.values[nIdx])) continue;
          if (_flowsInto(nIdx, flowDir.values[nIdx].toInt(), currIdx, w)) {
            wsVisited.add(nIdx);
            queue.add(nIdx);
          }
        }
      }
    }
    return RasterData(
      width: w, height: h,
      cellWidth: flowDir.cellWidth, cellHeight: flowDir.cellHeight,
      origin: flowDir.origin, crs: flowDir.crs,
      values: wsIds, noDataValue: flowDir.noDataValue,
    );
  }

  GeoLocation snapPourPoint({
    required GeoLocation point,
    required RasterData accumulation,
    double searchRadiusMetres = 500.0,
  }) {
    final int startIdx = _getCellIndex(point, accumulation);
    if (startIdx == -1) return point;

    final int w = accumulation.width;
    final int h = accumulation.height;
    final int r = (searchRadiusMetres / (accumulation.cellHeight * 111320)).ceil();

    int bestIdx = startIdx;
    double maxAcc = accumulation.values[startIdx];
    int cx = startIdx % w;
    int cy = startIdx ~/ w;

    for (int dy = -r; dy <= r; dy++) {
      for (int dx = -r; dx <= r; dx++) {
        int nx = cx + dx; int ny = cy + dy;
        if (nx < 0 || nx >= w || ny < 0 || ny >= h) continue;
        int nIdx = ny * w + nx;
        if (accumulation.isNoData(accumulation.values[nIdx])) continue;
        if (accumulation.values[nIdx] > maxAcc) {
          maxAcc = accumulation.values[nIdx];
          bestIdx = nIdx;
        }
      }
    }
    return _getCellLocation(bestIdx, accumulation);
  }

  static const List<int> _dx = [1, 1, 0, -1, -1, -1, 0, 1];
  static const List<int> _dy = [0, 1, 1, 1, 0, -1, -1, -1];
  static const List<int> _d8Codes = [1, 2, 4, 8, 16, 32, 64, 128];

  int _getCellIndex(GeoLocation loc, RasterData raster) {
    final double dx = loc.longitude - raster.origin.longitude;
    final double dy = raster.origin.latitude - loc.latitude;
    final int x = (dx / raster.cellWidth).floor();
    final int y = (dy / raster.cellHeight).floor();
    if (x < 0 || x >= raster.width || y < 0 || y >= raster.height) return -1;
    return y * raster.width + x;
  }

  GeoLocation _getCellLocation(int idx, RasterData raster) {
    int x = idx % raster.width;
    int y = idx ~/ raster.width;
    return GeoLocation(
      longitude: raster.origin.longitude + (x * raster.cellWidth) + (raster.cellWidth / 2.0),
      latitude: raster.origin.latitude - (y * raster.cellHeight) - (raster.cellHeight / 2.0),
    );
  }

  bool _flowsInto(int fromIdx, int code, int targetIdx, int w) {
    int x = fromIdx % w;
    int y = fromIdx ~/ w;
    int dirIdx = -1;
    for (int i = 0; i < 8; i++) {
      if (code == _d8Codes[i]) { dirIdx = i; break; }
    }
    if (dirIdx == -1) return false;
    return ((y + _dy[dirIdx]) * w + (x + _dx[dirIdx])) == targetIdx;
  }

  double _getCellArea(int idx, RasterData raster) {
    if (raster.crs.code == 'EPSG:4326') {
      int y = idx ~/ raster.width;
      double lat = raster.origin.latitude - (y * raster.cellHeight);
      return (raster.cellHeight * 111320.0) * (raster.cellWidth * 111320.0 * math.cos(lat * math.pi / 180.0));
    }
    return raster.cellWidth * raster.cellHeight;
  }
}
