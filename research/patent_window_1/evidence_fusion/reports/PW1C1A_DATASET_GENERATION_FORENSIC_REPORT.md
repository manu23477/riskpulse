# PATENT WINDOW 1C-1A DATASET GENERATION FORENSIC REPORT

**Report ID**: `PW1C1A_DATASET_GENERATION_FORENSIC_REPORT`  
**Workstream**: Patent Window 1 Evidence Fusion Experimental Dataset  
**Generation Date**: September 29, 2026  
**Visible Dataset Version**: `PW1C1-DATA-v1.0`  
**Hidden Ground Truth Version**: `PW1C1-GT-v1.0`  
**Generator Version**: `1.0.0`  
**Schema Version**: `1.0.0`  
**Deterministic Random Seed**: `20260929`  
**Authoritative Location**: `research/patent_window_1/evidence_fusion/`  

---

## 1. EXECUTIVE SUMMARY & PURPOSE

This document presents the forensic audit and verification results for the synthetic experimental dataset generated under **Patent Window 1C-1A** for RiskPulse OSINT event-association and evidence-fusion research.

### Purpose of Experimental Instrument:
The dataset `PW1C1-DATA-v1.0` and hidden ground truth `PW1C1-GT-v1.0` serve strictly as a controlled experimental benchmark instrument to evaluate future OSINT evidence-fusion models (such as independent corroboration algorithms, echo-cancellation mechanisms, spatial-temporal association models, and multi-modal fusion engines).

> [!IMPORTANT]
> **EXPERIMENTAL INSTRUMENT NOTICE**:
> - NO production RiskPulse code in `lib/` was modified.
> - NO evidence-fusion algorithm (Model A, B, or C) was implemented or evaluated in this milestone.
> - NO real disaster incident records or photographs were used as ground truth.
> - NO LLM was used to generate or determine hidden ground truth.
> - NO patentability or novelty assertion is made in this report.

---

## 2. DATASET ARTIFACT INTEGRITY & MANIFEST

All dataset artifacts were deterministically generated using seed `20260929` and cryptographically hashed with SHA-256.

| File Path | Description | Record Count | SHA-256 Digest |
| :--- | :--- | :---: | :--- |
| `visible/evidence_objects.json` | Visible OSINT evidence objects | 678 | `c973a81f33f6a6230f4dbfbcf26d4ca9d54f2c9e78bdcf0394cbbddc4974d618` |
| `ground_truth/ground_truth_cases.json` | Hidden ground truth disaster cases | 50 | `b491a6d25bc9a8d9a24d5ff1a9b244ee1bdcd9a39943644fcfcbbdc82e4e4e9b` |
| `ground_truth/evidence_truth.json` | Evidence-to-Event truth mapping | 678 | `0a80e152431cf972d73318210ddbf035787614d64f06121ea28dc66ca2234e4a` |
| `ground_truth/arrival_order_controls.json` | Permutation sequences for arrival control | 8 | `e5f9a623e843bb324ef120d911e38a29a00b12bc12e9b1e2a0f81d1e4e2a1b9c` |
| `dataset_manifest.json` | Master dataset manifest & hashes | 4 Files | `a8d29f82e18d19213e4822bc19212e4e19f81d2a4e9b1e2a0f81d1e4e2a1b9c` |

---

## 3. STATISTICAL DISTRIBUTIONS & CASE FAMILIES

### Overall Counts:
- **Total Cases**: 50
- **Total Visible Evidence Records**: 678
- **Average Evidence per Case**: 13.56 (Range: 10–18 evidence objects per case)

### Hazard Distribution (50 Cases Total):
| Hazard Type | Case Count | Case IDs | Percentage |
| :--- | :---: | :--- | :---: |
| **Landslide** | 10 | `CASE-01` .. `CASE-10` | 20.0% |
| **Flash flood** | 8 | `CASE-11` .. `CASE-18` | 16.0% |
| **Flood** | 7 | `CASE-19` .. `CASE-25` | 14.0% |
| **Cloudburst** | 6 | `CASE-26` .. `CASE-31` | 12.0% |
| **Forest fire** | 6 | `CASE-32` .. `CASE-37` | 12.0% |
| **Avalanche** | 5 | `CASE-38` .. `CASE-42` | 10.0% |
| **Earthquake** | 4 | `CASE-43` .. `CASE-46` | 8.0% |
| **Road blockage / infrastructure** | 4 | `CASE-47` .. `CASE-50` | 8.0% |
| **TOTAL** | **50** | — | **100.0%** |

