# P1.5 FORENSIC EVENT MODEL INVENTORY

**Document Identifier**: `P1_5_EVENT_MODEL_FORENSIC_INVENTORY`  
**Workstream**: Forensic Inventory of Existing RiskPulse Event & Hazard Data Structures  
**Date**: October 1, 2026  
**Status**: COMPLETED FORENSIC INVENTORY  

---

## 1. INVENTORY OF EXISTING EVENT & HAZARD DATA STRUCTURES

| Model Name | File Location | Key Fields | Spatial Representation | Temporal Fields | Primary Purpose & Usage |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`Hazard`** | `lib/domain/hazard/hazard.dart` | `id`, `name`, `category`, `intensity`, `active`, `verificationStatus` | `GeoLocation location`, `Map<String,dynamic>? geometry` | `date`, `time`, `year`, `lastUpdated` | Operational RiskMap hazard feature & UI rendering |
| **`OSINTCandidateEvent`** | `lib/domain/osint/osint_candidate_event.dart` | `eventId`, `eventType`, `title`, `description`, `verificationState` | `OSINTSpatialReference spatialRef` (Point or Polygon) | `eventTime`, `detectionTime` | Candidate disaster event intelligence from OSINT claims |
| **`CompoundHazardEvent`** | `lib/domain/forecasting/compound_hazard_event.dart` | `compoundEventId`, `title`, `componentHazardIds`, `overallStatus` | `GeoLocation location`, `MapExtent? spatialExtent` | `ForecastHorizon temporalWindow` | Multi-hazard cascade & compound event forecasting |
| **`LandslideEventRecord`** | `lib/domain/forecasting/landslide_calibration_contracts.dart` | `eventId`, `slideType`, `triggerType` | `double latitude`, `double longitude` | `DateTime eventTimestamp` | Landslide calibration & historical event records |
| **`FloodEventRecord`** | `lib/domain/forecasting/flood_calibration_contracts.dart` | `eventId`, `peakDischargeCms` | `double latitude`, `double longitude` | `DateTime eventTimestamp` | Hydrological flood calibration records |
| **`GroundTruthEvent`** | `lib/data/services/forecasting/event_matching_policy.dart` | `eventId`, `hazardType`, `confidence` | `double latitude`, `double longitude` | `DateTime timestamp` | Forecasting ground-truth event matching |

---

## 2. FORENSIC DISCOVERY & INTEGRATION POINT SELECTION

1. **No Parallel Event Model Required**: RiskPulse already possesses mature event and hazard models (`Hazard`, `OSINTCandidateEvent`, `CompoundHazardEvent`).
2. **Bridge Strategy**: P1.5 constructs a unified adapter service (`EventAdministrativeAttributionService`) and attribution object (`EventAdministrativeAttribution`) that interfaces cleanly with all existing event/hazard models without modifying their core classes.
