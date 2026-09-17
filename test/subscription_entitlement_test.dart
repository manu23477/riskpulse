import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/domain/subscription/subscription.dart';
import 'package:riskpulse/data/services/subscription/subscription_services.dart';
import 'package:riskpulse/screens/subscription/subscription_screen.dart';
import 'package:riskpulse/screens/owner_admin/owner_admin_screen.dart';

void main() {
  group('Phase R.3-R2 Subscription, Entitlement, Owner & Payment Foundation', () {
    const entitlementService = SubscriptionEntitlementService();
    const verificationService = VerificationService();
    const razorpayService = RazorpayService();
    const ownerAdminService = OwnerAdminService();

    final citizenUser = UserProfileEntity.defaultCitizen(userId: 'usr-cit-01', email: 'citizen@example.com');
    final ownerUser = UserProfileEntity.owner(userId: 'usr-owner-01', email: 'owner@riskpulse.org');

    group('1. UserRole.owner Architecture & Entitlements', () {
      test('Owner receives full application capability entitlement without commercial payment', () {
        expect(entitlementService.canAccess(ownerUser, FeatureCapability.ownerAdministration), isTrue);
        expect(entitlementService.canAccess(ownerUser, FeatureCapability.hydroAi), isTrue);
        expect(entitlementService.canAccess(ownerUser, FeatureCapability.sarValidation), isTrue);
        expect(entitlementService.canAccess(ownerUser, FeatureCapability.environmentalHealth), isTrue);
        expect(entitlementService.canAccess(ownerUser, FeatureCapability.systemAdministration), isTrue);
      });

      test('OwnerAdminService provides system stats for UserRole.owner only', () {
        final stats = ownerAdminService.getOwnerSystemDashboardStats(ownerUser);
        expect(stats['totalUsers'], equals(1250));
        expect(stats['systemHealth'], equals('ALL SYSTEMS OPERATIONAL'));
      });

      test('OwnerAdminService rejects non-owner access with SecurityException', () {
        expect(
          () => ownerAdminService.getOwnerSystemDashboardStats(citizenUser),
          throwsA(isA<SecurityException>()),
        );
      });
    });

    group('2. Commercial Tier Entitlement Evaluation', () {
      test('Citizen tier receives basic public-safety capabilities ONLY', () {
        expect(entitlementService.canAccess(citizenUser, FeatureCapability.basicRiskMap), isTrue);
        expect(entitlementService.canAccess(citizenUser, FeatureCapability.emergencyHub), isTrue);

        // Research & HydroAI capabilities blocked for Citizen
        expect(entitlementService.canAccess(citizenUser, FeatureCapability.researchGis), isFalse);
        expect(entitlementService.canAccess(citizenUser, FeatureCapability.hydroAi), isFalse);
        expect(entitlementService.canAccess(citizenUser, FeatureCapability.environmentalHealth), isFalse);
        expect(entitlementService.canAccess(citizenUser, FeatureCapability.ownerAdministration), isFalse);
      });

      test('Student tier (₹399/yr) receives Research GIS and Remote Sensing', () {
        final studentUser = verificationService.submitStudentVerification(
          user: citizenUser,
          method: VerificationMethod.libraryCard,
          institutionName: 'HPU Shimla',
        );

        expect(studentUser.role, equals(UserRole.student));
        expect(studentUser.subscriptionTier, equals(SubscriptionTier.studentAnnual));
        expect(entitlementService.canAccess(studentUser, FeatureCapability.researchGis), isTrue);
        expect(entitlementService.canAccess(studentUser, FeatureCapability.remoteSensing), isTrue);

        // HydroAI & Advanced Export require Researcher tier
        expect(entitlementService.canAccess(studentUser, FeatureCapability.hydroAi), isFalse);
      });

      test('Researcher tier (₹1,499/yr) receives full Research GIS, HydroAI, and Environmental Health', () {
        final researcherUser = verificationService.submitResearcherVerification(
          user: citizenUser,
          institutionName: 'IIT Mandi',
          researchAffiliation: 'Disaster Mitigation Center',
        );

        expect(researcherUser.role, equals(UserRole.researcher));
        expect(entitlementService.canAccess(researcherUser, FeatureCapability.hydroAi), isTrue);
        expect(entitlementService.canAccess(researcherUser, FeatureCapability.sarValidation), isTrue);
        expect(entitlementService.canAccess(researcherUser, FeatureCapability.environmentalHealth), isTrue);
      });
    });

    group('3. Razorpay Test Mode & Activation', () {
      test('RazorpayService creates test order and activates entitlement upon signature verification', () {
        final plan = SubscriptionPlan.commercialPlans.firstWhere((p) => p.tier == SubscriptionTier.researcherAnnual);
        final order = razorpayService.createPaymentOrder(plan: plan, user: citizenUser);

        expect(order['orderId'], contains('order_test_'));
        expect(order['amount'], equals(149900)); // ₹1,499 in paise

        final activatedUser = razorpayService.verifyAndActivateSubscription(
          user: citizenUser,
          plan: plan,
          paymentId: 'pay_test_001',
          signature: 'sig_test_001',
        );

        expect(activatedUser.subscriptionTier, equals(SubscriptionTier.researcherAnnual));
        expect(entitlementService.canAccess(activatedUser, FeatureCapability.hydroAi), isTrue);
      });
    });

    group('4. Subscription & Owner Admin UI Widget Tests', () {
      testWidgets('renders SubscriptionScreen with 4 commercial cards (No Owner card)', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: SubscriptionScreen(currentUser: citizenUser),
          ),
        );

        expect(find.text('Choose your RiskPulse plan'), findsOneWidget);
        expect(find.text('CITIZEN'), findsOneWidget);
        expect(find.text('STUDENT / PhD SCHOLAR'), findsOneWidget);
        expect(find.text('RESEARCHER'), findsOneWidget);
        expect(find.text('INSTITUTIONAL'), findsOneWidget);
      });

      testWidgets('renders OwnerAdminScreen for UserRole.owner', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: OwnerAdminScreen(ownerUser: ownerUser),
          ),
        );

        expect(find.text('RiskPulse Owner & Admin Area'), findsOneWidget);
        expect(find.text('ROLE: OWNER'), findsOneWidget);
        expect(find.textContaining('ALL SYSTEMS OPERATIONAL'), findsOneWidget);
      });
    });
  });
}
