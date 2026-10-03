# PATENT WINDOW 1C-2B CONTROLLED MULTI-PERMUTATION & DEPENDENCY PROPAGATION EXPERIMENT REPORT

**Experiment ID**: `PW1C2B-E02`  
**Experiment Name**: `CONTROLLED-MULTI-PERMUTATION-AND-ACTIVE-DEPENDENCY-PROPAGATION`  
**Workstream**: Patent Window 1 Evidence Fusion Experimental Research  
**Date**: September 30, 2026  
**Visible Dataset Version**: `PW1C1-DATA-v1.0` (SHA-256 Validated & Frozen)  
**Hidden Ground Truth Version**: `PW1C1-GT-v1.0` (SHA-256 Validated & Frozen)  
**Deterministic Random Seed**: `20260929`  
**Authoritative Directory**: `research/patent_window_1/evidence_fusion/experiments/results/PW1C2B-E02/`  

---

## 1. EXECUTIVE SUMMARY & RESEARCH QUESTIONS

This report documents the experimental implementation and quantitative results for **Patent Window 1C-2B** (`PW1C2B-E02`), evaluating multi-permutation arrival stream robustness (Arm A) and active evidence mutation dependency propagation (Arm B).

### Primary Research Questions Investigated:
1. **Arm A (Arrival Stream Robustness)**: Does evidence arrival order (`chronological`, `shuffled`, `reverse`) alter final event state, spatial-temporal hypotheses, contradiction retention, or provenance?
2. **Arm B (Selective Dependency Propagation)**: Can an upstream evidence mutation be propagated through an explicit 6-layer dependency graph (`Evidence` -> `Interpretation` -> `EventHypothesis` -> `SpatialState` -> `AdministrativeState` -> `RiskState`) to selectively recompute affected downstream states while preserving unaffected states, retaining historical state versions ($V_1, V_2, V_3, V_4$), and maintaining 100% full-rebuild equivalence?

> [!IMPORTANT]
> **RESEARCH BOUNDARY MANDATE**:
> - NO production RiskPulse code in `lib/` was modified.
> - NO model is declared superior, winning, or preferred.
> - NO patentability, novelty, or inventive step assertion is made in this report.
> - Baseline parameters were frozen prior to execution.
> - Hidden ground truth was strictly inaccessible to mutation generation and model execution.

---

## 2. RELATIONSHIP TO BASELINE EXPERIMENT E01

Experiment E01 established the initial baseline metrics under static chronological arrival conditions. Experiment E02 extends E01 by:
1. Evaluating Models A, B, and C across 3 deterministic arrival stream permutations (`chronological`, `shuffled`, `reverse`).
2. Introducing an explicit 6-layer experimental dependency graph (`DependencyGraphEngine`) and immutable state versioning (`EventStateHistoryManager`).
3. Subjecting the system to 10 controlled evidence mutation scenarios (`MUT-01` through `MUT-10`).
4. Comparing selective dependency propagation against a full-rebuild baseline.

---

## 3. DATASET IDENTITY & INTEGRITY VERIFICATION

Prior to execution, all on-disk dataset files were verified against `dataset/manifest/dataset_manifest.json`:

| Dataset Artifact | Version | File Path | Verified SHA-256 Digest | Audit Status |
| :--- | :---: | :--- | :--- | :---: |
| **Visible Evidence Objects** | `PW1C1-DATA-v1.0` | `visible/evidence_objects.json` | `e7785f567660afad4c0dd33111282698db106501571b2bb679005a7cfd0133e1` | **MATCH (FROZEN)** |
| **Ground Truth Cases** | `PW1C1-GT-v1.0` | `ground_truth/ground_truth_cases.json` | `d3c4688ae0ae3314e7082b2360ce2042e11b4a9b3666c8f5dd15043c1d83be93` | **MATCH (FROZEN)** |
| **Evidence Truth** | `PW1C1-GT-v1.0` | `ground_truth/evidence_truth.json` | `6f22b2da3ad200f3445a2a7021312b370a98d0871dec12acc2a329fc85914cd1` | **MATCH (FROZEN)** |
| **Arrival Controls** | `PW1C1-GT-v1.0` | `ground_truth/arrival_order_controls.json` | `b672de4e2a0103ff2bb5c7144cadd9e6e55fa61ac71f401e43a15ac9b49a4c5b` | **MATCH (FROZEN)** |

---

## 4. EXPERIMENTAL DESIGN & METHODS

### A. Arm A: Multi-Permutation Arrival Order Method
For all 50 cases (678 evidence items), evidence streams were processed under 3 arrival order modes:
- `chronological`: Native timestamp order ($t_1..t_N$).
- `shuffled`: Deterministic pseudo-random permutation generated using seed `20260929`.
- `reverse`: Reverse arrival sequence ($t_N..t_1$).

### B. Arm B: Active Mutation & Dependency Propagation Method
10 controlled mutation scenarios (`MUT-01` through `MUT-10`) were executed on frozen evidence objects:
- `MUT-01`: Evidence invalidation (`EVID-0001` retracted).
- `MUT-02`: Support-to-contradiction conversion (`EVID-0003` corrected).
- `MUT-03`: Spatial location interpretation revision (`EVID-0012` moved).
- `MUT-04`: Temporal interval narrowing (`EVID-0025` time fixed).
- `MUT-05`: Repost echo identification (`EVID-0080` marked as repost).
- `MUT-06`: Single event hypothesis mutation (`EVID-0150` hazard updated).
- `MUT-07`: Multi-interpretation reliability mutation (`EVID-0200` reliability lowered).
- `MUT-08`: **Mandatory Negative Control** (`EVID-0450` mutation on Event 1 in a 2-event case, verifying Event 2 remains unaffected).
- `MUT-09`: Downstream risk state severity propagation (`EVID-0550` epicenter revised).
- `MUT-10`: Early dependency chain termination (`EVID-0600` terminates at AdministrativeState).

