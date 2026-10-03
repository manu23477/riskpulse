# PATENT CONSOLIDATION — ROUND 3: ADMINISTRATIVE CROSSWALK MODEL

**Document Identifier**: `CONSOLIDATED_R3_09_ADMINISTRATIVE_CROSSWALK_MODEL`  
**Workstream**: Proportional Administrative Unit Crosswalk & Boundary Versioning  
**Date**: October 1, 2026  
**Status**: RESEARCH TECHNICAL SPECIFICATION  

---

## 1. ADMINISTRATIVE CROSSWALK CONCEPTUAL SCHEMA

```json
{
  "crosswalk_id": "CROSS-HP-2026-0042",
  "spatial_state_id": "SPAT-HP-2026-0042",
  "boundary_version": "HP_REVENUE_2026_V2",
  "attributed_units": [
    {"unit_code": "HP-MND-SAD", "unit_name": "Sadar Mandi Tehsil", "attribution_ratio": 0.65},
    {"unit_code": "HP-MND-BAL", "unit_name": "Bali Chowki Tehsil", "attribution_ratio": 0.35}
  ]
}
```

Supports multi-district proportional attributions and historical boundary dataset versioning (Boundary V1 vs Boundary V2).
