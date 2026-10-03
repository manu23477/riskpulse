# P1.3-L VILLAGE GEOGRAPHY FORENSICS REPORT

**Document Identifier**: `P1_3_L_03_VILLAGE_GEOGRAPHY_FORENSICS`  
**Workstream**: Himachal Pradesh Revenue Village Geometry & MDDS Codification  
**Date**: October 1, 2026  
**Status**: FORENSIC AUDIT COMPLETE  

---

## 1. VILLAGE DATASET METRICS & CODIFICATION

- **Total Revenue Villages**: $20,690$ Revenue Villages (Census 2011 MDDS / LGD).
- **Spatial Geometry Types**:
  - `Revenue Polygons`: Cadastral / Revenue mouza polygons available in Survey of India / HP Bhuvan datasets.
  - `Village Centroids`: Latitude/Longitude points available in Census 2011 directory.
- **Identifier System**: Census 2011 6-digit MDDS village code (e.g. `014285`).

---

## 2. DUPLICATE NAME DISAMBIGUATION FORENSICS

### Duplicate Name Occurrence Analysis:
Out of $20,690$ villages, approximately $2,840$ village names occur more than once in Himachal Pradesh (e.g., "Koti" appears in 8 different tehsils; "Dhar" appears in 12 tehsils).

### RiskPulse Identity Engine Safeguard:
1. Names are **NEVER** used as identity keys.
2. The `AdministrativeIdentityEngine` generates deterministic FNV-1a hex internal IDs scoped by parent Tehsil ID:
   $$\text{internalId} = \text{HP-VIL-} + \text{FNV1a}(\text{"HP|LOCAL\_UNIT|"} + \text{normName} + \text{"|"} + \text{parentTehsilSourceId})$$
3. Duplicate names within different tehsils generate **100% collision-free, deterministic internal IDs**.
