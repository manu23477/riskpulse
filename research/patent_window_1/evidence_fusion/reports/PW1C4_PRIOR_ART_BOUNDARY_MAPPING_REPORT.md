# PATENT WINDOW 1C-4 PRIOR-ART BOUNDARY MAPPING REPORT
## EXPERIMENTALLY DEMONSTRATED MECHANISM FROM PW1C-3

**Report ID**: `PW1C4_PRIOR_ART_BOUNDARY_MAPPING_REPORT`  
**Workstream**: Patent Window 1 Prior-Art Technical Boundary Analysis  
**Date**: September 30, 2026  
**Audited Baseline**: `PW1C-3` (`PW1C3-E02` Deep Mutation & Propagation)  
**Visible Dataset Version**: `PW1C1-DATA-v1.0` (SHA-256 Validated & Frozen)  
**Authoritative Directory**: `research/patent_window_1/evidence_fusion/reports/`  

---

## 1. EXECUTIVE SUMMARY & RESEARCH PURPOSE

This report presents a technical prior-art boundary mapping analysis of the evidence-fusion and dependency-state propagation mechanism experimentally demonstrated in **Patent Window 1C-3**.

### Purpose of 1C-4 Boundary Mapping:
The objective of 1C-4 is **NOT** to prove patentability or draft patent claims. The objective is to establish an objective, evidence-based technical boundary mapping that identifies:
1. Which atomic technical operations in the 1C-3 architecture are clearly disclosed by prior art.
2. Which feature combinations are disclosed in single references vs. across multiple references.
3. Which technical relationships remain unresolved by the prior art located so far.
4. Which architecture concepts are unsuitable as standalone patent distinctions.
5. Which specific technical combinations, if any, justify further experimental research.

> [!IMPORTANT]
> **RESEARCH BOUNDARY MANDATE**:
> - NO patent claims are drafted in this report.
> - NO declaration of novelty, inventive step, or patentability is made.
> - The absence of a located reference does NOT establish novelty or patentability.
> - NO production RiskPulse code in `lib/` was modified.

---

## 2. RELATIONSHIP TO EXPERIMENTAL MILESTONES (PW1C-1 THROUGH PW1C-3)

The prior-art analysis evaluates the **ACTUAL**, physical experimental mechanism demonstrated in:
- **PW1C-1A/1B**: Synthetic dataset (`PW1C1-DATA-v1.0`) and neutral 12-metric experimental harness.
- **PW1C-2A**: Initial baseline comparative experiment (`PW1C2A-E01`).
- **PW1C-2B**: Multi-permutation arrival stream testing and initial active dependency propagation.
- **PW1C-3**: Deep 7-version cascading mutations ($V_1..V_7$), non-sequential state reconstruction, multi-event shared administrative dependencies, late-arriving evidence ($t_{\text{arrival}}$ vs $t_{\text{event}}$), adversarial false/missed propagation testing, and 3-way strategy comparison (Selective Propagation vs Full Rebuild vs Naive Global Invalidation).

### Summary of Demonstrated 1C-3 Quantitative Findings:
- Cumulative selective recomputation reduction: **89.62%** node evaluation reduction (`M40`).
- Full-rebuild state equivalence: **100%** equivalence (`M45 = 1.0000`).
- False propagation rate: **0.0%** (`M41 = 0.0000`).
- Missed propagation rate: **0.0%** (`M42 = 0.0000`).
- Historical state reconstruction accuracy: **100%** (`M31 = 1.0000`).
- Historical state immutability: **100%** (`M32 = 1.0000`).

---

## 3. ATOMIC TECHNICAL FEATURE DECOMPOSITION (F01–F36)

The 1C-3 architecture was decomposed into 36 atomic technical features:

