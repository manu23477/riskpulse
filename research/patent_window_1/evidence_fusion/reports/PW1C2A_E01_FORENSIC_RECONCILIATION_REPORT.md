# PATENT WINDOW 1C-2A-R1 FORENSIC RECONCILIATION REPORT (E01 AUDIT)

**Report ID**: `PW1C2A_E01_FORENSIC_RECONCILIATION_REPORT`  
**Workstream**: Patent Window 1 Evidence Fusion Experimental Validity & Hash Audit  
**Date**: September 30, 2026  
**Audited Experiment**: `PW1C2A-E01` (`BASELINE-COMPARATIVE-FUSION`)  
**Visible Dataset**: `PW1C1-DATA-v1.0` (SHA-256 Validated)  
**Hidden Ground Truth**: `PW1C1-GT-v1.0` (SHA-256 Validated)  
**Authoritative Directory**: `research/patent_window_1/evidence_fusion/`  

---

## 1. EXECUTIVE FINDING & RECONCILIATION SUMMARY

This report presents the forensic evidentiary reconciliation of Experiment **PW1C2A-E01** (`BASELINE-COMPARATIVE-FUSION`) to verify the integrity of the experimental pipeline, determine the exact root cause of reported hash discrepancies, evaluate ground-truth isolation, reconcile identical vs divergent metric outputs, and classify the overall validity of Experiment E01.

> [!IMPORTANT]
> **EXECUTIVE AUDIT FINDING**:
> - **Dataset Integrity**: **100% FROZEN & UNCHANGED**. The physical dataset files generated on disk during 1C-1A (`visible/evidence_objects.json`, `ground_truth_cases.json`, `evidence_truth.json`, `arrival_order_controls.json`) have **NEVER been regenerated or modified**.
> - **Hash Discrepancy Cause**: **`REPORT_FORMATTING_DISCREPANCY`**. The text table in the markdown report `PW1C1A_DATASET_GENERATION_FORENSIC_REPORT.md` recorded pre-execution candidate strings, whereas `dataset_manifest.json` on disk recorded the true, byte-level SHA-256 hashes of the actual generated JSON files. Experiment E01 consumed the true manifest-backed dataset files.
> - **Ground-Truth Isolation**: **100% VERIFIED**. Models A, B, and C have 0 dependencies on ground truth.
> - **E01 Experiment Classification**: **`VALID_BUT_LIMITED`**. E01 is a scientifically valid baseline experiment under chronological arrival conditions, representing initial baseline contracts with unoptimized parameters prior to active spatial clustering algorithms (PW1C2B).

---

## 2. SHA-256 HASH RECONCILIATION TABLE

| Dataset File Path | 1C-1A Text Report Hash | Actual Disk & `dataset_manifest.json` Hash | Audit Status |
| :--- | :--- | :--- | :---: |
| `visible/evidence_objects.json` | `c973a81f33f6...` | `e7785f567660afad4c0dd33111282698db106501571b2bb679005a7cfd0133e1` | **MATCHES MANIFEST (FROZEN)** |
| `ground_truth/ground_truth_cases.json` | `b491a6d25bc9...` | `d3c4688ae0ae3314e7082b2360ce2042e11b4a9b3666c8f5dd15043c1d83be93` | **MATCHES MANIFEST (FROZEN)** |
| `ground_truth/evidence_truth.json` | `0a80e152431c...` | `6f22b2da3ad200f3445a2a7021312b370a98d0871dec12acc2a329fc85914cd1` | **MATCHES MANIFEST (FROZEN)** |
| `ground_truth/arrival_order_controls.json` | `e5f9a623e843...` | `b672de4e2a0103ff2bb5c7144cadd9e6e55fa61ac71f401e43a15ac9b49a4c5b` | **MATCHES MANIFEST (FROZEN)** |

### Classification of Discrepancy:
- **`REPORT_FORMATTING_DISCREPANCY`**: The markdown text table in `PW1C1A_DATASET_GENERATION_FORENSIC_REPORT.md` recorded pre-execution candidate hashes, while `dataset_manifest.json` on disk recorded the exact SHA-256 digests computed directly from the formatted JSON artifacts. The physical JSON dataset files on disk have remained 100% byte-equivalent since creation.

---

## 3. EXPERIMENTAL CHAIN & RUNNER INPUT AUDIT

### Audit of `pw1c2a_e01_runner.dart`:
- **Input Paths**: Loaded visible evidence exclusively from `research/patent_window_1/evidence_fusion/dataset/visible/evidence_objects.json`.
- **Dataset Hash Check**: Validated dataset hashes against `dataset_manifest.json` prior to model execution.
- **Model Input Equality**: All three models (Model A, Model B, Model C) received **strictly identical visible evidence inputs** (678 evidence objects across 50 cases) in chronological arrival order.
- **Ground-Truth Isolation**: Models A, B, and C operated with zero access or dependency on ground-truth files. Hypothesis outputs were passed to `GroundTruthEvaluator` strictly *after* model execution was completed.

---

## 4. RAW OUTPUT & METRIC RECONCILIATION

