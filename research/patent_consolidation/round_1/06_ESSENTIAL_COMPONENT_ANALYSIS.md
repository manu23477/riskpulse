# CONSOLIDATED INVENTION BOUNDARY REVIEW — ROUND 1: ESSENTIAL COMPONENT ANALYSIS

**Document Identifier**: `CONSOLIDATED_R1_06_ESSENTIAL_COMPONENT_ANALYSIS`  
**Workstream**: Essential vs Non-Essential Component Forensic Analysis  
**Date**: October 1, 2026  
**Status**: RESEARCH SYNTHESIS ONLY  

---

## 1. ESSENTIAL COMPONENT FORENSIC ANALYSIS

Based on ablation experiments in PW1C-6, PW2R6, and Round 6:

| Component ID | Component Name | Ablation Effect when Removed | Essentiality Status |
| :---: | :--- | :--- | :---: |
| **`C01` / `K01`** | Observation Mutation Ingestion | Pipeline lacks trigger; state remains static | **`ESSENTIAL`** |
| **`C02` / `K02`** | Spatial Event Closure | Spatial crosswalk fails; no bounding geometry | **`ESSENTIAL`** |
| **`C03` / `K03`** | Administrative Crosswalk | District/Tehsil attribution fails; risk unallocated | **`ESSENTIAL`** |
| **`C04` / `K04`** | Risk State Score Evaluation | No composite risk output emitted | **`ESSENTIAL`** |
| **`C05` / `K05`** | Cross-Event Branch Isolation | Unrelated events contaminated (False propagation $> 0$) | **`ESSENTIAL`** |
| **`C06` / `K06`** | Bitemporal Historical Versioning| Past states overwritten; historical auditability lost | **`ESSENTIAL`** |
| **`C07` / `K07`** | Selective Recomputation | Recomputation runs slower (Full rebuild); output **100% identical** | **`NON-ESSENTIAL`** (*Efficiency-Only*) |
| **`C08` / `K08`** | Shared Admin Node Recalculation | Multi-event district risk totals inaccurate | **`ESSENTIAL`** |
| **`C09` / `K09`** | Shared Risk Node Recalculation | Downstream risk propagation incomplete | **`ESSENTIAL`** |
| **`C10` / `K10`** | Dynamic Topology Edge Shift | Broken infrastructure rerouting fails | **`ESSENTIAL`** |
