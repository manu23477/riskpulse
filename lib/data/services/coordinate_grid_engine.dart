import 'dart:math' as math;
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/gis/cartographic_element_config.dart';

class GridLine {
  final double value;
  final String label;
  final bool isLatitude;

  const GridLine(this.value, this.label, this.isLatitude);
}

class CoordinateGridData {
  final List<GridLine> parallels;
  final List<GridLine> meridians;
  final double interval;

  const CoordinateGridData({
    required this.parallels,
    required this.meridians,
    required this.interval,
  });
}

/// Engine responsible for calculating geographic grid lines and labels.
class CoordinateGridEngine {
  
  CoordinateGridData generateGrid({
    required MapExtent extent, 
    required CoordinateGridConfig config,
  }) {
    double interval = config.intervalDegrees;
    if (interval <= 0) {
      interval = _calculateDynamicInterval(extent);
    }

    final parallels = _generateLines(
      extent.southWest.latitude, 
      extent.northEast.latitude, 
      interval, 
      true, 
      config.format,
    );
    
    final meridians = _generateLines(
      extent.southWest.longitude, 
      extent.northEast.longitude, 
      interval, 
      false, 
      config.format,
    );

    return CoordinateGridData(
      parallels: parallels, 
      meridians: meridians, 
      interval: interval,
    );
  }

  double _calculateDynamicInterval(MapExtent extent) {
    final double latSpan = (extent.northEast.latitude - extent.southWest.latitude).abs();
    final double lonSpan = (extent.northEast.longitude - extent.southWest.longitude).abs();
    final double span = math.max(latSpan, lonSpan);

    // Standard geographic intervals
    if (span > 20) return 10.0;
    if (span > 10) return 5.0;
    if (span > 5) return 2.0;
    if (span > 2) return 1.0;
    if (span > 1) return 0.5; // 30'
    if (span > 0.5) return 0.25; // 15'
    if (span > 0.1) return 0.1; // 6'
    if (span > 0.05) return 0.05; // 3'
    if (span > 0.01) return 0.01; // 36"
    return 0.005; // 18"
  }

  List<GridLine> _generateLines(double min, double max, double interval, bool isLat, CoordinateFormat format) {
    final List<GridLine> lines = [];
    
    // Ensure we find the first multiple of interval below or equal to min
    double start = (min / interval).floor() * interval;
    
    // Iterate until we pass max
    for (double v = start; v <= max + (interval * 0.1); v += interval) {
      if (v >= min - (interval * 0.1) && v <= max + (interval * 0.1)) {
        lines.add(GridLine(v, _formatCoordinate(v, isLat, format), isLat));
      }
    }
    return lines;
  }

  String _formatCoordinate(double value, bool isLat, CoordinateFormat format) {
    if (format == CoordinateFormat.decimal) {
      String suffix = isLat ? (value >= 0 ? 'N' : 'S') : (value >= 0 ? 'E' : 'W');
      return '${value.abs().toStringAsFixed(3)}° $suffix';
    } else {
      return _toDMS(value, isLat);
    }
  }

  String _toDMS(double value, bool isLat) {
    double absVal = value.abs();
    int d = absVal.floor();
    double mFull = (absVal - d) * 60;
    int m = mFull.floor();
    double s = (mFull - m) * 60;
    String suffix = isLat ? (value >= 0 ? 'N' : 'S') : (value >= 0 ? 'E' : 'W');
    
    if (s.round() == 60) {
      s = 0;
      m++;
    }
    if (m == 60) {
      m = 0;
      d++;
    }

    return "$d°$m′${s.toStringAsFixed(0)}″ $suffix";
  }
}
