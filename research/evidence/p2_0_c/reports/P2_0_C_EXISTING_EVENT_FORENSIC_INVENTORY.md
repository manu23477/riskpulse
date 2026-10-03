# P2.0-C EXISTING EVENT ARCHITECTURE FORENSIC INVENTORY

**Document Identifier**: `P2_0_C_EXISTING_EVENT_FORENSIC_INVENTORY`  
**Workstream**: Forensic Inventory of Existing RiskPulse Event & Hazard Structures  
**Date**: October 1, 2026  
**Status**: COMPLETED FORENSIC INVENTORY  

---

## 1. INVENTORY OF EXISTING EVENT & HAZARD STRUCTURES

| Structure / Model Name | File Location | Key Fields | Semantic Category | Reusability / Action |
| :--- | :--- | :--- | :--- | :--- |
| **`EventAdministrativeAttribution`** | `lib/domain/administrative/event_administrative_attribution.dart` | `eventId`, `administrativeContext`, `spatialBasis`, `status` | Administrative Context Bridge | **`KEEP`** & Integrate directly |
| **`HazardAdministrativeAttribution`**| `lib/domain/administrative/hazard_administrative_attribution.dart` | `hazardId`, `hazardCategory`, `affectedContexts` | Physical Hazard Boundary Attribution | **`KEEP`** & Reference |
| **`Hazard`** | `lib/domain/hazard/hazard.dart` | `id`, `name`, `category`, `intensity`, `location` | Operational RiskMap Feature | **`KEEP`** & Operational target |
| **`OSINTCandidateEvent`** | `lib/domain/osint/osint_candidate_event.dart` | `eventId`, `eventType`, `spatialRef`, `eventTime` | OSINT Intelligence Candidate | **`KEEP`** & Candidate source |
| **`CompoundHazardEvent`** | `lib/domain/forecasting/compound_hazard_event.dart` | `compoundEventId`, `componentHazardIds`, `location` | Multi-Hazard Cascade Model | **`KEEP`** & Reference |

---

## 2. GAPS & P2.0-C IMPLEMENTATION BOUNDARY

1. **No Duplicate Operational Model**: `EventHypothesis` (`lib/domain/evidence/event_hypothesis.dart`) serves as the normalized candidate hypothesis tier in the intelligence pipeline, leaving operational `Hazard` features and `OSINTCandidateEvent` intact.
2. **Four-Tier Lineage**:
   $$\text{Observation} \rightarrow \text{EvidenceObject} \rightarrow \text{InterpretationObject} \rightarrow \text{EventHypothesis}$$
3. **Derived Administrative Context**: Reuses `EventAdministrativeAttributionService` and `AdministrativeIntelligenceService` for spatial context without duplicating administrative engines.
