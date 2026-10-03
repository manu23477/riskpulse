# HPSDMA GAP ANALYSIS — ROUND 5: SCHEMA FORENSICS

**Document Identifier**: `HPSDMA_R5_04_SCHEMA_FORENSICS`  
**Workstream**: Real-World Schema Forensics & Attribute Mapping  
**Date**: October 1, 2026  
**Status**: RESEARCH / EXPERIMENTAL VALIDATION ONLY  

---

## 1. REAL-WORLD SCHEMA MAPPING MATRIX

| Dataset | Field Name | Native Type | Field Meaning | Nullable? | Normalized Envelope Field |
| :--- | :--- | :---: | :--- | :---: | :--- |
| **RW-01** | `inc_id` | String | Daily Loss Incident ID | No | `observation_id` |
| **RW-01** | `report_dt` | String | Report submission date | No | `timestamps.received_at` |
| **RW-01** | `dist_name` | String | Revenue district name | No | `spatial.administrative_hint.district` |
| **RW-01** | `loss_type` | String | Structural damage category | Yes | `hazard.hazard_type` |
| **RW-01** | `est_cost_lakh` | Float | Financial damage in Lakh INR | Yes | `measurement.value` (Unit: `INR_Lakh`) |
| **RW-02** | `station_code` | String | CWC Hydro Gauge Station | No | `source.source_id` |
| **RW-02** | `read_time` | String | Telemetry observation time | No | `timestamps.observed_at` |
| **RW-02** | `water_lvl_m` | Float | River gauge height in meters | Yes | `measurement.value` (Unit: `meters`) |
| **RW-03** | `rf_mm_hr` | Float | Hourly rainfall intensity | Yes | `measurement.value` (Unit: `mm_hr`) |
| **RW-04** | `lake_area_ha` | Float | Glacial lake surface area | Yes | `measurement.value` (Unit: `hectares`) |
| **RW-05** | `tehsil_code` | String | Revenue Tehsil Code | No | `spatial.administrative_hint.block` |
| **RW-06** | `road_name` | String | Highway corridor designation| No | `spatial.location_expression` |
| **RW-07** | `tweet_text` | String | Informal social report text | No | `payload_reference.raw_payload` |
