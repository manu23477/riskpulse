# HPSDMA GAP ANALYSIS — ROUND 4: PROPOSED OUTPUT CONTRACT

**Document Identifier**: `HPSDMA_R4_12_OUTPUT_CONTRACT`  
**Workstream**: Proposed Outbound Interoperability Contract JSON Specification  
**Date**: October 1, 2026  
**Status**: RESEARCH / EXPERIMENTAL HARNESS ONLY  

---

## 1. PROPOSED OUTBOUND INTEROPERABILITY CONTRACT

RiskPulse emits enriched spatial-administrative-risk state objects to HPSDMA's GIS-DSS via REST / GeoJSON APIs:

```json
{
  "$schema": "https://riskpulse.io/schemas/outbound_event_state_v1.json",
  "event_id": "EVT-HP-2026-0042",
  "state_version": 5,
  "hazard_type": "flash_flood",
  "timestamps": {
    "event_time": "2026-08-15T09:55:00Z",
    "last_updated_at": "2026-08-15T11:00:12Z"
  },
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
    "supporting_evidence_ids": ["OBS-HP-2026-0001", "OSINT-TW-8841"],
    "conflicting_evidence_ids": ["FIELD-REP-012"],
    "provenance_hash": "e7785f567660afad4c0dd33111282698db106501571b2bb679005a7cfd0133e1"
  },
  "quality_flags": {
    "has_conflict": true,
    "is_stale": false,
    "version_status": "CURRENT_REVISED"
  }
}
```

---

## 2. OUTBOUND CONTRACT VALIDATION RESULTS

Across 100 test output states emitted by the harness, **100% satisfied the output contract JSON schema** ($M22 = 1.0$).
