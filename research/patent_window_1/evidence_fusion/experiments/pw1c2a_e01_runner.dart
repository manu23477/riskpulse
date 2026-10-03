import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';

import '../contracts/experiment_result.dart';
import '../contracts/metric_contract.dart';
import '../contracts/model_output_contract.dart';
import '../harness/experiment_configuration.dart';
import '../harness/ground_truth_evaluator.dart';
import '../harness/visible_dataset_loader.dart';
import '../models/model_a_weighted_fusion_contract.dart';
import '../models/model_b_bayesian_updating_contract.dart';
import '../models/model_c_evidence_graph_contract.dart';

void main() async {
  print('============================================================');
  print('PATENT WINDOW 1C-2A: EXPERIMENT PW1C2A-E01 RUNNER STARTING');
  print('============================================================');

  // Step 1: Verify Dataset Hashes
  _verifyDatasetHashes();

  // Step 2: Load Visible Dataset
  final visibleLoader = VisibleDatasetLoader();
  final visibleEvidence = visibleLoader.loadAndValidateVisibleDataset();

  // Group evidence by caseId (CASE-01 through CASE-50)
  final caseMap = <String, List<VisibleEvidenceObject>>{};
  for (final ev in visibleEvidence) {
    caseMap.putIfAbsent(ev.caseId, () => []).add(ev);
  }

  print('Loaded ${visibleEvidence.length} visible evidence records across ${caseMap.length} cases.');

  // Initialize Ground Truth Evaluator (Isolated Evaluation Layer)
  final evaluator = GroundTruthEvaluator();

  // Step 3: Instantiate Models with Frozen Parameters
  final modelA = ModelAWeightedFusion(
    sourceReliabilityWeight: 0.25,
    semanticAgreementWeight: 0.25,
    spatialAgreementWeight: 0.25,
    temporalAgreementWeight: 0.25,
  );

  final modelB = ModelBBayesianUpdating(
    priorProbability: 0.50,
    likelihoodRatioCorroborating: 2.50,
    likelihoodRatioContradicting: 0.30,
    updatingThreshold: 0.85,
  );

  final modelC = ModelCEvidenceGraph(
    enableEchoCancellation: true,
    enableLineagePruning: true,
    contradictionWeightPenalty: 0.40,
    spatialClusteringRadiusMeters: 500.0,
  );

  const timestamp = '2026-09-30T12:00:00Z';
  const seed = 20260929;

  // Run Model A
  print('Running Model A (Conventional Weighted Fusion)...');
  final resultA = await _runModelExperiment(
    model: modelA,
    caseMap: caseMap,
    evaluator: evaluator,
    experimentId: 'PW1C2A-E01-MODA',
    arrivalOrderMode: 'chronological',
    randomSeed: seed,
    timestamp: timestamp,
  );

  // Run Model B
  print('Running Model B (Bayesian Updating)...');
  final resultB = await _runModelExperiment(
    model: modelB,
    caseMap: caseMap,
    evaluator: evaluator,
    experimentId: 'PW1C2A-E01-MODB',
    arrivalOrderMode: 'chronological',
    randomSeed: seed,
    timestamp: timestamp,
  );

  // Run Model C
  print('Running Model C (Evidence-State Graph)...');
  final resultC = await _runModelExperiment(
    model: modelC,
    caseMap: caseMap,
    evaluator: evaluator,
    experimentId: 'PW1C2A-E01-MODC',
    arrivalOrderMode: 'chronological',
    randomSeed: seed,
    timestamp: timestamp,
  );

  // Output Directory
  final outDir = Directory('research/patent_window_1/evidence_fusion/experiments/results/PW1C2A-E01');
  outDir.createSync(recursive: true);

  final encoder = const JsonEncoder.withIndent('  ');

  final fileA = File('${outDir.path}/model_a_results.json');
  final fileB = File('${outDir.path}/model_b_results.json');
  final fileC = File('${outDir.path}/model_c_results.json');
  final aggregateFile = File('${outDir.path}/aggregate_metrics.json');
  final caseResultsFile = File('${outDir.path}/case_results.json');
  final failureRecordsFile = File('${outDir.path}/failure_records.json');
  final manifestFile = File('${outDir.path}/experiment_manifest.json');

  fileA.writeAsStringSync(encoder.convert(resultA.toJson()));
  fileB.writeAsStringSync(encoder.convert(resultB.toJson()));
  fileC.writeAsStringSync(encoder.convert(resultC.toJson()));

  final aggregates = {
    'modelA': resultA.aggregateMetrics.toJson(),
    'modelB': resultB.aggregateMetrics.toJson(),
    'modelC': resultC.aggregateMetrics.toJson(),
  };
  aggregateFile.writeAsStringSync(encoder.convert(aggregates));

  final combinedCaseResults = {
    'modelA_cases': resultA.caseResults.map((c) => c.toJson()).toList(),
    'modelB_cases': resultB.caseResults.map((c) => c.toJson()).toList(),
    'modelC_cases': resultC.caseResults.map((c) => c.toJson()).toList(),
  };
  caseResultsFile.writeAsStringSync(encoder.convert(combinedCaseResults));

  final combinedFailures = {
    'modelA_failures': resultA.failureCases.map((f) => f.toJson()).toList(),
    'modelB_failures': resultB.failureCases.map((f) => f.toJson()).toList(),
    'modelC_failures': resultC.failureCases.map((f) => f.toJson()).toList(),
  };
  failureRecordsFile.writeAsStringSync(encoder.convert(combinedFailures));

  final manifest = {
    'experimentId': 'PW1C2A-E01',
    'experimentName': 'BASELINE-COMPARATIVE-FUSION',
    'datasetVersion': 'PW1C1-DATA-v1.0',
    'groundTruthVersion': 'PW1C1-GT-v1.0',
    'arrivalOrderMode': 'chronological',
    'randomSeed': seed,
    'executionTimestamp': timestamp,
    'inputHashes': {
      'visibleDataset': 'c973a81f33f6a6230f4dbfbcf26d4ca9d54f2c9e78bdcf0394cbbddc4974d618',
      'groundTruthCases': 'b491a6d25bc9a8d9a24d5ff1a9b244ee1bdcd9a39943644fcfcbbdc82e4e4e9b',
      'evidenceTruth': '0a80e152431cf972d73318210ddbf035787614d64f06121ea28dc66ca2234e4a',
      'arrivalControls': 'e5f9a623e843bb324ef120d911e38a29a00b12bc12e9b1e2a0f81d1e4e2a1b9c',
    },
    'modelsEvaluated': [
      {'modelId': modelA.modelId, 'version': modelA.modelVersion, 'parameters': modelA.parameterSet},
      {'modelId': modelB.modelId, 'version': modelB.modelVersion, 'parameters': modelB.parameterSet},
      {'modelId': modelC.modelId, 'version': modelC.modelVersion, 'parameters': modelC.parameterSet},
    ],
    'resultHashes': {
      'modelA': sha256.convert(fileA.readAsBytesSync()).toString(),
      'modelB': sha256.convert(fileB.readAsBytesSync()).toString(),
      'modelC': sha256.convert(fileC.readAsBytesSync()).toString(),
    }
  };

  manifestFile.writeAsStringSync(encoder.convert(manifest));

  print('============================================================');
  print('PW1C2A-E01 EXPERIMENT COMPLETED SUCCESSFULLY');
  print('Results written to: research/patent_window_1/evidence_fusion/experiments/results/PW1C2A-E01/');
  print('============================================================');
}

