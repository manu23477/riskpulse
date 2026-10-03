# P2.0-A EXISTING EVIDENCE ARCHITECTURE FORENSIC INVENTORY

**Document Identifier**: `P2_0_A_EXISTING_EVIDENCE_FORENSIC_INVENTORY`  
**Workstream**: Forensic Inventory of Existing Evidence & Observation Data Structures  
**Date**: October 1, 2026  
**Status**: COMPLETED FORENSIC INVENTORY  

---

## 1. INVENTORY OF EXISTING EVIDENCE & OBSERVATION STRUCTURES

| Structure / Model Name | File Location | Key Fields | Semantic Category | Immutability Status | Consumer Modules |
| :--- | :--- | :--- | :--- | :---: | :--- |
| **`OSINTEvidence`** | `lib/domain/osint/osint_evidence.dart` | `evidenceId`, `sourceId`, `extractedText`, `contentFingerprint`, `retrievedAt` | Raw OSINT Content Observation | Immutable (`@immutable`) | OSINT Workspace & Claim Extractor |
| **`HazardObservation`** | `lib/domain/forecasting/hazard_observation.dart` | `observationId`, `parameterId`, `value`, `unit`, `observationTime`, `location` | Measured Physical Hazard Observation | Immutable (`@immutable`) | Forecasting & Rainfall Association Engine |
| **`EvidenceDecisionChainContract`** | `lib/domain/gis/evidence_decision_chain_contract.dart` | `chainId`, `eventId`, `inputEvidenceIds`, `evidenceStatus`, `scientificStatus` | Scientific Decision Chain Contract | Immutable (`@immutable`) | HydroAI Execution Governance |
| **`GaugeObservationRecord`** | `lib/domain/forecasting/flood_calibration_contracts.dart` | `eventId`, `peakDischargeCms`, `observationTime` | Hydrological River Gauge Reading | Immutable | Flood Calibration Engine |
| **`VisibleEvidenceObject`** | `research/patent_window_1/.../visible_dataset_loader.dart` | `evidenceId`, `sourceSystem`, `contentHash`, `receivedAt` | Research Visible Evidence Artifact | Immutable | Evidence Fusion Patent Window 1 |

---

## 2. REUSABLE COMPONENTS & PROTECTION BOUNDARY

1. **`OSINTEvidence`**: Preserved byte-for-byte intact. Adapts cleanly to `EvidenceObject` with `evidenceType = EvidenceType.socialMedia` or `EvidenceType.newsReport`.
2. **`HazardObservation`**: Preserved byte-for-byte intact. Adapts cleanly to `EvidenceObject` with `evidenceType = EvidenceType.sensor` or `EvidenceType.riverGauge`.
3. **`EvidenceDecisionChainContract`**: Preserved byte-for-byte intact.
4. **No Parallel Redundancy**: `EvidenceObject` (`lib/domain/evidence/evidence_object.dart`) provides the normalized, multi-source evidence layer bridging all physical, OSINT, and sensor observations.
