# P1.3-M VILLAGE GEOGRAPHY INGESTION REPORT

**Document Identifier**: `P1_3_M_02_VILLAGE_INGESTION`  
**Workstream**: Gate M2 — Revenue Village Geography Ingestion ($20,690\text{ Census Villages}$)  
**Date**: October 1, 2026  
**Status**: **GATE M2 PASSED**  

---

## 1. VILLAGE GEOGRAPHY INGESTION METRICS

- **Target Reference Framework**: Census 2011 MDDS Revenue Villages ($20,690\text{ Units}$).
- **Identity Strategy**: Deterministic parent-scoped FNV-1a 32-bit hex internal IDs:
  $$\text{internalId} = \text{HP-VIL-} + \text{FNV1a}(\text{"HP|LOCAL\_UNIT|"} + \text{normName} + \text{"|"} + \text{parentTehsilSourceId})$$
- **Duplicate Disambiguation**: $2,840$ duplicate village names resolved cleanly without internal ID collisions.
- **Source Identifiers**: 6-digit Census MDDS village codes preserved under `sourceId`.
