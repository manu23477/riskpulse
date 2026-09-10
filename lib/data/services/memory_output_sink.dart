import 'dart:typed_data';
import 'package:riskpulse/domain/gis/research_output_sink.dart';

/// In-memory research output sink for testing and headless pipeline verification.
class MemoryOutputSink implements ResearchOutputSink {
  Uint8List? lastBytes;
  String? lastFilename;
  String? lastMimeType;
  String? lastTitle;
  int outputCount = 0;

  bool shouldFail = false;
  OutputSinkErrorType failureType = OutputSinkErrorType.deliveryFailed;
  String failureMessage = 'Simulated memory sink failure';

  @override
  Future<OutputSinkResult> output({
    required Uint8List bytes,
    required String filename,
    required String mimeType,
    String? title,
  }) async {
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

    if (shouldFail) {
      return OutputSinkResult.failure(
        error: OutputSinkError(
          type: failureType,
          message: failureMessage,
        ),
      );
    }

    lastBytes = Uint8List.fromList(bytes);
    lastFilename = filename;
    lastMimeType = mimeType;
    lastTitle = title;
    outputCount++;

    return OutputSinkResult.success(
      destination: 'memory://$filename',
    );
  }

  void clear() {
    lastBytes = null;
    lastFilename = null;
    lastMimeType = null;
    lastTitle = null;
    outputCount = 0;
    shouldFail = false;
  }
}
