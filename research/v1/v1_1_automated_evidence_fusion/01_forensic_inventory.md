# V1.1 FORENSIC EVIDENCE FUSION INVENTORY

**Document Identifier**: `V1_1_FORENSIC_FUSION_INVENTORY`  
**Workstream**: Forensic Inventory of Existing RiskPulse Evidence, Fusion & Revision Structures  
**Date**: October 1, 2026  
**Status**: COMPLETED FORENSIC INVENTORY  

---

## 1. INVENTORY OF EXISTING EVIDENCE & REVISION STRUCTURES

| Structure / Model Name | File Location | Key Fields | Semantic Category | Reusability / Action |
| :--- | :--- | :--- | :--- | :--- |
| **`EvidenceObject`** | `lib/domain/evidence/evidence_object.dart` | `evidenceId`, `source`, `sourcePublisher`, `contentHash` | Factual Observation | **`KEEP & REUSE`** 100% |
| **`EventHypothesis`** | `lib/domain/evidence/event_hypothesis.dart` | `hypothesisId`, `hypothesisVersion`, `confidence` | Candidate Event Identity | **`KEEP & REUSE`** 100% |
| **`NegativeEvidence`** | `lib/domain/evidence/negative_evidence.dart` | `negativeEvidenceId`, `contradictionType`, `strength` | Contradiction Assessment | **`KEEP & REUSE`** 100% |
| **`EventGraphService`** | `lib/data/services/evidence/event_graph_service.dart` | `registerRelationshipEdge()`, `getDirectDependents()` | Knowledge Topology Gateway | **`KEEP & REUSE`** 100% |
| **`EvidenceFusionAssessment`**| `lib/domain/evidence/evidence_fusion_assessment.dart` | `fusionId`, `independentSourceCount`, `duplicateEvidenceIds` | Automated Fusion Assessment | **`NEW`** V1.1 Core Object |
| **`EvidenceFusionService`** | `lib/data/services/evidence/evidence_fusion_service.dart` | `evaluateEvidenceFusion()`, `assessSourceIndependence()` | Fusion Engine Gateway | **`NEW`** V1.1 Core Service |

---

## 2. GAPS & V1.1 IMPLEMENTATION BOUNDARY

1. **Source Independence vs Evidence Count**: Distinguishes total evidence object count from independent source count (`independentSourceCount`).
2. **Rule-Based Analytical Score**: Uses explicit rule-based analytical score marked `UNCALIBRATED_RULE_BASED` without claiming statistically calibrated probability.
3. **P2.2 Revision Integration**: Translates fusion assessment into P2.2 `RevisionAssessment` $\rightarrow$ `RevisionDecision` $\rightarrow$ `EventHypothesis` v2 without bypassing P2.2 revision machinery.
