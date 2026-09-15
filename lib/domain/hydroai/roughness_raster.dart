import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/gis/raster_data.dart';

/// Provider-neutral hydraulic roughness raster ($Manning\ n$).
///
/// SCIENTIFIC GOVERNANCE:
/// NO default Manning coefficients are hardcoded in RiskPulse.
/// Values must be explicitly supplied by datasets or researcher input.
@immutable
class RoughnessRaster {
  final RasterData rasterData;
  final String sourceDescription;
  final String derivationMethod;

  const RoughnessRaster({
    required this.rasterData,
    this.sourceDescription = 'Researcher Supplied / Dataset Derived',
    this.derivationMethod = 'LULC Mapping / Direct Ingestion',
  });

  int get width => rasterData.width;
  int get height => rasterData.height;
  double get cellWidth => rasterData.cellWidth;
  double get cellHeight => rasterData.cellHeight;
  double getManningN(int x, int y) => rasterData.getValue(x, y);
}
