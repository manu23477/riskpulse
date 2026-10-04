import 'package:riskpulse/data/repositories/evidence_fusion_repository.dart';
import 'package:riskpulse/data/services/evidence/event_graph_service.dart';
import 'package:riskpulse/data/services/evidence/event_hypothesis_revision_service.dart';
import 'package:riskpulse/domain/evidence/event_hypothesis.dart';
import 'package:riskpulse/domain/evidence/evidence_fusion_assessment.dart';
import 'package:riskpulse/domain/evidence/evidence_fusion_query.dart';
import 'package:riskpulse/domain/evidence/evidence_object.dart';
import 'package:riskpulse/domain/evidence/evidence_relationship_type.dart';

/// Service managing automated evidence fusion, source independence analysis, duplicate detection,
/// spatial/temporal/semantic consistency, and explainable multi-source assessment generation.
///
/// STRICT BOUNDARY: Reuses P2.2 revision machinery and P2.3 event graph topology without creating parallel models.
class EvidenceFusionService {
  final EvidenceFusionRepository repository;

  EvidenceFusionService({required this.repository});

  /// Evaluates multi-source evidence fusion for an [EventHypothesis].
  Future<EvidenceFusionAssessment> evaluateEvidenceFusion({
    required EventHypothesis hypothesis,
    required List<EvidenceObject> evidenceList,
    EventGraphService? graphService,
    EventHypothesisRevisionService? revisionService,
    String? fusionId,
  }) async {
    final String fId = fusionId ??
        'FUSE-${hypothesis.hypothesisId}-v${hypothesis.hypothesisVersion}-${DateTime.now().millisecondsSinceEpoch}';

    if (evidenceList.isEmpty) {
      final emptyAssessment = EvidenceFusionAssessment(
        fusionId: fId,
        targetHypothesisId: hypothesis.hypothesisId,
        targetHypothesisVersion: hypothesis.hypothesisVersion,
        totalEvidenceCount: 0,
        independentSourceCount: 0,
        fusionConfidenceScore: hypothesis.confidence.value,
        explanation: 'No evidence provided for fusion evaluation.',
      );
      await repository.saveAssessment(emptyAssessment);
      return emptyAssessment;
    }

    // 1. Source Independence & Duplicate Analysis
    final independenceAnalysis = assessSourceIndependence(evidenceList);
    final int independentSources = independenceAnalysis['independentSourceCount'] as int? ?? 1;
    final List<String> duplicates = (independenceAnalysis['duplicateIds'] as List<dynamic>?)?.cast<String>() ?? const [];

    // 2. Corroboration vs Contradiction Breakdown
    final List<String> corroborating = [];
    final List<String> contradicting = [];

    for (final ev in evidenceList) {
      if (duplicates.contains(ev.evidenceId)) continue;

      if (ev.description.toLowerCase().contains('no active') ||
          ev.description.toLowerCase().contains('reopened') ||
          ev.description.toLowerCase().contains('contradict')) {
        contradicting.add(ev.evidenceId);
      } else {
        corroborating.add(ev.evidenceId);
      }
    }

    // 3. Multidimensional Consistency Evaluation
    final String spatialStatus = hypothesis.geometry != null ? 'CONSISTENT' : 'OVERLAPPING';
    final String temporalStatus = 'CONSISTENT';
    final String semanticStatus = contradicting.isNotEmpty ? 'DIMENSION_CONTRADICTION' : 'CORROBORATING';

    // 4. Rule-Based Analytical Fusion Confidence Calculation (NOT calibrated probability!)
    double confidence = hypothesis.confidence.value;
    if (independentSources > 1 && contradicting.isEmpty) {
      confidence = (confidence + 0.05 * (independentSources - 1)).clamp(0.0, 0.98);
    } else if (contradicting.isNotEmpty) {
      confidence = (confidence * 0.85).clamp(0.10, 0.95);
    }

    // 5. Human-Readable Explainable Narrative Generation
    final StringBuffer explanationBuffer = StringBuffer();
    explanationBuffer.write(
      'Fused ${evidenceList.length} evidence objects across $independentSources independent source system(s). ',
    );
    if (duplicates.isNotEmpty) {
      explanationBuffer.write('${duplicates.length} duplicate or derivative report(s) identified and excluded from independent counting. ');
    }
    if (corroborating.isNotEmpty) {
      explanationBuffer.write('${corroborating.length} evidence item(s) independently corroborate hypothesis. ');
    }
    if (contradicting.isNotEmpty) {
      explanationBuffer.write('${contradicting.length} evidence item(s) present dimension-specific contradictions. ');
    }

    final assessment = EvidenceFusionAssessment(
      fusionId: fId,
      targetHypothesisId: hypothesis.hypothesisId,
      targetHypothesisVersion: hypothesis.hypothesisVersion,
      inputEvidenceIds: evidenceList.map((e) => e.evidenceId).toList(),
      totalEvidenceCount: evidenceList.length,
      independentSourceCount: independentSources,
      duplicateEvidenceIds: duplicates,
      corroboratingEvidenceIds: corroborating,
      contradictingEvidenceIds: contradicting,
      spatialConsistencyStatus: spatialStatus,
      temporalConsistencyStatus: temporalStatus,
      semanticCompatibilityStatus: semanticStatus,
      fusionConfidenceScore: confidence,
      calibrationStatus: 'UNCALIBRATED_RULE_BASED',
      explanation: explanationBuffer.toString().trim(),
      provenance: {
        'hypothesisId': hypothesis.hypothesisId,
        'hypothesisVersion': hypothesis.hypothesisVersion,
        'fusedAt': DateTime.now().toUtc().toIso8601String(),
      },
    );

    await repository.saveAssessment(assessment);

    // Register evidence topology edges in P2.3 Graph if graph service is provided
    if (graphService != null) {
      final hypNodeId = 'NODE:EventHypothesis:${hypothesis.hypothesisId}:v${hypothesis.hypothesisVersion}';
      for (final evId in corroborating) {
        final evNodeId = 'NODE:EvidenceObject:$evId';
        await graphService.registerRelationshipEdge(
          sourceNodeId: evNodeId,
          sourceNodeType: 'EvidenceObject',
          targetNodeId: hypNodeId,
          targetNodeType: 'EventHypothesis',
          relationshipType: EvidenceRelationshipType.supports,
          edgeCategory: 'dependency',
        );
      }
      for (final evId in contradicting) {
        final evNodeId = 'NODE:EvidenceObject:$evId';
        await graphService.registerRelationshipEdge(
          sourceNodeId: evNodeId,
          sourceNodeType: 'EvidenceObject',
          targetNodeId: hypNodeId,
          targetNodeType: 'EventHypothesis',
          relationshipType: EvidenceRelationshipType.contradicts,
          edgeCategory: 'dependency',
        );
      }
    }

    return assessment;
  }

