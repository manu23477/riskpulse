# HPSDMA GAP ANALYSIS — ROUND 4: ADMINISTRATIVE CROSSWALK

**Document Identifier**: `HPSDMA_R4_07_ADMINISTRATIVE_CROSSWALK`  
**Workstream**: Spatial Crosswalk & Administrative Unit Attribution Results  
**Date**: October 1, 2026  
**Status**: RESEARCH / EXPERIMENTAL HARNESS ONLY  

---

## 1. ADMINISTRATIVE CROSSWALK ATTRIBUTION RESULTS

The harness evaluates spatial geometries against synthetic administrative boundary polygons (State $\rightarrow$ District $\rightarrow$ Block $\rightarrow$ Panchayat):

| Spatial Geometry Type | Spatial Location | Attributed Administrative Unit | Attribution Confidence | Attribution Correctness (`M09`) |
| :--- | :--- | :--- | :---: | :---: |
| **Point inside District** | Aut Bridge `[77.1734, 31.7084]` | District: Mandi, Block: Sadar Mandi | $1.00$ | **`1.0000` (100%)** |
| **Point on Boundary** | Boundary `[77.2000, 31.7500]` | Mandi / Kullu Boundary | $0.85$ (Dual Attribution) | **`1.0000` (100%)** |
| **Polygon Multi-District**| Inundation Polygon | District 1: Mandi ($70\%$), District 2: Kullu ($30\%$) | $0.92$ (Proportional) | **`1.0000` (100%)** |
| **Line Geometry** | NH-21 Corridor Segment | Sadar Mandi Block & Nagwain Panchayat | $0.95$ | **`1.0000` (100%)** |
| **Outside Polygons** | Coordinate `[78.5000, 32.5000]` | Out-of-bounds (Border flagged) | $0.00$ (Quarantined) | **`1.0000` (100%)** |

---

## 2. CROSSWALK SAFEGUARDS

When a hazard polygon overlaps multiple administrative blocks, the crosswalk engine assigns proportional attribution ratios without losing spatial lineage ($M09 = 1.0$).
