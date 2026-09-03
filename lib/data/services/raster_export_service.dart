import 'dart:typed_data';
import 'package:riskpulse/domain/gis/raster_export_contract.dart';
import 'package:riskpulse/domain/gis/research_product.dart';
import 'package:riskpulse/data/services/geotiff_writer.dart';

/// Platform-independent service contract for validating and coordinating raster exports.
///
/// This service performs ZERO GIS calculations, ZERO file filesystem I/O, and ZERO UI operations.
class RasterExportService {
  final GeoTiffWriter _writer;

  RasterExportService({GeoTiffWriter? writer})
      : _writer = writer ?? GeoTiffWriter();

  /// Validates a [RasterExportRequest] against the authoritative research product state.
  ///
  /// Distinguishes between:
  /// - Product unavailable ([RasterExportErrorType.productUnavailable])
  /// - Invalid request ([RasterExportErrorType.invalidRequest])
  /// - Unsupported format ([RasterExportErrorType.unsupportedFormat])
  /// - Missing raster data ([RasterExportErrorType.missingRasterData])
  RasterExportResult validateRequest(RasterExportRequest request) {
    final product = request.product;

    // 1. Availability check
    if (!product.isAvailable) {
      return RasterExportResult.failure(
        request: request,
        error: RasterExportError(
          type: RasterExportErrorType.productUnavailable,
          message: 'Product "${product.id}" (${product.name}) is unavailable or has not been generated.',
          productId: product.id,
        ),
      );
    }

    // 2. Category check
    if (product.category != ResearchProductCategory.raster) {
      return RasterExportResult.failure(
        request: request,
        error: RasterExportError(
          type: RasterExportErrorType.invalidRequest,
          message: 'Product "${product.id}" is of category ${product.category.name}, not raster.',
          productId: product.id,
        ),
      );
    }

    // 3. Authoritative RasterData check
    final raster = request.authoritativeRaster;
    if (raster == null) {
      return RasterExportResult.failure(
        request: request,
        error: RasterExportError(
          type: RasterExportErrorType.missingRasterData,
          message: 'Product "${product.id}" has no authoritative RasterData bound to sourceData.',
          productId: product.id,
        ),
      );
    }

    // 4. Format support check
    final isFormatSupported = product.supportedExportFormats.any(
      (fmt) => fmt.name == request.format.name,
    );
    if (!isFormatSupported) {
      return RasterExportResult.failure(
        request: request,
        error: RasterExportError(
          type: RasterExportErrorType.unsupportedFormat,
          message: 'Format ${request.format.name} is not in supported export formats for product "${product.id}".',
          productId: product.id,
        ),
      );
    }

    // 5. Dimension integrity check
    if (raster.width <= 0 || raster.height <= 0 || raster.values.length != raster.width * raster.height) {
      return RasterExportResult.failure(
        request: request,
        error: RasterExportError(
          type: RasterExportErrorType.invalidRequest,
          message: 'Product "${product.id}" has invalid raster dimensions or buffer length (${raster.width}x${raster.height}, len: ${raster.values.length}).',
          productId: product.id,
        ),
      );
    }

    // 6. Valid contract request
    return RasterExportResult.success(
      request: request,
    );
  }

  /// Executes raster export for a valid [RasterExportRequest], returning encoded bytes on success.
  RasterExportResult export(RasterExportRequest request) {
    final validation = validateRequest(request);
    if (!validation.isSuccess) {
      return validation;
    }

    final raster = request.authoritativeRaster!;

    try {
      if (request.format == RasterExportFormat.geoTiff) {
        final Uint8List bytes = _writer.encode(
          raster,
          numericPolicy: request.numericPolicy,
          description: '${request.product.name} (${request.product.id})',
        );
        return RasterExportResult.success(
          request: request,
          bytes: bytes,
        );
      } else {
        return RasterExportResult.failure(
          request: request,
          error: RasterExportError(
            type: RasterExportErrorType.unsupportedFormat,
            message: 'Unsupported export format: ${request.format.name}.',
            productId: request.product.id,
          ),
        );
      }
    } catch (e) {
      return RasterExportResult.failure(
        request: request,
        error: RasterExportError(
          type: RasterExportErrorType.exportFailed,
          message: 'Raster export encoding failed: $e',
          productId: request.product.id,
        ),
      );
    }
  }
}