| Feature ID | Feature Description | Prior-Art Classification |
| :---: | :--- | :---: |
| **F01** | Immutable evidence object | **A (Clearly Disclosed)** |
| **F02** | Evidence separated from interpretation | **A (Clearly Disclosed)** |
| **F03** | Interpretation separated from event hypothesis | **A (Clearly Disclosed)** |
| **F04** | Event hypothesis separated from derived spatial state | **A (Clearly Disclosed)** |
| **F05** | Derived spatial state linked to administrative state | **B (Partially Disclosed)** |
| **F06** | Administrative state linked to risk state | **B (Partially Disclosed)** |
| **F07** | Explicit dependency graph connecting layers | **A (Clearly Disclosed)** |
| **F08** | Evidence mutation represented as an event rather than destructive modification | **A (Clearly Disclosed)** |
| **F09** | Identification of affected dependency closure | **A (Clearly Disclosed)** |
| **F10** | Selective invalidation of affected derived states | **A (Clearly Disclosed)** |
| **F11** | Selective downstream recomputation | **A (Clearly Disclosed)** |
| **F12** | Preservation of unaffected branches | **A (Clearly Disclosed)** |
| **F13** | Versioned event-state history | **A (Clearly Disclosed)** |
| **F14** | Historical reconstruction of previous event states | **A (Clearly Disclosed)** |
| **F15** | Persistent contradiction representation | **A (Clearly Disclosed)** |
| **F16** | Persistent evidence provenance | **A (Clearly Disclosed)** |
| **F17** | Evidence lineage retained across state transitions | **A (Clearly Disclosed)** |
| **F18** | Separation of evidence arrival time from event time | **A (Clearly Disclosed)** |
| **F19** | Late evidence creates new current state while historical states remain intact | **A (Clearly Disclosed)** |
| **F20** | Shared downstream administrative dependencies | **B (Partially Disclosed)** |
| **F21** | Shared downstream risk dependencies | **B (Partially Disclosed)** |
| **F22** | Mutation propagation through shared downstream dependencies without invalidating unrelated upstream branches | **A (Clearly Disclosed)** |
| **F23** | Full-rebuild equivalence verification | **B (Partially Disclosed)** |
| **F24** | Selective recomputation reduction | **A (Clearly Disclosed)** |
| **F25** | Repeated multi-generation mutation handling | **A (Clearly Disclosed)** |
| **F26** | Mutation reversal | **A (Clearly Disclosed)** |
| **F27** | Dependency closure accuracy | **A (Clearly Disclosed)** |
| **F28** | False propagation detection | **B (Partially Disclosed)** |
| **F29** | Missed propagation detection | **B (Partially Disclosed)** |
| **F30** | Current state + historical state coexistence | **A (Clearly Disclosed)** |
| **F31** | Evidence-to-state impact traversal | **A (Clearly Disclosed)** |
| **F32** | State-to-evidence provenance reconstruction | **A (Clearly Disclosed)** |
| **F33** | Temporal event-state reconstruction | **A (Clearly Disclosed)** |
| **F34** | Cross-event dependency isolation | **A (Clearly Disclosed)** |
| **F35** | Contradictory evidence retained through subsequent state versions rather than deleted | **A (Clearly Disclosed)** |
| **F36** | Administrative/risk representation updated as downstream consequence of mutation | **B (Partially Disclosed)** |

*Classification Summary*: **28 Features Clearly Disclosed (A)**, **8 Features Partially Disclosed (B)**, **0 Not Located (C)**, **0 Ambiguous (D)**.

---

## 4. PRIOR-ART REFERENCE FAMILIES REVIEWED

Ten primary patent publications / patent families were analyzed in detail:

1. **REF-01 (`US7441230B2`)** - *Method of utilizing product proxies with a dependency graph* (Microsoft Corp, 2003). Discloses dependency graph invalidation, traversal from changed nodes, and selective recalculation of affected product proxies.
2. **REF-02 (`EP3622411B1`)** - *Incremental graph computations for querying large graphs* (SAP SE, 2018). Discloses incremental graph computation for dynamic query evaluation on graph updates.
3. **REF-03 (`US10067788B2`)** - *Automated invalidation of job output data in a job processing system* (Amazon Technologies Inc, 2015). Discloses automated invalidation of downstream descendants in job dependency structures.
4. **REF-04 (`US20200379978A1`)** - *System and method of processing late arriving and out of order data* (Google LLC, 2019). Discloses incremental processing of out-of-order and late-arriving data streams in computation graphs.
5. **REF-05 (`US20210286481A1`)** - *Unified Document Surface* (Palantir Technologies Inc, 2020). Discloses dependency invalidation graphs for determining affected document elements and reducing redundant recalculations.
6. **REF-06 (`US10360209B2`)** - *Highly selective invalidation of database cursors* (Oracle International Corp, 2016). Discloses fine-grained selective invalidation using dependency metadata.
7. **REF-07 (`US12182202B2`)** - *System, devices and/or processes for updating call graphs* (IBM Corp, 2021). Discloses identification of specific graph tasks requiring recomputation to avoid unnecessary re-execution.
8. **REF-08 (`CN117235153B`)** - *ProV-DM model-based compliance data evidence-storing and tracing* (Zhejiang Univ, 2023). Discloses persistent directed graphs for provenance tracing, modification tracking, and historical state preservation.
9. **REF-09 (`US10452652B2`)** - *Geospatial event extraction and correlation graph* (BAE Systems, 2016). Discloses extraction of geospatial events and correlation graphs from unstructured text sources.
10. **REF-10 (`US9870396B2`)** - *Multi-source evidence fusion and contradiction resolution* (Raytheon Co, 2014). Discloses evidence fusion across heterogeneous sources and contradiction management.

---

