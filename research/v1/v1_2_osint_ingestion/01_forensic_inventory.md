# V1.2 FORENSIC OSINT INGESTION INVENTORY

**Document Identifier**: `V1_2_FORENSIC_OSINT_INVENTORY`  
**Workstream**: Forensic Inventory of Existing OSINT, Normalization & Evidence Ingestion Structures  
**Date**: October 1, 2026  
**Status**: COMPLETED FORENSIC INVENTORY  

---

## 1. INVENTORY OF EXISTING OSINT STRUCTURES

| Structure / Model Name | File Location | Key Fields | Semantic Category | Reusability / Action |
| :--- | :--- | :--- | :--- | :--- |
| **`OsintRawObservation`** | `lib/domain/osint/osint_raw_observation.dart` | `rawObservationId`, `headline`, `rawContent`, `contentHash` | Unedited Raw External Post | **`NEW`** V1.2 Core Object |
| **`OsintNormalizedPayload`** | `lib/domain/osint/osint_normalized_payload.dart` | `extractedText`, `extractedHazardCategories`, `geolocationType` | Extracted NLP Payload | **`NEW`** V1.2 Core Object |
| **`OsintSourceAdapter`** | `lib/domain/osint/osint_source_adapter.dart` | `fetchLatestObservations()`, `checkSourceHealth()` | Source Connector Contract | **`NEW`** V1.2 Core Interface |
| **`OsintIngestionService`** | `lib/data/services/osint/osint_ingestion_service.dart` | `ingestRawObservation()`, `convertToEvidenceObject()` | Ingestion Gateway | **`NEW`** V1.2 Core Service |
| **`EvidenceObject`** | `lib/domain/evidence/evidence_object.dart` | `evidenceId`, `source`, `contentHash`, `provenance` | P2.0-A Factual Observation | **`KEEP & REUSE`** 100% |

---

## 2. GAPS & V1.2 IMPLEMENTATION BOUNDARY

1. **OSINT IS EVIDENCE, NOT TRUTH**: Ingested OSINT posts convert to `EvidenceObject` instances. They do NOT automatically become confirmed disaster events.
2. **Uncertainty-Aware Geolocation**: Classifies location precision (`exactPoint`, `approximatePoint`, `roadSegment`, `villageArea`) without fabricating point coordinates.
3. **V1.1 Fusion Submission**: Converted `EvidenceObject` instances are submitted directly to V1.1 `EvidenceFusionService`.
