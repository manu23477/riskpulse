import 'dart:math' as math;
import 'package:riskpulse/domain/gis/raster_data.dart';
import 'package:riskpulse/domain/gis/watershed.dart';
import 'package:riskpulse/domain/gis/drainage_network.dart';
import 'package:riskpulse/domain/gis/morphometric_result.dart';
import 'package:riskpulse/domain/location/geo_location.dart';

class MorphometricAnalysisService {
  
  MorphometricResult analyze({
    required Watershed watershed,
    required DrainageNetwork network,
    required RasterData dem,
  }) {
    final mask = watershed.mask;

    // 1. Filter segments belonging to this watershed
    final watershedSegments = network.segments.where((seg) {
      // A segment belongs to the watershed if its downstream node is within the mask
      final endPoint = seg.polyline.last;
      return _isLocationInMask(endPoint, mask);
    }).toList();

    // 2. Linear Morphometry
    final Map<int, int> streamCounts = {};
    final Map<int, double> totalLengths = {};
    
    for (var seg in watershedSegments) {
      final order = seg.strahlerOrder.round();
      streamCounts[order] = (streamCounts[order] ?? 0) + 1;
      totalLengths[order] = (totalLengths[order] ?? 0.0) + (seg.length / 1000.0); // Convert m to km
    }

    final Map<int, double> meanLengths = {};
    streamCounts.forEach((order, count) {
      meanLengths[order] = count > 0 ? totalLengths[order]! / count : 0.0;
    });

    final Map<int, double> bifurcationRatios = {};
    final List<int> sortedOrders = streamCounts.keys.toList()..sort();
    for (int i = 0; i < sortedOrders.length - 1; i++) {
      final u = sortedOrders[i];
      final uNext = sortedOrders[i+1];
      if (streamCounts.containsKey(uNext) && streamCounts[uNext]! > 0) {
        bifurcationRatios[u] = streamCounts[u]! / streamCounts[uNext]!;
      }
    }

    double meanRb = 0.0;
    if (bifurcationRatios.isNotEmpty) {
      meanRb = bifurcationRatios.values.reduce((a, b) => a + b) / bifurcationRatios.length;
    }

    // 3. Perimeter Calculation (Edge Counting)
    final perimeterStats = _calculatePerimeter(mask);
    final double perimeterKm = perimeterStats.perimeterM / 1000.0;

    // 4. Basin Length calculation
    final double basinLengthKm = _calculateBasinLength(watershed.pourPointLocation, perimeterStats.edgeCells, mask) / 1000.0;

    // 5. Relief Morphometry
    final reliefStats = _calculateRelief(mask, dem);

    // 6. Areal Morphometry
    final double totalStreamLengthKm = totalLengths.values.fold(0.0, (a, b) => a + b);
    final int totalStreamCount = streamCounts.values.fold(0, (a, b) => a + b);
    
    final double areaKm2 = watershed.areaKm2 > 0 ? watershed.areaKm2 : 1e-9; // Avoid div by zero
    final double drainageDensity = totalStreamLengthKm / areaKm2;
    final double streamFrequency = totalStreamCount / areaKm2;
    
    // Circularity Ratio: 4 * pi * A / P^2
    final double circularityRatio = perimeterKm > 0 
        ? (4.0 * math.pi * areaKm2) / (perimeterKm * perimeterKm)
        : 0.0;
        
    // Elongation Ratio: (2/Lb) * sqrt(A/pi)
    final double elongationRatio = basinLengthKm > 0
        ? (2.0 / basinLengthKm) * math.sqrt(areaKm2 / math.pi)
        : 0.0;

    final double reliefRatio = basinLengthKm > 0 
        ? reliefStats.basinRelief / (basinLengthKm * 1000.0) 
        : 0.0;

    return MorphometricResult(
      watershedId: watershed.id,
      streamCountsByOrder: streamCounts,
      totalStreamLengthByOrder: totalLengths,
      meanStreamLengthByOrder: meanLengths,
      bifurcationRatios: bifurcationRatios,
      meanBifurcationRatio: meanRb,
      areaKm2: watershed.areaKm2,
      perimeterKm: perimeterKm,
      drainageDensity: drainageDensity,
      streamFrequency: streamFrequency,
      circularityRatio: circularityRatio,
      elongationRatio: elongationRatio,
      basinLengthKm: basinLengthKm,
      maxElevation: reliefStats.maxZ,
      minElevation: reliefStats.minZ,
      basinRelief: reliefStats.basinRelief,
      reliefRatio: reliefRatio,
      ruggednessNumber: (drainageDensity * reliefStats.basinRelief) / 1000.0,
      metadata: {
        'conventions': 'Schumm (1956), Horton (1945), Strahler (1952)',
        'perimeter_method': 'Raster Edge Counting',
        'basin_length_method': 'Pour Point to Furthest Perimeter Cell',
      },
    );
  }

