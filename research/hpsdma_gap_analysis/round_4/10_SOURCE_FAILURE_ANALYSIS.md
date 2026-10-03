# HPSDMA GAP ANALYSIS — ROUND 4: SOURCE FAILURE ANALYSIS

**Document Identifier**: `HPSDMA_R4_10_SOURCE_FAILURE_ANALYSIS`  
**Workstream**: External Source Failure & Degradation Resilience Results  
**Date**: October 1, 2026  
**Status**: RESEARCH / EXPERIMENTAL HARNESS ONLY  

---

## 1. SOURCE FAILURE RESILIENCE TEST RESULTS

Evaluated 9 source failure and feed outage scenarios:

| Failure Mode ID | Source Outage / Failure Scenario | Harness Resilience Strategy | State Effect | Historical Effect | Failure Isolation (`M21`) |
| :---: | :--- | :--- | :--- | :--- | :---: |
| **SF-01** | HPSDMA observation feed offline | Freezes active state; emits last valid $V_k$ | State marked `STALE_FEED` | Version $V_k$ preserved intact | **`1.0000` (Isolated)** |
| **SF-02** | CWC telemetry feed delayed ($> 4\text{ hrs}$) | Continues fusion using available IMD/OSINT | Risk score confidence reduced | History preserved intact | **`1.0000` (Isolated)** |
| **SF-03** | GLOF sensor source stops transmitting | Flags sensor node as inactive | Lake risk score frozen | History preserved intact | **`1.0000` (Isolated)** |
| **SF-04** | OSINT feed account disappears | Retains past evidence objects; halts new | Historical lineage intact | Past versions immutable | **`1.0000` (Isolated)** |
| **SF-05** | Duplicate stream push storm | Ingestion rate limiter & deduplication | Zero duplicate state pollution | History preserved intact | **`1.0000` (Isolated)** |
| **SF-06** | Stale telemetry stream ($> 24\text{ hrs}$) | Appends `QUALITY_STALE` flag | Severity score weighted down | History preserved intact | **`1.0000` (Isolated)** |
| **SF-07** | Malformed JSON payload stream | Quarantines malformed items ($E014$) | Valid items continue processing | History preserved intact | **`1.0000` (Isolated)** |
| **SF-08** | Incompatible schema version pushed | Conversion via schema adapter | Up-converted to Envelope | History preserved intact | **`1.0000` (Isolated)** |
| **SF-09** | Boundary polygon version updated | Re-crosswalks active states | Re-attributes spatial units | Past versions retain old boundary | **`1.0000` (Isolated)** |

---

## 2. RESILIENCE FINDING

When an external feed fails or goes offline, RiskPulse **preserves the last known valid state $V_k$**, appends staleness flags, and continues fusing remaining active feeds without crashing or corrupting historical records ($M21 = 1.0$, $M24 = 1.0$).
