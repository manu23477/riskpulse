# P2.9 FORENSIC INTEGRATION INVENTORY

**Document Identifier**: `P2_9_FORENSIC_INTEGRATION_INVENTORY`  
**Workstream**: Forensic End-To-End Risk Intelligence Integration Audit  
**Date**: October 1, 2026  
**Status**: COMPLETED FORENSIC INVENTORY  

---

## 1. INVENTORY OF EXISTING RISK MAP & RESEARCH GIS STRUCTURES

| Structure / Model Name | File Location | Key Fields | Semantic Category | Reusability / Action |
| :--- | :--- | :--- | :--- | :--- |
| **`RiskResearchSession`** | `lib/domain/evidence/risk_research_session.dart` | `sessionId`, `riskObjectId`, `mode`, `eventHypothesisId`, `spatialStateId` | Canonical Intelligence Context | **`NEW`** P2.9 Core Object |
| **`ResearchAnalysisResult`** | `lib/domain/evidence/research_analysis_result.dart` | `resultId`, `originatingSessionId`, `analysisType`, `outputGeoJson` | Research Result Contract | **`NEW`** P2.9 Core Object |
| **`RiskIntelligenceContextService`**| `lib/data/services/evidence/risk_intelligence_context_service.dart` | `createSessionFromRiskObject()`, `saveAnalysisResult()` | Intelligence Context Gateway | **`NEW`** P2.9 Core Service |
| **`SpatialState`** | `lib/domain/evidence/spatial_state.dart` | `spatialStateId`, `geometry`, `location`, `crs` | P2.4 Versioned Spatial State | **`KEEP`** & Input source |
| **`AdministrativeState`** | `lib/domain/evidence/administrative_state.dart` | `administrativeStateId`, `unitRecords`, `primaryContext` | P2.5 Versioned Admin State | **`KEEP`** & Input source |
| **`DynamicRiskState`** | `lib/domain/evidence/dynamic_risk_state.dart` | `riskStateId`, `hazardCondition`, `exposureCondition`, `confidenceScore` | P2.6 Dynamic Risk State | **`KEEP`** & Input source |

---

## 2. GAPS & P2.9 IMPLEMENTATION BOUNDARY

1. **ONE RISK OBJECT $\rightarrow$ MULTIPLE VIEWS**: Risk Map and Research GIS share `RiskResearchSession` referencing authoritative state versions ($H_1, S_1, A_1, R_1$).
2. **Buffer vs Geometry Isolation**: Analysis `bufferMeters` or study area polygon does NOT overwrite authoritative `targetGeometry` or `SpatialState`.
3. **Return Path**: Research GIS outputs convert to `ResearchAnalysisResult`, creating new `EvidenceObject` and `InterpretationObject` instances that feed back into the Risk Intelligence lifecycle.
