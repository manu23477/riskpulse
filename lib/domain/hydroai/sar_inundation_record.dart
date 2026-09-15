import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/gis/raster_data.dart';

/// Immutable domain model representing an independent Sentinel-1 SAR observed/inferred flood extent dataset.
@immutable
class SarInundationRecord {
  final String datasetId;
  final String satelliteName;
  final DateTime acquisitionTime;
  final MapExtent extent;
  final CoordinateReferenceSystem crs;
  final RasterData sarFloodMask; // Binary mask: 1.0 = Flooded, 0.0 = Non-Flooded
  final String polarization; // 'VV', 'VH'
  final String processingLevel; // 'GRD_HD'
  final Map<String, dynamic> metadata;

  SarInundationRecord({
    required this.datasetId,
    this.satelliteName = 'Sentinel-1A',
    required this.acquisitionTime,
    required this.extent,
    required this.crs,
    required this.sarFloodMask,
    this.polarization = 'VV',
    this.processingLevel = 'GRD_HD',
    this.metadata = const {},
  }) {
    if (datasetId.trim().isEmpty) {
      throw ArgumentError('datasetId cannot be empty.');
    }
  }

  int get width => sarFloodMask.width;
  int get height => sarFloodMask.height;
}
