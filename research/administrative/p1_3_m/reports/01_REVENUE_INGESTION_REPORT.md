# P1.3-M REVENUE HIERARCHY INGESTION REPORT

**Document Identifier**: `P1_3_M_01_REVENUE_INGESTION`  
**Workstream**: Gate M1 — Revenue Geography Ingestion (12 Districts + 172 Sub-Districts)  
**Date**: October 1, 2026  
**Status**: **GATE M1 PASSED**  

---

## 1. REVENUE HIERARCHY INGESTION METRICS

- **State Level**: Himachal Pradesh (`HP-STATE`).
- **District Level**: 12 Districts (`HP-01` through `HP-12`) ingested from `hp_districts.geojson`.
- **Sub-District Level**: 172 Sub-Districts (118 Tehsils + 54 Sub-Tehsils) staged under `src-soi-lgd-hp-tehsils-2024`.
- **Feature Count Reconciliation**: 172 staged features matched LGD 2024.2 database with $100\%$ precision.
- **Hierarchy Invariants**: Every Tehsil/Sub-Tehsil links deterministically to its parent District via `parentId`.
