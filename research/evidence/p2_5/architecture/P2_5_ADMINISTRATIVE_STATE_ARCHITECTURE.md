# P2.5 ADMINISTRATIVE STATE INTEGRATION ARCHITECTURE SPECIFICATION

**Document Identifier**: `P2_5_ADMINISTRATIVE_STATE_ARCHITECTURE`  
**Workstream**: Versioned Administrative State Integration Architecture  
**Date**: October 1, 2026  
**Status**: COMPLETED ARCHITECTURE  

---

## 1. ADMINISTRATIVE STATE LAYER IN THE INTELLIGENCE PIPELINE

```
                     SPATIAL STATE S1-v1 (P2.4)
             (Point Lat/Lon or Polygon Footprint Extent)
                                │
                                ▼
             P1.4 / P1.5 ADMINISTRATIVE INTELLIGENCE ENGINE
          (identifyPoint / intersectGeometry / identifyGeometry)
                                │
                                ▼
                     ADMINISTRATIVE STATE AS1-v1 (P2.5)
         (UnitRecords: District Mandi, Tehsil Sadar, Village Aut;
          Parallel Dev: Block Mandi, GP Aut; Versioned, Immutable)
                                │
                                ├────────────────────────────────────────┐
                                ▼                                        ▼
                   ADMINISTRATIVE STATE AS1-v2               DYNAMIC RISK STATE (Future)
         (Updated upon SpatialState revision, AS1-v1 preserved)
```

---

## 2. KEY ARCHITECTURAL INVARIANTS

1. **Reuse P1.x Architecture**: P2.5 does NOT create a second administrative GIS engine. All spatial intersection and hierarchy lookups are delegated to P1.4 `AdministrativeIntelligenceService`.
2. **Parallel Hierarchy Invariant**: Preserves Revenue and Development chains as separate parallel branches (`hierarchyType: 'revenue'` vs `'development'`).
3. **Historical Boundary Warnings**: If historical boundary datasets are missing for historical event timestamps, records explicit warning `HISTORICAL_BOUNDARY_DATA_UNAVAILABLE`.
