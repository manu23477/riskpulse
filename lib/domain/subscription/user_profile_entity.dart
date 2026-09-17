import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/subscription/user_role.dart';

/// Immutable domain entity representing a user profile with role, account type, subscription tier, and verification.
@immutable
class UserProfileEntity {
  final String userId;
  final String displayName;
  final String email;
  final UserRole role;
  final AccountType accountType;
  final SubscriptionTier subscriptionTier;
  final bool isVerified;
  final VerificationMethod verificationMethod;
  final String? institutionName;
  final DateTime createdAt;

  const UserProfileEntity({
    required this.userId,
    required this.displayName,
    required this.email,
    required this.role,
    required this.accountType,
    required this.subscriptionTier,
    this.isVerified = false,
    this.verificationMethod = VerificationMethod.none,
    this.institutionName,
    required this.createdAt,
  });

  bool get isOwner => role == UserRole.owner;
  bool get isInstitutional => accountType == AccountType.institutional;

  /// Creates a default Citizen user profile.
  factory UserProfileEntity.defaultCitizen({required String userId, required String email}) {
    return UserProfileEntity(
      userId: userId,
      displayName: 'Citizen User',
      email: email,
      role: UserRole.citizen,
      accountType: AccountType.citizen,
      subscriptionTier: SubscriptionTier.citizenFree,
      createdAt: DateTime.now().toUtc(),
    );
  }

  /// Creates an Owner user profile.
  factory UserProfileEntity.owner({required String userId, required String email}) {
    return UserProfileEntity(
      userId: userId,
      displayName: 'System Owner',
      email: email,
      role: UserRole.owner,
      accountType: AccountType.researcher,
      subscriptionTier: SubscriptionTier.researcherAnnual,
      isVerified: true,
      createdAt: DateTime.now().toUtc(),
    );
  }
}
