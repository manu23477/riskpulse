# HPSDMA GAP ANALYSIS — ROUND 3: RISKPULSE INSERTION POINTS EVALUATION

**Document Identifier**: `HPSDMA_R3_04_RISKPULSE_INSERTION_POINTS`  
**Workstream**: Architectural Insertion Point Evaluation (Options A through F)  
**Date**: September 30, 2026  
**Status**: RESEARCH ONLY — NO PRODUCTION CODE CHANGES  

---

## 1. INTEGRATION ARCHITECTURE OPTIONS (A THROUGH F)

Six candidate architectural insertion points were evaluated to determine where RiskPulse should sit relative to the HPSDMA ecosystem:

```
[OPTION A] External Sources → RiskPulse → HPSDMA Ingestion → IMS → GIS-DSS
[OPTION B] External Sources → HPSDMA Ingestion → RiskPulse → IMS → GIS-DSS
[OPTION C] External Sources → HPSDMA Ingestion → IMS → RiskPulse → GIS-DSS
[OPTION D] External Sources → HPSDMA Ingestion → IMS/GIS-DSS ↔ RiskPulse (Parallel Intelligence Service)
[OPTION E] External Sources → HPSDMA Ingestion → IMS → GIS-DSS → RiskPulse (Downstream Overlay)
[OPTION F] External Sources → RiskPulse Intelligence API ← HPSDMA (Independent Cloud Middleware)
```

---

## 2. DETAILED COMPARATIVE EVALUATION MATRIX

| Trade-Off Criterion | Option A (Pre-Ingestion) | Option B (Ingest-IMS) | Option C (IMS-GIS) | Option D (Parallel) | Option E (Downstream) | Option F (Independent API) |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| **Required Inputs** | Raw feeds | Ingested feeds | IMS records | IMS / API feeds | Rendered GIS | Standard JSON/GeoJSON |
| **Required Outputs** | Cleaned feeds | Pre-IMS states | Enriched states | Risk states | Map overlays | Enriched State Objects |
| **Integration Complexity**| **HIGH** | **HIGH** | **MEDIUM** | **LOW** | **LOW** | **LOW (Cleanest)** |
| **Duplication Risk** | High | High | Medium | Low | High | **NONE** |
| **HPSDMA Internal Dep.** | High | High | High | Medium | High | **MINIMAL** |
| **Technical Feasibility**| Low | Medium | Medium | High | High | **VERY HIGH** |
| **Data Ownership** | Complex | HPSDMA | HPSDMA | Shared | HPSDMA | **HPSDMA Retains All** |
| **Scalability** | Medium | Medium | Medium | High | Low | **VERY HIGH** |
| **Value to HPSDMA** | Low | Medium | High | High | Low | **MAXIMUM** |
| **RiskPulse Differentiation**| Low | Medium | High | High | Low | **MAXIMUM** |
| **Patent Relevance** | Low | Medium | High | High | Low | **DIRECT (PW1/PW2)** |

---

## 3. ARCHITECTURAL EVALUATION FINDINGS

- **Option A & B (Pre-Ingestion & Early Ingest)**: High integration complexity; forces RiskPulse to manage raw government network connections and hardware adapters, duplicating HPSDMA's IMS ingestion role.
- **Option C & E (IMS-GIS & Downstream Overlay)**: Tight coupling to internal HPSDMA database schemas; high risk of breaking when internal HPSDMA databases update.
- **Option D & F (Parallel Service & External API Middleware)**: **Optimal Architectural Fit**. RiskPulse operates as a decoupled, stateless intelligence middleware layer consuming HPSDMA / government feeds and emitting enriched evidence-aware, spatially resolved, administrative risk state objects via clean REST APIs.
