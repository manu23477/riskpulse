import 'package:flutter/foundation.dart';
import '../../../domain/gis/import/import_data_models.dart';

/// Immutable container holding structured parse results or parsing failure details.
@immutable
class FormatImportResult<T extends BaseImportData> {
  final T? data;
  final bool isSuccess;
  final String? errorMessage;

  const FormatImportResult.success(this.data)
      : isSuccess = true,
        errorMessage = null;

  const FormatImportResult.failure(this.errorMessage)
      : isSuccess = false,
        data = null;
}

/// Generic adapter for decoding raw binary file bytes into a strictly typed 
/// intermediate domain model (Tabular, Vector, or Raster).
/// 
/// FormatAdapters MUST NOT:
/// - Perform administrative or thematic classification.
/// - Apply implicit GIS coordinate transformations without explicit recording.
/// - Modify geometries structurally to fit base maps.
/// - Include Flutter UI dependencies.
abstract class FormatAdapter<T extends BaseImportData> {
  /// Parses the incoming bytes according to the adapter's specific format logic.
  Future<FormatImportResult<T>> parse(Uint8List bytes, {required String filename});
}