  bool _isLocationInMask(GeoLocation loc, RasterData mask) {
    final double dx = loc.longitude - mask.origin.longitude;
    final double dy = mask.origin.latitude - loc.latitude;
    final int x = (dx / mask.cellWidth).floor();
    final int y = (dy / mask.cellHeight).floor();
    if (x < 0 || x >= mask.width || y < 0 || y >= mask.height) return false;
    return mask.values[y * mask.width + x] == 1.0;
  }

  _PerimeterResult _calculatePerimeter(RasterData mask) {
    double totalP = 0.0;
    final List<int> edgeCells = [];
    final int w = mask.width;
    final int h = mask.height;

    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final int idx = y * w + x;
        if (mask.values[idx] != 1.0) continue;

        bool isEdge = false;
        
        // North
        if (y == 0 || mask.values[(y - 1) * w + x] != 1.0) {
          totalP += _getMetricCellWidth(x, y, mask);
          isEdge = true;
        }
        // South
        if (y == h - 1 || mask.values[(y + 1) * w + x] != 1.0) {
          totalP += _getMetricCellWidth(x, y, mask);
          isEdge = true;
        }
        // West
        if (x == 0 || mask.values[y * w + (x - 1)] != 1.0) {
          totalP += _getMetricCellHeight(mask);
          isEdge = true;
        }
        // East
        if (x == w - 1 || mask.values[y * w + (x + 1)] != 1.0) {
          totalP += _getMetricCellHeight(mask);
          isEdge = true;
        }

        if (isEdge) edgeCells.add(idx);
      }
    }
    return _PerimeterResult(totalP, edgeCells);
  }

  double _calculateBasinLength(GeoLocation pourPoint, List<int> perimeterCells, RasterData mask) {
    if (perimeterCells.isEmpty) return 0.0;
    double maxDist = 0.0;
    for (var idx in perimeterCells) {
      final loc = _getCellLocation(idx, mask);
      final d = _distance(pourPoint, loc, mask);
      if (d > maxDist) maxDist = d;
    }
    return maxDist;
  }

  _ReliefResult _calculateRelief(RasterData mask, RasterData dem) {
    double maxZ = -double.maxFinite;
    double minZ = double.maxFinite;
    bool found = false;

    for (int i = 0; i < mask.values.length; i++) {
      if (mask.values[i] == 1.0 && !dem.isNoData(dem.values[i])) {
        if (dem.values[i] > maxZ) maxZ = dem.values[i];
        if (dem.values[i] < minZ) minZ = dem.values[i];
        found = true;
      }
    }

    if (!found) return _ReliefResult(0, 0, 0);
    return _ReliefResult(maxZ, minZ, maxZ - minZ);
  }

  // Metric scaling helpers
  double _getMetricCellWidth(int x, int y, RasterData raster) {
    if (raster.crs.code == 'EPSG:4326') {
      double lat = raster.origin.latitude - (y * raster.cellHeight);
      return raster.cellWidth * 111320.0 * math.cos(lat * math.pi / 180.0);
    }
    return raster.cellWidth;
  }

  double _getMetricCellHeight(RasterData raster) {
    if (raster.crs.code == 'EPSG:4326') {
      return raster.cellHeight * 111320.0;
    }
    return raster.cellHeight;
  }

  GeoLocation _getCellLocation(int idx, RasterData raster) {
    int x = idx % raster.width;
    int y = idx ~/ raster.width;
    return GeoLocation(
      longitude: raster.origin.longitude + (x * raster.cellWidth) + (raster.cellWidth / 2.0),
      latitude: raster.origin.latitude - (y * raster.cellHeight) - (raster.cellHeight / 2.0),
    );
  }

  double _distance(GeoLocation p1, GeoLocation p2, RasterData raster) {
    if (raster.crs.code == 'EPSG:4326') {
      final double latMid = (p1.latitude + p2.latitude) / 2.0;
      final double dy = (p1.latitude - p2.latitude).abs() * 111320;
      final double dx = (p1.longitude - p2.longitude).abs() * 111320 * math.cos(latMid * math.pi / 180.0);
      return math.sqrt(dx * dx + dy * dy);
    }
    final double dx = p1.longitude - p2.longitude;
    final double dy = p1.latitude - p2.latitude;
    return math.sqrt(dx * dx + dy * dy);
  }
}

class _PerimeterResult {
  final double perimeterM;
  final List<int> edgeCells;
  _PerimeterResult(this.perimeterM, this.edgeCells);
}

class _ReliefResult {
  final double maxZ;
  final double minZ;
  final double basinRelief;
  _ReliefResult(this.maxZ, this.minZ, this.basinRelief);
}
