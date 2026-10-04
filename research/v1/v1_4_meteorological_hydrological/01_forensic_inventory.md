# V1.4 FORENSIC METEOROLOGICAL & HYDROLOGICAL INVENTORY

**Document Identifier**: `V1_4_FORENSIC_HYDRO_INVENTORY`  
**Workstream**: Forensic Inventory of Existing Meteorological & Hydrological Observation Structures  
**Date**: October 1, 2026  
**Status**: COMPLETED FORENSIC INVENTORY  

---

## 1. INVENTORY OF EXISTING WEATHER & HYDRO STRUCTURES

| Structure / Model Name | File Location | Key Fields | Semantic Category | Reusability / Action |
| :--- | :--- | :--- | :--- | :--- |
| **`WeatherData`** | `lib/domain/weather/weather_data.dart` | `temperature`, `humidity`, `windSpeed` | Weather Observation | **`KEEP`** 100% |
| **`EnvironmentalRawObservation`**| `lib/domain/evidence/environmental_raw_observation.dart` | `rawObservationId`, `stationId`, `variables` | Time-Series Environmental Input | **`NEW`** V1.4 Core Object |
| **`EnvironmentalIndicator`**| `lib/domain/evidence/environmental_indicator.dart` | `variableName`, `numericValue`, `trend` | Derived Measurement Variable | **`NEW`** V1.4 Core Object |
| **`EnvironmentalEvidenceService`**| `lib/data/services/evidence/environmental_evidence_service.dart` | `ingestObservation()`, `convertToEvidenceObject()` | Environmental Gateway | **`NEW`** V1.4 Core Service |

---

## 2. GAPS & V1.4 IMPLEMENTATION BOUNDARY

1. **V1.4 OBSERVES ENVIRONMENTAL CONDITIONS**: V1.4 captures precipitation accumulations (24h, 72h), river stage, and trends as `EvidenceObject` records. It does NOT perform rainfall-runoff hydrograph simulations (deferred to V1.5).
2. **Forecast vs Observed Separation**: Forecast rainfall is tagged `EnvironmentalObservationCategory.forecast` and never merged into observed accumulations.
3. **Missing Data $\neq$ Zero**: Missing rainfall is stored as `MISSING`, not 0 mm.
