import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/gis/raster_data.dart';

/// Error categories for research data providers.
enum DataProviderErrorType {
  invalidRequest,
  networkFailure,
  unauthorized,
  quotaExceeded,
  datasetUnavailable,
  invalidRasterData,
  unsupportedFormat,
}

/// Strongly typed error container for research data provider failures.
@immutable
class DataProviderError {
  final DataProviderErrorType type;
  final String message;
  final String? providerId;

  const DataProviderError({
    required this.type,
    required this.message,
    this.providerId,
  });

  @override
  String toString() => 'DataProviderError($type, $message, providerId: $providerId)';
}

/// Immutable result object returned by research data providers.
@immutable
class DataProviderResult<T> {
  final bool isSuccess;
  final T? data;
  final DataProviderError? error;
  final DateTime timestamp;

  const DataProviderResult._({
    required this.isSuccess,
    this.data,
    this.error,
    required this.timestamp,
  });

  factory DataProviderResult.success(T data, {DateTime? timestamp}) {
    return DataProviderResult._(
      isSuccess: true,
      data: data,
      error: null,
      timestamp: timestamp ?? DateTime.now(),
    );
  }

  factory DataProviderResult.failure(DataProviderError error, {DateTime? timestamp}) {
    return DataProviderResult._(
      isSuccess: false,
      data: null,
      error: error,
      timestamp: timestamp ?? DateTime.now(),
    );
  }
}

/// Abstract contract interface for external research data providers.
///
/// Providers supply authoritative research datasets (e.g. DEMs) into RiskPulse.
///
/// This domain contract contains ZERO Flutter UI, ZERO GEE credentials, and ZERO HTTP logic.
abstract class ResearchDataProvider {
  /// Provider unique identity (e.g. "gee", "opentopography", "local_file").
  String get providerId;

  /// Provider human-readable display name.
  String get displayName;

  /// Requests a genuine DEM raster dataset for the specified spatial extent.
  Future<DataProviderResult<RasterData>> fetchDem({
    required MapExtent extent,
    double resolutionMeters = 30.0,
    String? datasetId,
  });
}
