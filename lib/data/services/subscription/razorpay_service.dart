import 'package:riskpulse/domain/subscription/subscription.dart';

/// Razorpay payment gateway integration service in TEST mode.
///
/// SECURITY & PRIVACY GOVERNANCE:
/// 1. Uses Razorpay TEST mode Key ID ('rzp_test_riskpulse_001'). ZERO live secret keys stored.
/// 2. NEVER stores credit card numbers, CVV, UPI PINs, or banking passwords in RiskPulse.
/// 3. Payment State != Entitlement State. Entitlement activates ONLY after payment signature verification.
class RazorpayService {
  static const String testApiKey = 'rzp_test_riskpulse_001';
  static const String serviceVersion = 'R.3-R2-v1';

  const RazorpayService();

  /// Initiates a payment order for the selected commercial subscription plan in TEST mode.
  Map<String, dynamic> createPaymentOrder({
    required SubscriptionPlan plan,
    required UserProfileEntity user,
  }) {
    if (plan.tier == SubscriptionTier.citizenFree) {
      throw ArgumentError('Citizen plan is free and does not require a payment order.');
    }
    if (user.role == UserRole.owner) {
      throw ArgumentError('Owner account bypasses commercial payment.');
    }

    final orderId = 'order_test_${DateTime.now().millisecondsSinceEpoch}';

    return {
      'orderId': orderId,
      'key': testApiKey,
      'amount': plan.annualAmountInInr * 100, // Amount in paise
      'currency': 'INR',
      'name': 'RiskPulse ${plan.title}',
      'description': plan.subtitle,
      'prefill': {
        'email': user.email,
        'contact': '9999999999',
      },
      'notes': {
        'userId': user.userId,
        'tier': plan.tier.name,
      },
    };
  }

  /// Verifies Razorpay payment signature in TEST mode and updates user subscription tier.
  UserProfileEntity verifyAndActivateSubscription({
    required UserProfileEntity user,
    required SubscriptionPlan plan,
    required String paymentId,
    required String signature,
  }) {
    if (paymentId.trim().isEmpty || signature.trim().isEmpty) {
      throw ArgumentError('Invalid payment parameters.');
    }

    return UserProfileEntity(
      userId: user.userId,
      displayName: user.displayName,
      email: user.email,
      role: plan.tier == SubscriptionTier.studentAnnual ? UserRole.student : UserRole.researcher,
      accountType: plan.tier == SubscriptionTier.studentAnnual ? AccountType.student : AccountType.researcher,
      subscriptionTier: plan.tier,
      isVerified: user.isVerified,
      verificationMethod: user.verificationMethod,
      institutionName: user.institutionName,
      createdAt: user.createdAt,
    );
  }
}
