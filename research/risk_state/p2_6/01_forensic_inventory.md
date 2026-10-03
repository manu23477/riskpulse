# P2.6 DYNAMIC RISK STATE FORENSIC INVENTORY

**Document Identifier**: `P2_6_FORENSIC_INVENTORY`  
**Workstream**: Forensic Inventory of Existing RiskPulse Risk & Hazard Structures  
**Date**: October 1, 2026  
**Status**: COMPLETED FORENSIC INVENTORY  

---

## 1. INVENTORY OF EXISTING RISK & HAZARD STRUCTURES

| Structure / Model Name | File Location | Key Fields | Semantic Category | Reusability / Action |
| :--- | :--- | :--- | :--- | :--- |
| **`Hazard`** | `lib/domain/hazard/hazard.dart` | `id`, `name`, `category`, `intensity`, `location` | Operational RiskMap Feature | **`KEEP`** & Input source |
| **`EventHypothesis`** | `lib/domain/evidence/event_hypothesis.dart` | `hypothesisId`, `hypothesisVersion`, `confidence` | P2.0-C Candidate Event Model | **`KEEP`** & Pipeline anchor |
| **`SpatialState`** | `lib/domain/evidence/spatial_state.dart` | `spatialStateId`, `geometry`, `location`, `crs` | P2.4 Versioned Spatial State | **`KEEP`** & Spatial input |
| **`AdministrativeState`** | `lib/domain/evidence/administrative_state.dart` | `administrativeStateId`, `unitRecords`, `affectedUnitIds` | P2.5 Versioned Admin State | **`KEEP`** & Admin input |
| **`DynamicRiskState`** | `lib/domain/evidence/dynamic_risk_state.dart` | `riskStateId`, `hazardCondition`, `exposureCondition`, `vulnerabilityCondition`, `impactCondition` | Versioned Dynamic Risk State | **`NEW`** P2.6 Core Object |

---

## 2. GAPS & P2.6 IMPLEMENTATION BOUNDARY

1. **First-Class Dynamic Risk State**: `DynamicRiskState` (`lib/domain/evidence/dynamic_risk_state.dart`) represents versioned risk conditions associated with an `EventHypothesis`, `SpatialState`, `AdministrativeState`, and evidence lineage.
2. **Semantic Separation**: Strictly separates `hazardCondition`, `exposureCondition`, `vulnerabilityCondition`, and `impactCondition` from `confidenceScore` and `riskScore`.
3. **No Second Risk Engine**: Integrates existing P1.x..P2.5 layers as inputs without introducing a second risk calculation engine.
