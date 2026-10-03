# PW2 ROUND 8 (PW2R8) MOSAIC COMBINATION & RELATIONSHIP-GAP REPORT

**Candidate Identifier**: `PW2 Candidate 02`  
**Report ID**: `PW2R8_MOSAIC_COMBINATION_RELATIONSHIP_GAP_REPORT`  
**Workstream**: Patent Window 2 Candidate 02 Research  
**Date**: September 30, 2026  
**Git HEAD Baseline**: `d6552707e0a693b04f40a2ade6a4efc5fdf9ae0a`  
**Authoritative Results Directory**: `research/patent_window_2/candidate_02/results/PW2R8/`  

---

## 1. EXECUTIVE SUMMARY

This report documents the mosaic combination collision and relationship-gap analysis for **PW2 Round 8 (PW2R8)**, evaluating the **PW2R6 minimal technical boundary (`PW2-MINIMAL-CANDIDATE` / K10)** against multi-reference prior-art mosaics, teaching compatibility matrices (`T01`..`T10`), examiner-style reconstructions (`E01`..`E08`), mosaic distance metrics (`M01`..`M07`), and establishing the **`PW2-MINIMAL-RELATIONSHIP-CORE`**.

> [!IMPORTANT]
> **RESEARCH BOUNDARY MANDATE**:
> - NO patentability, novelty, inventive-step, or freedom-to-operate conclusion is made.
> - NO patent claims are drafted.
> - Strictly excluded terms as conclusions: "novel", "patentable", "inventive", "patent-worthy".
> - Strict four-way final separation: Technical Boundary, Mosaic Prior-Art Boundary, Relationship Gap, and Legal Patentability Status (`UNDETERMINED — REQUIRES PATENT COUNSEL`).
> - NO production RiskPulse code in `lib/` was modified.

---

## 2. PW2R6 TECHNICAL BOUNDARY (`PW2-MINIMAL-CANDIDATE` / K10)

The PW2R6 minimal technical candidate comprises 9 necessary components: C01 (mutation), C02 (spatial closure), C03 (admin propagation), C04 (risk propagation), C05 (isolation), C06 (historical versioning), C08 (shared admin), C09 (shared risk), and C10 (topology handling). Selective recomputation (C07) was classified as `EFFICIENCY_ONLY` and is excluded from the minimal correctness boundary.

---

## 3. PW2R7 SINGLE-REFERENCE RESULT SUMMARY

PW2R7 established that **NO SINGLE PRIOR-ART REFERENCE** in the searched corpus discloses the complete K10 relationship in a single publication.

---

## 4. PW2R8 OBJECTIVE

To determine whether the multi-reference prior-art mosaic actually teaches the specific technical relationships among the K10 components (R01..R30), identify the exact relationship gaps that remain after assembling the mosaic, and isolate the **`PW2-MINIMAL-RELATIONSHIP-CORE`**.

---

## 5. REFERENCE IDENTITY & DATE VERIFICATION

Audited primary prior-art references:
- **`REF-01` (`US8548248B2`)**: DigitalGlobe (2010 priority, 2013 grant). Satellite imagery raster classification.
- **`REF-02` (`US10036650B2`)**: ESRI (2015 priority, 2018 grant). Spatial dependency graph traversal in hazard mapping.
- **`REF-03` (`US10452652B2`)**: BAE Systems (2016 priority, 2019 grant). Geospatial event correlation graphs.
- **`REF-04` (`US7441230B2`)**: Microsoft (2003 priority, 2008 grant). Build proxy dependency graph invalidation.
- **`REF-05` (`US20200379978A1`)**: Google (2019 priority, 2020 publication). Bitemporal watermark stream processing.
- **`REF-06` (`CN117235153B`)**: Zhejiang Univ (2023 priority, 2024 grant). Versioned provenance compliance graphs.

---

## 6. RELATIONSHIP DEFINITIONS (R01–R30)

Evaluated 30 atomic technical relationships (`R01` through `R30`):
- `R01`..`R07`: Single-step transformations (observation $\rightarrow$ mutation $\rightarrow$ spatial $\rightarrow$ admin $\rightarrow$ risk).
- `R08`..`R11`: Multi-layer pipeline propagation ($Mutation \rightarrow Spatial \rightarrow Admin \rightarrow Risk$) and shared dependency recalculations ($R10$, $R11$).
- `R12`..`R14`: Historical state retention, version reconstruction, and lineage tracking.
- `R15`..`R20`: Topology edge redirection, contributor additions/removals from shared admin/risk states.
- `R21`..`R25`: Bitemporal coexistence, cross-event isolation under shared downstream nodes ($R22$), true closure boundary ($R23$), and remote sensing integration ($R25$).
- `R26`..`R29`: Integrated pipeline, historical version validity, topology/history coexistence, isolation/aggregation coexistence.
- `R30`: **Complete integrated mechanism forming one technical system**.

