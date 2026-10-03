# RISKPULSE RESEARCH WORKSTREAM — ROUND 6: SYNTHETIC DISASTER TIMELINE

**Document Identifier**: `RISKPULSE_R6_02_SYNTHETIC_DISASTER_TIMELINE`  
**Workstream**: Controlled Synthetic Himalayan Landslide Disaster Chronology (T1 through T15)  
**Date**: October 1, 2026  
**Status**: EXPERIMENTAL CONTROLLED CHRONOLOGY  

---

## 1. CONTROLLED EXPERIMENTAL CHRONOLOGY (T1 THROUGH T15)

Location: Synthetic Himalayan Corridor (`Alpha Corridor, Mandi District, Himachal Pradesh`)  
Primary Hazard: Landslide & Cascading Transport Inundation

| Step ID | Time | Event Action / Arrival | Source Class | Triggered System Action | State Version |
| :---: | :---: | :--- | :--- | :--- | :---: |
| **`T1`** | `08:00Z` | OSINT tweet: *"Possible landslide near Alpha Road"* | OSINT | Ingested; low confidence hypothesis created | `V1` |
| **`T2`** | `08:30Z` | Govt field report: *"Road blocked at km 14"* | Field | Road blockage confirmed; confidence escalated | `V2` |
| **`T3`** | `09:00Z` | IMD telemetry: Heavy rainfall ($85\text{ mm/hr}$) | Weather | Rain trigger linked to event hypothesis | `V2` |
| **`T4`** | `09:30Z` | Sentinel-2 satellite pass: Terrain change detected | Satellite | Slope disturbance confirmed via remote sensing | `V2` |
| **`T5`** | `10:00Z` | RiskPulse unifies evidence into Event `EVT-E1` | Pipeline | Formal Event Hypothesis `E1` created | `V2` |
| **`T6`** | `10:30Z` | Spatial engine resolves line segment geometry | Spatial | Road segment geometry versioned | `V3` |
| **`T7`** | `11:00Z` | Admin crosswalk attributes Tehsil & District | Crosswalk | Sadar Mandi Tehsil attributed | `V3` |
| **`T8`** | `11:30Z` | Risk score escalated: `LOW` $\rightarrow$ `MODERATE` | Risk Engine | Composite risk score = `0.55` | `V3` |
| **`T9`** | `12:00Z` | Second field report: Blockage confirmed | Field | Risk escalated: `MODERATE` $\rightarrow$ `HIGH` (`0.85`) | `V3` |
| **`T10`**| `12:30Z` | Contradictory report: *"Road has reopened"* | Field | Non-deletion conflict relation created | `V4` |
| **`T11`**| `13:00Z` | Verification: *"One-lane open; slope unstable"* | Field | Revised state: `PARTIALLY_OPEN` (`0.75`) | `V5` |
| **`T12`**| `13:30Z` | Satellite pass 2: Additional slope movement | Satellite | Spatial geometry mutated to expanded polygon | `V6` |
| **`T13`**| `14:00Z` | Dependency closure updates downstream nodes | DAG Engine | Recomputes Mandi; preserves Kullu branch | `V6` |
| **`T14`**| `14:30Z` | Late report ($t_{\text{observed}} = 08:15\text{Z}$) arrives | Late Ingest | $V_7$ revision created; $V_1..V_6$ intact | `V7` |
| **`T15`**| `15:00Z` | Historical "As-Of" audit query requested | Audit | Reconstructs exact state at $T_5, T_8, T_{10}, T_{13}$ | `V7` |
