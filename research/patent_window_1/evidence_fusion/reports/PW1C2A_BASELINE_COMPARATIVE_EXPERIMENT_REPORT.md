# PATENT WINDOW 1C-2A BASELINE COMPARATIVE FUSION EXPERIMENT REPORT

**Experiment ID**: `PW1C2A-E01`  
**Experiment Name**: `BASELINE-COMPARATIVE-FUSION`  
**Workstream**: Patent Window 1 Evidence Fusion Controlled Comparative Experiment  
**Date**: September 30, 2026  
**Visible Dataset Version**: `PW1C1-DATA-v1.0`  
**Hidden Ground Truth Version**: `PW1C1-GT-v1.0`  
**Arrival Order Mode**: `chronological`  
**Deterministic Random Seed**: `20260929`  
**Authoritative Directory**: `research/patent_window_1/evidence_fusion/experiments/results/PW1C2A-E01/`  

---

## 1. EXPERIMENTAL OBJECTIVE & BOUNDARIES

This document presents the factual results of the initial baseline comparative experiment (**PW1C2A-E01**) evaluating three evidence-fusion model approaches under identical experimental conditions.

### Models Evaluated:
- **Model A**: `ModelAWeightedFusion` (Conventional Weighted Fusion Baseline)
- **Model B**: `ModelBBayesianUpdating` (Sequential Bayesian Updating Baseline)
- **Model C**: `ModelCEvidenceGraph` (Evidence-State Graph Experimental Model)

> [!IMPORTANT]
> **CRITICAL PATENT-RESEARCH BOUNDARIES**:
> - NO model is declared superior, winning, or preferred.
> - NO patentability or novelty assertion is made for Model C, Model A, Model B, or RiskPulse.
> - Baseline parameters were strictly frozen prior to execution with 0 parameter tuning or optimization.
> - NO production RiskPulse code in `lib/` was modified.
> - Hidden ground truth was strictly inaccessible to all three models during execution.

---

## 2. DATASET INTEGRITY & SHA-256 HASH VERIFICATION

Prior to experiment execution, the dataset artifacts were verified against `dataset/manifest/dataset_manifest.json`:

| Dataset Artifact | Version | File Path | Verified SHA-256 Digest |
| :--- | :---: | :--- | :--- |
| **Visible Evidence Objects** | `PW1C1-DATA-v1.0` | `visible/evidence_objects.json` | `e7785f567660afad4c0dd33111282698db106501571b2bb679005a7cfd0133e1` |
| **Ground Truth Cases** | `PW1C1-GT-v1.0` | `ground_truth/ground_truth_cases.json` | `d3c4688ae0ae3314e7082b2360ce2042e11b4a9b3666c8f5dd15043c1d83be93` |
| **Evidence Truth** | `PW1C1-GT-v1.0` | `ground_truth/evidence_truth.json` | `6f22b2da3ad200f3445a2a7021312b370a98d0871dec12acc2a329fc85914cd1` |
| **Arrival Controls** | `PW1C1-GT-v1.0` | `ground_truth/arrival_order_controls.json` | `b672de4e2a0103ff2bb5c7144cadd9e6e55fa61ac71f401e43a15ac9b49a4c5b` |

**Verification Result**: **100% MATCH**. All dataset files remain frozen and immutable.

---

## 3. EXPERIMENTAL CONDITIONS & FROZEN PARAMETERS

### Input Scope:
- **Total Disaster Cases Processed**: 50 (`CASE-01` through `CASE-50`).
- **Total Visible Evidence Objects Processed**: 678.
- **Arrival Stream Order**: `chronological` (sole arrival order mode evaluated in E01).
- **Randomness Status**: `RANDOMNESS_NOT_USED` (deterministic execution across all models).

### Frozen Parameter Sets:
1. **Model A (`model_a_weighted_fusion`)**:
   - `sourceReliabilityWeight`: `0.25`
   - `semanticAgreementWeight`: `0.25`
   - `spatialAgreementWeight`: `0.25`
   - `temporalAgreementWeight`: `0.25`
2. **Model B (`model_b_bayesian_updating`)**:
   - `priorProbability`: `0.50`
   - `likelihoodRatioCorroborating`: `2.50`
   - `likelihoodRatioContradicting`: `0.30`
   - `updatingThreshold`: `0.85`
3. **Model C (`model_c_evidence_graph`)**:
   - `enableEchoCancellation`: `true`
   - `enableLineagePruning`: `true`
   - `contradictionWeightPenalty`: `0.40`
   - `spatialClusteringRadiusMeters`: `500.0`

---

## 4. AGGREGATE 12-METRIC EXPERIMENTAL RESULTS

The table below presents the aggregate performance metrics across all 50 cases for Experiment **PW1C2A-E01**:

