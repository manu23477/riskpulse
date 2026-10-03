/// Categorical strength classification of a contradiction evaluation.
enum ContradictionStrength {
  none,
  weak,
  moderate,
  strong,
  direct;

  static ContradictionStrength fromCode(String code) {
    final normalized = code.trim().toLowerCase();
    for (final strength in ContradictionStrength.values) {
      if (strength.name.toLowerCase() == normalized) {
        return strength;
      }
    }
    return ContradictionStrength.moderate;
  }
}
