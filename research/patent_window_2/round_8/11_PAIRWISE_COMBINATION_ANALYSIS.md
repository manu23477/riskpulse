# PATENT WINDOW 2 — ROUND 7/8: PAIRWISE COMBINATION ANALYSIS

**Document Identifier**: `PW2R8_11_PAIRWISE_COMBINATION_ANALYSIS`  
**Workstream**: Pairwise Combination Evaluation across Combinations A through H  
**Date**: October 1, 2026  
**Status**: RESEARCH ONLY — PAIRWISE COMBINATION ANALYSIS  

---

## 1. EVALUATION OF EIGHT PAIRWISE COMBINATIONS (A THROUGH H)

| Pair ID | References Combined | Combined Focus Areas | K-Components Covered | Relationships Formed | Critical Missing Relationships | Architectural Mismatch / Hindsight Risk | Pairwise Complete? |
| :---: | :--- | :--- | :--- | :--- | :--- | :--- | :---: |
| **`Pair A`** | `REF-01` + `REF-02` | Satellite Feature Extraction + Spatial Hazard Graph | K01, K02, K04 | R01, R02, R03 | R08, R10, R11, R16, R22, R25, R28, R30 | Lacks bitemporal versioning & transitive DAG closure | **`NO`** |
| **`Pair B`** | `REF-01` + `REF-13` | Satellite Feature Extraction + Admin Loss Mapping | K01, K02, K03, K04 | R01, R02, R03 | R08, R10, R11, R16, R22, R25, R28, R30 | Lacks dependency DAG propagation & bitemporal history | **`NO`** |
| **`Pair C`** | `REF-01` + `REF-07` | Satellite Feature Extraction + RS Landslide Warning | K01, K02, K04 | R01, R03 | R08, R10, R11, R16, R22, R25, R28, R30 | Lacks admin crosswalk & transitive DAG closure | **`NO`** |
| **`Pair D`** | `REF-02` + `REF-04` | Hazard Graph + Build Proxy Dependency Invalidation | K02, K04, K05, K08..K10| R02, R03, R10*, R11*, R16*, R22* | R01, R08, R25, R28, R29, R30 | **Domain Mismatch**: Build graph vs Geospatial GIS | **`NO`** |
| **`Pair E`** | `REF-04` + `REF-05` | Build Invalidation + Bitemporal Stream Versioning | K05, K06, K08..K10 | R10*, R11*, R12, R13, R16*, R22* | R01, R02, R03, R08, R25, R28, R30 | **Domain Mismatch**: Non-geospatial software infrastructure | **`NO`** |
| **`Pair F`** | `REF-01` + `REF-05` | Satellite Feature Extraction + Bitemporal Versioning | K01, K02, K06 | R01, R12, R13 | R02, R03, R08, R10, R11, R16, R22, R25, R30 | Lacks admin crosswalk & risk state DAGs | **`NO`** |
| **`Pair G`** | `REF-03` + `REF-06` | Event Graphs + Provenance Spatial Graphs | K02, K04, K06 | R03, R12, R13 | R01, R08, R10, R11, R16, R22, R25, R28, R30 | Lacks remote-sensing mutation & DAG closures | **`NO`** |
| **`Pair H`** | `REF-01` + `REF-04` | Satellite Extraction + Build Proxy Invalidation | K01, K02, K05, K08..K10 | R01, R10*, R11*, R16*, R22* | R02, R03, R08, R25, R28, R29, R30 | **Domain Mismatch**: Requires combining satellite imagery with build proxies | **`NO`** |

---

## 2. PAIRWISE ANALYSIS FINDING

No two-reference combination discloses the complete `PW2-MINIMAL-RELATIONSHIP-CORE`. Pairwise combinations either lack critical relationships (R08, R25, R30) or depend on combining non-geospatial build systems (`REF-04`) with satellite raster processing (`REF-01`).
