import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';

/// Provider-neutral temporal and spatial query container for remote sensing products.
@immutable
class RemoteSensingQuery {
  final MapExtent extent;
  final DateTime startDate;
  final DateTime endDate;
  final double maxCloudCoverPercentage;
  final List<String> requestedBands;
  final String? datasetId;

  const RemoteSensingQuery({
    required this.extent,
    required this.startDate,
    required this.endDate,
    this.maxCloudCoverPercentage = 20.0,
    this.requestedBands = const ['B2', 'B3', 'B4', 'B8', 'B11', 'B12'],
    this.datasetId,
  });
}
