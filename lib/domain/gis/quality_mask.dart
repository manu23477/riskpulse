import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/location/geo_location.dart';

/// Categorical pixel state classification for remote sensing quality masking.
enum QualityPixelState {
  valid,
  cloud,
  cirrus,
  cloudShadow,
  defective,
  noData,
}

/// Provider-neutral, immutable quality mask grid representing valid vs invalid/cloudy pixels.
@immutable
class QualityMask {
  final int width;
  final int height;
  final double cellWidth;
  final double cellHeight;
  final GeoLocation origin;
  final CoordinateReferenceSystem crs;
  final List<QualityPixelState> maskStates;
  final String qualitySource;
  final Map<String, dynamic> metadata;

  const QualityMask({
    required this.width,
    required this.height,
    required this.cellWidth,
    required this.cellHeight,
    required this.origin,
    required this.crs,
    required this.maskStates,
    required this.qualitySource,
    this.metadata = const {},
  });

  int get totalPixels => width * height;

  int get validPixels => maskStates.where((s) => s == QualityPixelState.valid).length;

  int get maskedPixels => totalPixels - validPixels;

  double get validPercentage => totalPixels == 0 ? 0.0 : (validPixels / totalPixels) * 100.0;

  double get maskedPercentage => totalPixels == 0 ? 0.0 : (maskedPixels / totalPixels) * 100.0;

  bool isValid(int index) {
    if (index < 0 || index >= maskStates.length) return false;
    return maskStates[index] == QualityPixelState.valid;
  }

  bool isMasked(int index) => !isValid(index);

  bool isValidAt(int x, int y) {
    if (x < 0 || x >= width || y < 0 || y >= height) return false;
    return isValid(y * width + x);
  }
}
