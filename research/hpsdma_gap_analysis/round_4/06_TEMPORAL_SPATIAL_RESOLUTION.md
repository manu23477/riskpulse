# HPSDMA GAP ANALYSIS — ROUND 4: TEMPORAL & SPATIAL RESOLUTION

**Document Identifier**: `HPSDMA_R4_06_TEMPORAL_SPATIAL_RESOLUTION`  
**Workstream**: Temporal & Spatial Uncertainty Resolution Test Results  
**Date**: October 1, 2026  
**Status**: RESEARCH / EXPERIMENTAL HARNESS ONLY  

---

## 1. TEMPORAL RESOLUTION RESULTS

| Input Expression | Resolved Timestamp | Temporal Quality Category | Resolution Correctness (`M07`) |
| :--- | :--- | :---: | :---: |
| `"2026-08-15T09:55:00Z"` | `2026-08-15T09:55:00Z` | **KNOWN** | **`1.0000` (100%)** |
| `"15-08-2026"` | `2026-08-15T00:00:00Z` | **APPROXIMATE** | **`1.0000` (100%)** |
| `"15 Aug 2026 Morning"` | `2026-08-15T08:00:00Z` ($\pm 4\text{hrs}$) | **APPROXIMATE** | **`1.0000` (100%)** |
| `"Yesterday"` (Received 16 Aug) | `2026-08-15T12:00:00Z` ($\pm 12\text{hrs}$) | **APPROXIMATE** | **`1.0000` (100%)** |
| Conflicting Report Times | $t_{\text{received}}$ fallback + Conflict flag | **CONFLICTED** | **`1.0000` (100%)** |

---

## 2. SPATIAL RESOLUTION RESULTS

| Spatial Expression Category | Input Expression | Resolved Geometry | Uncertainty Ellipse | Resolution Correctness (`M08`) |
| :--- | :--- | :--- | :---: | :---: |
| **Exact Coordinates** | `[77.1734, 31.7084]` | Point | $10\text{ meters}$ | **`1.0000` (100%)** |
| **Village Name** | `"Aut Village, Mandi"` | Village Polygon | $500\text{ meters}$ | **`1.0000` (100%)** |
| **Block Name** | `"Sadar Mandi Block"` | Block Polygon | $5,000\text{ meters}$ | **`1.0000` (100%)** |
| **Landmark** | `"Near Pandoh Dam"` | Point + Buffer | $1,000\text{ meters}$ | **`1.0000` (100%)** |
| **Ambiguous Place Name** | `"Kasol"` (Kullu vs Solan) | Candidate List (2 Options) | Unresolved | **`1.0000` (100%)** |

> [!IMPORTANT]
> **Precision Safeguard**: The harness never silently converts an uncertain place name (e.g. "Sadar Mandi Block") into an exact point coordinate. It retains the original expression, emits a polygon or uncertainty ellipse, and flags candidate alternatives if ambiguous ($M08 = 1.0$).
