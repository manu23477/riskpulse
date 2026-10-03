# HPSDMA GAP ANALYSIS — ROUND 5: PROPOSED OBSERVATION ENVELOPE V2

**Document Identifier**: `HPSDMA_R5_15_OBSERVATION_ENVELOPE_V2`  
**Workstream**: Revised Inbound Observation Envelope Schema V2  
**Date**: October 1, 2026  
**Status**: RESEARCH / EXPERIMENTAL VALIDATION ONLY  

---

## 1. REVISION JUSTIFICATIONS (V1 TO V2)

Based on real-world dataset findings (`RW-01` through `RW-07`), four enhancements were incorporated into **Observation Envelope V2**:
1. **`spatial.native_crs`**: Explicitly captures native coordinate reference systems (e.g. `EPSG:32643`) prior to WGS84 reprojection.
2. **`measurement.raw_unit`**: Retains native unit string (e.g. `"feet"`, `"cfs"`, `"Lakh_INR"`) alongside normalized SI values.
3. **`quality.sentinel_flag`**: Records if a missing value sentinel (e.g. `-9999.0`) was stripped.
4. **`timestamps.temporal_category`**: Explicitly tags temporal quality (`KNOWN`, `APPROXIMATE`, `CONFLICTED`, `UNKNOWN`).

```json
{
  "$schema": "https://riskpulse.io/schemas/observation_envelope_v2.json",
  "observation_id": "OBS-HP-2026-0001",
  "timestamps": {
    "observed_at": "2026-08-15T09:55:00Z",
    "received_at": "2026-08-15T11:00:00Z",
    "temporal_category": "KNOWN"
  },
  "spatial": {
    "geometry": {"type": "Point", "coordinates": [77.1734, 31.7084]},
    "native_crs": "EPSG:4326",
    "spatial_uncertainty_meters": 45.0
  },
  "measurement": {
    "parameter": "water_level",
    "normalized_value": 4.85,
    "normalized_unit": "meters",
    "raw_value": 15.91,
    "raw_unit": "feet"
  }
}
```
