# P2.8 FORENSIC CASCADE & COMPOUND INTELLIGENCE INVENTORY

**Document Identifier**: `P2_8_FORENSIC_CASCADE_INVENTORY`  
**Workstream**: Forensic Inventory of Existing RiskPulse Hazard Interaction, Cascade & Compound Structures  
**Date**: October 1, 2026  
**Status**: COMPLETED FORENSIC INVENTORY  

---

## 1. INVENTORY OF EXISTING CASCADE & COMPOUND STRUCTURES

| Structure / Model Name | File Location | Key Fields | Semantic Category | Reusability / Action |
| :--- | :--- | :--- | :--- | :--- |
| **`EventGraphService`** | `lib/data/services/evidence/event_graph_service.dart` | `registerNode()`, `registerRelationshipEdge()`, `getEventNeighborhood()` | P2.3 Graph Topology Gateway | **`KEEP & REUSE`** 100% |
| **`PropagationService`** | `lib/data/services/evidence/propagation_service.dart` | `createTrigger()`, `executePropagation()` | P2.7 Propagation Execution Gateway | **`KEEP & REUSE`** 100% |
| **`CascadeRelationship`** | `lib/domain/evidence/cascade_relationship.dart` | `cascadeRelationshipId`, `primaryEventId`, `secondaryEventId`, `relationshipType` | Evidence-Linked Cascade Edge | **`NEW`** P2.8 Core Object |
| **`CompoundEventCondition`** | `lib/domain/evidence/compound_event_condition.dart` | `compoundEventId`, `rootEventIds`, `hazardCategories`, `combinedSeverity` | Multi-Hazard Compound Event Model | **`NEW`** P2.8 Core Object |
| **`CascadeService`** | `lib/data/services/evidence/cascade_service.dart` | `registerCascadeRelationship()`, `analyzeCascadeChain()`, `triggerCascadePropagation()` | Cascade & Compound Intelligence Gateway | **`NEW`** P2.8 Core Service |

---

## 2. GAPS & P2.8 IMPLEMENTATION BOUNDARY

1. **Causality vs Association**: Strictly distinguishes causal relationships (`triggers`, `amplifies`, `resultsIn`) from spatial/temporal proximity associations (`spatiallyInteracts`, `temporallyPrecedes`).
2. **Reuse P2.3 Graph & P2.7 Propagation**: Reuses P2.3 graph topology for chain analysis and P2.7 selective propagation for derived state execution. NO second graph engine or second propagation engine created.
3. **Multi-Depth Chain Analysis**: Categorizes nodes across 5 cascade depths (`rootHazard`, `secondaryEvent`, `infrastructureConsequence`, `serviceDisruption`, `populationConsequence`).
