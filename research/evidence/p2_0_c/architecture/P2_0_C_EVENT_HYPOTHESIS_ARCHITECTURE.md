# P2.0-C EVENT HYPOTHESIS ARCHITECTURE SPECIFICATION

**Document Identifier**: `P2_0_C_EVENT_HYPOTHESIS_ARCHITECTURE`  
**Workstream**: Event Hypothesis Layer Architecture  
**Date**: October 1, 2026  
**Status**: COMPLETED ARCHITECTURE  

---

## 1. EVENT HYPOTHESIS LAYER IN THE INTELLIGENCE PIPELINE

```
                     RAW OBSERVATION
                            │
                            ▼
                  IMMUTABLE EVIDENCE OBJECT (P2.0-A)
                            │
                            ▼
                  INTERPRETATION OBJECT (P2.0-B)
                            │
                            ▼
                   EVENT HYPOTHESIS (P2.0-C)
            (Candidate Event Representation, Versioned,
             Derived from interpretations, Immutable)
                            │
                            ├──────────────────────────────────────┐
                            ▼                                      ▼
             EVENT GRAPH / EVIDENCE FUSION (Future)   ADMINISTRATIVE ATTRIBUTION (P1.5)
```

---

## 2. KEY ARCHITECTURAL INVARIANTS

1. **Candidate Status**: Creating an `EventHypothesis` represents a candidate hypothesis and does NOT claim the disaster is confirmed real-world truth.
2. **Multi-Interpretation Fusion**: Fuses multiple `InterpretationObject` records, preserving all parent IDs and provenance lineage without deleting interpretations.
3. **Derived Administrative Context**: Reuses existing `EventAdministrativeAttributionService` and `AdministrativeIntelligenceService` for spatial administrative attribution.
