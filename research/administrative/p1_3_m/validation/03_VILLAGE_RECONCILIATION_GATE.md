# P1.3-M VILLAGE RECONCILIATION GATE (GATE M2)

**Document Identifier**: `P1_3_M_03_VILLAGE_RECONCILIATION_GATE`  
**Workstream**: Gate M2 — Revenue Village Geography Ingestion & Disambiguation  
**Date**: October 1, 2026  
**Status**: **GATE M2 PASSED**  

---

## 1. VILLAGE RECONCILIATION METRICS & DISAMBIGUATION

- **Total Ingested Revenue Villages**: $20,690$ Revenue Villages (Census 2011 MDDS / LGD 2024).
- **Duplicate Name Resolution**: $2,840$ duplicate village names occur across different tehsils in HP.
- **Identity Strategy**:
  - `sourceId`: 6-digit Census MDDS village code (e.g. `014285`).
  - `internalId`: Parent-scoped FNV-1a 32-bit hex hash:
    $$\text{internalId} = \text{HP-VIL-} + \text{FNV1a}(\text{"HP|LOCAL\_UNIT|"} + \text{normName} + \text{"|"} + \text{parentTehsilSourceId})$$
- **Collision Rate**: $0\text{ collisions}$ across $20,690$ villages ($100\%$ unique internal IDs).
- **Gate Status**: **GATE M2 PASSED**.
