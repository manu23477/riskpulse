# HPSDMA GAP ANALYSIS — ROUND 3: GIS-DSS RESPONSIBILITY BOUNDARY

**Document Identifier**: `HPSDMA_R3_03_GIS_DSS_BOUNDARY`  
**Workstream**: HPSDMA Core Capabilities vs RiskPulse Enrichment Boundary  
**Date**: September 30, 2026  
**Status**: RESEARCH ONLY — NO PRODUCTION CODE CHANGES  

---

## 1. RESPONSIBILITY BOUNDARY CLASSIFICATION

To prevent architectural duplication, 15 core disaster management capabilities were evaluated to establish what belongs to the HPSDMA GIS-DSS versus what can be enriched by RiskPulse:

| Capability | Official HPSDMA Role | Responsibility Classification | RiskPulse Duplication Risk |
| :--- | :--- | :---: | :---: |
| **Map Visualization** | Base map layers, roads, rivers, administrative boundaries. | **CORE HPSDMA GIS-DSS** | **HIGH** (Do NOT Duplicate) |
| **Administrative Boundaries** | Official district, block, panchayat, ward GIS polygons. | **CORE HPSDMA GIS-DSS** | **HIGH** (Do NOT Duplicate) |
| **Hazard Layer Mapping** | Historical flood, landslide, GLOF hazard zone overlays. | **CORE HPSDMA GIS-DSS** | **MEDIUM** (Consume, Do Not Re-map) |
| **Vulnerability Layers** | Demographic, housing, and social vulnerability datasets. | **CORE HPSDMA GIS-DSS** | **MEDIUM** (Consume, Do Not Re-map) |
| **Infrastructure Mapping** | Roads, bridges, HPSEBL power lines, Jal Shakti networks. | **CORE HPSDMA GIS-DSS** | **HIGH** (Do NOT Duplicate) |
| **Sensor Data Collection** | Physical GLOF, water level, and automatic weather stations. | **INTEGRATION INPUT** | **LOW** (Consume Sensor Feeds) |
| **EWS Alerts & Thresholds** | Early warning thresholds for rainfall and water levels. | **CORE HPSDMA GIS-DSS** | **MEDIUM** (Enrich, Do Not Replace) |
| **Meteorological Forecasts** | IMD / CWC rainfall and river stage forecast feeds. | **INTEGRATION INPUT** | **LOW** (Consume Forecasts) |
| **Damage & Loss Mapping** | Coordinate-based daily loss reports and PDNA sector data. | **CORE HPSDMA GIS-DSS** | **MEDIUM** (Enrich Attribution) |
| **Buffer Analysis** | Radius/buffer zone calculations around hazard points. | **CORE HPSDMA GIS-DSS** | **HIGH** (Standard GIS Tool) |
| **Scenario Generation** | Disaster impact simulation and worst-case modeling. | **CORE HPSDMA GIS-DSS** | **LOW** (Supply Enriched States) |
| **Resource Dispatch Mapping** | NDRF, fire, police, medical asset location tracking. | **CORE HPSDMA GIS-DSS** | **HIGH** (Do NOT Duplicate) |
| **Multi-Source Evidence Fusion** | Resolving contradictory OSINT/sensor/field reports. | **POSSIBLE RISKPULSE ENRICHMENT** | **NONE** (Core RiskPulse Value) |
| **Selective Dependency Propagation**| Recalculating affected admin/risk closure upon mutation. | **POSSIBLE RISKPULSE ENRICHMENT** | **NONE** (Core RiskPulse Value) |
| **Bitemporal State History** | Preserving immutable historical versions ($t_{\text{event}}$ vs $t_{\text{arrival}}$). | **POSSIBLE RISKPULSE ENRICHMENT** | **NONE** (Core RiskPulse Value) |

---

## 2. DUPLICATION SAFEGUARDS FOR RISKPULSE

1. **Do NOT build custom GIS map viewers**: RiskPulse should export spatial GeoJSON / WMS layers for rendering directly inside the HPSDMA GIS portal.
2. **Do NOT redefine official administrative boundaries**: RiskPulse must consume HPSDMA's official Census / Revenue district and block boundaries.
3. **Do NOT replace physical sensor infrastructure**: RiskPulse ingests telemetry feeds from IMD, CWC, and HPSDMA sensors as raw evidence objects.
