# P2.4 EXISTING SPATIAL ARCHITECTURE FORENSIC INVENTORY

**Document Identifier**: `P2_4_EXISTING_SPATIAL_FORENSIC_INVENTORY`  
**Workstream**: Forensic Inventory of Existing RiskPulse Spatial & Geometry Structures  
**Date**: October 1, 2026  
**Status**: COMPLETED FORENSIC INVENTORY  

---

## 1. INVENTORY OF EXISTING SPATIAL & GEOMETRY STRUCTURES

| Structure / Model Name | File Location | Key Fields | Semantic Category | Reusability / Action |
| :--- | :--- | :--- | :--- | :--- |
| **`EventHypothesis`** | `lib/domain/evidence/event_hypothesis.dart` | `location`, `geometry`, `spatialExtent`, `boundingBox`, `spatialPrecision` | Hypothesis Spatial State | **`KEEP`** & Reference Option A |
| **`InterpretationObject`** | `lib/domain/evidence/interpretation_object.dart` | `inferredPoint`, `inferredGeometry`, `spatialUncertaintyMeters` | Derived Inferred Location | **`KEEP`** & Input source |
| **`EvidenceObject`** | `lib/domain/evidence/evidence_object.dart` | `location`, `geometry`, `rawLocationDescription` | Raw Observation Location | **`KEEP`** & Input source |
| **`SpatialState`** | `lib/domain/evidence/spatial_state.dart` | `spatialStateId`, `eventHypothesisId`, `geometry`, `crs`, `uncertainty` | Authoritative Versioned Spatial State | **`NEW`** P2.4 Core Object |
| **`EventAdministrativeAttribution`**| `lib/domain/administrative/event_administrative_attribution.dart` | `eventId`, `administrativeContext`, `spatialBasis` | Administrative Context Bridge | **`KEEP`** & Integrate via P1.5 |

---

## 2. GAPS & P2.4 IMPLEMENTATION BOUNDARY

1. **Option A Architectural Decision**: `EventHypothesis` contains the current spatial representation for fast access, while `SpatialState` (`lib/domain/evidence/spatial_state.dart`) provides the authoritative, versioned, provenance-preserving spatial state history.
2. **Location vs Extent**: Keeps reference point (`location`) distinct from affected footprint polygon (`geometry` / `spatialExtent`).
3. **Uncertainty Separation**: Spatial uncertainty (`uncertaintyRadiusMeters`) is represented in `SpatialUncertainty` without distorting physical geometry coordinates.
