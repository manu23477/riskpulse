# P2.0-D EXISTING RELATIONSHIP ARCHITECTURE FORENSIC INVENTORY

**Document Identifier**: `P2_0_D_EXISTING_RELATIONSHIP_FORENSIC_INVENTORY`  
**Workstream**: Forensic Inventory of Existing RiskPulse Link & Relationship Structures  
**Date**: October 1, 2026  
**Status**: COMPLETED FORENSIC INVENTORY  

---

## 1. INVENTORY OF EXISTING LINK & RELATIONSHIP STRUCTURES

| Structure / Model Name | File Location | Key Fields | Semantic Category | Reusability / Action |
| :--- | :--- | :--- | :--- | :--- |
| **`EvidenceEventLink`** | `lib/domain/evidence/evidence_event_link.dart` | `evidenceId`, `eventId`, `relationshipType` | Evidence-to-Event Link Contract | **`KEEP`** & Integrate directly |
| **`EvidenceInterpretationLink`** | `lib/domain/evidence/evidence_interpretation_link.dart` | `evidenceId`, `interpretationId`, `relationshipType` | Evidence-to-Interpretation Contract | **`KEEP`** & Integrate directly |
| **`EvidenceRelationship`** | `lib/domain/evidence/evidence_relationship.dart` | `relationshipId`, `sourceType`, `sourceId`, `targetType`, `targetId`, `relationshipType` | First-Class Immutable Relationship Layer | **`NEW`** P2.0-D Core Object |
| **`EvidenceDecisionChainContract`** | `lib/domain/gis/evidence_decision_chain_contract.dart` | `chainId`, `inputEvidenceIds`, `evidenceStatus` | Decision Chain Governance Contract | **`KEEP`** & Reference |

---

## 2. GAPS & P2.0-D IMPLEMENTATION BOUNDARY

1. **First-Class Relationship Abstraction**: `EvidenceRelationship` (`lib/domain/evidence/evidence_relationship.dart`) represents explicit `SUPPORTS`, `CONTRADICTS`, and `RELATED_TO` links between Evidence/Interpretation objects and `EventHypothesis` instances.
2. **Directional Invariant**: `sourceType:sourceId ──relationshipType──> targetType:targetId` explicitly preserves directionality.
3. **No Automatic Effect**: Creating `SUPPORTS` or `CONTRADICTS` links does NOT mutate `EventHypothesis` confidence, status, or spatial bounds. Evaluation belongs to Phase P2.1.
