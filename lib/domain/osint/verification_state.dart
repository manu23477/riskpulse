/// Verification state machine values for OSINT candidate intelligence events.
enum VerificationState {
  unverified,
  corroborated,
  verified,
  conflicting,
  rejected,
  stale,
}
