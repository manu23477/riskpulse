# RISKPULSE RESEARCH WORKSTREAM — ROUND 6: DEPENDENCY GRAPH RESULTS

**Document Identifier**: `RISKPULSE_R6_10_DEPENDENCY_GRAPH_RESULTS`  
**Workstream**: 6-Layer Transitive DAG Closure & Selective Recomputation Results  
**Date**: October 1, 2026  
**Status**: EXPERIMENTAL DEPENDENCY GRAPH LOG  

---

## 1. 6-LAYER DEPENDENCY GRAPH RESULTS

Calculated selective dependency closure upon mutating Satellite Evidence $E_{11}$ on a 314-node scale graph:
- **Strategy A (Full Rebuild)**: Recomputed all 314 graph nodes.
- **Strategy C (Selective DAG Closure)**: Recomputed only 4 downstream nodes (`EventHypothesis H6`, `SpatialState V6`, `AdminState Mandi`, `RiskState V6`).
- **Recomputation Reduction**: **`98.73%` Node Evaluation Reduction** ($L28 = 0.9873$).
- **State Equivalence**: **`1.0000` (100% Full-Rebuild State Equivalence)** ($L11 = 1.0, L12 = 1.0$).
