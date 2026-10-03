# HPSDMA GAP ANALYSIS — ROUND 5: MISSING DATA ANALYSIS

**Document Identifier**: `HPSDMA_R5_08_MISSING_DATA_ANALYSIS`  
**Workstream**: Missing Values, Sentinel Values & Zero vs Null Distinction  
**Date**: October 1, 2026  
**Status**: RESEARCH / EXPERIMENTAL VALIDATION ONLY  

---

## 1. REAL-WORLD MISSING VALUE PATTERNS ENCOUNTERED

The real-world datasets contained 6 distinct missing value representations:
1. **`NULL` / `None`**: Database null values (`RW-01`, `RW-02`).
2. **Empty String `""`**: Blank CSV fields (`RW-01`).
3. **Text Sentinels `"NA"`, `"-"`, `"Unknown"`**: Missing place names (`RW-07`).
4. **Numerical Sentinels `-9999.0`, `-999.0`**: Missing satellite/grid raster values (`RW-03`).
5. **Zero `0.0`**: Zero measurement (e.g. `0.0 mm` rainfall vs missing reading).

---

## 2. CRITICAL ZERO VS NULL DISCRIMINATION

> [!IMPORTANT]
> **Discriminative Rule**: The pipeline explicitly distinguishes `0.0` (zero rainfall measured) from `NULL` / `-9999.0` (sensor offline or value unmeasured).
> - `0.0 mm` rainfall is processed as a valid measurement of zero precipitation.
> - `-9999.0` is converted to `measurement.value = null` and tagged with quality flag `MISSING_SENSOR_READING` ($M01 = 1.0$).
