/// Overall evidence evaluation state for an EventHypothesis.
enum EvaluationState {
  consistent,
  conflicted,
  insufficient,
  unresolved,
  notEvaluable;

  static EvaluationState fromCode(String code) {
    final normalized = code.trim().toLowerCase();
    for (final state in EvaluationState.values) {
      if (state.name.toLowerCase() == normalized) {
        return state;
      }
    }
    return EvaluationState.unresolved;
  }
}