void _verifyDatasetHashes() {
  final manifestFile = File('research/patent_window_1/evidence_fusion/dataset/manifest/dataset_manifest.json');
  if (!manifestFile.existsSync()) {
    throw StateError('DATASET INTEGRITY FAILURE: dataset_manifest.json missing');
  }

  final manifest = jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
  final filesList = (manifest['files'] as List<dynamic>).cast<Map<String, dynamic>>();

  final expectedHashes = <String, String>{};
  for (final f in filesList) {
    expectedHashes[f['path'] as String] = f['sha256'] as String;
  }

  final visibleFile = File('research/patent_window_1/evidence_fusion/dataset/visible/evidence_objects.json');
  final gtCasesFile = File('research/patent_window_1/evidence_fusion/dataset/ground_truth/ground_truth_cases.json');
  final evTruthFile = File('research/patent_window_1/evidence_fusion/dataset/ground_truth/evidence_truth.json');
  final arrivalFile = File('research/patent_window_1/evidence_fusion/dataset/ground_truth/arrival_order_controls.json');

  if (!visibleFile.existsSync() || !gtCasesFile.existsSync() || !evTruthFile.existsSync() || !arrivalFile.existsSync()) {
    throw StateError('DATASET INTEGRITY FAILURE: Missing dataset artifact files!');
  }

  final visHash = sha256.convert(visibleFile.readAsBytesSync()).toString();
  final gtCasesHash = sha256.convert(gtCasesFile.readAsBytesSync()).toString();
  final evTruthHash = sha256.convert(evTruthFile.readAsBytesSync()).toString();
  final arrHash = sha256.convert(arrivalFile.readAsBytesSync()).toString();

  if (visHash != expectedHashes['visible/evidence_objects.json'] ||
      gtCasesHash != expectedHashes['ground_truth/ground_truth_cases.json'] ||
      evTruthHash != expectedHashes['ground_truth/evidence_truth.json'] ||
      arrHash != expectedHashes['ground_truth/arrival_order_controls.json']) {
    throw StateError('DATASET INTEGRITY FAILURE: Hash mismatch detected against dataset_manifest.json!');
  }

  print('DATASET INTEGRITY VERIFIED: All SHA-256 hashes match frozen v1.0 dataset_manifest.json baseline exactly.');
}

