# P2.6 DYNAMIC RISK STATE ENGINE ARCHITECTURE SPECIFICATION

**Document Identifier**: `P2_6_DYNAMIC_RISK_STATE_ARCHITECTURE`  
**Workstream**: Versioned Dynamic Risk State Engine Architecture  
**Date**: October 1, 2026  
**Status**: COMPLETED ARCHITECTURE  

---

## 1. DYNAMIC RISK STATE LAYER IN THE INTELLIGENCE PIPELINE

```
                     EVENT HYPOTHESIS H1-v1
                                │
                                ▼
                     SPATIAL STATE S1-v1
         (Footprint Polygon 4.2 ha, CRS: EPSG:4326)
                                │
                                ▼
                 ADMINISTRATIVE STATE AS1-v1
         (Mandi District, Sadar Mandi Tehsil, Aut Village)
                                │
                                ▼
                  DYNAMIC RISK STATE R1-v1
    (Hazard: Moderate Landslide, Exposure: Significant,
     Vulnerability: Moderate, Impact: Unconfirmed;
     Confidence: 0.82, Status: ACTIVE, Trend: STABLE)
                                │
                                ▼
                  DYNAMIC RISK STATE R1-v2
    (Triggered upon SpatialState revision S1-v2, R1-v1 preserved)
```

---

## 2. KEY ARCHITECTURAL INVARIANTS

1. **State vs Score**: `DynamicRiskState` represents structured state conditions (`hazardCondition`, `exposureCondition`, `vulnerabilityCondition`, `impactCondition`) without forcing uncalibrated numerical risk scores.
2. **Immutable Versioning**: Updating risk state creates a new `DynamicRiskState` version (v2) with `previousRiskStateId = v1.riskStateId`, keeping v1 $100\%$ queryable.
3. **No Graph Propagation**: P2.6 establishes state records without triggering graph propagation algorithms, alert generation, or cross-event mutations.
