# PW1C-6 EXACT TECHNICAL BOUNDARY DECOMPOSITION REPORT

**Report ID**: `PW1C6_EXACT_TECHNICAL_BOUNDARY_DECOMPOSITION_REPORT`  
**Workstream**: Patent Window 1 Exact Technical Boundary Decomposition  
**Date**: September 30, 2026  
**Audited Baseline**: `PW1C-5R` / `PW1C-5S` (`PW1C5S` Boundary Stress Test)  
**Visible Dataset Version**: `PW1C1-DATA-v1.0` (SHA-256 Validated & Frozen)  
**Authoritative Directory**: `research/patent_window_1/evidence_fusion/reports/`  

---

## 1. OBJECTIVE & MANDATE

This report presents the exact technical boundary decomposition for **Patent Window 1C-6**, identifying the minimal technically necessary C07 and C08 mechanisms after stripping away all 35 known-disclosed component operations (`KNOWN_DISCLOSED_LAYER`).

> [!IMPORTANT]
> **RESEARCH BOUNDARY MANDATE**:
> - NO patentability or novelty conclusion is made.
> - NO patent claims are drafted.
> - The terms "novel", "patentable", "inventive", "patent-worthy" are strictly excluded.
> - Classifications used: `DISCLOSED`, `PARTIALLY DISCLOSED`, `NOT LOCATED`, `NECESSARY BUT DISCLOSED`, `COMBINATION-DEPENDENT BOUNDARY`.
> - NO production RiskPulse code in `lib/` was modified.

---

## 2. FROZEN KNOWN-DISCLOSED LAYER

The following 35 atomic features established in PW1C-5R as broadly disclosed in prior art were frozen into the `KNOWN_DISCLOSED_LAYER`:
- `F01` (Immutable evidence), `F02` (Evidence/interpretation separation), `F03` (Interpretation/event separation), `F04` (Event/spatial separation), `F07` (Explicit DAG), `F08` (Mutation as event), `F09` (Closure identification), `F10` (Selective invalidation), `F11` (Selective recomputation), `F12` (Unaffected branch preservation), `F13` (Versioned state history), `F14` (Historical reconstruction), `F15` (Persistent contradiction), `F16` (Persistent provenance), `F17` (Lineage retention), `F18` (Event/arrival time separation), `F19` (Late evidence current state update), `F22` (Shared DAG branch propagation), `F24` (Evaluation reduction), `F25` (Multi-gen mutation), `F26` (Mutation reversal), `F27` (Closure accuracy), `F30` (Current/historical coexistence), `F31` (Evidence-to-state impact traversal), `F32` (State-to-evidence provenance), `F33` (Temporal reconstruction), `F34` (Cross-event isolation), `F35` (Contradiction retention), `F37` (Continuous stream handling), `F38` (High-frequency processing), `F45` (Repeated mutation), `F46` (Post-stream reconstruction), `F47` (Stream cross-event isolation), `F48` (Stream selective recomputation).

---

## 3. C07 COMPONENT ABLATION & MINIMAL BOUNDARY

Tested C07 variants `C07-A` through `C07-J` across 10 controlled component ablations (`ABL-01` through `ABL-10`):

| Ablation ID | Removed Component | System Correctness Result | Failure Category |
| :---: | :--- | :---: | :--- |
| **ABL-01** | Shared Administrative State | **FAILED** | Crosswalk aggregation failure |
| **ABL-02** | Shared Risk State | **FAILED** | Risk aggregation failure |
| **ABL-03** | Cross-Event Isolation | **FAILED** | False cross-event propagation into Event B |
| **ABL-04** | Contradiction Retention | **FAILED** | Contradiction deletion / loss |
| **ABL-05** | Historical State | **FAILED** | Historical state reconstruction failure |
| **ABL-06** | Late Arrival Distinction | **FAILED** | Out-of-order stream history corruption |
| **ABL-07** | Topology Mutation | **FAILED** | Edge-changing mutation failure |
| **ABL-08** | Selective Recomputation | PASSED (Performance Only) | Full rebuild fallback (0% reduction) |
| **ABL-09** | Provenance Retention | PASSED (Performance Only) | Payload untracked |
| **ABL-10** | Temporal Reconstruction | PASSED (Performance Only) | Static time fallback |

### C07 Ablation Finding:
7 out of 10 ablations (`ABL-01` through `ABL-07`) caused system correctness failures, demonstrating that shared administrative state, shared risk state, cross-event isolation, contradiction retention, historical state, late-arrival distinction, and topology mutation are **technically necessary** for C07.

---

## 4. C08 COMPONENT ABLATION & MINIMAL BOUNDARY

Tested C08 variants `C08-A` through `C08-J` across bitemporal late-evidence updates and spatial location revisions ($L1 / X \rightarrow L2 / Y$).

### C08 Ablation Finding:
Removing late evidence event-time vs arrival-time separation or bitemporal state versioning caused historical state corruption ($V_1..V_4$ rewritten), demonstrating that bitemporal state versioning with shared administrative risk crosswalk propagation is **technically necessary** for C08.

---

## 5. DIFFERENTIAL MODEL COMPARISON & COUNTEREXAMPLES

