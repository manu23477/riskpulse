# HPSDMA GAP ANALYSIS — ROUND 5: SPATIAL CRS COMPATIBILITY

**Document Identifier**: `HPSDMA_R5_06_SPATIAL_CRS_COMPATIBILITY`  
**Workstream**: Coordinate Reference Systems (CRS) & Projection Transformations  
**Date**: October 1, 2026  
**Status**: RESEARCH / EXPERIMENTAL VALIDATION ONLY  

---

## 1. REAL-WORLD SPATIAL CRS & PROJECTIONS ENCOUNTERED

| Dataset ID | Geometry Type | Native Coordinate Reference System (CRS) | EPSG Code | Transformation Result to WGS84 |
| :---: | :---: | :--- | :---: | :--- |
| **`RW-01`** | District Polygons | WGS84 Geographic Longitude / Latitude | `EPSG:4326` | **Direct Ingestion** |
| **`RW-02`** | Station Points | WGS84 Geographic Longitude / Latitude | `EPSG:4326` | **Direct Ingestion** |
| **`RW-03`** | Rainfall Grid | WGS84 Geographic Longitude / Latitude | `EPSG:4326` | **Direct Ingestion** |
| **`RW-04`** | Lake Mask Polygon| UTM Zone 43N Projected Coordinates | `EPSG:32643` | **Reprojected to EPSG:4326** |
| **`RW-05`** | Tehsil Polygons | WGS84 Geographic Longitude / Latitude | `EPSG:4326` | **Direct Ingestion** |
| **`RW-06`** | Road Lines | WGS84 Geographic Longitude / Latitude | `EPSG:4326` | **Direct Ingestion** |
| **`RW-07`** | Place Names | Text Place Name (`"Aut Bridge"`) | `Unspecified` | **Geocoded to Point + Uncertainty Ellipse** |

---

## 2. CRS TRANSFORMATIONS & GEOMETRY VALIDATION

- **Reprojection Accuracy**: Projected coordinates in `RW-04` (`EPSG:32643`) were transformed to `EPSG:4326` with $100\%$ topological validity.
- **Uncertainty Resolution**: Unspecified place names (`RW-07`) emitted a candidate point with a $500\text{m}$ uncertainty polygon, preventing false precision ($M04 = 1.0$).
