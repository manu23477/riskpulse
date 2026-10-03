# HPSDMA GAP ANALYSIS — ROUND 5: CONTRACT REVISION

**Document Identifier**: `HPSDMA_R5_22_CONTRACT_REVISION`  
**Workstream**: Interoperability Contract V2 Revisions & Field Justifications  
**Date**: October 1, 2026  
**Status**: RESEARCH / EXPERIMENTAL VALIDATION ONLY  

---

## 1. REVISION JUSTIFICATIONS FOR OBSERVATION ENVELOPE V2

Based on real-world dataset evaluation (`RW-01` through `RW-07`), four fields were added to the Inbound Contract:
1. **`spatial.native_crs`**: Required to record native projected EPSG codes (`EPSG:32643`) before WGS84 reprojection.
2. **`measurement.raw_unit`**: Required to preserve non-SI units (`"feet"`, `"cfs"`, `"Lakh_INR"`) alongside SI normalized values.
3. **`quality.sentinel_flag`**: Required to document when numerical sentinels (`-9999.0`) were stripped.
4. **`timestamps.temporal_category`**: Required to document temporal uncertainty categories (`KNOWN`, `APPROXIMATE`, `CONFLICTED`, `UNKNOWN`).

---

## 2. REVISION JUSTIFICATIONS FOR OUTBOUND STATE CONTRACT V2

1. **`risk_state.financial_loss_estimate`**: Added to convey aggregated sectoral financial impact (in INR) derived from daily loss reports (`RW-01`).
2. **`quality_flags.confidence_degraded`**: Added to notify HPSDMA when CWC hydro telemetry goes offline or becomes stale ($SF-01$).
