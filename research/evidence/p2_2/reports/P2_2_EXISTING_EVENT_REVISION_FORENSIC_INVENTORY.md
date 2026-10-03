# P2.2 EXISTING EVENT HYPOTHESIS REVISION FORENSIC INVENTORY

**Document Identifier**: `P2_2_EXISTING_EVENT_REVISION_FORENSIC_INVENTORY`  
**Workstream**: Forensic Inventory of Existing Event Hypothesis & Versioning Structures  
**Date**: October 1, 2026  
**Status**: COMPLETED FORENSIC INVENTORY  

---

## 1. INVENTORY OF EXISTING REVISION & VERSIONING STRUCTURES

| Structure / Model Name | File Location | Key Fields | Semantic Category | Reusability / Action |
| :--- | :--- | :--- | :--- | :--- |
| **`EventHypothesis`** | `lib/domain/evidence/event_hypothesis.dart` | `hypothesisId`, `hypothesisVersion`, `supersedesHypothesisId`, `parentHypothesisIds` | Primary Candidate Event Model | **`KEEP`** & Revise via Versioning |
| **`EvidenceEvaluationResult`** | `lib/domain/evidence/evidence_evaluation_result.dart` | `evaluationId`, `evaluationState`, `contradictionSummary` | P2.1 Evaluation Input Snapshot | **`KEEP`** & Input source |
| **`RevisionAssessment`** | `lib/domain/evidence/revision_assessment.dart` | `assessmentId`, `eventHypothesisId`, `revisionCategory`, `affectedFields` | Pre-Decision Assessment Model | **`NEW`** P2.2 Core Object |
| **`RevisionDecision`** | `lib/domain/evidence/revision_decision.dart` | `decisionId`, `sourceVersion`, `targetVersion`, `changedFields` | Controlled Revision Decision Model | **`NEW`** P2.2 Core Object |

---

## 2. GAPS & P2.2 IMPLEMENTATION BOUNDARY

1. **Non-Destructive Versioning**: Revision creates `EventHypothesis` v2 with `hypothesisVersion: 2`, keeping v1 $100\%$ intact and queryable.
2. **Field-Level Revision**: Evaluates specific affected dimensions (`spatialRevision`, `temporalRevision`, `semanticRevision`, `severityRevision`) without applying arbitrary numerical confidence penalties.
3. **P1.5 Administrative Re-Attribution Bridge**: New spatial revisions receive updated `administrativeContextReference` via P1.5 without mutating prior administrative context.
