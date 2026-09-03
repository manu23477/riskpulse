import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/gis/raster_data.dart';
import 'package:riskpulse/domain/gis/research_product.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';

/// Supported formats for raster export operations.
enum RasterExportFormat {
  geoTiff,
}

/// Explicit numeric precision policies for raster export.
enum NumericExportPolicy {
  preserveSource,
  float64,
  float32,
}

/// Specific error conditions for raster export contract validation and execution.
enum RasterExportErrorType {
  productUnavailable,
  invalidRequest,
  unsupportedFormat,
  missingRasterData,
  unsupportedCrs,
  unsupportedNumericPolicy,
  exportFailed,
}

/// Strongly typed error container for raster export failures.
@immutable
class RasterExportError {
  final RasterExportErrorType type;
  final String message;
  final String? productId;

  const RasterExportError({
    required this.type,
    required this.message,
    this.productId,
  });

  @override
  String toString() => 'RasterExportError($type, $message, productId: $productId)';
}

/// Immutable export request representing the intention to export a specific raster product.
///
/// Refers directly to the authoritative [ResearchProduct] without duplicating raster values.
@immutable
class RasterExportRequest {
  final ResearchProduct product;
  final RasterExportFormat format;
  final NumericExportPolicy numericPolicy;
  final DateTime requestedAt;

  const RasterExportRequest({
    required this.product,
    this.format = RasterExportFormat.geoTiff,
    this.numericPolicy = NumericExportPolicy.preserveSource,
    required this.requestedAt,
  });

  /// Resolves the authoritative [RasterData] from the underlying product reference.
  /// Returns null if the source data is missing or not a [RasterData] instance.
  RasterData? get authoritativeRaster {
    final source = product.sourceData;
    return source is RasterData ? source : null;
  }

  /// Authoritative CRS derived directly from the underlying [RasterData].
  CoordinateReferenceSystem? get crs => authoritativeRaster?.crs;

  /// Authoritative NoData value derived directly from the underlying [RasterData].
  double? get noDataValue => authoritativeRaster?.noDataValue;

  /// Returns true if the product is available and holds a genuine [RasterData] instance.
  bool get isAvailable => product.isAvailable && authoritativeRaster != null;

  /// Returns true if the product belongs to the raster category.
  bool get isRasterCategory => product.category == ResearchProductCategory.raster;

  /// Product identifier preserved directly from the research product.
  String get productId => product.id;

  /// Provenance step name preserved directly from the research product.
  String? get provenanceStepName => product.provenanceStepName;
}

/// Immutable result object representing the deterministic outcome of a raster export validation or future operation.
@immutable
class RasterExportResult {
  final bool isSuccess;
  final RasterExportRequest request;
  final Uint8List? bytes;
  final RasterExportError? error;
  final DateTime completedAt;

  const RasterExportResult._({
    required this.isSuccess,
    required this.request,
    this.bytes,
    this.error,
    required this.completedAt,
  });

  /// Factory constructor for a successful export validation/execution.
  factory RasterExportResult.success({
    required RasterExportRequest request,
    Uint8List? bytes,
    DateTime? completedAt,
  }) {
    return RasterExportResult._(
      isSuccess: true,
      request: request,
      bytes: bytes,
      error: null,
      completedAt: completedAt ?? DateTime.now(),
    );
  }

  /// Factory constructor for a failed export validation/execution.
  factory RasterExportResult.failure({
    required RasterExportRequest request,
    required RasterExportError error,
    DateTime? completedAt,
  }) {
    return RasterExportResult._(
      isSuccess: false,
      request: request,
      bytes: null,
      error: error,
      completedAt: completedAt ?? DateTime.now(),
    );
  }
}
