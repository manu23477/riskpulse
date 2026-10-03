# HPSDMA GAP ANALYSIS — ROUND 3: PROPOSED RISKPULSE INTEGRATION CONTRACT

**Document Identifier**: `HPSDMA_R3_06_INTEGRATION_CONTRACT`  
**Workstream**: Proposed Interoperability API & Data Contract  
**Date**: September 30, 2026  
**Status**: RESEARCH ONLY — PROPOSED CONTRACT (NO PRODUCTION CODE IMPLEMENTED)  

---

## 1. PROPOSED RISKPULSE INPUT SCHEMA (CONSUMED FROM HPSDMA / SOURCES)

RiskPulse ingests raw observation events pushed from HPSDMA's IMS or source feeds:

```json
{
  "observation_id": "OBS-HP-2026-0815-001",
  "source_id": "HP-JAL-SHAKTI-STATION-14",
  "source_type": "sensor_telemetry",
  "observation_timestamp": "2026-08-15T09:55:00Z",
  "ingestion_timestamp": "2026-08-15T11:00:00Z",
  "geometry": {
    "type": "Point",
    "coordinates": [77.1734, 31.7084]
  },
  "location_text": "Aut Bridge, Mandi District, Himachal Pradesh",
  "hazard_type": "flash_flood",
  "payload": {
    "water_level_meters": 4.85,
    "discharge_cumecl": 1250.0,
    "rainfall_mm_hr": 65.4
  },
  "source_reliability": 0.92,
  "metadata": {
    "department": "Jal Shakti Vibhag",
    "district": "Mandi",
    "block": "Sadar Mandi"
  }
}
```

---

## 2. PROPOSED RISKPULSE OUTPUT SCHEMA (EMITTED TO HPSDMA GIS-DSS)

RiskPulse emits enriched evidence-aware, spatially resolved, administrative risk state objects:

```json
{
  "event_id": "EVT-HP-2026-0042",
  "state_version": 5,
  "hazard_type": "flash_flood",
  "event_timestamp": "2026-08-15T09:55:00Z",
  "last_updated_timestamp": "2026-08-15T11:00:12Z",
  "spatial_state": {
    "bounding_polygon": {
      "type": "Polygon",
      "coordinates": [[[77.15, 31.68], [77.20, 31.68], [77.20, 31.72], [77.15, 31.72], [77.15, 31.68]]]
    },
    "spatial_error_meters": 45.2,
    "confidence": 0.94
  },
  "administrative_state": {
    "state_code": "HP",
    "district_code": "HP-MND",
    "district_name": "Mandi",
    "affected_blocks": ["HP-MND-SAD", "HP-MND-BAL"],
    "crosswalk_attribution_ratio": 0.88
  },
  "risk_state": {
    "composite_risk_score": 0.85,
    "risk_level": "EXTREME",
    "primary_threat": "Bridge inundation and downstream transport corridor disruption"
  },
  "evidence_lineage": {
    "supporting_evidence_ids": ["OBS-HP-2026-0815-001", "OSINT-TW-8841"],
    "conflicting_evidence_ids": ["FIELD-REP-012"],
    "provenance_hash": "e7785f567660afad4c0dd33111282698db106501571b2bb679005a7cfd0133e1"
  },
  "affected_entities": {
    "roads_affected": ["NH-21 Mandi-Kullu Highway"],
    "power_lines_affected": ["HPSEBL 33kV Aut Feeder"]
  }
}
```

---

## 3. MINIMUM DATA EXPOSURE REQUIREMENTS FOR HPSDMA

For RiskPulse to operate effectively as an intelligence layer, HPSDMA needs to expose:
1. **Observation Push Webhook / REST Feed**: Telemetry readings, daily loss reports, and OSINT/field call logs.
2. **Official Administrative Polygons**: WFS / GeoJSON endpoints for district and block boundaries.
3. **Critical Asset Layers**: WMS / WFS layers for major road corridors and power substations.
