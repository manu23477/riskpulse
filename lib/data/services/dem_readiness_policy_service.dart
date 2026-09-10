import 'package:riskpulse/domain/gis/analytical_step.dart';
import 'package:riskpulse/domain/gis/dem_readiness_assessment.dart';
import 'package:riskpulse/data/services/dem_validation_service.dart';

/// Provider-neutral deterministic service for evaluating [DemReadinessAssessment] from a [DemValidationResult].
///
/// SCIENTIFIC GOVERNANCE:
/// 1. Separates measured data quality from scientific acceptance decisions.
/// 2. NO invented scientific acceptance thresholds (sets [isScientificThresholdEstablished = false] when no policy threshold exists).
/// 3. Returns [DemReadinessStatus.notEstablished] or [DemReadinessStatus.requiresResearcherReview] when threshold is unestablished.
class DemReadinessPolicyService {
  static const String policyVersion = '4K.8.14-v1';

  const DemReadinessPolicyService();

  /// Evaluates DEM scientific readiness for a given [productContext].
  DemReadinessAssessment evaluateReadiness({
    required String assessmentId,
    required DemValidationResult validationResult,
    String productContext = 'general_terrain',
  }) {
    if (assessmentId.trim().isEmpty) {
      throw ArgumentError('assessmentId cannot be empty.');
    }

    final now = DateTime.now().toUtc();

    // 1. Check Structural / Footprint Rejection
    if (validationResult.isRejected) {
      final step = AnalyticalStep(
        name: 'dem_readiness_policy_evaluation',
        operationType: 'dem_readiness_policy_eval',
        parameters: {
          'policyVersion': policyVersion,
          'validationRuleVersion': DemValidationService.validationRuleVersion,
          'productContext': productContext,
          'status': DemReadinessStatus.rejected.name,
          'isScientificThresholdEstablished': false,
        },
        timestamp: now,
        inputReferences: [assessmentId],
      );

      return DemReadinessAssessment(
        assessmentId: assessmentId,
        policyVersion: policyVersion,
        productContext: productContext,
        status: DemReadinessStatus.rejected,
        validationResult: validationResult,
        isScientificThresholdEstablished: false,
        rationale: 'DEM Rejected: ${validationResult.message}',
        warnings: [validationResult.message],
        provenanceStep: step,
      );
    }

    // 2. Evaluate Scientific Policy Status (Without Inventing Thresholds)
    final warnings = <String>[];
    if (validationResult.noDataPercentage > 0.0) {
      warnings.add(
        'DEM contains ${validationResult.noDataPercentage.toStringAsFixed(1)}% NoData cells (${validationResult.noDataCells} cells).',
      );
    }

    DemReadinessStatus status;
    String rationale;

    if (validationResult.isPartial) {
      status = DemReadinessStatus.requiresResearcherReview;
      rationale =
          'DEM footprint partially covers AOI (${validationResult.footprintCoveragePercentage.toStringAsFixed(1)}%). '
          'Valid elevation cells: ${validationResult.validCellPercentage.toStringAsFixed(1)}%, NoData: ${validationResult.noDataPercentage.toStringAsFixed(1)}%. '
          'Researcher review required.';
    } else {
      // MANDATORY GOVERNANCE RULE: Scientific acceptance threshold is NOT ESTABLISHED in governance.
      status = DemReadinessStatus.notEstablished;
      rationale =
          'DEM data quality assessed: Footprint = ${validationResult.footprintCoveragePercentage.toStringAsFixed(1)}%, '
          'Valid Elevation Cells = ${validationResult.validCellPercentage.toStringAsFixed(1)}%, '
          'NoData = ${validationResult.noDataPercentage.toStringAsFixed(1)}%. '
          'Scientific acceptance threshold is NOT ESTABLISHED in RiskPulse governance.';
      warnings.add('Scientific acceptance threshold is NOT ESTABLISHED in RiskPulse governance.');
    }

    final step = AnalyticalStep(
      name: 'dem_readiness_policy_evaluation',
      operationType: 'dem_readiness_policy_eval',
      parameters: {
        'policyVersion': policyVersion,
        'validationRuleVersion': DemValidationService.validationRuleVersion,
        'productContext': productContext,
        'status': status.name,
        'isScientificThresholdEstablished': false,
        'footprintCoveragePercentage': validationResult.footprintCoveragePercentage,
        'validCellPercentage': validationResult.validCellPercentage,
        'noDataPercentage': validationResult.noDataPercentage,
      },
      timestamp: now,
      inputReferences: [assessmentId],
    );

    return DemReadinessAssessment(
      assessmentId: assessmentId,
      policyVersion: policyVersion,
      productContext: productContext,
      status: status,
      validationResult: validationResult,
      isScientificThresholdEstablished: false,
      rationale: rationale,
      warnings: warnings,
      provenanceStep: step,
      metadata: {
        'policyVersion': policyVersion,
        'validationRuleVersion': DemValidationService.validationRuleVersion,
        'productContext': productContext,
      },
    );
  }
}
