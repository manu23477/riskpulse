# V1.3 FORENSIC REMOTE SENSING INVENTORY

**Document Identifier**: `V1_3_FORENSIC_RS_INVENTORY`  
**Workstream**: Forensic Inventory of Existing Satellite, GEE & Remote Sensing Structures  
**Date**: October 1, 2026  
**Status**: COMPLETED FORENSIC INVENTORY  

---

## 1. INVENTORY OF EXISTING REMOTE SENSING STRUCTURES

| Structure / Model Name | File Location | Key Fields | Semantic Category | Reusability / Action |
| :--- | :--- | :--- | :--- | :--- |
| **`RemoteSensingBand`** | `lib/domain/gis/remote_sensing_band.dart` | `bandId`, `scaleFactor`, `nominalResolutionMeters` | Sentinel-2 Spectral Band Contract | **`KEEP`** 100% |
| **`RemoteSensingObservation`**| `lib/domain/gis/remote_sensing_observation.dart` | `observationId`, `datasetName`, `sceneId` | Satellite Scene Acquisition | **`NEW`** V1.3 Core Object |
| **`RemoteSensingIndicator`**| `lib/domain/gis/remote_sensing_indicator.dart` | `indicatorId`, `indicatorType`, `meanValue` | Derived Physical Variable | **`NEW`** V1.3 Core Object |
| **`RemoteSensingEvidenceService`**| `lib/data/services/gee/remote_sensing_evidence_service.dart` | `calculateNdvi()`, `convertToEvidenceObject()` | RS Scientific Gateway | **`NEW`** V1.3 Core Service |
| **`CloudMaskingEngine`** | `lib/data/services/cloud_masking_engine.zip` | Cloud / QA Band Masking | Quality Gate | **`KEEP`** 100% |

---

## 2. GAPS & V1.3 IMPLEMENTATION BOUNDARY

1. **SATELLITE SIGNAL IS EVIDENCE, NOT TRUTH**: Remote sensing signals (NDVI drop, SAR backscatter change) convert to `EvidenceObject` records with `EvidenceType.remoteSensing`. They do NOT directly create confirmed hazard events.
2. **Sentinel-2 Band Contract**: Reuses `RemoteSensingBand.sentinel2B2..B8` (B2=Blue, B3=Green, B4=Red, B8=NIR) at 10m spatial resolution and scale factor 0.0001.
3. **NoData Preservation**: Cloud-masked pixels set NoData fraction without fabricating valid reflectance.
