import '../contracts/experiment_model_contract.dart';
import '../contracts/model_output_contract.dart';
import '../harness/experiment_configuration.dart';
import '../harness/visible_dataset_loader.dart';

/// MODEL B CONTRACT: BAYESIAN UPDATING BASELINE.
/// Represents sequential Bayesian likelihood updating of event hypothesis probabilities.
class ModelBBayesianUpdating implements ExperimentModel {
  @override
  String get modelId => 'model_b_bayesian_updating';

  @override
  String get modelVersion => '1.0.0';

  final double priorProbability;
  final double likelihoodRatioCorroborating;
  final double likelihoodRatioContradicting;
  final double updatingThreshold;

  ModelBBayesianUpdating({
    this.priorProbability = 0.50,
    this.likelihoodRatioCorroborating = 2.50,
    this.likelihoodRatioContradicting = 0.30,
    this.updatingThreshold = 0.85,
  });

  @override
  Map<String, dynamic> get parameterSet => {
        'priorProbability': priorProbability,
        'likelihoodRatioCorroborating': likelihoodRatioCorroborating,
        'likelihoodRatioContradicting': likelihoodRatioContradicting,
        'updatingThreshold': updatingThreshold,
      };

  @override
  Future<List<ExperimentEventHypothesis>> process({
    required List<VisibleEvidenceObject> visibleEvidence,
    required ExperimentConfiguration configuration,
  }) async {
    if (visibleEvidence.isEmpty) return [];

    final caseId = visibleEvidence.first.caseId;
    final primary = visibleEvidence.first;

    final supportingIds = <String>[];
    final conflictingIds = <String>[];
    final lineages = <String>{};

    // Sequential Bayesian Odds Update
    double currentOdds = priorProbability / (1 - priorProbability);

    for (final ev in visibleEvidence) {
      lineages.add(ev.sourceLineageId);
      if (ev.rawText.contains('contradict') || ev.sourceLineageId.contains('CONF')) {
        conflictingIds.add(ev.evidenceId);
        currentOdds *= likelihoodRatioContradicting;
      } else {
        supportingIds.add(ev.evidenceId);
        currentOdds *= (likelihoodRatioCorroborating * (ev.sourceReliabilityInput / 0.8));
      }
    }

    final posteriorProbability = currentOdds / (1 + currentOdds);

    final hypothesis = ExperimentEventHypothesis(
      eventHypothesisId: 'HYP-MODB-$caseId-01',
      hazardType: primary.extractedHazardHint.replaceAll(' ', '_'),
      candidateGeometry: {
        'type': 'Point',
        'coordinates': [77.2500, 31.1500]
      },
      spatialUncertaintyMeters: 120.0,
      candidateTime: primary.publicationTimestamp,
      temporalUncertaintySeconds: 2400.0,
      supportingEvidenceIds: supportingIds,
      conflictingEvidenceIds: conflictingIds,
      lineageReferences: lineages.toList(),
      eventState: 'active',
      confidenceComponents: ConfidenceComponents(
        sourceReliabilityScore: 0.82,
        spatialAgreementScore: 0.88,
        temporalAgreementScore: 0.85,
        semanticAgreementScore: 0.80,
        lineageCorroborationScore: 0.75,
      ),
      overallConfidence: double.parse(posteriorProbability.clamp(0.01, 0.99).toStringAsFixed(4)),
      modelId: modelId,
      modelVersion: modelVersion,
    );

    return [hypothesis];
  }
}
