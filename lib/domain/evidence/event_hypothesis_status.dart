/// Lifecycle status categories for Event Hypotheses.
///
/// Creating an EventHypothesis represents a candidate event inference and does NOT mean
/// that the real-world disaster is confirmed truth.
enum EventHypothesisStatus {
  candidate,
  underReview,
  supported,
  weakened,
  superseded,
  invalidated,
  resolved,
  unavailable;

  static EventHypothesisStatus fromCode(String code) {
    final normalized = code.trim().toLowerCase();
    for (final status in EventHypothesisStatus.values) {
      if (status.name.toLowerCase() == normalized) {
        return status;
      }
    }
    return EventHypothesisStatus.candidate;
  }
}
