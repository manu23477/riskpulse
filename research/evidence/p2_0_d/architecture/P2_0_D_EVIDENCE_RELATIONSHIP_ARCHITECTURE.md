# P2.0-D EVIDENCE RELATIONSHIP ARCHITECTURE SPECIFICATION

**Document Identifier**: `P2_0_D_EVIDENCE_RELATIONSHIP_ARCHITECTURE`  
**Workstream**: First-Class Evidence Relationship Semantics Architecture  
**Date**: October 1, 2026  
**Status**: COMPLETED ARCHITECTURE  

---

## 1. RELATIONSHIP LAYER IN THE INTELLIGENCE PIPELINE

```
       EVIDENCE OBJECT / INTERPRETATION OBJECT
                          │
                          ▼
            EVIDENCE RELATIONSHIP (P2.0-D)
     (Directional, Immutable, SUPPORTS / CONTRADICTS / RELATED_TO,
      Rationale, Evaluation Method, Provenance)
                          │
                          ▼
                EVENT HYPOTHESIS (P2.0-C)
            (Candidate Event Representation, Untouched
             by relationship creation)
```

---

## 2. KEY ARCHITECTURAL INVARIANTS

1. **First-Class Domain Object**: `EvidenceRelationship` is an independent, immutable domain object with its own versioning, lifecycle, and provenance. It is NOT a mutable flag on `EventHypothesis` or `EvidenceObject`.
2. **No Automatic Effect**: Registering `E1 CONTRADICTS EH1` records the relationship without decreasing `EH1` confidence or invalidating `EH1`. Evaluation belongs to Phase P2.1.
3. **Explicit Rationale & Provenance**: Captures `rationale`, `evaluatorType` (`HUMAN_REVIEW`, `RULE_ENGINE`, `MODEL`), and `evaluationMethod`.
