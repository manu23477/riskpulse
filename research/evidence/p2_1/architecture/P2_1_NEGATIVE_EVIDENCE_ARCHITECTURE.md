# P2.1 NEGATIVE EVIDENCE & CONTRADICTION EVALUATION ARCHITECTURE SPECIFICATION

**Document Identifier**: `P2_1_NEGATIVE_EVIDENCE_ARCHITECTURE`  
**Workstream**: Negative Evidence & Contradiction Evaluation Layer Architecture  
**Date**: October 1, 2026  
**Status**: COMPLETED ARCHITECTURE  

---

## 1. NEGATIVE EVIDENCE LAYER IN THE INTELLIGENCE PIPELINE

```
                     RAW OBSERVATION
                            │
                            ▼
                  EVIDENCE OBJECT (P2.0-A)
                            │
                            ▼
                  INTERPRETATION OBJECT (P2.0-B)
                            │
                            ▼
                   EVENT HYPOTHESIS (P2.0-C)
                            ▲
                            │ (CONTRADICTS relationship)
                  EVIDENCE RELATIONSHIP (P2.0-D)
                            │
                            ▼
            NEGATIVE EVIDENCE EVALUATION (P2.1)
   (Multi-dimensional relevance: Spatial / Temporal / Semantic,
    Contradiction Type & Target, Evaluation State: CONFLICTED)
                            │
                            ▼
            EVIDENCE EVALUATION RESULT (P2.1)
          (Immutable Snapshot, Target Hypothesis UNMUTATED)
```

---

## 2. KEY ARCHITECTURAL INVARIANTS

1. **Negative Evidence is NOT Deletion**: Contradictory evidence is preserved as positive analytical information without invalidating source evidence objects or deleting historical records.
2. **Absence is NOT Contradiction**: `EvidencePresence.absent` (no satellite image available) is NOT treated as negative evidence (`"no landslide"`).
3. **Target Hypothesis Immutability**: Evaluating contradiction produces an immutable `EvidenceEvaluationResult` with `evaluationState = EvaluationState.conflicted`, leaving `EventHypothesis` confidence and status 100% untouched. Hypothesis revision belongs to Phase P2.2.
