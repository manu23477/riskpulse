# HPSDMA GAP ANALYSIS — ROUND 4: PROPOSED OBSERVATION ENVELOPE

**Document Identifier**: `HPSDMA_R4_02_OBSERVATION_ENVELOPE`  
**Workstream**: Proposed Normalized Observation Envelope Specification  
**Date**: October 1, 2026  
**Status**: RESEARCH / EXPERIMENTAL HARNESS ONLY  

---

## 1. PROPOSED OBSERVATION ENVELOPE SPECIFICATION

To ingest heterogeneous input formats (Daily Loss Reports, CWC Telemetry, OSINT, Satellite, Sensors, Field Reports), the harness defines a unified **Proposed Observation Envelope**:

```json
{
  "$schema": "https://riskpulse.io/schemas/observation_envelope_v1.json",
  "observation_id": "OBS-HP-2026-0001",
  "source": {
    "source_id": "HP-JAL-SHAKTI-MND-01",
    "source_name": "Jal Shakti Vibhag Division Mandi",
    "source_type": "sensor_telemetry",
    "reliability_weight": 0.92
  },
  "timestamps": {
    "observed_at": "2026-08-15T09:55:00Z",
    "received_at": "2026-08-15T11:00:00Z"
  },
  "hazard": {
    "hazard_type": "flash_flood",
    "category": "hydrological",
    "severity_hint": "high"
  },
  "spatial": {
    "location_expression": "Aut Bridge, Sadar Mandi, Himachal Pradesh",
    "geometry": {
      "type": "Point",
      "coordinates": [77.1734, 31.7084]
    },
    "spatial_uncertainty_meters": 45.0,
    "administrative_hint": {
      "state": "Himachal Pradesh",
      "district": "Mandi",
      "block": "Sadar Mandi"
    }
  },
  "measurement": {
    "parameter": "water_level",
    "value": 4.85,
    "unit": "meters",
    "threshold_status": "warning_exceeded"
  },
  "quality": {
    "validation_status": "VALID",
    "quality_flags": ["DUAL_TIMESTAMP_VERIFIED", "GEOMETRY_RESOLVED"],
    "processing_latency_ms": 1.2
  },
  "payload_reference": {
    "raw_hash": "e7785f567660afad4c0dd33111282698db106501571b2bb679005a7cfd0133e1",
    "raw_payload": "[SYNTHETIC_REPRESENTATIVE_PAYLOAD_STRING]"
  }
}
```

---

## 2. REPRESENTATIVE INPUT CLASSES SPECIFICATION

The harness defines 10 representative test input classes:
1. **`Class A` Daily Loss Report**: District Magistrate loss report with text location & damage sums.
2. **`Class B` CWC Telemetry**: Sensor reading with gauge height, discharge cumecl, and station ID.
3. **`Class C` OSINT Observation**: Social media report with informal text location and photo attachment.
4. **`Class D` Remote-Sensing Observation**: Satellite raster change detection with cloud-masking flags.
5. **`Class E` Sensor Observation**: Automated GLOF lake level telemetry.
6. **`Class F` Government Field Report**: SDMA field responder mobile app submission with GPS coordinates.
7. **`Class G` Duplicate Observation**: Exact payload duplicate or re-transmitted report.
8. **`Class H` Contradictory Observation**: Report asserting road open when earlier report asserted road blocked.
9. **`Class I` Late-Arriving Observation**: Report observed at 08:30 arriving at 15:00 after $V_3$ created.
10. **`Class J` Partially Specified Observation**: Report missing explicit coordinates or timestamp.
