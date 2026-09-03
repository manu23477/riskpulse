import 'package:flutter/foundation.dart';

enum ResearchProductType {
  dem,
  slope,
  aspect,
  hillshade,
  filledDem,
  flowDirection,
  flowAccumulation,
  streamRaster,
  strahlerOrder,
  shreveMagnitude,
  drainageNetwork,
  watershed,
  subWatersheds,
  pourPoint,
  morphometricResults,
  studyArea,
}

enum ResearchProductAvailability {
  available,
  unavailable,
}

enum ResearchProductCategory {
  raster,
  vector,
  tabular,
  spatialContext,
}

enum ResearchProductFormat {
  geoTiff,
  geoJson,
  csv,
  json,
}

/// Represents a single research product in the Research GIS inventory.
///
/// This is a derived, immutable representation that links analytical outputs
/// with their metadata and future export capability declarations without
/// mutating or duplicating the underlying GIS data.
@immutable
class ResearchProduct {
  final String id;
  final String name;
  final ResearchProductType type;
  final ResearchProductCategory category;
  final ResearchProductAvailability availability;
  final List<ResearchProductFormat> supportedExportFormats;
  final String? crsCode;
  final String? units;
  final ({int width, int height})? dimensions;
  final int? featureCount;
  final double? areaKm2;
  final String? provenanceStepName;
  final Map<String, dynamic> metadata;

  /// Typed lightweight reference to the underlying analytical object
  /// (e.g., [RasterData], [DrainageNetwork], [Watershed], [MorphometricResult]).
  final Object? sourceData;

  const ResearchProduct({
    required this.id,
    required this.name,
    required this.type,
    required this.category,
    required this.availability,
    required this.supportedExportFormats,
    this.crsCode,
    this.units,
    this.dimensions,
    this.featureCount,
    this.areaKm2,
    this.provenanceStepName,
    this.metadata = const {},
    this.sourceData,
  });

  bool get isAvailable => availability == ResearchProductAvailability.available;

  ResearchProduct copyWith({
    String? id,
    String? name,
    ResearchProductType? type,
    ResearchProductCategory? category,
    ResearchProductAvailability? availability,
    List<ResearchProductFormat>? supportedExportFormats,
    String? crsCode,
    String? units,
    ({int width, int height})? dimensions,
    int? featureCount,
    double? areaKm2,
    String? provenanceStepName,
    Map<String, dynamic>? metadata,
    Object? sourceData,
  }) {
    return ResearchProduct(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      category: category ?? this.category,
      availability: availability ?? this.availability,
      supportedExportFormats: supportedExportFormats ?? this.supportedExportFormats,
      crsCode: crsCode ?? this.crsCode,
      units: units ?? this.units,
      dimensions: dimensions ?? this.dimensions,
      featureCount: featureCount ?? this.featureCount,
      areaKm2: areaKm2 ?? this.areaKm2,
      provenanceStepName: provenanceStepName ?? this.provenanceStepName,
      metadata: metadata ?? this.metadata,
      sourceData: sourceData ?? this.sourceData,
    );
  }
}
