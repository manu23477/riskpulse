import 'package:riskpulse/domain/subscription/subscription.dart';

/// Service engine managing academic and professional eligibility verification for Student (₹399/yr) and Researcher (₹1,499/yr) tiers.
class VerificationService {
  static const String serviceVersion = 'R.3-R2-v1';

  const VerificationService();

  /// Submits student or scholar eligibility evidence for verification.
  ///
  /// Supported methods: Student ID Card, PhD Scholar ID, Library Card, or Academic Email.
  UserProfileEntity submitStudentVerification({
    required UserProfileEntity user,
    required VerificationMethod method,
    required String institutionName,
    String? documentNumber,
  }) {
    if (method == VerificationMethod.none) {
      throw ArgumentError('VerificationMethod must be specified.');
    }
    if (institutionName.trim().isEmpty) {
      throw ArgumentError('Institution name cannot be empty.');
    }

    return UserProfileEntity(
      userId: user.userId,
      displayName: user.displayName,
      email: user.email,
      role: UserRole.student,
      accountType: AccountType.student,
      subscriptionTier: SubscriptionTier.studentAnnual,
      isVerified: true,
      verificationMethod: method,
      institutionName: institutionName,
      createdAt: user.createdAt,
    );
  }

  /// Submits researcher or academic affiliation evidence for verification.
  UserProfileEntity submitResearcherVerification({
    required UserProfileEntity user,
    required String institutionName,
    required String researchAffiliation,
  }) {
    if (institutionName.trim().isEmpty) {
      throw ArgumentError('Institution name cannot be empty.');
    }

    return UserProfileEntity(
      userId: user.userId,
      displayName: user.displayName,
      email: user.email,
      role: UserRole.researcher,
      accountType: AccountType.researcher,
      subscriptionTier: SubscriptionTier.researcherAnnual,
      isVerified: true,
      verificationMethod: VerificationMethod.institutionalAffiliation,
      institutionName: institutionName,
      createdAt: user.createdAt,
    );
  }
}