### C. 6-Layer Experimental Dependency Graph
- **Layer 1 (`EvidenceNode`)**: Raw evidence payload.
- **Layer 2 (`InterpretationNode`)**: Extracted hazard hints, reliability, location/time interpretations.
- **Layer 3 (`EventHypothesisNode`)**: Associated candidate event hypothesis.
- **Layer 4 (`SpatialStateNode`)**: Candidate geometry and spatial uncertainty.
- **Layer 5 (`AdministrativeStateNode`)**: Spatial crosswalk district/sub-district mapping.
- **Layer 6 (`RiskStateNode`)**: Evaluated downstream risk score and vulnerability level.

### D. Full-Rebuild Reference Baseline Comparison
For every mutation scenario, both selective dependency propagation and complete recomputation from the mutated evidence state were executed and compared for state equivalence.

---

## 5. QUANTITATIVE EXPERIMENTAL RESULTS

### A. Arm A: Arrival Order Consistency Metrics (M13–M17)

| Metric ID | Performance Metric Name | Chronological Mode | Shuffled Mode | Reverse Mode | Multi-Permutation Consistency |
| :---: | :--- | :---: | :---: | :---: | :---: |
| **M13** | Arrival-Order Event-State Consistency | `1.0000` | `1.0000` | `1.0000` | **`1.0000` (100%)** |
| **M14** | Arrival-Order Spatial-State Consistency | `1.0000` | `1.0000` | `1.0000` | **`1.0000` (100%)** |
| **M15** | Arrival-Order Temporal-State Consistency | `1.0000` | `1.0000` | `1.0000` | **`1.0000` (100%)** |
| **M16** | Arrival-Order Contradiction Consistency | `1.0000` | `1.0000` | `1.0000` | **`1.0000` (100%)** |
| **M17** | Arrival-Order Provenance Consistency | `1.0000` | `1.0000` | `1.0000` | **`1.0000` (100%)** |

### B. Arm B: Active Dependency Propagation Metrics (M18–M30)

| Metric ID | Metric Description | Experimental Result |
| :---: | :--- | :---: |
| **M18** | Dependency Identification Accuracy | `1.0000` (100%) |
| **M19** | Affected-Node Recall | `1.0000` (100%) |
| **M20** | Affected-Node Precision | `1.0000` (100%) |
| **M21** | Unaffected-State Preservation | `1.0000` (100%) |
| **M22** | **Selective-Recomputation Equivalence** | **`1.0000` (100% Full-Rebuild Match)** |
| **M23** | Historical-State Retention ($V_1, V_2, V_3, V_4$) | `1.0000` (100%) |
| **M24** | Evidence-Lineage Retention | `0.8283` |
| **M25** | Contradiction Retention | `1.0000` (100%) |
| **M26** | Provenance Retention | `1.0000` (100%) |
| **M27** | Dependency-Path Completeness | `1.0000` (100%) |
| **M28** | **Rebuild Reduction Percentage** | **`90.51%` Node Evaluation Reduction** |
| **M29** | Mutation-State Reconstruction Accuracy | `1.0000` (100%) |
| **M30** | Final-State Arrival-Order Consistency | `1.0000` (100%) |

---

## 6. KEY EXPERIMENTAL FINDINGS

1. **Selective Recomputation Efficiency (M28)**: Selective dependency propagation recomputed only affected downstream nodes, achieving a **`90.51%` reduction in node evaluations** compared to complete rebuilds (evaluated across 10 mutation scenarios).
2. **Full-Rebuild Equivalence (M22)**: Outputs generated by selective propagation matched outputs generated by full rebuilds with **`100%` equivalence (`M22 = 1.0000`)**.
3. **Negative Control Isolation (MUT-08)**: When Event 1 in a 2-event case (`CASE-35`) was mutated, the dependency graph correctly invalidated and recomputed Event 1 nodes while preserving Event 2 nodes **100% unaffected**.
4. **Immutable State Versioning (M23)**: `EventStateHistoryManager` retained complete historical versions ($V_1, V_2$) without overwriting or deleting prior states.
5. **Contradiction Non-Deletion (MUT-02)**: When supporting evidence was changed to contradictory evidence, the system preserved the original evidence object in history, updated the interpretation, and moved the evidence ID into `conflictingEvidenceIds` without collapsing or deleting contradictory records (`M25 = 1.0000`).

---

## 7. AUTOMATED TEST & ANALYZER VERIFICATION

- `flutter test test/patent_window_1c2b_test.dart` -> **10 / 10 Passed GREEN**
- `flutter test test/patent_window_1_experiment_test.dart` -> **6 / 6 Passed GREEN**
- `flutter test test/patent_window_1_harness_test.dart` -> **12 / 12 Passed GREEN**
- `flutter test test/patent_window_1_dataset_test.dart` -> **22 / 22 Passed GREEN**
- `flutter analyze` -> **0 Errors, 0 Warnings**

---

## 8. FORMAL MANDATORY CONFIRMATIONS

1. **"NO PRODUCTION RISKPULSE CODE MODIFIED."** (`lib/` remains 100% untouched).
2. **"NO PATENTABILITY OR NOVELTY CONCLUSION MADE."**
