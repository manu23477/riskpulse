import 'package:riskpulse/domain/gis/analytical_step.dart';
import 'package:riskpulse/domain/forecasting/forecasting.dart';
import 'package:riskpulse/data/services/forecasting/decision_support_engine.dart';

/// Provider-neutral deterministic engine for generating and filtering a [ResearchPriorityQueue]
/// from research decision-support [ResearchSituationBrief]s.
///
/// SCIENTIFIC GOVERNANCE RULES:
/// 1. PriorityScore represents RESEARCH WORKFLOW PRIORITY ONLY (NOT a probability or disaster risk score).
/// 2. NO arbitrary weighted composite risk formulas (e.g. H x E x V).
/// 3. Actual Observed and Scenario Conditional contexts are strictly preserved.
/// 4. Deduplication respects stable item identity (preserves first occurrence).
class ResearchPriorityQueueEngine {
  static const String researchPriorityRuleVersion = '3.9.8-v1';

  final DecisionSupportEngine decisionSupportEngine;

  const ResearchPriorityQueueEngine({
    this.decisionSupportEngine = const DecisionSupportEngine(),
  });

  /// Generates a [ResearchPriorityQueue] from a collection of [ResearchSituationBrief]s.
  ResearchPriorityQueue generateQueue({
    required String queueId,
    required List<ResearchSituationBrief> briefs,
    DateTime? generatedAt,
  }) {
    if (queueId.trim().isEmpty) {
      throw ArgumentError('queueId cannot be empty.');
    }

    final now = generatedAt ?? DateTime.now().toUtc();

    // 1. Deduplicate briefs by briefId (preserve first occurrence)
    final deduplicatedBriefs = <ResearchSituationBrief>[];
    final seenBriefIds = <String>{};

    for (final brief in briefs) {
      if (seenBriefIds.add(brief.briefId)) {
        deduplicatedBriefs.add(brief);
      }
    }

    // 2. Assemble Analytical Provenance Step
    final step = AnalyticalStep(
      name: 'research_priority_queue_generation',
      operationType: 'priority_queue_eval',
      parameters: {
        'researchPriorityRuleVersion': researchPriorityRuleVersion,
        'decisionRuleVersion': DecisionSupportEngine.decisionRuleVersion,
        'totalBriefCount': briefs.length,
        'deduplicatedBriefCount': deduplicatedBriefs.length,
      },
      timestamp: now,
      inputReferences: [
        queueId,
        ...deduplicatedBriefs.map((b) => b.briefId),
      ],
    );

    // 3. Transform briefs into ResearchAttentionItems and attach provenance step
    final items = <ResearchAttentionItem>[];
    for (final brief in deduplicatedBriefs) {
      final updatedBrief = brief.copyWith(
        provenanceSteps: [...brief.provenanceSteps, step],
      );
      final item = decisionSupportEngine.createAttentionItem(
        itemId: 'item-${brief.briefId}',
        brief: updatedBrief,
      );
      items.add(item);
    }

    return ResearchPriorityQueue(
      queueId: queueId,
      generatedAt: now,
      items: items, // ResearchPriorityQueue constructor automatically sorts descending by priorityScore
      schemaVersion: ResearchPriorityQueue.currentSchemaVersion,
    );
  }

  /// Generates a queue containing ONLY briefs with situationContext == 'actual_observed'.
  ResearchPriorityQueue generateActualObservedQueue({
    required String queueId,
    required List<ResearchSituationBrief> briefs,
    DateTime? generatedAt,
  }) {
    final filtered = briefs.where((b) => b.isActualObserved).toList();
    return generateQueue(
      queueId: queueId,
      briefs: filtered,
      generatedAt: generatedAt,
    );
  }

  /// Generates a queue containing ONLY briefs with situationContext == 'scenario_conditional'.
  ResearchPriorityQueue generateScenarioConditionalQueue({
    required String queueId,
    required List<ResearchSituationBrief> briefs,
    DateTime? generatedAt,
  }) {
    final filtered = briefs.where((b) => b.isScenarioConditional).toList();
    return generateQueue(
      queueId: queueId,
      briefs: filtered,
      generatedAt: generatedAt,
    );
  }
}