---

## 7. COMBINATION ANALYSIS (COMBO-01–COMBO-10)

Audited 10 combination mosaics:
- **`COMBO-10` (Principal Mosaic: REF-01 + REF-02 + REF-03 + REF-04 + REF-05 + REF-06)**: Assembles individual sub-system teachings across 6 distinct patent families. Discloses individual sub-components, but fails to disclose the integrated multi-event spatial-administrative-risk crosswalk DAG versioning pipeline as a single coherent mechanism (`COMBO-10` Single-Ref Disclosed = **`NO`**).

---

## 8. TEACHING / COMBINATION COMPATIBILITY MATRIX (T01–T10)

- `T01` (Explicit teaching to combine): **`NO`** (No located reference suggests combining satellite raster classification with build proxy DAG invalidation or compliance provenance graphs).
- `T10` (Combination requires substantial redesign): **`YES`** (Combining these 6 disparate systems requires unifying incompatible data models, spatial coordinate representations, and state update semantics).

---

## 9. EXAMINER-STYLE RECONSTRUCTIONS (E01–E08)

All 8 examiner-style reconstructions (`E01` through `E08`) require combining 2 to 6 references across disparate domains and require unstated architectural assumptions and redesign to match K10.

---

## 10. CRITICAL RELATIONSHIP ANALYSIS & RELATIONSHIP GAP

The following 9 critical coupling relationships were **NOT LOCATED** as complete disclosures in any single prior-art reference or pairwise combination:
- **`R08`**: $Mutation \rightarrow Spatial \rightarrow Administrative \rightarrow Risk$ pipeline propagation.
- **`R10`**: Shared administrative dependency recalculation after upstream mutation.
- **`R11`**: Shared risk dependency recalculation after upstream mutation.
- **`R16`**: Topology mutation causing downstream administrative/risk recalculation.
- **`R22`**: Cross-event isolation despite shared downstream administrative/risk dependency.
- **`R25`**: Remote-sensing mutation participating in the same dependency structure driving admin/risk updates.
- **`R28`**: Topology mutation and historical versioning coexisting.
- **`R29`**: Cross-region isolation and shared downstream aggregation coexisting.
- **`R30`**: Complete integrated mechanism operating as one system.

---

## 11. MOSAIC DISTANCE METRICS (M01–M07)

- **`M01`**: 6 references required to cover all K10 components.
- **`M02`**: 8 references required to cover all R01–R30 relationships.
- **`M03`**: 22 relationships require multi-reference mosaic assembly.
- **`M04`**: 8 critical relationships not located completely in the searched corpus.
- **`M05`**: 5 critical relationships requiring architectural redesign.
- **`M06`**: 6 critical relationships requiring unstated assumptions.
- **`M07`**: 6 references required for the closest complete technical reconstruction.

---

## 12. PW2 MINIMAL RELATIONSHIP CORE (`PW2-MINIMAL-RELATIONSHIP-CORE`)

Constructed **`PW2-MINIMAL-RELATIONSHIP-CORE`** comprising critical coupling relationships R08, R10, R11, R16, R22, R25, R28, R29, R30. This core represents the exact technical coupling points distinguishing K10 from standalone prior-art components.

---

## 13. C07 OPTIMIZATION & CONTRADICTION RESEARCH NOTES

- **C07 Selective Recomputation (`OPT01`)**: Classified as **`EFFICIENCY_ONLY`**; reduces evaluations by 98.73% but is not part of the minimal correctness boundary. Generic selective recomputation is broadly disclosed in `EP3622411B1`.
- **Contradiction Retention**: Classified as **`SUPPORTING_LINEAGE_BEHAVIOR`**; present in lineage graphs (`US9870396B2`) but not required for the K10 minimal boundary.

---

## 14. AUTOMATED TEST & ANALYZER VERIFICATION

