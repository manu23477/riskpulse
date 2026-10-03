# HPSDMA GAP ANALYSIS — ROUND 5: ERROR GAP ANALYSIS

**Document Identifier**: `HPSDMA_R5_21_ERROR_GAP_ANALYSIS`  
**Workstream**: Real-World Error Class Matrix & Discovered Error Classes E019..E022  
**Date**: October 1, 2026  
**Status**: RESEARCH / EXPERIMENTAL VALIDATION ONLY  

---

## 1. REAL-WORLD DISCOVERED ERROR CLASSES (E019 THROUGH E022)

In addition to Round 4 error classes $E001..E018$, four new error classes were discovered in real-world datasets:

| New Error Code | Error Description | Discovery Source | Validation Handling | Pipeline Disposition |
| :---: | :--- | :---: | :--- | :--- |
| **`E019`** | Project coordinate Out-of-Bounds | `RW-04` (Copernicus) | Reprojection check | Reprojected to WGS84 |
| **`E020`** | Numerical sentinel `-9999.0` | `RW-03` (IMD Grid) | Sentinel filter | Set to `null` with flag |
| **`E021`** | Mixed text place name + coordinates | `RW-01` (Loss Report) | Hybrid geocode | Geometry used; text in hint |
| **`E022`** | Currency conversion requirement | `RW-01` (Loss Report) | Financial normalizer | Normalized to INR integer |

---

## 2. REAL-WORLD ERROR FREQUENCY SUMMARY

- Total real-world observation records tested: $250$.
- Total validation errors caught: $14$ (All handled cleanly by $E001..E022$ rules with zero unhandled crashes).
