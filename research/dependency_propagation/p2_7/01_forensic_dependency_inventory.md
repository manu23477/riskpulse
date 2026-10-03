# P2.7 FORENSIC DEPENDENCY INVENTORY

**Document Identifier**: `P2_7_FORENSIC_DEPENDENCY_INVENTORY`  
**Workstream**: Forensic Inventory of Existing RiskPulse Graph, Dependency & Topology Structures  
**Date**: October 1, 2026  
**Status**: COMPLETED FORENSIC INVENTORY  

---

## 1. INVENTORY OF EXISTING DEPENDENCY & TOPOLOGY STRUCTURES

| Structure / Model Name | File Location | Key Fields | Semantic Category | Reusability / Action |
| :--- | :--- | :--- | :--- | :--- |
| **`EventGraphService`** | `lib/data/services/evidence/event_graph_service.dart` | `getDirectDependencies()`, `getDirectDependents()`, `validateGraphIntegrity()` | P2.3 Graph Topology Gateway | **`KEEP & REUSE`** 100% |
| **`DependencyEdge`** | `lib/domain/evidence/dependency_edge.dart` | `dependentHypothesisId`, `dependsOnHypothesisId`, `dependencyType` | P2.3 Knowledge Dependency Edge | **`KEEP`** & Edge input |
| **`SpatialStateService`** | `lib/data/services/spatial/spatial_state_service.dart` | `createNextVersion()`, `compareSpatialStates()` | P2.4 Spatial State Gateway | **`KEEP`** & Propagation execution target |
| **`AdministrativeStateService`**| `lib/data/services/administrative/administrative_state_service.dart` | `createNextVersion()`, `compareAdministrativeStates()` | P2.5 Admin State Gateway | **`KEEP`** & Propagation execution target |
| **`DynamicRiskStateService`** | `lib/data/services/evidence/dynamic_risk_state_service.dart` | `createNextVersion()`, `compareRiskStates()` | P2.6 Risk State Gateway | **`KEEP`** & Propagation execution target |
| **`PropagationService`** | `lib/data/services/evidence/propagation_service.dart` | `createTrigger()`, `analyzeImpact()`, `buildPropagationPlan()`, `executePropagation()` | Selective Propagation Engine | **`NEW`** P2.7 Core Service |

---

## 2. GAPS & P2.7 IMPLEMENTATION BOUNDARY

1. **Selective Propagation Engine**: `PropagationService` (`lib/data/services/evidence/propagation_service.dart`) analyzes trigger impact, builds topologically ordered plans, and recomputes ONLY affected derived states.
2. **Event & Version Isolation**: Event A changes $\rightarrow$ Risk B remains 100% untouched. Version v1 remains 100% queryable when v2 is derived.
3. **Equivalence Guarantee**: Selective propagation result == Full rebuild result for all affected outputs.
