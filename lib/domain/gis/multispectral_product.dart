import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/gis/raster_data.dart';
import 'package:riskpulse/domain/gis/remote_sensing_band.dart';

/// Immutable model representing a multispectral remote sensing product acquisition.
@immutable
class MultispectralProduct {
  final String productId;
  final String providerId;
  final String datasetId;
  final DateTime acquisitionDate;
  final CoordinateReferenceSystem crs;
  final MapExtent extent;
  final double? cloudCoverPercentage;
  final List<RemoteSensingBand> bands;
  final Map<String, RasterData> bandRasters;
  final Map<String, dynamic> metadata;

  const MultispectralProduct({
    required this.productId,
    required this.providerId,
    required this.datasetId,
    required this.acquisitionDate,
    required this.crs,
    required this.extent,
    this.cloudCoverPercentage,
    required this.bands,
    required this.bandRasters,
    this.metadata = const {},
  });

  /// Retrieves the single-band [RasterData] for a specified band ID (e.g. 'B4', 'B8').
  RasterData? getBandRaster(String bandId) => bandRasters[bandId];

  /// Retrieves the [RemoteSensingBand] definition for a specified band ID.
  RemoteSensingBand? getBandDefinition(String bandId) {
    try {
      return bands.firstWhere((b) => b.bandId == bandId);
    } catch (_) {
      return null;
    }
  }

  /// True if the specified band ID is present in this product.
  bool hasBand(String bandId) => bandRasters.containsKey(bandId);
}
