import 'dart:collection';
import 'dart:math' as math;
import 'package:riskpulse/domain/gis/raster_data.dart';
import 'package:riskpulse/domain/gis/hydrological_product_type.dart';

/// Service responsible for hydrological analysis and drainage extraction.
///
/// Operates on provider-neutral [RasterData].
class HydrologicalAnalysisService {

  /// Implements DEM Conditioning (Sink Filling).
  ///
  /// Uses an iterative approach inspired by Planchon and Darboux.
  RasterData fillSinks(RasterData dem) {
    final int width = dem.width;
    final int height = dem.height;
    final List<double> filledValues = List<double>.from(dem.values);

    // 1. Initialize: Set non-boundary cells to infinity
    const double infinity = double.maxFinite;
    for (int y = 1; y < height - 1; y++) {
      for (int x = 1; x < width - 1; x++) {
        final int idx = y * width + x;
        if (!dem.isNoData(dem.values[idx])) {
          filledValues[idx] = infinity;
        }
      }
    }

    // 2. Iterative Filling
    bool changed = true;
    while (changed) {
      changed = false;
      // Forward pass
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          changed |= _updateFillCell(dem, filledValues, x, y, width, height);
        }
      }
      if (!changed) break;
      // Backward pass
      for (int y = height - 1; y >= 0; y--) {
        for (int x = width - 1; x >= 0; x--) {
          changed |= _updateFillCell(dem, filledValues, x, y, width, height);
        }
      }
    }

    return RasterData(
      width: width,
      height: height,
      cellWidth: dem.cellWidth,
      cellHeight: dem.cellHeight,
      origin: dem.origin,
      crs: dem.crs,
      values: filledValues,
      noDataValue: dem.noDataValue,
      units: dem.units,
      metadata: {
        ...dem.metadata,
        'hydrology_product': HydrologicalProductType.filledDem.name,
      },
    );
  }

  bool _updateFillCell(RasterData dem, List<double> filled, int x, int y, int w, int h) {
    final int idx = y * w + x;
    if (dem.isNoData(dem.values[idx])) return false;

    double current = filled[idx];
    if (current == dem.values[idx]) return false;

    double minNeighbor = double.maxFinite;
    for (int i = 0; i < 8; i++) {
      final int nx = x + _dx[i];
      final int ny = y + _dy[i];
      if (nx < 0 || nx >= w || ny < 0 || ny >= h) continue;
      final double val = filled[ny * w + nx];
      if (val < minNeighbor) minNeighbor = val;
    }

    double newValue = math.max(dem.values[idx], minNeighbor + 1e-7);
    if (newValue < current) {
      filled[idx] = newValue;
      return true;
    }
    return false;
  }

  /// Calculates D8 Flow Direction with flat resolution.
  RasterData calculateFlowDirection(RasterData dem) {
    final int width = dem.width;
    final int height = dem.height;
    final List<double> directions = List<double>.filled(width * height, dem.noDataValue);

    // Initial pass: Steepest descent
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int idx = y * width + x;
        if (dem.isNoData(dem.values[idx])) continue;

        double maxDrop = 0.0;
        int bestDir = -1;

        for (int i = 0; i < 8; i++) {
          final int nx = x + _dx[i];
          final int ny = y + _dy[i];
          if (nx < 0 || nx >= width || ny < 0 || ny >= height) continue;

          final double nVal = dem.values[ny * width + nx];
          if (dem.isNoData(nVal)) continue;

          double dist = (nx == x || ny == y) ? 1.0 : 1.41421356;
          double drop = (dem.values[idx] - nVal) / dist;

          if (drop > maxDrop) {
            maxDrop = drop;
            bestDir = i;
          }
        }

        if (bestDir != -1) {
          directions[idx] = _d8Codes[bestDir].toDouble();
        } else {
          directions[idx] = 0; // Possible flat or pit
        }
      }
    }

    // Flat resolution: Iteratively propagate direction from outlets
    bool changed = true;
    while (changed) {
      changed = false;
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final int idx = y * width + x;
          if (directions[idx] != 0) continue;
          if (dem.isNoData(dem.values[idx])) continue;

          // Look for a neighbor that already has a direction and is at the same elevation
          for (int i = 0; i < 8; i++) {
            final int nx = x + _dx[i];
            final int ny = y + _dy[i];
            if (nx < 0 || nx >= width || ny < 0 || ny >= height) continue;

            if (dem.values[ny * width + nx] <= dem.values[idx] && directions[ny * width + nx] != 0) {
                directions[idx] = _d8Codes[i].toDouble();
                changed = true;
                break;
            }
          }
        }
      }
    }

    return RasterData(
      width: width,
      height: height,
      cellWidth: dem.cellWidth,
      cellHeight: dem.cellHeight,
      origin: dem.origin,
      crs: dem.crs,
      values: directions,
      noDataValue: dem.noDataValue,
      units: 'D8 Code',
      metadata: {
        ...dem.metadata,
        'hydrology_product': HydrologicalProductType.flowDirection.name,
      },
    );
  }

  /// Calculates Flow Accumulation.
  RasterData calculateFlowAccumulation(RasterData flowDir) {
    final int width = flowDir.width;
    final int height = flowDir.height;
    final List<double> accumulation = List<double>.filled(width * height, 1.0);
    final List<int> inDegree = List<int>.filled(width * height, 0);

    for (int i = 0; i < width * height; i++) {
      if (flowDir.isNoData(flowDir.values[i])) {
        accumulation[i] = flowDir.noDataValue;
        continue;
      }
      final int nextIdx = _getDownstreamIndex(i, flowDir.values[i].toInt(), width, height);
      if (nextIdx != -1 && nextIdx != i) inDegree[nextIdx]++;
    }

    final Queue<int> queue = Queue<int>();
    for (int i = 0; i < width * height; i++) {
      if (!flowDir.isNoData(flowDir.values[i]) && inDegree[i] == 0) queue.add(i);
    }

    while (queue.isNotEmpty) {
      final int currIdx = queue.removeFirst();
      final int nextIdx = _getDownstreamIndex(currIdx, flowDir.values[currIdx].toInt(), width, height);
      if (nextIdx != -1 && nextIdx != currIdx) {
        accumulation[nextIdx] += accumulation[currIdx];
        inDegree[nextIdx]--;
        if (inDegree[nextIdx] == 0) queue.add(nextIdx);
      }
    }

    return RasterData(
      width: width,
      height: height,
      cellWidth: flowDir.cellWidth,
      cellHeight: flowDir.cellHeight,
      origin: flowDir.origin,
      crs: flowDir.crs,
      values: accumulation,
      noDataValue: flowDir.noDataValue,
      units: 'cells',
      metadata: {
        ...flowDir.metadata,
        'hydrology_product': HydrologicalProductType.flowAccumulation.name,
      },
    );
  }

  /// Extracts streams based on threshold.
  RasterData extractStreams(RasterData accumulation, double threshold) {
    final List<double> streams = accumulation.values.map((v) {
      if (accumulation.isNoData(v)) return accumulation.noDataValue;
      return v >= threshold ? 1.0 : 0.0;
    }).toList();
    return RasterData(
      width: accumulation.width, height: accumulation.height,
      cellWidth: accumulation.cellWidth, cellHeight: accumulation.cellHeight,
      origin: accumulation.origin, crs: accumulation.crs,
      values: streams, noDataValue: accumulation.noDataValue,
      units: 'binary',
      metadata: {
        ...accumulation.metadata,
        'hydrology_product': HydrologicalProductType.streamRaster.name,
        'threshold': threshold,
      },
    );
  }

  /// Calculates Strahler Order.
  RasterData calculateStrahlerOrder(RasterData flowDir, RasterData streamRaster) {
    final int w = flowDir.width;
    final int h = flowDir.height;
    final List<double> orders = List<double>.filled(w * h, 0.0);
    final List<int> inDegree = List<int>.filled(w * h, 0);
    final List<List<int>> upstreamSources = List.generate(w * h, (_) => []);

    for (int i = 0; i < w * h; i++) {
      if (streamRaster.values[i] != 1.0) {
        orders[i] = streamRaster.noDataValue;
        continue;
      }
      final int nextIdx = _getDownstreamIndex(i, flowDir.values[i].toInt(), w, h);
      if (nextIdx != -1 && streamRaster.values[nextIdx] == 1.0) {
        inDegree[nextIdx]++;
        upstreamSources[nextIdx].add(i);
      }
    }

    final Queue<int> queue = Queue<int>();
    for (int i = 0; i < w * h; i++) {
      if (streamRaster.values[i] == 1.0 && inDegree[i] == 0) {
        orders[i] = 1.0;
        queue.add(i);
      }
    }

    while (queue.isNotEmpty) {
      final int currIdx = queue.removeFirst();
      final int nextIdx = _getDownstreamIndex(currIdx, flowDir.values[currIdx].toInt(), w, h);

      if (nextIdx != -1 && streamRaster.values[nextIdx] == 1.0) {
        inDegree[nextIdx]--;
        if (inDegree[nextIdx] == 0) {
          final List<double> upOrders = upstreamSources[nextIdx].map((idx) => orders[idx]).toList();
          double maxOrder = upOrders.fold(0.0, math.max);
          int countMax = upOrders.where((o) => o == maxOrder).length;
          orders[nextIdx] = countMax > 1 ? maxOrder + 1 : maxOrder;
          queue.add(nextIdx);
        }
      }
    }

    return RasterData(
      width: w, height: h,
      cellWidth: flowDir.cellWidth, cellHeight: flowDir.cellHeight,
      origin: flowDir.origin, crs: flowDir.crs,
      values: orders, noDataValue: streamRaster.noDataValue,
      units: 'order',
      metadata: {
        ...flowDir.metadata,
        'hydrology_product': HydrologicalProductType.strahlerOrder.name,
      },
    );
  }

  /// Calculates Shreve Magnitude.
  RasterData calculateShreveMagnitude(RasterData flowDir, RasterData streamRaster) {
    final int w = flowDir.width;
    final int h = flowDir.height;
    final List<double> magnitudes = List<double>.filled(w * h, 0.0);
    final List<int> inDegree = List<int>.filled(w * h, 0);

    for (int i = 0; i < w * h; i++) {
      if (streamRaster.values[i] != 1.0) {
        magnitudes[i] = streamRaster.noDataValue;
        continue;
      }
      final int nextIdx = _getDownstreamIndex(i, flowDir.values[i].toInt(), w, h);
      if (nextIdx != -1 && streamRaster.values[nextIdx] == 1.0) inDegree[nextIdx]++;
    }

    final Queue<int> queue = Queue<int>();
    for (int i = 0; i < w * h; i++) {
      if (streamRaster.values[i] == 1.0 && inDegree[i] == 0) {
        magnitudes[i] = 1.0;
        queue.add(i);
      }
    }

    while (queue.isNotEmpty) {
      final int currIdx = queue.removeFirst();
      final int nextIdx = _getDownstreamIndex(currIdx, flowDir.values[currIdx].toInt(), w, h);
      if (nextIdx != -1 && streamRaster.values[nextIdx] == 1.0) {
        magnitudes[nextIdx] += magnitudes[currIdx];
        inDegree[nextIdx]--;
        if (inDegree[nextIdx] == 0) queue.add(nextIdx);
      }
    }

    return RasterData(
      width: w, height: h,
      cellWidth: flowDir.cellWidth, cellHeight: flowDir.cellHeight,
      origin: flowDir.origin, crs: flowDir.crs,
      values: magnitudes, noDataValue: streamRaster.noDataValue,
      units: 'magnitude',
      metadata: {
        ...flowDir.metadata,
        'hydrology_product': HydrologicalProductType.shreveMagnitude.name,
      },
    );
  }

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
}
