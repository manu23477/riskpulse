/// Specific aspect or proposition of an EventHypothesis targeted by a contradiction.
enum ContradictionTarget {
  existence,
  location,
  extent,
  time,
  type,
  severity,
  consequence,
  causalInterpretation,
  other;

  static ContradictionTarget fromCode(String code) {
    final normalized = code.trim().toLowerCase();
    for (final target in ContradictionTarget.values) {
      if (target.name.toLowerCase() == normalized) {
        return target;
      }
    }
    return ContradictionTarget.existence;
  }
}
