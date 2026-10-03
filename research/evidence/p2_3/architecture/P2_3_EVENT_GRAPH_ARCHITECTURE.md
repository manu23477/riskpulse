# P2.3 EVENT GRAPH & KNOWLEDGE DEPENDENCY TOPOLOGY ARCHITECTURE SPECIFICATION

**Document Identifier**: `P2_3_EVENT_GRAPH_ARCHITECTURE`  
**Workstream**: Immutable Event Graph & Knowledge Dependency Topology Architecture  
**Date**: October 1, 2026  
**Status**: COMPLETED ARCHITECTURE  

---

## 1. EVENT GRAPH IN THE INTELLIGENCE PIPELINE

```
                     EVIDENCE OBJECT (NODE:EvidenceObject:E1)
                                │
                                ▼ (semantic / INTERPRETED_AS)
                  INTERPRETATION OBJECT (NODE:InterpretationObject:I1)
                                │
                                ▼ (semantic / SUPPORTS / CONTRADICTS)
                     EVENT HYPOTHESIS v1 (NODE:EventHypothesis:H1:v1)
                                │
                                ▼ (lineage / SUPERSEDES)
                     EVENT HYPOTHESIS v2 (NODE:EventHypothesis:H1:v2)
                                │
                                ▼ (dependency / DEPENDS_ON)
                     EVENT HYPOTHESIS H2 (NODE:EventHypothesis:H2)
```

---

## 2. KEY ARCHITECTURAL INVARIANTS

1. **Topology Declaration vs Propagation**: Registering `H1 DEPENDS_ON H2` declares knowledge topology. It does NOT automatically mutate `H1` state when `H2` changes.
2. **Stable Node Identity**: Node IDs use deterministic FQNs (`NODE:objectType:objectId:vVersion`).
3. **No Transitive Closure Execution**: `getDirectDependencies()` and `getDirectDependents()` return 1-hop direct neighbors without executing transitive propagation algorithms.