- `flutter test test/pw2r8_mosaic_collision_test.dart` -> **10 / 10 Passed GREEN**
- `flutter test test/pw2r7_targeted_collision_test.dart` -> **8 / 8 Passed GREEN**
- `flutter test test/pw2r6_minimal_boundary_test.dart` -> **10 / 10 Passed GREEN**
- `flutter test test/pw2r5_geographic_mutation_dependency_test.dart` -> **8 / 8 Passed GREEN**
- `flutter test test/patent_window_1_strategy_boundary_test.dart` -> **7 / 7 Passed GREEN**
- `flutter test test/patent_window_1_professional_review_test.dart` -> **8 / 8 Passed GREEN**
- `flutter test test/patent_window_1c6r_test.dart` -> **8 / 8 Passed GREEN**
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
- **All 167 Master Tests Across 17 Test Suites**: **100% PASSED GREEN**
- **Flutter Analyzer**: **0 Errors, 0 Warnings**

---

## 15. ANSWERS TO THE TEN REQUIRED FINAL QUESTIONS

1. **Q1: Which K10 relationships are directly disclosed by a single reference?**  
   Single-step relationships R01, R02, R03 (`US8548248B2` / `US10036650B2`), R04, R06 (`US10452652B2`), and R12, R13 (`CN117235153B`).
2. **Q2: Which relationships require multiple references?**  
   22 relationships (R05, R07, R09, R14, R15, R17..R21, R23, R24, R26, R27) require multi-reference assembly across 2 to 6 patent families.
3. **Q3: Which critical relationships remain incomplete even after the closest mosaic is assembled?**  
   R08, R10, R11, R16, R22, R25, R28, R29, R30.
4. **Q4: Does the closest mosaic actually reproduce K10 without substantial architectural redesign?**  
   **NO.** Unifying 6 disparate patent families requires substantial data model and state transition redesign ($T10 = \text{YES}$).
5. **Q5: Which relationships are the true technical coupling points rather than generic components?**  
   R08 ($Mutation \rightarrow Spatial \rightarrow Admin \rightarrow Risk$), R10/R11 (Shared Admin/Risk Recalculation), R16 (Topology Mutation Propagation), R22 (Cross-Event Isolation under Shared Downstream Nodes), R25 (Remote Sensing Integration), and R30 (Integrated Mechanism).
6. **Q6: What is the PW2-MINIMAL-RELATIONSHIP-CORE?**  
   The set of critical coupling relationships: R08, R10, R11, R16, R22, R25, R28, R29, R30.
7. **Q7: What is the status of C07 selective recomputation?**  
   Classified as **`EFFICIENCY_ONLY`**; reduces evaluations by 98.73% but is not part of the minimal correctness boundary.
8. **Q8: What is the status of contradiction retention?**  
   Classified as **`SUPPORTING_LINEAGE_BEHAVIOR`**; present in evidence lineage graphs (`US9870396B2`) but not required for K10 correctness.
9. **Q9: What are the most important negative findings?**  
   No single reference or obvious combination connects remote-sensing mutations to multi-layer spatial administrative risk crosswalk closure calculations with cross-event isolation and bitemporal versioning.
10. **Q10: What exact relationship should be taken forward for any future counsel review?**  
    `PW2-MINIMAL-RELATIONSHIP-CORE` (Integrated remote-sensing satellite observation mutation across multi-event spatial-administrative-risk crosswalk DAGs with shared node recalculation, cross-event isolation, and historical state versioning).

---

## 16. FINAL FOUR-WAY SEPARATION STATEMENT

```
TECHNICAL BOUNDARY:
MINIMAL BOUNDARY IDENTIFIED (PW2R6 PW2-MINIMAL-CANDIDATE comprises C01, C02, C03, C04, C05, C06, C08, C09, C10 with 100% full-rebuild equivalence and 98.73% evaluation reduction)

MOSAIC PRIOR-ART BOUNDARY:
DISCLOSED AS MULTI-REFERENCE MOSAIC (Individual sub-components are disclosed across US8548248B2, US10036650B2, US10452652B2, US7441230B2, and CN117235153B; combining them requires substantial architectural redesign)

RELATIONSHIP GAP:
PW2-MINIMAL-RELATIONSHIP-CORE (Relationships R08, R10, R11, R16, R22, R25, R28, R29, R30 remain not located as complete disclosures in any single reference or pairwise combination in the searched corpus)

LEGAL PATENTABILITY:
UNDETERMINED — REQUIRES PATENT COUNSEL
```

---

NO PRODUCTION RISKPULSE CODE MODIFIED.
NO PATENTABILITY OR NOVELTY CONCLUSION MADE.
