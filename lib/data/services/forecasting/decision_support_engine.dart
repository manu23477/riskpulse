import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/gis/analytical_step.dart';
import 'package:riskpulse/domain/forecasting/forecasting.dart';

/// Provider-neutral deterministic engine for synthesizing research forecasting outputs into
/// structured [ResearchSituationBrief]s, [EvidentiaryBriefing]s, and advisory [AttentionLevel]s.
///
/// MANDATORY GOVERNANCE RULES:
/// 1. Output is ADVISORY RESEARCH DECISION SUPPORT ONLY (NOT an emergency alert or public warning).
/// 2. AttentionLevel is NOT a probability or confidence score.
/// 3. NO opaque composite risk score. Rules are inspectable, deterministic, and versioned.
/// 4. UNKNOWN vulnerability and impact statuses are preserved without fabrication.
class DecisionSupportEngine {
  static const String decisionRuleVersion = '3.9.5-v1';

  const DecisionSupportEngine();

  /// Synthesizes research outputs into a structured [ResearchSituationBrief].
  ResearchSituationBrief synthesizeSituationBrief({
    required String briefId,
    required String studyAreaName,
    required GeoLocation location,
    required ForecastHorizon horizon,
    List<HazardForecast> activeForecasts = const [],
    List<CompoundHazardEvent> compoundEvents = const [],
    List<ImpactAssessment> impactAssessments = const [],
    RiskTrajectory? trajectory,
    RiskDriverAttributionResult? attribution,
    double dataCompletenessRatio = 1.0,
    ScientificValidationStatus scientificStatus =
        ScientificValidationStatus.provisionalSoftwareOnly,
  }) {
    if (briefId.trim().isEmpty) {
      throw ArgumentError('briefId cannot be empty.');
    }
    if (studyAreaName.trim().isEmpty) {
      throw ArgumentError('studyAreaName cannot be empty.');
    }

    final now = DateTime.now().toUtc();

    // 1. Determine Advisory Attention Level Deterministically
    final attentionLevel = _evaluateAttentionLevel(
      forecasts: activeForecasts,
      compoundEvents: compoundEvents,
      impactAssessments: impactAssessments,
      trajectory: trajectory,
      attribution: attribution,
    );

    // 2. Assemble Evidentiary Briefing & Uncertainty Warnings
    final evidenceIds = <String>{};
    final modelIds = <String>{};
    final uncertaintyWarnings = <String>[];

    for (final f in activeForecasts) {
      modelIds.add(f.modelId);
    }
    for (final c in compoundEvents) {
      for (final e in c.evidenceList) {
        evidenceIds.add(e.evidenceId);
      }
    }
    for (final i in impactAssessments) {
      if (i.isVulnerabilityUnknown) {
        uncertaintyWarnings.add(
          'Vulnerability is UNKNOWN for hazard ${i.hazardId}. Potential impact score is NOT ESTIMATED.',
        );
      }
    }

    if (trajectory == null || trajectory.isUnknown) {
      uncertaintyWarnings.add(
        'Risk trajectory direction is UNKNOWN or insufficient temporal observation data.',
      );
    }

    if (attribution != null && attribution.conflictDetected) {
      uncertaintyWarnings.add(
        'CONFLICT DETECTED: Opposing driver contribution directions present.',
      );
    }

    uncertaintyWarnings.add('PROVISIONAL / UNCALIBRATED FOR HIMACHAL REGION.');

    final evidentiaryBriefing = EvidentiaryBriefing(
      briefingId: 'ev-brief-$briefId',
      contributingEvidenceIds: evidenceIds.toList(),
      contributingModelIds: modelIds.toList(),
      dataCompletenessRatio: dataCompletenessRatio.clamp(0.0, 1.0),
      calibrationStatusNotice: 'PROVISIONAL / UNCALIBRATED FOR REGION',
      uncertaintyWarnings: uncertaintyWarnings,
    );

    // 3. Formulate Rationale
    final rationaleBuffer = StringBuffer();
    rationaleBuffer.write(
      'Advisory AttentionLevel set to ${attentionLevel.name.toUpperCase()} for $studyAreaName based on rule version $decisionRuleVersion. ',
    );

    if (trajectory != null && !trajectory.isUnknown) {
      rationaleBuffer.write(
        'Trajectory is ${trajectory.direction.name.toUpperCase()} (${trajectory.stateVariable}). ',
      );
    }
    if (activeForecasts.isNotEmpty) {
      final maxVal = activeForecasts
          .map((f) => f.primaryValue)
          .reduce((a, b) => a > b ? a : b);
      rationaleBuffer.write(
        'Max primary forecast value is ${maxVal.toStringAsFixed(2)}. ',
      );
    }
    if (compoundEvents.isNotEmpty) {
      rationaleBuffer.write(
        'Multi-hazard compound event active (${compoundEvents.length} candidates). ',
      );
    }
    rationaleBuffer.write(
      'Decision support is advisory; models remain provisional and uncalibrated.',
    );

    final step = AnalyticalStep(
      name: 'decision_support_synthesis',
      operationType: 'decision_support_eval',
      parameters: {
        'decisionRuleVersion': decisionRuleVersion,
        'attentionLevel': attentionLevel.name,
        'forecastCount': activeForecasts.length,
        'compoundEventCount': compoundEvents.length,
        'impactAssessmentCount': impactAssessments.length,
        'trajectoryDirection': trajectory?.direction.name ?? 'unknown',
        'conflictDetected': attribution?.conflictDetected ?? false,
      },
      timestamp: now,
      inputReferences: [
        briefId,
        ...activeForecasts.map((f) => f.forecastId),
        if (trajectory != null) trajectory.trajectoryId,
      ],
    );

    return ResearchSituationBrief(
      briefId: briefId,
      studyAreaName: studyAreaName,
      location: location,
      horizon: horizon,
      advisoryAttentionLevel: attentionLevel,
      activeForecasts: activeForecasts,
      compoundEvents: compoundEvents,
      impactAssessments: impactAssessments,
      evidentiaryBriefing: evidentiaryBriefing,
      scientificStatus: scientificStatus,
      provenanceSteps: [step],
      metadata: {
        'decisionRuleVersion': decisionRuleVersion,
        'rationale': rationaleBuffer.toString(),
        'trajectoryDirection': trajectory?.direction.name ?? 'unknown',
        'isCausalValidated': false,
      },
    );
  }

