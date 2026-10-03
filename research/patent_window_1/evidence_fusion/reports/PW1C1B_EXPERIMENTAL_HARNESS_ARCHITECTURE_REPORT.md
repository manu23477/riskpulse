# PATENT WINDOW 1C-1B EXPERIMENTAL FUSION HARNESS ARCHITECTURE REPORT

**Report ID**: `PW1C1B_EXPERIMENTAL_HARNESS_ARCHITECTURE_REPORT`  
**Workstream**: Patent Window 1 Experimental Fusion Harness Contract  
**Date**: September 29, 2026  
**Visible Dataset Version**: `PW1C1-DATA-v1.0` (SHA-256 Validated & Frozen)  
**Hidden Ground Truth Version**: `PW1C1-GT-v1.0` (SHA-256 Validated & Frozen)  
**Harness Version**: `1.0.0`  
**Authoritative Location**: `research/patent_window_1/evidence_fusion/`  

---

## 1. EXECUTIVE SUMMARY & PURPOSE

This report documents the architectural design, contract specifications, ground-truth isolation safeguards, and validation results for the **Patent Window 1C-1B Experimental Fusion Harness**.

### Primary Purpose:
The 1C-1B experimental harness provides a neutral, standardized, and strictly reproducible benchmark framework to compare three evidence-fusion model approaches (Model A: Conventional Weighted Fusion, Model B: Bayesian Updating, Model C: Evidence-State Graph Model) under identical experimental conditions.

> [!IMPORTANT]
> **EXPERIMENTAL BOUNDARY MANDATE**:
> - NO production RiskPulse code in `lib/` was modified.
> - NO Research GIS code was modified.
> - NO fusion algorithm was evaluated in this milestone.
> - NO model (Model A, B, or C) was declared superior.
> - NO patentability or novelty conclusion was made.

---

## 2. HARNESS PIPELINE & ARCHITECTURE

The experimental pipeline establishes complete architectural separation between model execution and ground-truth evaluation:

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│ VISIBLE DATASET (PW1C1-DATA-v1.0)                                               │
│ visible/evidence_objects.json                                                   │
└─────────────────────────────────────────────────────────────────────────────────┘
                                       │
                                       ▼ (SHA-256 Hash Validation)
┌─────────────────────────────────────────────────────────────────────────────────┐
│ VisibleDatasetLoader                                                            │
│ Strictly isolated — CANNOT access ground_truth/ directory                       │
└─────────────────────────────────────────────────────────────────────────────────┘
                                       │
                                       ▼ (Arrival Order Permutations)
┌─────────────────────────────────────────────────────────────────────────────────┐
│ ExperimentConfiguration & ExperimentModel (Model A / Model B / Model C)         │
│ Input: List<VisibleEvidenceObject> (0 ground truth fields)                      │
│ Output: List<ExperimentEventHypothesis>                                         │
└─────────────────────────────────────────────────────────────────────────────────┘
                                       │
                                       ▼ (Model Outputs Passed to Evaluator)
┌─────────────────────────────────────────────────────────────────────────────────┐
│ GroundTruthEvaluator (Evaluation Layer ONLY)                                    │
│ Accesses: ground_truth_cases.json, evidence_truth.json, arrival_controls.json  │
└─────────────────────────────────────────────────────────────────────────────────┘
                                       │
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│ ExperimentResult & 12-Metric Performance Report                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. GROUND-TRUTH ISOLATION AUDIT

A forensic source code audit was conducted on all model contracts, model classes, and visible dataset loaders:

- **Files Audited**: `contracts/`, `models/`, `harness/visible_dataset_loader.dart`.
- **Forbidden Ground-Truth Field Scan**: Searched for `trueEventId`, `trueLineageId`, `trueRelationship`, `trueCoordinates`, `trueHazard`, `trueEventTime`, `trueEventState`.
- **Audit Result**: **0 Forbidden Key Occurrences in Model Code**. Ground-truth imports and field references are confined exclusively to `GroundTruthEvaluator` inside the evaluation layer.

---

## 4. DATASET IMMUTABILITY & HASH VERIFICATION

Before harness execution, dataset integrity was verified against `dataset/manifest/dataset_manifest.json`:

| File Path | Version | Expected SHA-256 Digest | Audit Status |
| :--- | :---: | :--- | :---: |
| `visible/evidence_objects.json` | `PW1C1-DATA-v1.0` | `c973a81f33f6a6230f4dbfbcf26d4ca9d54f2c9e78bdcf0394cbbddc4974d618` | **MATCH (FROZEN)** |
| `ground_truth/ground_truth_cases.json` | `PW1C1-GT-v1.0` | `b491a6d25bc9a8d9a24d5ff1a9b244ee1bdcd9a39943644fcfcbbdc82e4e4e9b` | **MATCH (FROZEN)** |
| `ground_truth/evidence_truth.json` | `PW1C1-GT-v1.0` | `0a80e152431cf972d73318210ddbf035787614d64f06121ea28dc66ca2234e4a` | **MATCH (FROZEN)** |
| `ground_truth/arrival_order_controls.json` | `PW1C1-GT-v1.0` | `e5f9a623e843bb324ef120d911e38a29a00b12bc12e9b1e2a0f81d1e4e2a1b9c` | **MATCH (FROZEN)** |

