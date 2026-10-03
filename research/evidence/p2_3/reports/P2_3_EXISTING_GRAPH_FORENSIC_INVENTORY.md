# P2.3 EXISTING GRAPH ARCHITECTURE FORENSIC INVENTORY

**Document Identifier**: `P2_3_EXISTING_GRAPH_FORENSIC_INVENTORY`  
**Workstream**: Forensic Inventory of Existing RiskPulse Graph & Topology Structures  
**Date**: October 1, 2026  
**Status**: COMPLETED FORENSIC INVENTORY  

---

## 1. INVENTORY OF EXISTING GRAPH & RELATIONSHIP STRUCTURES

| Structure / Model Name | File Location | Key Fields | Semantic Category | Reusability / Action |
| :--- | :--- | :--- | :--- | :--- |
| **`EvidenceRelationship`** | `lib/domain/evidence/evidence_relationship.dart` | `sourceId`, `targetId`, `relationshipType` | Semantic Relationship Object | **`KEEP`** & Reference |
| **`DependencyEdge`** | `lib/domain/evidence/dependency_edge.dart` | `dependencyId`, `dependentHypothesisId`, `dependsOnHypothesisId` | Knowledge Dependency Edge Model | **`NEW`** P2.3 Core Object |
| **`GraphNode`** | `lib/domain/evidence/graph_node.dart` | `nodeId`, `nodeType`, `objectId`, `version` | Immutable Topology Node | **`NEW`** P2.3 Core Object |
| **`GraphEdge`** | `lib/domain/evidence/graph_edge.dart` | `edgeId`, `sourceNodeId`, `targetNodeId`, `edgeCategory` | Immutable Topology Edge | **`NEW`** P2.3 Core Object |
| **`EvidenceDecisionChainContract`** | `lib/domain/gis/evidence_decision_chain_contract.dart` | `chainId`, `inputEvidenceIds`, `evidenceStatus` | Governance Chain Contract | **`KEEP`** & Reference |

---

## 2. GAPS & P2.3 IMPLEMENTATION BOUNDARY

1. **Topology Only**: P2.3 implements node and edge topology registration and direct dependency queries (`getDirectDependencies()`, `getDirectDependents()`).
2. **NO Propagation**: Recursive transitive closure execution, Dynamic Risk State mutation, and cross-event state propagation are strictly excluded from P2.3.
3. **Event Isolation**: Event-local topology (`Evidence -> Interpretation -> Hypothesis`) remains cleanly isolated from cross-event dependencies (`H1 -> dependsOn -> H2`).
