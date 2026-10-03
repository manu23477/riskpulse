# RISKPULSE P1.6 — HAZARD → ADMINISTRATIVE ATTRIBUTION ARCHITECTURE

**Workstream Identifier**: `P1_6_01_HAZARD_ATTRIBUTION_ARCHITECTURE`  
**Phase**: P1.6 (Hazard -> Administrative Attribution Integration)  
**Date**: October 1, 2026  
**Status**: COMPLETED ARCHITECTURE  

---

## 1. HAZARD PRODUCT INTEGRATION ARCHITECTURE

The P1.6 hazard attribution architecture connects 7 primary physical hazard product categories (Landslide, Flood, Cloudburst, GLOF, Earthquake, Avalanche, Forest Fire) to `AdministrativeIntelligenceService`:

```
                           HAZARD LAYER / PRODUCT
    (Landslide, Flood, Cloudburst, GLOF, Earthquake, Avalanche, Forest Fire)
                                     │
                                     ▼
                          HAZARD SPATIAL FOOTPRINT
                         (GeoJSON Polygon / MultiPolygon)
                                     │
                                     ▼
                    ADMINISTRATIVE INTELLIGENCE SERVICE
                     (AdministrativeIntelligenceService)
                                     │
                                     ▼
                  HAZARD ADMINISTRATIVE ATTRIBUTION SERVICE
                  (HazardAdministrativeAttributionService)
                                     │
                                     ▼
                   HAZARD ADMINISTRATIVE ATTRIBUTION
                   (HazardAdministrativeAttribution)
                                     │
                                     ▼
──────────────────────────────────────────────────────────────────────────
│                  │                  │               │                  │
Affected Districts Affected Tehsils   Affected        Affected Blocks    Exposure
(Mandi / Kullu)    (Sadar / Aut)      Villages (Aut)  (Mandi / Gohar)    Area (km2)
```

---

## 2. SUPPORTED HAZARD PRODUCT CATEGORIES

1. **Landslide Products**: Slope movement scarps, debris flow corridors, Kotropi 2017 anchor.
2. **Flood Products**: 2D inundation extents, river reach overflow polygons.
3. **Cloudburst Products**: Convective precipitation cell footprints ($> 100\text{ mm/hr}$).
4. **GLOF Products**: Glacial lake outburst flood inundation pathways.
5. **Earthquake Products**: Isoseismal ground motion intensity zones.
6. **Avalanche Products**: Snow chute runout polygons.
7. **Forest Fire Products**: Burned area severity polygons.
