import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/subscription/user_role.dart';

/// Immutable domain model representing a commercial subscription plan.
@immutable
class SubscriptionPlan {
  final SubscriptionTier tier;
  final String title;
  final String subtitle;
  final String priceDisplay;
  final int annualAmountInInr;
  final List<String> features;
  final bool requiresVerification;

  const SubscriptionPlan({
    required this.tier,
    required this.title,
    required this.subtitle,
    required this.priceDisplay,
    required this.annualAmountInInr,
    required this.features,
    this.requiresVerification = false,
  });

  static const List<SubscriptionPlan> commercialPlans = [
    SubscriptionPlan(
      tier: SubscriptionTier.citizenFree,
      title: 'CITIZEN',
      subtitle: 'Basic disaster awareness and emergency information.',
      priceDisplay: 'FREE',
      annualAmountInInr: 0,
      features: [
        'Basic current hazard information',
        'Operational Risk Map (168 district features)',
        'Hazard location & status',
        'SOS / Emergency Hub & contacts',
        'Multilingual public interface',
        'Community hazard reporting',
        'In-app Help Centre',
      ],
      requiresVerification: false,
    ),
    SubscriptionPlan(
      tier: SubscriptionTier.studentAnnual,
      title: 'STUDENT / PhD SCHOLAR',
      subtitle: 'Learning GIS, disaster management and environmental analysis.',
      priceDisplay: '₹399 / year',
      annualAmountInInr: 399,
      features: [
        'Everything in Citizen +',
        'Research GIS Studio access',
        'AOI creation & layer management',
        'DEM & terrain analysis learning',
        'Remote sensing (NDVI / NDWI)',
        'Guided research workflows',
        'Basic map composition & exports',
        'Feature Workflow Atlas',
      ],
      requiresVerification: true,
    ),
    SubscriptionPlan(
      tier: SubscriptionTier.researcherAnnual,
      title: 'RESEARCHER',
      subtitle: 'Advanced Research GIS and environmental and hazard analysis.',
      priceDisplay: '₹1,499 / year',
      annualAmountInInr: 1499,
      features: [
        'Everything in Student +',
        'Advanced Research GIS Studio',
        'Advanced DEM readiness governance',
        'HydroAI 2D Hydrodynamic Modeling',
        'HEC-RAS 2D solver adapter',
        'Sentinel-1 SAR 2D inundation validation',
        'Environmental Health & Disease Intelligence',
        'Exposure & Impact assessment engines',
        'Decision Support & Research Priority Queue',
        'Full research provenance & registry',
      ],
      requiresVerification: true,
    ),
    SubscriptionPlan(
      tier: SubscriptionTier.institutionalCustom,
      title: 'INSTITUTIONAL',
      subtitle: 'For NGOs, universities, Government departments and agencies.',
      priceDisplay: 'CUSTOM',
      annualAmountInInr: 0,
      features: [
        'Multi-user organizational workspaces',
        'Project-level access control',
        'Advanced Research GIS & HydroAI',
        'Organizational reporting & exports',
        'Administrative controls & user management',
        'Customized deployment & integration options',
      ],
      requiresVerification: true,
    ),
  ];
}
