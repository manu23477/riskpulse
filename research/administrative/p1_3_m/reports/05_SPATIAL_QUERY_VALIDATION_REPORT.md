# P1.3-M SPATIAL QUERY VALIDATION REPORT

**Document Identifier**: `P1_3_M_05_SPATIAL_QUERY_VALIDATION`  
**Workstream**: Spatial Point-in-Polygon & Intersecting Geometry Acceptance Tests (A through J)  
**Date**: October 1, 2026  
**Status**: **SPATIAL QUERY ACCEPTANCE PASSED**  

---

## 1. SPATIAL QUERY ACCEPTANCE TEST RESULTS (TESTS A THROUGH J)

All 10 required spatial query acceptance tests executed successfully:

| Test ID | Spatial Query Type | Test Coordinate / Geometry | Returned Administrative Match | Status |
| :---: | :--- | :--- | :--- | :---: |
| **`Test A`** | Point $\rightarrow$ District | Lat: $31.6$, Lon: $77.0$ | District: Mandi (`HP-06`) | **PASS** |
| **`Test B`** | Point $\rightarrow$ Sub-District | Lat: $31.72$, Lon: $76.95$ | Tehsil: Sadar Mandi (`HP-TEH-0114`) | **PASS** |
| **`Test C`** | Point $\rightarrow$ Village | Lat: $31.70$, Lon: $77.15$ | Village: Aut Village (`HP-VIL-aut`) | **PASS** |
| **`Test D`** | Point $\rightarrow$ Development Block | Lat: $31.65$, Lon: $76.90$ | Block: Mandi Block (`HP-BLK-0088`) | **PASS** |
| **`Test E`** | Point $\rightarrow$ Gram Panchayat | Lat: $31.68$, Lon: $77.12$ | Panchayat: Aut GP (`HP-GP-0042`) | **PASS** |
| **`Test F`** | Village $\rightarrow$ Revenue Parent | Village: Aut Village | Parent Tehsil: Sadar Mandi (`HP-TEH-0114`)| **PASS** |
| **`Test G`** | Village $\rightarrow$ Development Parent | Village: Aut Village | Parent Block: Mandi Block (`HP-BLK-0088`) | **PASS** |
| **`Test H`** | Geometry $\rightarrow$ Intersecting Districts | Polygon over Mandi/Kullu | Districts: Mandi & Kullu | **PASS** |
| **`Test I`** | Geometry $\rightarrow$ Intersecting Sub-Districts | Polygon over Sadar Mandi/Aut | Tehsils: Sadar Mandi & Aut Sub-Tehsil | **PASS** |
| **`Test J`** | Geometry $\rightarrow$ Intersecting Blocks | Polygon over Mandi/Kullu Blocks | Blocks: Mandi Block & Nagwain Block | **PASS** |
