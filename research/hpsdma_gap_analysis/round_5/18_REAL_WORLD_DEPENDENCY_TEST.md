# HPSDMA GAP ANALYSIS — ROUND 5: REAL-WORLD DEPENDENCY CLOSURE TEST

**Document Identifier**: `HPSDMA_R5_18_REAL_WORLD_DEPENDENCY_TEST`  
**Workstream**: Real-Data Dependency Closure Execution Results  
**Date**: October 1, 2026  
**Status**: RESEARCH / EXPERIMENTAL VALIDATION ONLY  

---

## 1. REAL-DATA DEPENDENCY CLOSURE EXECUTION

Evaluated real-data dependency propagation on a 157-node graph built from `RW-01`, `RW-02`, and `RW-05`:
- **Mutation Input**: CWC Gauge Station `RW-02` reading mutated from $4.85\text{m}$ to $6.20\text{m}$.
- **Strategy A (Full Rebuild)**: Recomputed all 157 graph nodes.
- **Strategy C (Selective Dependency Closure)**: Recomputed only 4 downstream nodes (`ObservationState`, `SpatialState`, `Admin State Mandi`, `Risk State Mandi`).
- **Recomputation Reduction**: **`97.45%` Node Evaluation Reduction**.
- **Equivalence**: **`1.0000` (100% State Equivalence with Full Rebuild)**.
- **Cross-Region Isolation**: Kullu and Shimla branches remained **100% unpoisoned and unaffected**.