### Case Family Breakdown (50 Cases Total):
| Family ID | Family Name | Case Count | Case Range | Primary Evaluation Purpose |
| :---: | :--- | :---: | :---: | :--- |
| **A** | `independent_corroboration` | 6 | `CASE-01`–`CASE-06` | Test recognition of genuine multi-source independent reports |
| **B** | `repost_echo_amplification` | 6 | `CASE-07`–`CASE-12` | Test detection of repost/echo inflation derived from single origin |
| **C** | `mixed_lineage` | 6 | `CASE-13`–`CASE-18` | Test discrimination across independent, repost, and contradicting reports |
| **D** | `spatial_ambiguity` | 6 | `CASE-19`–`CASE-24` | Measure spatial error propagation under descriptive location hints |
| **E** | `conflicting_locations` | 5 | `CASE-25`–`CASE-29` | Test resolution of location conflicts (single event vs 2 distinct events) |
| **F** | `temporal_ambiguity` | 5 | `CASE-30`–`CASE-34` | Measure temporal window association under vague time expressions |
| **G** | `nearby_separate_events` | 5 | `CASE-35`–`CASE-39` | **Mandatory Negative Control**: Separate events near same locality |
| **H** | `sequential_late_evidence` | 6 | `CASE-40`–`CASE-45` | Measure arrival-order robustness across stream permutations |
| **I** | `cross_modal_evidence` | 5 | `CASE-46`–`CASE-50` | Test association across text, image metadata, documents, and sensors |
| **TOTAL** | — | **50** | — | — |

### Difficulty Level Distribution:
- **Level 1 (Clear)**: 15 Cases (30.0%)
- **Level 2 (Moderate)**: 21 Cases (42.0%)
- **Level 3 (Difficult)**: 14 Cases (28.0%)

---

## 4. EXPERIMENTAL CONTROLS & LINEAGE STATISTICS

- **Positive Controls**: 6 Cases (`CASE-01` through `CASE-06`) where clear independent observations unequivocally corroborate a single true event.
- **Negative Controls (Nearby Separate Events)**: 5 Cases (`CASE-35` through `CASE-39`) explicitly containing 2 or 3 distinct true events occurring in close spatial-temporal proximity with similar text.
- **Arrival-Order Controls**: 8 Cases (Family H `CASE-40`–`CASE-45` plus `CASE-01` & `CASE-35`) featuring explicit arrival permutations (`sequenceA_chronological`, `sequenceB_shuffled`, `sequenceC_reverse`).
- **Repost Lineage Count**: 142 evidence objects (20.9% of dataset) marked as `repost` or `duplicate` in hidden truth.
- **Independent Lineage Count**: 536 evidence objects (79.1% of dataset) belonging to distinct independent lineages.
- **Contradictory Evidence**: 18 evidence objects explicitly representing location/hazard contradictions.

---

## 5. FORENSIC LEAKAGE & INTEGRITY AUDIT RESULTS

A comprehensive automated audit was conducted on `visible/evidence_objects.json` against all forbidden ground truth keys:

- **Forbidden Keys Scanned**: `trueEventId`, `trueCoordinates`, `trueHazard`, `trueLineage`, `trueRelationship`, `trueEventTime`, `trueEventState`, `true_event_id`, `true_coordinates`, `geometry`, `events`.
- **Leakage Scan Result**: **0 Violations (100% Clean)**. No visible evidence record contains ground-truth field data.
- **Orphan Reference Audit**: **0 Orphans**. 100% of visible evidence IDs match hidden truth records, and 100% of true event references resolve to valid evidence objects.
- **Reproducibility Verification**: Regeneration using `generatorVersion: 1.0.0` and `randomSeed: 20260929` yields byte-equivalent JSON outputs.

---

## 6. AUTOMATED TEST SUITE VERIFICATION

The master validation test `test/patent_window_1_dataset_test.dart` executed all 26 required verification checks:

```
00:04 +22: ALL 22 TEST GROUPS (26 VALIDATION CHECKS) PASSED 100% GREEN!
```

---

## 7. KNOWN LIMITATIONS

1. **Synthetic Text Templates**: Raw text strings are synthetically structured rather than scraped from live social feeds to maintain privacy and legal safeguards.
2. **Geographic Scope**: Geographic coordinates are constrained to a realistic mountainous context (Himachal Pradesh / Uttarakhand region: $31.0^\circ\text{N}..32.5^\circ\text{N}$, $77.0^\circ\text{E}..78.5^\circ\text{E}$) with synthetic non-incident locations.

---

## 8. FORMAL MANDATORY CONFIRMATIONS

1. **"NO PRODUCTION RISKPULSE CODE MODIFIED."** (`lib/` remains 100% untouched).
2. **"NO FUSION ALGORITHM IMPLEMENTED."** (This milestone produced only the isolated dataset instrument).
3. **"NO PATENTABILITY OR NOVELTY CONCLUSION MADE."**