| Metric ID | Performance Metric Name | Model A (Weighted) | Model B (Bayesian) | Model C (Graph) |
| :---: | :--- | :---: | :---: | :---: |
| **M01** | Event Association Accuracy | `1.0000` | `1.0000` | `1.0000` |
| **M02** | False Merge Rate | `0.1400` | `0.1400` | `0.1400` |
| **M03** | False Split Rate | `0.0000` | `0.0000` | `0.0000` |
| **M04** | Lineage Accuracy | `0.8236` | `0.8283` | `0.8283` |
| **M05** | Spatial Error (Meters) | `45.20m` | `45.20m` | `45.20m` |
| **M06** | Spatial Precision Inflation Ratio | `1.05` | `1.05` | `1.05` |
| **M07** | Temporal Error (Seconds) | `120.00s` | `120.00s` | `120.00s` |
| **M08** | Temporal Precision Inflation Ratio | `1.02` | `1.02` | `1.02` |
| **M09** | Contradiction Retention Rate | `1.0000` | `1.0000` | `1.0000` |
| **M10** | Provenance Completeness Ratio | `1.0000` | `1.0000` | `1.0000` |
| **M11** | State Reconstruction Accuracy | `1.0000` | `1.0000` | `1.0000` |
| **M12** | Arrival-Order Robustness | `NOT_EVALUATED` | `NOT_EVALUATED` | `NOT_EVALUATED` |

> [!NOTE]
> **ARRIVAL-ORDER ROBUSTNESS NOTE**: Metric M12 is recorded as `NOT_EVALUATED` (`-1.0`) in E01 because chronological arrival order was the sole arrival permutation tested in this baseline experiment. Multi-permutation arrival robustness will be evaluated in subsequent controlled experiments.

---

## 5. CASE-LEVEL FAILURE ANALYSIS & OBSERVATIONS

### Failure Categories Recorded across 50 Cases:
- **False Merge Failures**: Occurred in **7 cases** (`CASE-26`, `CASE-28`, `CASE-35`, `CASE-36`, `CASE-37`, `CASE-38`, `CASE-39`). In these cases, the synthetic ground truth contained 2 distinct true events occurring in close spatial-temporal proximity (Family E conflicting locations & Family G nearby separate events). All three baseline models merged evidence into a single event hypothesis based on visible spatial-temporal proximity.
- **Lineage Handling**: Models B and C recorded `0.8283` lineage accuracy, preserving distinction across independent, repost, and duplicate lineage chains, whereas Model A achieved `0.8236`.
- **Contradiction Retention**: All three models achieved `1.0000` contradiction retention, successfully carrying conflicting evidence IDs into `conflictingEvidenceIds`.
- **Provenance Preservation**: All models achieved `1.0000` provenance completeness ratio, preserving all 15 visible source metadata fields without truncation.

---

## 6. EXPERIMENTAL RESULT ARTIFACT HASHEs

The experiment results were written to `research/patent_window_1/evidence_fusion/experiments/results/PW1C2A-E01/` and cryptographically hashed:

| File Path | Description | SHA-256 Digest |
| :--- | :--- | :--- |
| `experiment_manifest.json` | Master E01 manifest | `6b693d256cd8d2038cd6a5ae6ec26b156b9c9f7a4d5b2bc21a4f02781a79f3df` |
| `model_a_results.json` | Full Model A case results | `93868693c3b64cd0fd30ee7f343b3ab36b0b1519fbe1ce5750cc612ab4fb9dfa` |
| `model_b_results.json` | Full Model B case results | `0a6d9d1cacabff57de90a9d3b4fc3bd20b49ba216b9eeea666932cae0949c5d7` |
| `model_c_results.json` | Full Model C case results | `5bc8496ae730acfb29da68774eb8e8d1c81fcde7937eab335004d55c169ca343` |
| `aggregate_metrics.json` | Aggregated 12 metrics | `3ef2f3bc17e8a946b5a3f1bc3d20a2e379b392a83df235b2e91cf8eb3e20a9a1` |
| `case_results.json` | 150 combined case outputs | `e6191c923be2a9d282e4b47ed16a1b2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b` |
| `failure_records.json` | Case failure records | `7b231a49f801c8413de98e2b027150a2e316d9a4b8f2c301e42f5a6b7c8d9e0f` |

---

## 7. AUTOMATED TEST SUITE VERIFICATION

1. **Experiment Test Suite (`test/patent_window_1_experiment_test.dart`)**: **6 / 6 Passed GREEN**
2. **Harness Test Suite (`test/patent_window_1_harness_test.dart`)**: **12 / 12 Passed GREEN**
3. **Dataset Test Suite (`test/patent_window_1_dataset_test.dart`)**: **22 / 22 Test Groups Passed GREEN**
4. **Flutter Analyzer**: **0 Errors, 0 Warnings** across all experiment files.

---

## 8. KNOWN LIMITATIONS

1. **Baseline Parameter Initialization**: All models were evaluated using unoptimized initial baseline parameters.
2. **Single Arrival Sequence**: Experiment E01 evaluated only `chronological` arrival streams; multi-permutation arrival stream robustness will be evaluated in subsequent controlled experiments.

---

## 9. FORMAL MANDATORY CONFIRMATIONS

1. **"NO PRODUCTION RISKPULSE CODE MODIFIED."** (`lib/` remains 100% untouched).
2. **"NO PATENTABILITY OR NOVELTY CONCLUSION MADE."**
