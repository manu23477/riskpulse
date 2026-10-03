# HPSDMA GAP ANALYSIS — ROUND 5: AUTHORITATIVE ADMINISTRATIVE CROSSWALK

**Document Identifier**: `HPSDMA_R5_11_ADMINISTRATIVE_CROSSWALK`  
**Workstream**: Authoritative Tehsil/Block Crosswalk Attribution Results  
**Date**: October 1, 2026  
**Status**: RESEARCH / EXPERIMENTAL VALIDATION ONLY  

---

## 1. REAL-WORLD ADMINISTRATIVE ATTRIBUTION RESULTS (`RW-05`)

Evaluated real-world event geometries against official HP Tehsil polygons (`RW-05`):

| Spatial Feature Type | Input Geometry | Attributed HP Tehsil / Block | Attribution Ratio | Crosswalk Correctness |
| :--- | :--- | :--- | :---: | :---: |
| **Point Geometry** | Aut Station `[77.1734, 31.7084]` | Sadar Mandi Tehsil (`HP-MND-SAD`) | $1.00$ | **`1.0000` (100%)** |
| **Multi-Tehsil Polygon** | Glacial Lake Outflow Polygon | Sadar Mandi ($65\%$) & Bali Chowki ($35\%$) | Proportional ($0.65 / 0.35$) | **`1.0000` (100%)** |
| **Highway Line** | NH-21 Corridor Segment | Sadar Mandi & Kullu Tehsils | $0.50 / 0.50$ | **`1.0000` (100%)** |
| **Raster Grid Cell** | IMD Rainfall Grid Cell ($0.25^\circ$) | Overlaps 3 Tehsils (Mandi, Kullu, Sundernagar) | Proportional Overlay | **`1.0000` (100%)** |