> [!CAUTION]
> If any dataset file SHA-256 hash fails validation, `VisibleDatasetLoader` or `GroundTruthEvaluator` immediately throws a `StateError`, halting execution to prevent silent corruption.

---

## 5. CONTRACT SPECIFICATIONS

### A. Common Model Interface (`ExperimentModel`)
- Neutral abstract interface requiring `modelId`, `modelVersion`, `parameterSet`, and deterministic `process(visibleEvidence, configuration)`.
- Input contains strictly `VisibleEvidenceObject` list preserving all 15 source provenance fields.

### B. Common Output Contract (`ExperimentEventHypothesis`)
- Structured output containing: `eventHypothesisId`, `hazardType`, `candidateGeometry`, `spatialUncertaintyMeters`, `candidateTime`, `temporalUncertaintySeconds`, `supportingEvidenceIds`, `conflictingEvidenceIds`, `lineageReferences`, `eventState`, `confidenceComponents`, `overallConfidence`, `modelId`, `modelVersion`.

### C. Model A Contract (`ModelAWeightedFusion`)
- Conventional weighted fusion baseline contract supporting parameters: `sourceReliabilityWeight`, `semanticAgreementWeight`, `spatialAgreementWeight`, `temporalAgreementWeight`.

### D. Model B Contract (`ModelBBayesianUpdating`)
- Sequential Bayesian updating baseline contract supporting parameters: `priorProbability`, `likelihoodRatioCorroborating`, `likelihoodRatioContradicting`, `updatingThreshold`.

### E. Model C Contract (`ModelCEvidenceGraph`)
- Evidence-state graph model contract preserving `EvidenceNode` -> `InterpretationNode` -> `EventHypothesisNode` graph representations, independent/repost lineage edges, explicit contradiction retention, and parameters `enableEchoCancellation`, `enableLineagePruning`, `contradictionWeightPenalty`, `spatialClusteringRadiusMeters`.

---

## 6. METRIC & RESULT CONTRACTS

The evaluation layer computes 12 neutral performance metrics in `ExperimentMetrics`:
1. **Event Association Accuracy**: Ratio of correctly associated evidence-to-event pairs.
2. **False Merge Rate**: Rate at which distinct events are incorrectly merged.
3. **False Split Rate**: Rate at which evidence from a single event is split into multiple hypotheses.
4. **Lineage Accuracy**: Proportion of evidence lineage chains correctly preserved.
5. **Spatial Error (Meters)**: Mean geodesic distance between candidate geometry and ground truth.
6. **Spatial Precision Inflation Ratio**: Ratio of estimated spatial uncertainty area to true extent area.
7. **Temporal Error (Seconds)**: Difference in seconds between candidate event time and true event start/center.
8. **Temporal Precision Inflation Ratio**: Ratio of model temporal window tightness to actual event duration.
9. **Contradiction Retention Rate**: Proportion of conflicting evidence items retained in `conflictingEvidenceIds`.
10. **Provenance Completeness Ratio**: Ratio of visible source attributes retained in output.
11. **State Reconstruction Accuracy**: Accuracy of reconstructed event lifecycle state.
12. **Arrival-Order Robustness**: Similarity score of hypotheses output across chronological, shuffled, and reverse arrival permutations.

Every experiment run produces a full `ExperimentResult` containing `parameterSet`, `arrivalOrderMode`, `caseResults`, `aggregateMetrics`, `failureCases` (`false_merge`, `false_split`, `incorrect_lineage`, etc.), and execution metadata.

---

## 7. AUTOMATED TEST & ANALYZER RESULTS

1. **Harness Test Suite (`test/patent_window_1_harness_test.dart`)**:
   - **12 / 12 Tests Passed GREEN** (Covering loader validation, isolation, model interfaces, output contracts, parameter recording, evaluator metrics, arrival permutations, and failure recording).
2. **Dataset Test Suite (`test/patent_window_1_dataset_test.dart`)**:
   - **22 / 22 Test Groups Passed GREEN** (Covering all 26 Section 23 dataset validation checks).
3. **Flutter Analyzer**:
   - **0 Errors, 0 Warnings** across all 1C-1B contract files.

---

## 8. FORMAL MANDATORY CONFIRMATIONS

1. **"NO PRODUCTION RISKPULSE CODE MODIFIED."** (`lib/` remains 100% untouched).
2. **"NO FUSION ALGORITHM WAS EVALUATED IN THIS MILESTONE."**
3. **"NO PATENTABILITY OR NOVELTY CONCLUSION WAS MADE."**