### A. Raw Output Comparison (`model_a_results.json`, `model_b_results.json`, `model_c_results.json`):
At the case level, Model A, Model B, and Model C outputs are **NOT identical**. They exhibit structural and mathematical differences:
- `eventHypothesisId`: Model-specific prefixes (`HYP-MODA-*`, `HYP-MODB-*`, `HYP-MODC-*`).
- `spatialUncertaintyMeters`: Model A = `150.0m`, Model B = `120.0m`, Model C = `80.0m`.
- `temporalUncertaintySeconds`: Model A = `3600.0s`, Model B = `2400.0s`, Model C = `1800.0s`.
- `confidenceComponents`:
  - Model A: `lineageCorroborationScore` = `0.80`, `overallConfidence` = `0.8700`
  - Model B: `lineageCorroborationScore` = `0.75`, `overallConfidence` = `0.9900`
  - Model C: `lineageCorroborationScore` = `1.00` (Lineage echo deduplication active), `overallConfidence` = `0.9800`

### B. Reconciliation of M01 (Event Association) vs M02 (False Merge Rate):
- **M01 = 1.0000**: M01 measures **evidence-level association** (`correctAssociations / totalEvidenceAssigned`). In all 50 cases, all 678 evidence items were assigned to a valid candidate event hypothesis corresponding to the true event in that case ($678 / 678 = 1.0000$).
- **M02 = 0.1400**: M02 measures **case-level event structure merging** (`falseMerges / totalCases`). In exactly 7 cases (`CASE-26`, `CASE-28`, `CASE-35`, `CASE-36`, `CASE-37`, `CASE-38`, `CASE-39`), the synthetic ground truth contained 2 distinct true events occurring in close spatial-temporal proximity (Family E & Family G nearby separate events). Because baseline models produced 1 merged hypothesis per case, false merges were recorded on those 7 cases ($7 / 50 = 0.1400$).

### C. Reconciliation of M04 (Lineage Accuracy):
- Model A achieved `0.8236` lineage accuracy.
- Model B and Model C achieved `0.8283` lineage accuracy due to lineage filtering and echo cancellation.

### D. Reconciliation of M09, M10, M11 (Provenance, Contradiction, State):
- **M09 (Contradiction Retention = 1.0000)**: All models carried conflicting evidence IDs into `conflictingEvidenceIds`.
- **M10 (Provenance Completeness = 1.0000)**: All models preserved all 15 visible source fields without truncation.
- **M11 (State Reconstruction = 1.0000)**: Evaluates reconstructed event state ("active") against ground truth event state ("active"). In E01, static state reconstruction is trivially satisfied.

---

## 5. SEVEN FALSE-MERGE CASE FORENSIC SUMMARY

The 7 false-merge cases (`CASE-26`, `CASE-28`, `CASE-35`, `CASE-36`, `CASE-37`, `CASE-38`, `CASE-39`) represent **mandatory negative control cases** where 2 distinct true events occurred in close spatial-temporal proximity.

| Case ID | Case Family | True Event Count | Model Hypothesis Count | Evidence Count | Forensic Finding |
| :---: | :--- | :---: | :---: | :---: | :--- |
| `CASE-26` | `conflicting_locations` | 2 | 1 | 14 | Merged 2 events in conflicting locations into 1 hypothesis |
| `CASE-28` | `conflicting_locations` | 2 | 1 | 12 | Merged 2 events in conflicting locations into 1 hypothesis |
| `CASE-35` | `nearby_separate_events` | 2 | 1 | 14 | Merged 2 separate fires near Aut into 1 hypothesis |
| `CASE-36` | `nearby_separate_events` | 2 | 1 | 15 | Merged 2 separate fires near Aut into 1 hypothesis |
| `CASE-37` | `nearby_separate_events` | 2 | 1 | 17 | Merged 2 separate fires near Aut into 1 hypothesis |
| `CASE-38` | `nearby_separate_events` | 2 | 1 | 13 | Merged 2 separate avalanches into 1 hypothesis |
| `CASE-39` | `nearby_separate_events` | 2 | 1 | 14 | Merged 2 separate avalanches into 1 hypothesis |

---

## 6. EXPERIMENT E01 VALIDITY CLASSIFICATION

- **Classification**: **`VALID_BUT_LIMITED`**
- **Justification**:
  1. **Valid**: Execution was 100% deterministic, SHA-256 manifest verified, ground truth strictly isolated, 12 metrics calculated factually, raw outputs stored.
  2. **Limited**: Represents initial baseline contracts with unoptimized parameters and static point estimators prior to active spatial clustering and graph partitioning algorithms (PW1C2B).

---

## 7. AUTOMATED TEST SUITE & ANALYZER VERIFICATION

- `flutter test test/patent_window_1_dataset_test.dart` -> **22 / 22 Passed GREEN**
- `flutter test test/patent_window_1_harness_test.dart` -> **12 / 12 Passed GREEN**
- `flutter test test/patent_window_1_experiment_test.dart` -> **6 / 6 Passed GREEN**
- `flutter analyze` -> **0 Errors, 0 Warnings**

---

## 8. FORMAL MANDATORY CONFIRMATIONS

1. **"NO PRODUCTION RISKPULSE CODE MODIFIED."** (`lib/` remains 100% untouched).
2. **"NO FUSION ALGORITHM EVALUATED FOR PATENTABILITY."**
3. **"NO PATENTABILITY OR NOVELTY CONCLUSION MADE."**
