import 'package:flutter/foundation.dart';

/// Immutable record of the origin, format, and spatial state of imported data.
/// Tracks data from the raw binary stage through interpretation and validation.
@immutable
class ImportProvenance {
  /// The original filename supplied during upload/import.
  final String originalFilename;

  /// The size of the original file in bytes, if available.
  final int? fileSizeBytes;

  /// The exact timestamp the import process was initiated.
  final DateTime importTimestamp;

  /// The format detected by the FormatDetector (e.g., "csv", "geojson").
  final String detectedFormat;

  /// Optional explicitly supplied source provider (e.g., "USGS", "SDMA").
  final String? sourceProvider;

  /// The Coordinate Reference System exactly as declared in the source.
  /// If null, the source CRS is explicitly UNKNOWN. 
  /// Do not silently assume EPSG:4326.
  final String? sourceCrs;

  /// Whether the geometries were transformed from their source CRS during import.
  final bool isTransformed;

  /// Details of the spatial transformation applied, if any.
  final String? transformationDetails;

  /// Validation counts/flags accumulated during parsing and structural validation.
  final Map<String, dynamic> validationSummary;

  /// The user-selected or auto-inferred spatial interpretation applied to this data 
  /// (e.g., "administrative_join", "point_coordinates", "raster_extent").
  final String? spatialInterpretation;

  /// The identifier/version of the FormatAdapter that parsed the raw bytes.
  final String parserIdentity;

  const ImportProvenance({
    required this.originalFilename,
    this.fileSizeBytes,
    required this.importTimestamp,
    required this.detectedFormat,
    this.sourceProvider,
    this.sourceCrs,
    this.isTransformed = false,
    this.transformationDetails,
    this.validationSummary = const {},
    this.spatialInterpretation,
    required this.parserIdentity,
  });
}