## 5. FEATURE COMBINATION ANALYSIS (C01–C08)

To determine whether combinations of operations are disclosed, 8 key feature combinations were analyzed:

| Combination ID | Atomic Features Combined | Disclosed in Single Reference? | Partial References | Unresolved Technical Elements |
| :---: | :--- | :---: | :--- | :--- |
| **C01** | `F07` + `F09` + `F10` + `F11` (Dependency graph + closure + selective invalidation + selective recomputation) | **YES** | `US7441230B2` (REF-01), `US20210286481A1` (REF-05) | None. Classic software dependency invalidation pattern. |
| **C02** | `F08` + `F13` + `F14` (Evidence mutation event + versioned event state + historical reconstruction) | **YES** | `CN117235153B` (REF-08) | None. Event-sourcing persistent provenance graph. |
| **C03** | `F15` + `F16` + `F17` (Persistent contradiction + provenance + evidence lineage retention) | **PARTIAL** | `CN117235153B` (REF-08), `US9870396B2` (REF-10) | Multi-source evidence fusion combined with versioned provenance tracing. |
| **C04** | `F18` + `F19` + `F13` + `F14` (Late evidence + event/arrival-time separation + versioned state + historical reconstruction) | **PARTIAL** | `US20200379978A1` (REF-04), `CN117235153B` (REF-08) | Integration of late stream data into versioned provenance graphs. |
| **C05** | `F20` + `F21` + `F22` (Shared downstream administrative/risk state + selective propagation + unaffected branch preservation) | **PARTIAL** | `US7441230B2` (REF-01), `US10067788B2` (REF-03) | Domain-specific spatial administrative/risk state crosswalk coupling under selective DAG recomputation. |
| **C06** | `F08` + `F09` + `F11` + `F13` + `F16` (Mutation + dependency closure + selective recomputation + state history + provenance) | **PARTIAL** | `US7441230B2` (REF-01), `CN117235153B` (REF-08) | Combination of incremental dependency recomputation with persistent provenance graph. |
| **C07** | `F08` + `F09` + `F11` + `F15` + `F20` + `F21` + `F22` (Full pipeline: Mutation + DAG closure + contradiction + shared administrative/risk state + cross-event isolation) | **NO** | REF-01, REF-08, REF-10 | Full multi-layer disaster intelligence pipeline coupling mutation, DAG closure, contradiction retention, and shared administrative risk crosswalks. |
| **C08** | `F18` + `F20` + `F21` + `F22` + `F30` + `F33` (Late evidence + shared downstream administrative/risk state + historical state + temporal reconstruction) | **NO** | REF-04, REF-08, REF-01 | Combination of late data stream integration with shared spatial administrative risk DAG versioning. |

---

## 6. CANDIDATE TECHNICAL BOUNDARIES & EVALUATION

Based on the mapping, 7 candidate technical boundaries were evaluated:

| Candidate ID | Technical Combination | Prior-Art Coverage | Experimental Support in 1C-3 | Recommendation / Research Direction |
| :---: | :--- | :---: | :---: | :--- |
| **CAND-A** | Mutation-driven dependency closure across evidence-derived states (`F08`+`F09`+`F10`+`F11`) | Substantially covered | 89.62% recomputation reduction | **Unsuitable as standalone distinction**. Generic dependency graph invalidation is strongly disclosed in REF-01 and REF-05. |
| **CAND-B** | Selective recomputation across evidence $\rightarrow$ interpretation $\rightarrow$ event $\rightarrow$ spatial $\rightarrow$ admin $\rightarrow$ risk layers (`F01`..`F06`+`F11`) | Partially covered | 100% full-rebuild equivalence ($M45 = 1.0$) | **Requires further research**. Investigate whether 6-layer disaster intelligence crosswalk creates non-obvious technical relationships. |
| **CAND-C** | Shared downstream administrative/risk state with selective cross-event propagation (`F20`+`F21`+`F22`+`F34`) | Partially covered | MUT3-04: Event A mutated, shared Admin X updated, Event B hypothesis 100% unpoisoned | **Requires further research**. Investigate shared spatial administrative DAG node propagation boundaries. |
| **CAND-D** | Historical state preservation combined with mutation-driven selective propagation (`F13`+`F14`+`F11`) | Substantially covered | 7-generation history $V_1..V_7$ & non-sequential reconstruction ($M31 = 1.0$) | **Unsuitable as standalone distinction**. Persistent provenance graphs with versioning are disclosed in REF-08. |
| **CAND-E** | Contradictory evidence retained while derived event state is recomputed (`F15`+`F35`+`F11`) | Partially covered | MUT3-10 late report; E1 retained, contradiction recorded ($M25 = 1.0$) | **Requires further research**. Contradiction resolution disclosed in REF-10; non-deletion versioning in REF-08. |
| **CAND-F** | Late-arriving evidence updating current state while preserving historical event states (`F18`+`F19`+`F13`) | Substantially covered | MUT3-09: E4 arriving at 11:00 for 09:55 event creates $V_5$ while $V_1..V_4$ remain intact | **Unsuitable as standalone distinction**. Late stream processing strongly disclosed in REF-04 and bitemporal model prior art. |
| **CAND-G** | Combined full multi-layer pipeline: mutation + selective DAG closure + contradiction retention + shared administrative risk crosswalks (`C07` & `C08`) | Insufficiently resolved | 89.62% reduction, 100% full-rebuild equivalence, 0 false/missed propagation | **Requires further targeted research**. No single located reference discloses the full combined disaster-intelligence pipeline. |

