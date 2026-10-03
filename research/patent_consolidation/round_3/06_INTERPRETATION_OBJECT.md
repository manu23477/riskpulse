# PATENT CONSOLIDATION — ROUND 3: INTERPRETATION OBJECT

**Document Identifier**: `CONSOLIDATED_R3_06_INTERPRETATION_OBJECT`  
**Workstream**: Interpretation Object Model & Semantic Hazard Extraction  
**Date**: October 1, 2026  
**Status**: RESEARCH TECHNICAL SPECIFICATION  

---

## 1. INTERPRETATION OBJECT CONCEPTUAL SCHEMA

```json
{
  "interpretation_id": "INT-HP-2026-0001",
  "evidence_id": "EVID-HP-2026-0001",
  "extracted_hazard": {
    "hazard_type": "flash_flood",
    "extracted_severity": "high",
    "confidence_score": 0.88
  },
  "extracted_measurement": {
    "parameter": "water_level",
    "normalized_value": 4.85,
    "normalized_unit": "meters"
  },
  "version": 1
}
```

Interpretation mutation modifies extracted parameters or confidence scores without modifying the underlying `EvidenceObject`.
