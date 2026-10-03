# RISKPULSE P1.4 — ADMINISTRATIVE INTELLIGENCE SERVICE ARCHITECTURE

**Workstream Identifier**: `RISKPULSE_P1_4_SERVICE_ARCHITECTURE`  
**Phase**: P1.4 (Administrative Intelligence Service Integration)  
**Date**: October 1, 2026  
**Status**: COMPLETED SERVICE ARCHITECTURE  

---

## 1. CENTRALIZED SERVICE ARCHITECTURE

`AdministrativeIntelligenceService` is the single authoritative application-facing gateway for all administrative geography intelligence in RiskPulse:

```
                  CANONICAL ADMINISTRATIVE DATA
                    (hp_districts.geojson, P1.3-M Staged Datasets)
                                   │
                                   ▼
                       ADMINISTRATIVE REPOSITORY
                     (LocalAdministrativeRepository)
                                   │
                                   ▼
                   ADMINISTRATIVE INTELLIGENCE SERVICE
                  (AdministrativeIntelligenceService)
                                   │
                                   ▼
────────────────────────────────────────────────────────────────────────
│              │                   │                  │                │
GIS Maps    Event Graph        Exposure           Risk Engine       REST API
Thematic    OSINT / Hazards    Population / Assets Composite Risk   Endpoints
```

---

## 2. IMMUTABLE VALUE OBJECTS

- **`AdministrativeContext`**: Reusable immutable value object capturing State, District, Sub-Division, Tehsil, Sub-Tehsil, Village, Development Block, Gram Panchayat, dataset version, effective date, provenance, and status flags (`HISTORICAL_BOUNDARY_DATA_UNAVAILABLE`, `OUTSIDE_COVERAGE`).
- **`AdministrativeProfile`**: Extensible profile object bundling identity, centroid, area, parents, children, ancestors, dataset version, and future intelligence slots (population, infrastructure, hazard summary, risk score).

---

## 3. INTEGRATION CONTRACTS

- **Event Attribution**: `AdministrativeEventAttributionContract` attributes point/polygon events to administrative contexts.
- **Hazard Attribution**: `AdministrativeHazardAttributionContract` intersects hazard polygons (landslides, floods, fires) with administrative units.
- **Exposure Contract**: `AdministrativeExposureContract` queries infrastructure/population exposure within administrative boundaries.
