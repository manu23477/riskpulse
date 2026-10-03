/// Enumeration of evidence presence states.
///
/// Distinguishes ABSENCE OF EVIDENCE (no relevant evidence found) from NEGATIVE EVIDENCE (evidence explicitly conflicting).
enum EvidencePresence {
  present,
  absent,
  unknown,
  notApplicable;

  static EvidencePresence fromCode(String code) {
    final normalized = code.trim().toLowerCase();
    for (final state in EvidencePresence.values) {
      if (state.name.toLowerCase() == normalized) {
        return state;
      }
    }
    return EvidencePresence.unknown;
  }
}
