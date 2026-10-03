# HPSDMA GAP ANALYSIS — ROUND 4: DEPENDENCY CLOSURE RESULTS

**Document Identifier**: `HPSDMA_R4_14_DEPENDENCY_CLOSURE_RESULTS`  
**Workstream**: 6-Layer Transitive DAG Closure & Recomputation Reduction  
**Date**: October 1, 2026  
**Status**: RESEARCH / EXPERIMENTAL HARNESS ONLY  

---

## 1. DEPENDENCY CLOSURE CALCULATION

The harness calculates transitive downstream closures across a 6-layer directed graph:
$$\text{Evidence} \rightarrow \text{Interpretation} \rightarrow \text{EventHypothesis} \rightarrow \text{SpatialState} \rightarrow \text{AdministrativeState} \rightarrow \text{RiskState}$$

---

## 2. SELECTIVE DEPENDENCY VS FULL REBUILD COMPARISON

Evaluated across scale graphs with 10 to 1000 observations:

| Graph Scale | Total Graph Nodes | Full Rebuild Node Evaluations | Selective Dependency Evaluations | Recomputation Reduction (`M25`) | Closure Precision (`M13`) | Closure Recall (`M14`) | False Propagation (`M15`) | Missed Propagation (`M16`) |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **10** | 32 | 32 | 4 | **87.50%** | **`1.0000`** | **`1.0000`** | **`0`** | **`0`** |
| **50** | 157 | 157 | 4 | **97.45%** | **`1.0000`** | **`1.0000`** | **`0`** | **`0`** |
| **100** | 314 | 314 | 4 | **98.73%** | **`1.0000`** | **`1.0000`** | **`0`** | **`0`** |
| **500** | 1,570 | 1,570 | 4 | **99.75%** | **`1.0000`** | **`1.0000`** | **`0`** | **`0`** |
| **1000** | 3,140 | 3,140 | 4 | **99.87%** | **`1.0000`** | **`1.0000`** | **`0`** | **`0`** |

---

## 3. CLOSURE FINDING

Selective dependency closure evaluates only the exact downstream nodes affected by an observation mutation, achieving an **87.50% to 99.87% evaluation reduction** over full rebuilds while maintaining **100% full-rebuild state equivalence**.
