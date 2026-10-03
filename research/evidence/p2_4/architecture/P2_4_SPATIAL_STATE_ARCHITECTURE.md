# P2.4 SPATIAL STATE ENGINE ARCHITECTURE SPECIFICATION

**Document Identifier**: `P2_4_SPATIAL_STATE_ARCHITECTURE`  
**Workstream**: Versioned Spatial State Engine Architecture  
**Date**: October 1, 2026  
**Status**: COMPLETED ARCHITECTURE  

---

## 1. SPATIAL STATE LAYER IN THE INTELLIGENCE PIPELINE

```
                     RAW EVIDENCE (Location: "Near Aut Bridge")
                                │
                                ▼
                     INTERPRETATION OBJECT (Inferred Point: 31.72, 76.98)
                                │
                                ▼
                     EVENT HYPOTHESIS v1 (Candidate Event)
                                │
                                ▼
                     SPATIAL STATE S1-v1
         (Footprint Polygon 4.2 ha, CRS: EPSG:4326, Uncertainty ±250m)
                                │
                                ├────────────────────────────────────────┐
                                ▼                                        ▼
                     SPATIAL STATE S1-v2                   P1.5 ADMINISTRATIVE ATTRIBUTION
         (Revised Footprint 2.1 ha, S1-v1 preserved)        (District: Mandi, Tehsil: Sadar)
```

---

## 2. KEY ARCHITECTURAL INVARIANTS

1. **Option A Model**: `EventHypothesis` holds current spatial properties for runtime fast-path access, while `SpatialState` holds the immutable versioned spatial history (`spatialStateVersion`, `previousSpatialStateId`).
2. **Observed vs Inferred vs Derived**: Explicitly classifies `spatialBasis` (`observed`, `inferred`, `derived`, `modelOutput`, `administrativeReference`, `remoteSensing`).
3. **Explicit CRS**: Geometry defaults to `EPSG:4326` WGS84 without silent coordinate distortion.
