import 'package:riskpulse/domain/subscription/subscription.dart';

/// Centralized entitlement policy evaluator for RiskPulse features.
///
/// SCIENTIFIC & ADMINISTRATIVE GOVERNANCE:
/// 1. Owner role ([UserRole.owner]) receives full application capability entitlement without commercial payment.
/// 2. Bypasses payment requirements, but does NOT bypass scientific governance or operational safety controls.
class SubscriptionEntitlementService {
  static const String serviceVersion = 'R.3-R2-v1';

  const SubscriptionEntitlementService();

  /// Evaluates whether [user] is entitled to access [capability].
  bool canAccess(UserProfileEntity user, FeatureCapability capability) {
    // 1. OWNER ROLE — EVALUATED FIRST (FULL APPLICATION ENTITLEMENT)
    if (user.role == UserRole.owner) {
      return true;
    }

    // 2. COMMERCIAL TIER ENTITLEMENT EVALUATION
    switch (capability) {
      case FeatureCapability.basicRiskMap:
      case FeatureCapability.emergencyHub:
      case FeatureCapability.basicHazardReporting:
        return true; // Available across ALL tiers

      case FeatureCapability.researchGis:
      case FeatureCapability.demAnalysis:
      case FeatureCapability.remoteSensing:
        return user.subscriptionTier == SubscriptionTier.studentAnnual ||
            user.subscriptionTier == SubscriptionTier.researcherAnnual ||
            user.subscriptionTier == SubscriptionTier.institutionalCustom;

      case FeatureCapability.gee:
      case FeatureCapability.osintResearch:
      case FeatureCapability.hydroAi:
      case FeatureCapability.hecRas:
      case FeatureCapability.sarValidation:
      case FeatureCapability.environmentalHealth:
      case FeatureCapability.exposureImpact:
      case FeatureCapability.decisionSupport:
      case FeatureCapability.advancedExport:
      case FeatureCapability.researchProvenance:
        return user.subscriptionTier == SubscriptionTier.researcherAnnual ||
            user.subscriptionTier == SubscriptionTier.institutionalCustom;

      case FeatureCapability.institutionalWorkspace:
      case FeatureCapability.organizationAdministration:
        return user.subscriptionTier == SubscriptionTier.institutionalCustom;

      case FeatureCapability.subscriptionAdministration:
      case FeatureCapability.userAdministration:
      case FeatureCapability.verificationAdministration:
      case FeatureCapability.systemAdministration:
      case FeatureCapability.ownerAdministration:
        return false; // Reserved exclusively for UserRole.owner
    }
  }
}