  /// Helper to create a [ResearchAttentionItem] for a [ResearchPriorityQueue].
  ResearchAttentionItem createAttentionItem({
    required String itemId,
    required ResearchSituationBrief brief,
  }) {
    double priorityScore = 10.0;

    switch (brief.advisoryAttentionLevel) {
      case AttentionLevel.critical:
        priorityScore = 90.0;
        break;
      case AttentionLevel.alert:
        priorityScore = 70.0;
        break;
      case AttentionLevel.monitor:
        priorityScore = 40.0;
        break;
      case AttentionLevel.low:
        priorityScore = 10.0;
        break;
    }

    if (brief.compoundEvents.isNotEmpty) {
      priorityScore += 5.0;
    }

    final rationale = brief.metadata['rationale'] as String? ??
        'Advisory attention item for research priority queue.';

    return ResearchAttentionItem(
      itemId: itemId,
      locationName: brief.studyAreaName,
      location: brief.location,
      attentionLevel: brief.advisoryAttentionLevel,
      priorityScore: priorityScore,
      rationale: rationale,
      brief: brief,
    );
  }

  AttentionLevel _evaluateAttentionLevel({
    required List<HazardForecast> forecasts,
    required List<CompoundHazardEvent> compoundEvents,
    required List<ImpactAssessment> impactAssessments,
    RiskTrajectory? trajectory,
    RiskDriverAttributionResult? attribution,
  }) {
    bool isRising = trajectory?.direction == RiskTrajectoryDirection.rising;
    bool isSevereImpact = impactAssessments.any((i) => i.impactSeverityLabel == 'Severe');
    bool isHighImpact = impactAssessments.any((i) => i.impactSeverityLabel == 'High');

    double maxForecastValue = 0.0;
    if (forecasts.isNotEmpty) {
      maxForecastValue = forecasts.map((f) => f.primaryValue).reduce((a, b) => a > b ? a : b);
    }

    // Rule 1: CRITICAL
    if ((isSevereImpact && isRising) || (compoundEvents.isNotEmpty && maxForecastValue >= 1.5)) {
      return AttentionLevel.critical;
    }

    // Rule 2: ALERT
    if (isHighImpact || isRising || compoundEvents.isNotEmpty || maxForecastValue >= 1.0) {
      return AttentionLevel.alert;
    }

    // Rule 3: MONITOR
    if (maxForecastValue >= 0.5 ||
        impactAssessments.any((i) => i.impactSeverityLabel == 'Moderate') ||
        trajectory?.direction == RiskTrajectoryDirection.stable) {
      return AttentionLevel.monitor;
    }

    // Rule 4: LOW
    return AttentionLevel.low;
  }
}
