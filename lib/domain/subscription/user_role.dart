/// Authenticated user roles in RiskPulse.
///
/// SCIENTIFIC & ADMINISTRATIVE GOVERNANCE:
/// [owner] is an internal administrative role outside the commercial subscription hierarchy.
/// Owner access bypasses payment requirements but does NOT bypass scientific governance or operational safety controls.
enum UserRole {
  owner,
  citizen,
  student,
  researcher,
  institutionalAdmin,
  institutionalMember,
}

enum AccountType {
  citizen,
  student,
  researcher,
  institutional,
}

enum SubscriptionTier {
  citizenFree,
  studentAnnual,
  researcherAnnual,
  institutionalCustom,
}

enum VerificationMethod {
  studentIdCard,
  phdScholarId,
  libraryCard,
  academicEmail,
  institutionalAffiliation,
  none,
}
