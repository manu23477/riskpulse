# P2.2 EVENT HYPOTHESIS REVISION ARCHITECTURE SPECIFICATION

**Document Identifier**: `P2_2_EVENT_HYPOTHESIS_REVISION_ARCHITECTURE`  
**Workstream**: Immutable Event Hypothesis Revision Engine Architecture  
**Date**: October 1, 2026  
**Status**: COMPLETED ARCHITECTURE  

---

## 1. REVISION ENGINE IN THE INTELLIGENCE PIPELINE

```
                     EVENT HYPOTHESIS v1 (P2.0-C)
                            │
                            ▼
              EVIDENCE EVALUATION RESULT (P2.1)
                (EvaluationState: CONFLICTED)
                            │
                            ▼
                REVISION ASSESSMENT (P2.2)
         (Categorizes impact: Spatial / Temporal / Semantic)
                            │
                            ▼
                 REVISION DECISION (P2.2)
         (Target version increment: v1 -> v2, Changed vs Unchanged)
                            │
                            ▼
                     EVENT HYPOTHESIS v2
    (NEW Immutable Instance, supersedesHypothesisId: H1-v1,
     v1 preserved 100% intact, lineage tracked)
```

---

## 2. KEY ARCHITECTURAL INVARIANTS

1. **Original Hypothesis Immutability**: Revision NEVER mutates or overwrites `EventHypothesis` v1.
2. **Field-Level Revision**: Modifies only affected properties (e.g. extent polygon) while leaving unaffected fields (e.g. event type, start time) 100% identical.
3. **No Arbitrary Confidence Penalty**: Contradiction triggers field-specific revision rather than applying arbitrary numerical confidence reductions (`confidence = confidence - X`).
