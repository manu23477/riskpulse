# RISKPULSE RESEARCH WORKSTREAM — ROUND 6: AUDIT QUERY RESULTS

**Document Identifier**: `RISKPULSE_R6_24_AUDIT_QUERY_RESULTS`  
**Workstream**: Results for 10 Key Audit Queries (Q1 through Q10)  
**Date**: October 1, 2026  
**Status**: EXPERIMENTAL AUDIT QUERY LOG  

---

## 1. EVALUATION OF TEN KEY AUDIT QUERIES (Q1 THROUGH Q10)

| Query ID | Audit Question | Returned Machine-Readable Result | Query Completeness (`L25`) |
| :---: | :--- | :--- | :---: |
| **`AQ-1`** | What is the current state? | `Version V7`: `CompositeScore = 0.92`, `Level = CRITICAL` | **`1.0000` (100%)** |
| **`AQ-2`** | Why is it current? | Triggered by $T_{12}$ satellite mask $E_{11}$ + late report $E_{12}$ | **`1.0000` (100%)** |
| **`AQ-3`** | What evidence created it? | Evidence IDs: $E_2..E_8, E_{10}, E_{11}, E_{12}$ | **`1.0000` (100%)** |
| **`AQ-4`** | What evidence contradicted it? | Evidence ID: $E_9$ ("Road reopened") | **`1.0000` (100%)** |
| **`AQ-5`** | What changed since V1? | Geometry: Point $\rightarrow$ Polygon ($0.35\text{km}^2$); Score: $0.25 \rightarrow 0.92$ | **`1.0000` (100%)** |
| **`AQ-6`** | What was the state at T10? | `Version V4`: `CompositeScore = 0.65`, `has_conflict = true` | **`1.0000` (100%)** |
| **`AQ-7`** | Which district is affected? | District: Mandi (`HP-MND`), Tehsil: Sadar Mandi (`HP-MND-SAD`)| **`1.0000` (100%)** |
| **`AQ-8`** | Which risk nodes depend on E1? | Sadar Mandi Risk Node & NH-21 Corridor Vulnerability Node | **`1.0000` (100%)** |
| **`AQ-9`** | What invalidates current state?| Verified clearing report covering $100\%$ failure polygon | **`1.0000` (100%)** |
| **`AQ-10`**| Source contribution trace? | $E_2, E_8$ (Field: $40\%$), $E_4, E_{11}$ (Satellite: $40\%$), $E_3$ (Weather: $20\%$) | **`1.0000` (100%)** |

All 10 audit queries returned machine-readable, verified responses ($L25 = 1.0$).
