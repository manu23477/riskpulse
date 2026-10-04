# V1.6 FORENSIC EXPOSURE & IMPACT INVENTORY & AUDIT

**Document Identifier**: `V1_6_FORENSIC_EXPOSURE_AUDIT`  
**Workstream**: Forensic Audit of Existing RiskPulse Exposure, Impact & Asset Structures  
**Date**: October 1, 2026  
**Status**: COMPLETED FORENSIC AUDIT  

---

## 1. INVENTORY OF EXISTING EXPOSURE & IMPACT STRUCTURES

| Structure / Model Name | File Location | Key Fields | Semantic Category | Reusability / Action |
| :--- | :--- | :--- | :--- | :--- |
| **`ExposureAsset`** | `lib/domain/exposure/exposure_asset.dart` | `assetId`, `assetType`, `datasetVersion`, `referenceYear` | Physical Asset & Population | **`NEW`** V1.6 Core Object |
| **`ExposureResult`** | `lib/domain/exposure/exposure_result.dart` | `exposureResultId`, `hazardFootprintId`, `intersectionType` | Spatial Intersection Result | **`NEW`** V1.6 Core Object |
| **`ImpactAssessment`** | `lib/domain/impact/impact_assessment.dart` | `assessmentId`, `isObserved`, `impactCategory` | Potential vs Observed Impact | **`NEW`** V1.6 Core Object |
| **`ExposureImpactService`** | `lib/data/services/exposure/exposure_impact_service.dart` | `evaluateAssetExposure()`, `evaluatePotentialImpact()` | Exposure & Impact Gateway | **`NEW`** V1.6 Core Service |

---

## 2. GAPS & V1.6 IMPLEMENTATION BOUNDARY

1. **EXPOSURE != IMPACT**: Spatial overlap of a hazard footprint on a road or building constitutes EXPOSURE, NOT confirmed damage.
2. **POTENTIAL vs OBSERVED SEPARATION**: Potential impact (`isObserved = false`) is derived from spatial models; observed impact (`isObserved = true`) requires field/remote sensing evidence verification.
3. **Double-Counting Prevention**: Assets are processed by primary string `assetId` to prevent double-counting across overlapping hazard footprints.
