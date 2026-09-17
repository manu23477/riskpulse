import 'package:flutter/material.dart';
import 'package:riskpulse/domain/subscription/subscription.dart';
import 'package:riskpulse/data/services/subscription/subscription_services.dart';
import 'package:riskpulse/screens/subscription/student_verification_dialog.dart';

/// Subscription plans and tier selection screen.
class SubscriptionScreen extends StatefulWidget {
  final UserProfileEntity currentUser;
  final Function(UserProfileEntity updatedUser)? onUserUpdated;

  const SubscriptionScreen({
    super.key,
    required this.currentUser,
    this.onUserUpdated,
  });

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final RazorpayService _razorpayService = const RazorpayService();
  String _usageType = 'Personal Safety';
  late UserProfileEntity _user;

  @override
  void initState() {
    super.initState();
    _user = widget.currentUser;
  }

  void _handlePlanSelection(SubscriptionPlan plan) {
    if (plan.tier == SubscriptionTier.citizenFree) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You are on the Free Citizen Plan.')),
      );
      return;
    }

    if (plan.tier == SubscriptionTier.studentAnnual) {
      showDialog(
        context: context,
        builder: (context) => StudentVerificationDialog(
          currentUser: _user,
          onVerified: (verifiedUser) {
            setState(() => _user = verifiedUser);
            if (widget.onUserUpdated != null) widget.onUserUpdated!(verifiedUser);
            _initiateRazorpayPayment(plan);
          },
        ),
      );
      return;
    }

    if (plan.tier == SubscriptionTier.researcherAnnual) {
      _initiateRazorpayPayment(plan);
      return;
    }

    if (plan.tier == SubscriptionTier.institutionalCustom) {
      _showInstitutionalContactDialog();
    }
  }

  void _initiateRazorpayPayment(SubscriptionPlan plan) {
    try {
      final order = _razorpayService.createPaymentOrder(plan: plan, user: _user);
      final activatedUser = _razorpayService.verifyAndActivateSubscription(
        user: _user,
        plan: plan,
        paymentId: 'pay_test_${DateTime.now().millisecondsSinceEpoch}',
        signature: 'sig_test_valid',
      );

      setState(() => _user = activatedUser);
      if (widget.onUserUpdated != null) widget.onUserUpdated!(activatedUser);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment order ${order['orderId']} verified in TEST mode. Subscription activated!'),
          backgroundColor: const Color(0xFF22C55E),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment initiation failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showInstitutionalContactDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text('Institutional Custom Plan', style: TextStyle(color: Colors.white)),
        content: const Text(
          'For NGOs, Universities, Government Departments, and Research Agencies.\n\nPlease contact institutional-access@riskpulse.org for custom deployment and multi-user workspace licensing.',
          style: TextStyle(color: Color(0xFF94A3B8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK', style: TextStyle(color: Color(0xFF38BDF8))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final plans = SubscriptionPlan.commercialPlans;

    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text('Choose your RiskPulse plan'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose the plan that matches how you use RiskPulse.',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14.0),
            ),
            const SizedBox(height: 16.0),

            // Usage Prompt Selector
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(10.0),
                border: Border.all(color: const Color(0xFF1E293B)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'How will you use RiskPulse?',
                    style: TextStyle(color: Colors.white, fontSize: 13.0, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8.0),
                  Wrap(
                    spacing: 8.0,
                    children: [
                      _usageChip('Personal Safety', SubscriptionTier.citizenFree),
                      _usageChip('Learning & Education', SubscriptionTier.studentAnnual),
                      _usageChip('Research & Academic Work', SubscriptionTier.researcherAnnual),
                      _usageChip('Organization / Institution', SubscriptionTier.institutionalCustom),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20.0),

            // Plan Cards
            ...plans.map((plan) => _buildPlanCard(plan)),
          ],
        ),
      ),
    );
  }

  Widget _usageChip(String label, SubscriptionTier targetTier) {
    final isSelected = _usageType == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) setState(() => _usageType = label);
      },
      selectedColor: const Color(0xFF0EA5E9),
      backgroundColor: const Color(0xFF1E293B),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF94A3B8),
        fontSize: 11.0,
      ),
    );
  }

  Widget _buildPlanCard(SubscriptionPlan plan) {
    final isCurrentTier = _user.subscriptionTier == plan.tier;

    return Card(
      color: const Color(0xFF0F172A),
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(
          color: isCurrentTier ? const Color(0xFF38BDF8) : const Color(0xFF1E293B),
          width: isCurrentTier ? 2.0 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  plan.title,
                  style: const TextStyle(color: Colors.white, fontSize: 18.0, fontWeight: FontWeight.bold),
                ),
                Text(
                  plan.priceDisplay,
                  style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 18.0, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 6.0),
            Text(
              plan.subtitle,
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13.0),
            ),
            const SizedBox(height: 16.0),

            ...plan.features.map((feat) => Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, color: Color(0xFF22C55E), size: 16.0),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: Text(
                          feat,
                          style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12.0),
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 16.0),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _handlePlanSelection(plan),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCurrentTier ? const Color(0xFF22C55E) : const Color(0xFF0EA5E9),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                ),
                child: Text(
                  isCurrentTier
                      ? 'CURRENT PLAN'
                      : (plan.tier == SubscriptionTier.citizenFree
                          ? 'CONTINUE FREE'
                          : (plan.tier == SubscriptionTier.institutionalCustom
                              ? 'REQUEST ACCESS'
                              : 'VERIFY & SUBSCRIBE')),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