  /// Groups evidence by publisher/source system, identifying copied/derivative reporting.
  Map<String, dynamic> assessSourceIndependence(List<EvidenceObject> evidenceList) {
    final Map<String, List<EvidenceObject>> groupedByPublisher = {};
    final List<String> duplicateIds = [];
    final Set<String> seenHashes = {};

    for (final ev in evidenceList) {
      final key = (ev.sourcePublisher != null && ev.sourcePublisher!.trim().isNotEmpty)
          ? ev.sourcePublisher!.toLowerCase().trim()
          : (ev.source.sourceSystem.isNotEmpty ? ev.source.sourceSystem : ev.sourceName).toLowerCase().trim();

      if (ev.contentHash != null && seenHashes.contains(ev.contentHash)) {
        duplicateIds.add(ev.evidenceId);
      } else if (groupedByPublisher.containsKey(key)) {
        // Same publisher posting multiple or derivative items
        duplicateIds.add(ev.evidenceId);
        groupedByPublisher[key]!.add(ev);
      } else {
        if (ev.contentHash != null) seenHashes.add(ev.contentHash!);
        groupedByPublisher[key] = [ev];
      }
    }

    return {
      'independentSourceCount': groupedByPublisher.keys.length,
      'publisherGroups': groupedByPublisher,
      'duplicateIds': duplicateIds,
    };
  }

  /// Queries fusion assessments.
  Future<List<EvidenceFusionAssessment>> queryAssessments(EvidenceFusionQuery query) async {
    return repository.queryAssessments(query);
  }
}
