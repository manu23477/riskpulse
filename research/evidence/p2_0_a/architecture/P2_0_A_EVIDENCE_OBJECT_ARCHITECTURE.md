# P2.0-A EVIDENCE OBJECT ARCHITECTURE SPECIFICATION

**Document Identifier**: `P2_0_A_EVIDENCE_OBJECT_ARCHITECTURE`  
**Workstream**: Normalized Evidence Object Layer Architecture  
**Date**: October 1, 2026  
**Status**: COMPLETED ARCHITECTURE  

---

## 1. EVIDENCE OBJECT LAYER IN THE INTELLIGENCE PIPELINE

```
RAW OBSERVATION (Social Media, Sensor Telemetry, Satellite Scene, Field Call)
                    │
                    ▼
          IMMUTABLE EVIDENCE OBJECT (EvidenceObject)
      (contentHash SHA-256, dual timestamps, structured provenance)
                    │
                    ├──────────────────────────────────────┐
                    ▼                                      ▼
         INTERPRETATION OBJECT (Future)       ADMINISTRATIVE CONTEXT (P1.4)
         (Semantic Hazard Parameters)         (Revenue & Development Parallel)
                    │                                      │
                    └──────────────────┬───────────────────┘
                                       ▼
                           EVENT HYPOTHESIS (Future)
```

---

## 2. KEY ARCHITECTURAL INVARIANTS

1. **Observation vs Evidence vs Interpretation**:
   - **Raw Observation**: Un-normalized stream or file payload.
   - **Evidence Object**: Normalized, immutable representation with cryptographic hash (`contentHash`) and structured provenance. Evidence does NOT assert that a disaster occurred unless the source observation explicitly states it.
   - **Interpretation**: Derived semantic meaning or geocoded inference.
2. **Immutability & Non-Deletion Retraction**: Evidence Objects are strictly immutable. Corrections create a new version with `supersedesEvidenceId`; retractions update `status = EvidenceStatus.retracted` without deleting the original record.
3. **Model Output Distinction**: Model-generated outputs are marked `isModelOutput = true` with `modelName` and `modelVersion` to prevent conflating simulation outputs with ground-truth direct observations.
