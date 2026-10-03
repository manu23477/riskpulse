# CONSOLIDATED INVENTION BOUNDARY REVIEW — ROUND 1: CROSS-WINDOW COMPONENT MAP

**Document Identifier**: `CONSOLIDATED_R1_02_CROSS_WINDOW_COMPONENT_MAP`  
**Workstream**: Cross-Window Component Classification Matrix  
**Date**: October 1, 2026  
**Status**: RESEARCH SYNTHESIS ONLY  

---

## 1. CONSOLIDATED CROSS-WINDOW COMPONENT CLASSIFICATION MATRIX

Legend:
- **`KNOWN_DISCLOSED`**: Disclosed in single prior-art references.
- **`COMBINATION_DEPENDENT`**: Disclosed in multi-reference combination mosaics.
- **`TECHNICALLY_COUPLED`**: Core coupled mechanism distinguishing RiskPulse.
- **`INTEGRATION_CONTEXT`**: Government/external deployment interface requirement.
- **`SUPPORTING`**: Necessary pipeline infrastructure.
- **`OUTSIDE_CORE`**: Generic or non-essential capability.

| Component Description | PW1 ID | PW2 ID | Lifecycle ID | HPSDMA ID | Consolidated Classification |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **Observation / Telemetry Ingestion** | C01 | C01 (K01) | Obs Ingestion | Ingestion API | **`KNOWN_DISCLOSED`** |
| **Semantic Hazard Extraction** | C02 | - | Interpretation | Observation Env | **`KNOWN_DISCLOSED`** |
| **Event Hypothesis Clustering** | C03 | - | Event Hypothesis| Event Clustering | **`KNOWN_DISCLOSED`** |
| **Derived Spatial Event Closure** | C04 | C02 (K02) | Spatial State | GeoJSON Polygon | **`KNOWN_DISCLOSED`** |
| **Administrative Unit Crosswalk**| C05 | C03 (K03) | Admin State | Tehsil Crosswalk | **`KNOWN_DISCLOSED`** |
| **Composite Risk Score Evaluation**| C06 | C04 (K04) | Risk State | Risk Assessment | **`KNOWN_DISCLOSED`** |
| **Selective DAG Recomputation** | C07 | C07 (K07) | DAG Closure | Selective Recomp | **`KNOWN_DISCLOSED` / `OUTSIDE_CORE`** (*Efficiency-Only*) |
| **Shared Admin Node Recalculation**| C08 | C08 (K08) | Shared Admin | Shared Admin | **`COMBINATION_DEPENDENT`** |
| **Shared Risk Node Recalculation** | C09 | C09 (K09) | Shared Risk | Shared Risk | **`COMBINATION_DEPENDENT`** |
| **Cross-Event Branch Isolation** | C10 | C05 (K05) | Isolation | Isolation | **`COMBINATION_DEPENDENT`** |
| **Dynamic Topology Edge Shift** | - | C10 (K10) | Topology Shift | - | **`COMBINATION_DEPENDENT`** |
| **Bitemporal Historical Versioning**| - | C06 (K06) | History V1..V7 | State Version | **`COMBINATION_DEPENDENT`** |
| **Non-Deletion Conflict Lineage** | - | - | Contradiction | Failure Handling | **`SUPPORTING`** |
| **HPSDMA REST Middleware API V2** | - | - | Interoperability | Output Contract | **`INTEGRATION_CONTEXT`** |
| **Transitive 6-Layer DAG Closure** | Core | Core | Core | Core | **`TECHNICALLY_COUPLED`** |