Future<ExperimentResult> _runModelExperiment({
  required dynamic model,
  required Map<String, List<VisibleEvidenceObject>> caseMap,
  required GroundTruthEvaluator evaluator,
  required String experimentId,
  required String arrivalOrderMode,
  required int randomSeed,
  required String timestamp,
}) async {
  final config = ExperimentConfiguration(
    experimentId: experimentId,
    datasetVersion: 'PW1C1-DATA-v1.0',
    modelId: model.modelId as String,
    modelVersion: model.modelVersion as String,
    parameterSet: model.parameterSet as Map<String, dynamic>,
    arrivalOrderMode: arrivalOrderMode,
    randomSeed: randomSeed,
    executionTimestamp: timestamp,
  );

  final caseResults = <CaseResult>[];
  final allFailures = <FailureRecord>[];

  double sumAssocAcc = 0;
  double sumFalseMerge = 0;
  double sumFalseSplit = 0;
  double sumLineageAcc = 0;
  double sumSpatialErr = 0;
  double sumSpatialInf = 0;
  double sumTempErr = 0;
  double sumTempInf = 0;
  double sumContradict = 0;
  double sumProvComp = 0;
  double sumStateRec = 0;

  for (final entry in caseMap.entries) {
    final caseId = entry.key;
    final evidenceList = entry.value;

    final hypotheses = await model.process(
      visibleEvidence: evidenceList,
      configuration: config,
    ) as List<ExperimentEventHypothesis>;

    final cResult = evaluator.evaluateCase(
      caseId: caseId,
      hypotheses: hypotheses,
    );

    caseResults.add(cResult);
    allFailures.addAll(cResult.failures);

    final m = cResult.metrics;
    sumAssocAcc += m.eventAssociationAccuracy;
    sumFalseMerge += m.falseMergeRate;
    sumFalseSplit += m.falseSplitRate;
    sumLineageAcc += m.lineageAccuracy;
    sumSpatialErr += m.spatialErrorMeters;
    sumSpatialInf += m.spatialPrecisionInflationRatio;
    sumTempErr += m.temporalErrorSeconds;
    sumTempInf += m.temporalPrecisionInflationRatio;
    sumContradict += m.contradictionRetentionRate;
    sumProvComp += m.provenanceCompletenessRatio;
    sumStateRec += m.stateReconstructionAccuracy;
  }

  final n = caseResults.length;
  final aggregateMetrics = ExperimentMetrics(
    eventAssociationAccuracy: double.parse((sumAssocAcc / n).toStringAsFixed(4)),
    falseMergeRate: double.parse((sumFalseMerge / n).toStringAsFixed(4)),
    falseSplitRate: double.parse((sumFalseSplit / n).toStringAsFixed(4)),
    lineageAccuracy: double.parse((sumLineageAcc / n).toStringAsFixed(4)),
    spatialErrorMeters: double.parse((sumSpatialErr / n).toStringAsFixed(2)),
    spatialPrecisionInflationRatio: double.parse((sumSpatialInf / n).toStringAsFixed(2)),
    temporalErrorSeconds: double.parse((sumTempErr / n).toStringAsFixed(2)),
    temporalPrecisionInflationRatio: double.parse((sumTempInf / n).toStringAsFixed(2)),
    contradictionRetentionRate: double.parse((sumContradict / n).toStringAsFixed(4)),
    provenanceCompletenessRatio: double.parse((sumProvComp / n).toStringAsFixed(4)),
    stateReconstructionAccuracy: double.parse((sumStateRec / n).toStringAsFixed(4)),
    arrivalOrderRobustness: -1.0, // NOT_EVALUATED in E01 (Chronological order only)
  );

  return ExperimentResult(
    experimentId: experimentId,
    datasetVersion: 'PW1C1-DATA-v1.0',
    modelId: model.modelId as String,
    modelVersion: model.modelVersion as String,
    parameterSet: model.parameterSet as Map<String, dynamic>,
    arrivalOrderMode: arrivalOrderMode,
    caseResults: caseResults,
    aggregateMetrics: aggregateMetrics,
    failureCases: allFailures,
    executionMetadata: {
      'randomnessUsed': 'RANDOMNESS_NOT_USED',
      'totalCasesEvaluated': n,
      'evaluatedTimestamp': timestamp,
      'arrivalOrderRobustnessNote': 'NOT_EVALUATED in E01 (chronological order baseline only)',
    },
  );
}
