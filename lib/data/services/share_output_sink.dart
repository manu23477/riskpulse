import 'dart:typed_data';
import 'package:share_plus/share_plus.dart';
import 'package:riskpulse/domain/gis/research_output_sink.dart';

/// Handler function signature for dependency-injecting share execution.
typedef ShareXFilesHandler = Future<ShareResult> Function(
  List<XFile> files, {
  String? text,
  String? subject,
});

/// Factory signature for constructing cross-platform [XFile] containers.
typedef XFileFactory = XFile Function(Uint8List bytes, {String? name, String? mimeType});

/// Research output sink that delivers output files using the OS share sheet (`share_plus`).
///
/// This service performs NO GIS calculations, NO raster encoding, and NO domain mutations.
class ShareOutputSink implements ResearchOutputSink {
  final ShareXFilesHandler _shareHandler;
  final XFileFactory _xFileFactory;

  ShareOutputSink({
    ShareXFilesHandler? shareHandler,
    XFileFactory? xFileFactory,
  })  : _shareHandler = shareHandler ?? Share.shareXFiles,
        _xFileFactory = xFileFactory ?? _defaultXFileFactory;

  static XFile _defaultXFileFactory(Uint8List bytes, {String? name, String? mimeType}) {
    final safeName = (name == null || name.trim().isEmpty) ? 'output.bin' : name;
    try {
      final xf = XFile.fromData(bytes, name: safeName, mimeType: mimeType);
      // Validate property access on current platform
      final _ = xf.name;
      return xf;
    } catch (_) {
      return XFile(safeName, bytes: bytes, name: safeName, mimeType: mimeType);
    }
  }

  @override
  Future<OutputSinkResult> output({
    required Uint8List bytes,
    required String filename,
    required String mimeType,
    String? title,
  }) async {
    // 1. Validation
    if (bytes.isEmpty) {
      return OutputSinkResult.failure(
        error: const OutputSinkError(
          type: OutputSinkErrorType.emptyPayload,
          message: 'Output byte payload cannot be empty.',
        ),
      );
    }

    if (filename.trim().isEmpty || mimeType.trim().isEmpty) {
      return OutputSinkResult.failure(
        error: const OutputSinkError(
          type: OutputSinkErrorType.invalidData,
          message: 'Filename and MIME type must be non-empty strings.',
        ),
      );
    }

    // 2. Wrap bytes in XFile and share via OS share sheet
    try {
      final xFile = _xFileFactory(
        bytes,
        name: filename,
        mimeType: mimeType,
      );

      final result = await _shareHandler(
        [xFile],
        text: title,
        subject: title,
      );

      if (result.status == ShareResultStatus.dismissed) {
        return OutputSinkResult.failure(
          error: const OutputSinkError(
            type: OutputSinkErrorType.cancelled,
            message: 'Share operation was cancelled or dismissed by the user.',
          ),
        );
      }

      return OutputSinkResult.success(
        destination: 'share_sheet:${result.status.name}',
      );
    } catch (e) {
      return OutputSinkResult.failure(
        error: OutputSinkError(
          type: OutputSinkErrorType.deliveryFailed,
          message: 'Failed to share research output file: $e',
        ),
      );
    }
  }
}
