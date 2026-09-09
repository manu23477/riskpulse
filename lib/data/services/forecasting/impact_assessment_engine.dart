import 'package:riskpulse/domain/gis/analytical_step.dart';
import 'package:riskpulse/domain/forecasting/forecasting.dart';
import 'package:riskpulse/data/services/forecasting/hazard_exposure_intersection_engine.dart';

/// Provider-neutral deterministic engine for evaluating potential and observed impacts.
///
/// SCIENTIFIC BOUNDARIES:
/// 1. Hazard != Impact.
/// 2. Exposure != Vulnerability.
/// 3. Forecast-derived potential impact is NEVER labeled as observed damage.
/// 4. Economic loss is strictly marked as 'NOT AVAILABLE' without validated valuation parameters.
class ImpactAssessmentEngine {
  final HazardExposureIntersectionEngine intersectionEngine;

  const ImpactAssessmentEngine({
    this.intersectionEngine = const HazardExposureIntersectionEngine(),
  });

  /// Computes a [ImpactAssessment] combining hazard forecast/observation, spatial exposure, and optional vulnerability.
  ImpactAssessment assessImpact({
    required String assessmentId,
    required String hazardId,
    required String hazardCategory,
    String hazardSourceType = 'forecast_derived',
    required GeoLocation hazardLocation,
    required ForecastHorizon horizon,
    required ForecastUncertainty uncertainty,
    required List<ExposureElement> exposureElements,
    required String exposureDatasetId,
    double maxSpatialDistanceMeters = 5000.0,
    VulnerabilityProfile? vulnerabilityProfile,
  }) {
    // 1. Evaluate Spatial Hazard-Exposure Intersection
    final intersection = intersectionEngine.evaluateIntersection(
      hazardId: hazardId,
      hazardCategory: hazardCategory,
      hazardLocation: hazardLocation,
      exposureElements: exposureElements,
      maxSpatialDistanceMeters: maxSpatialDistanceMeters,
    );

    // 2. Determine Impact Score & Severity Label
    double? impactScore;
    String severityLabel = 'Negligible';

    final totalExposed = intersection.totalExposedQuantity;

    if (totalExposed > 0) {
      if (vulnerabilityProfile != null) {
        final vul = vulnerabilityProfile.vulnerabilityScore;
        impactScore = (vul * (totalExposed > 100 ? 1.0 : totalExposed / 100.0)).clamp(0.0, 1.0);
      } else {
        impactScore = (totalExposed > 100 ? 0.80 : totalExposed / 125.0).clamp(0.0, 1.0);
      }

      if (impactScore >= 0.75) {
        severityLabel = 'Severe';
      } else if (impactScore >= 0.50) {
        severityLabel = 'High';
      } else if (impactScore >= 0.25) {
        severityLabel = 'Moderate';
      } else {
        severityLabel = 'Low';
      }
    }

    final now = DateTime.now().toUtc();
    final step = AnalyticalStep(
      name: 'impact_assessment_calculation',
      operationType: 'impact_eval',
      parameters: {
        'hazardId': hazardId,
        'hazardSourceType': hazardSourceType,
        'exposureCategory': intersection.exposedElements.isNotEmpty
            ? intersection.exposedElements.first.category.name
            : 'other',
        'exposedElementCount': intersection.exposedElements.length,
        'totalExposedQuantity': totalExposed,
        'quantityUnit': intersection.quantityUnit,
        'hasVulnerabilityProfile': vulnerabilityProfile != null,
        'vulnerabilityProfileId': vulnerabilityProfile?.profileId,
        'impactSeverityLabel': severityLabel,
      },
      timestamp: now,
      inputReferences: [hazardId, exposureDatasetId],
    );

    return ImpactAssessment(
      assessmentId: assessmentId,
      hazardId: hazardId,
      hazardCategory: hazardCategory,
      hazardSourceType: hazardSourceType,
      exposureCategory: intersection.exposedElements.isNotEmpty
          ? intersection.exposedElements.first.category
          : ExposureCategory.other,
      exposureDatasetId: exposureDatasetId,
      exposedElementIds: intersection.exposedElements.map((e) => e.elementId).toList(),
      totalExposedQuantity: totalExposed,
      quantityUnit: intersection.quantityUnit,
      estimatedImpactScore: impactScore,
      impactSeverityLabel: severityLabel,
      vulnerabilityProfile: vulnerabilityProfile,
      horizon: horizon,
      location: hazardLocation,
      uncertainty: uncertainty,
      scientificStatus: ScientificValidationStatus.provisionalSoftwareOnly,
      economicImpactEstimate: 'NOT AVAILABLE',
      provenanceSteps: [step, intersection.provenanceStep],
      metadata: {
        'spatialRelationshipLabel': intersection.spatialRelationshipLabel,
        'hasVulnerabilityProfile': vulnerabilityProfile != null,
      },
    );
  }
}
