/// Explicit lifecycle status categories for Evidence Objects.
enum EvidenceStatus {
  received,
  verified,
  unverified,
  superseded,
  retracted,
  corrected,
  unavailable;

  static EvidenceStatus fromCode(String code) {
    final normalized = code.trim().toLowerCase();
    for (final status in EvidenceStatus.values) {
      if (status.name.toLowerCase() == normalized) {
        return status;
      }
    }
    return EvidenceStatus.unverified;
  }
}

/// Explicit cryptographic and content integrity status.
enum EvidenceIntegrityStatus {
  contentHashVerified,
  contentHashUnavailable,
  contentHashMismatch,
  corrupted;

  static EvidenceIntegrityStatus fromCode(String code) {
    final normalized = code.trim().toLowerCase();
    for (final status in EvidenceIntegrityStatus.values) {
      if (status.name.toLowerCase() == normalized) {
        return status;
      }
    }
    return EvidenceIntegrityStatus.contentHashUnavailable;
  }
}
