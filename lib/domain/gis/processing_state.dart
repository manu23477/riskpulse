/// Represents the lifecycle stages of long-running GIS analytical operations.
enum ProcessingStatus {
  idle,
  preparing,
  downloading,
  analyzing,
  rendering,
  completed,
  failed,
  cancelled,
}

/// Domain model for tracking the progress and state of an analytical task.
class ProcessingState {
  final ProcessingStatus status;
  final double progress; // 0.0 to 1.0
  final String? message;
  final String? error;
  final DateTime timestamp;

  const ProcessingState({
    required this.status,
    this.progress = 0.0,
    this.message,
    this.error,
    required this.timestamp,
  });

  /// Factory for the initial idle state.
  static ProcessingState idle() => ProcessingState(
        status: ProcessingStatus.idle,
        progress: 0.0,
        timestamp: DateTime.now(),
      );

  ProcessingState copyWith({
    ProcessingStatus? status,
    double? progress,
    String? message,
    String? error,
  }) {
    return ProcessingState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      message: message ?? this.message,
      error: error ?? this.error,
      timestamp: DateTime.now(),
    );
  }
}