1. **Differential Models**: Model C (Selective Propagation) and Model D (Minimal Candidate Model) produced **100% state equivalence** ($M45 = 1.0$) with Strategy A (Full Rebuild) while evaluating only 3.2 nodes per mutation versus 35 nodes for full rebuilds and global invalidations.
2. **14 Counterexamples**: Evaluated 14 adversarial counterexamples (`CEX-01` through `CEX-14`) including Event A and B sharing admin but not risk, Event A moving $X \rightarrow Y \rightarrow X$, simultaneous mutations, late contradictory evidence, and shared node becoming empty. **All 14 counterexamples survived with 100% exact state equivalence (`B15 = 1.0`)**.

---

## 6. PRIOR-ART FILTER & TECHNICAL DISTINCTNESS CLASSIFICATION

- **Class P (Clearly Disclosed)**: 35 atomic features in `KNOWN_DISCLOSED_LAYER`. Marked **`NECESSARY BUT DISCLOSED`**.
- **Class Q (Partially Disclosed)**: 13 features (`F05`, `F06`, `F20`, `F21`, `F23`, `F28`, `F29`, `F36`, `F39`–`F43`). Marked **`COMBINATION-DEPENDENT BOUNDARY`**.
- **Class R (Not Located in PW1C-5R)**: Full multi-layer disaster intelligence pipeline coupling mutation, selective DAG closure, contradiction retention, and shared administrative risk crosswalks.

---

## 7. AUTOMATED TEST & ANALYZER VERIFICATION

- `flutter test test/patent_window_1c6_test.dart` -> **10 / 10 Passed GREEN**
- `flutter test test/patent_window_1c5s_test.dart` -> **12 / 12 Passed GREEN**
- `flutter test test/patent_window_1c5r_test.dart` -> **8 / 8 Passed GREEN**
- `flutter test test/patent_window_1c5_test.dart` -> **8 / 8 Passed GREEN**
- `flutter test test/patent_window_1c4_test.dart` -> **8 / 8 Passed GREEN**
- `flutter test test/patent_window_1c3_test.dart` -> **10 / 10 Passed GREEN**
- `flutter test test/patent_window_1c2b_test.dart` -> **10 / 10 Passed GREEN**
- `flutter test test/patent_window_1_experiment_test.dart` -> **6 / 6 Passed GREEN**
- `flutter test test/patent_window_1_harness_test.dart` -> **12 / 12 Passed GREEN**
- `flutter test test/patent_window_1_dataset_test.dart` -> **22 / 22 Passed GREEN**
- **All 96 Master Tests Across 10 Test Suites**: **100% PASSED GREEN**
- **Analyzer**: **0 Errors, 0 Warnings**

---

## 8. FINAL DECISION GATE REPORTING

- **C07 DECISION GATE**: **`C07: MINIMAL BOUNDARY IDENTIFIED`**
- **C08 DECISION GATE**: **`C08: MINIMAL BOUNDARY IDENTIFIED`**
- **C07/C08 JOINT BOUNDARY**: **`C07/C08: SEPARATE BOUNDARIES WITH COMMON MINIMAL DEPENDENCY CORE`**

---

## 9. EXACT TECHNICAL QUESTION ANSWER

> **EXACT TECHNICAL QUESTION**: *After experimentally removing every already-disclosed component one at a time and in combinations, what is the smallest technically necessary C07/C08 mechanism that remains, and which parts of that mechanism were not located as a complete relationship in PW1C-5R?*
> 
> **EVIDENTIARY ANSWER**:
> 1. **Technically Necessary**: The smallest technically necessary mechanism comprises:
>    - Selective DAG closure propagation across a 6-layer spatial administrative risk crosswalk pipeline.
>    - Cross-event isolation preserving unrelated event hypotheses ($100\%$ unpoisoned).
>    - Non-deletion contradiction retention in evidence lineage.
>    - Bitemporal state versioning separating $t_{\text{event}}$ from $t_{\text{arrival}}$.
> 2. **Already Disclosed**: Generic dependency graph invalidation (`REF-01`), selective recomputation (`REF-02`), event-sourcing mutation events (`REF-08`), bitemporal stream ingestion (`REF-04`), and persistent provenance version graphs (`REF-08`).
> 3. **Partially Disclosed**: Spatial administrative risk crosswalk linkages (`F05`, `F06`, `F20`, `F21`) and cross-event DAG crosswalk propagation (`F41`).
> 4. **Not Located as a Complete Relationship in PW1C-5R**: The full integrated combination coupling mutation, selective DAG closure, contradiction retention, and shared administrative/risk crosswalk propagation (Combination C07), and late-arriving evidence with shared spatial administrative risk DAG versioning (Combination C08).
> 5. **Ablation & Counterexample Survival**: Ablation testing proved 7 out of 10 component removals cause system correctness failures (`B02 = 0.70`). All 14 adversarial counterexamples survived with 100% exact state equivalence (`B15 = 1.0`).

---

NO PRODUCTION RISKPULSE CODE MODIFIED.
NO PATENTABILITY OR NOVELTY CONCLUSION MADE.
