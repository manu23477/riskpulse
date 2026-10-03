# P2.0-B EXISTING INTERPRETATION ARCHITECTURE FORENSIC INVENTORY

**Document Identifier**: `P2_0_B_EXISTING_INTERPRETATION_FORENSIC_INVENTORY`  
**Workstream**: Forensic Inventory of Existing RiskPulse Interpretation & Inference Data Structures  
**Date**: October 1, 2026  
**Status**: COMPLETED FORENSIC INVENTORY  

---

## 1. INVENTORY OF EXISTING INTERPRETATION & INFERENCE STRUCTURES

| Structure / Model Name | File Location | Key Fields | Semantic Category | Reusability / Action |
| :--- | :--- | :--- | :--- | :--- |
| **`EvidenceInterpretationLink`** | `lib/domain/evidence/evidence_interpretation_link.dart` | `evidenceId`, `interpretationId`, `relationshipType` | Evidence-to-Interpretation Contract | **`KEEP`** & Integrate directly |
| **`EvidenceDecisionChainContract`** | `lib/domain/gis/evidence_decision_chain_contract.dart` | `chainId`, `inputEvidenceIds`, `derivedEvidenceIds`, `evidenceStatus` | Decision Chain Governance Contract | **`KEEP`** & Reference |
| **`EvidenceConfidence`** | `lib/domain/osint/evidence_confidence.dart` | `sourceCredibility`, `spatialAccuracy`, `temporalFreshness`, `overallConfidence` | OSINT Evidence Confidence | **`KEEP`** & Reference in `InterpretationConfidence` |
| **`OSINTSpatialReference`** | `lib/domain/osint/osint_spatial_reference.dart` | `spatialPrecision`, `location`, `uncertaintyRadiusKm`, `placeName` | Geocoded Location Reference | **`KEEP`** & Adapt to `inferredPoint` |
| **`HazardObservation`** | `lib/domain/forecasting/hazard_observation.dart` | `value`, `qualityState`, `uncertainty` | Sensor Telemetry Observation | **`KEEP`** & Parent Evidence Input |

---

## 2. GAPS & P2.0-B IMPLEMENTATION BOUNDARY

1. **No Duplicate Abstraction**: P2.0-B extends the existing evidence layer without duplicating operational event models.
2. **`InterpretationObject`**: Provides the normalized, multi-evidence derived semantic layer between `EvidenceObject` and future `EventHypothesis`.
3. **Inferred Location Safeguard**: `InterpretationObject` preserves inferred points (`inferredPoint`, `inferredGeometry`, `spatialUncertaintyMeters`) without overwriting raw evidence locations in `EvidenceObject`.