---

## 7. IMPORTANT NEGATIVE FINDINGS

1. **Generic Dependency Graph Invalidation is OLD**: Core software concepts of dependency graph creation, change detection, invalidation traversal, and selective downstream recomputation (`F07`, `F09`, `F10`, `F11`, `F12`, `F24`) are broadly disclosed in prior art (US7441230B2 REF-01, EP3622411B1 REF-02, US10067788B2 REF-03, US20210286481A1 REF-05). **They MUST NOT be claimed as standalone inventions**.
2. **Late / Out-of-Order Stream Processing is OLD**: Separating event occurrence time from evidence processing time and updating computation graphs upon late arrival (`F18`, `F19`, `F33`) is strongly disclosed in US20200379978A1 (REF-04).
3. **Versioned Provenance Graphs are OLD**: Storing modification records and historical version states in persistent directed graphs (`F08`, `F13`, `F14`, `F16`, `F17`, `F30`, `F32`) is strongly disclosed in CN117235153B (REF-08).

---

## 8. SEARCH LIMITATIONS & UNCERTAINTIES

1. **Database Coverage Limitation**: The search prioritized patent databases (USPTO, EPO, CNIPA) via Google Patents. Additional searching in specialized emergency management patent subclasses (e.g., G08B, G06Q50/26) and IEEE Xplore literature is recommended.
2. **Legal Prior-Art Date Status**: Priority, filing, and publication dates were recorded from patent office documents, but independent legal validity across jurisdictions was not evaluated.

---

## 9. TECHNICAL CONCLUSIONS

Answering the specific technical questions in Section 24:

- **A. What parts are clearly already known?**: Generic dependency graph invalidation, selective recomputation, event-sourcing mutation events, persistent provenance graphs, and late-arriving stream processing.
- **B. What parts are partially disclosed?**: Shared downstream administrative/risk state aggregation (`F20`, `F21`), 6-layer disaster spatial crosswalks (`F05`, `F06`), and full-rebuild equivalence verification (`F23`).
- **C. What combinations appear already disclosed?**: Combination C01 (`F07`+`F09`+`F10`+`F11` in REF-01/REF-05) and Combination C02 (`F08`+`F13`+`F14` in REF-08).
- **D. What exact combinations remain unresolved?**: Combination C07 (Mutation + selective DAG closure + contradiction retention + shared administrative risk crosswalks) and Combination C08 (Late evidence + shared downstream spatial/administrative/risk state + historical state + temporal reconstruction).
- **E. Which unresolved combinations require additional prior-art search?**: C07 and C08 require additional specialized searching in emergency management and geospatial patent subclasses before any technical boundary determination can be finalized.
- **F. Which technical experiments would most efficiently distinguish remaining possibilities?**: Experiments testing multi-event shared spatial administrative crosswalk boundary propagation under high-frequency stream mutations (PW1C-5).

---

## 10. AUTOMATED TEST & ANALYZER VERIFICATION

- `flutter test test/patent_window_1c4_test.dart` -> **8 / 8 Passed GREEN**
- `flutter test test/patent_window_1c3_test.dart` -> **10 / 10 Passed GREEN**
- `flutter test test/patent_window_1c2b_test.dart` -> **10 / 10 Passed GREEN**
- `flutter test test/patent_window_1_experiment_test.dart` -> **6 / 6 Passed GREEN**
- `flutter test test/patent_window_1_harness_test.dart` -> **12 / 12 Passed GREEN**
- `flutter test test/patent_window_1_dataset_test.dart` -> **22 / 22 Passed GREEN**
- **All 68 Master Tests**: **100% PASSED GREEN**
- **Analyzer**: **0 Errors, 0 Warnings**

---

## 11. FORMAL MANDATORY CONFIRMATIONS

1. **"NO PRODUCTION RISKPULSE CODE MODIFIED."** (`lib/` remains 100% untouched).
2. **"NO PATENTABILITY OR NOVELTY CONCLUSION MADE."**
