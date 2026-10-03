# RISKPULSE — FEATURE WORKFLOW ATLAS
### Comprehensive Operational & Research GIS Workflow Reference
**Document Version**: 1.0.0-R.2 | **Release Baseline**: v1.0.0+1

---

## WORKFLOW 1: OPERATIONAL RISKMAP NAVIGATION & ATTRIBUTE QUERY
**Module**: `Operational RiskMap` | **Status**: `IMPLEMENTED & SOFTWARE-VERIFIED`

**PURPOSE**:
View live/historical operational disaster risk points and hazard polygons across Mandi, Kinnaur, and Uttarakhand.

**INPUTS**:
Protected production GeoJSON dataset (168 features, Kotropi anchor).

**PRECONDITIONS**:
RiskPulse app launched in Operational Mode.

**USER ACTIONS**:
1. Open Operational RiskMap.
2. Tap on any risk point or hazard polygon.
3. Toggle basemap style.

**PROCESSING**:
Filters feature properties, calculates simulated risk scores based on susceptibility and live weather factor.

**OUTPUTS**:
Interactive feature attribute card displaying district name, hazard category, susceptibility score, and historical event details.

**INTERPRETATION**:
Provides operational situational awareness for public and emergency managers.

**LIMITATIONS**:
Operational layers are protected from experimental research modifications.

**PROVENANCE**:
Backing feature IDs and GeoJSON property schema.

**EXPORT / NEXT STEP**:
Click [VIEW FULL DETAILS] or open Emergency Hub for response coordination.

---

## WORKFLOW 2: RESEARCH GIS SESSION INITIALIZATION & AOI CAPTURE
**Module**: `Research GIS Studio` | **Status**: `IMPLEMENTED & SOFTWARE-VERIFIED`

**PURPOSE**:
Establish a new cartographic research session and capture Study Area / AOI extent.

**INPUTS**:
Researcher-selected map extent bounds (southWest, northEast).

**PRECONDITIONS**:
Open Research GIS Studio screen.

**USER ACTIONS**:
1. Click [NEW RESEARCH SESSION].
2. Zoom/pan map to target study area.
3. Click [CAPTURE AOI].

**PROCESSING**:
Creates ResearchSession, sets MapComposition extent, and registers prod-aoi in Product Registry.

**OUTPUTS**:
Active Research Session with defined CRS (EPSG:4326) and extent.

**INTERPRETATION**:
Defines spatial domain boundary for all downstream DEM, HydroAI, and RS analyses.

**LIMITATIONS**:
AOI extent bounds dictate raster cropping and validation grid limits.

**PROVENANCE**:
Recorded in ResearchWorkspaceProvider state.

**EXPORT / NEXT STEP**:
Proceed to DEM Acquisition or Remote Sensing ingestion.

---

## WORKFLOW 3: DEM ACQUISITION, STRUCTURAL VALIDATION & READINESS GATING
**Module**: `DEM Governance` | **Status**: `IMPLEMENTED & SOFTWARE-VERIFIED`

**PURPOSE**:
Acquire DEM raster (GEE GLO-30 / Local GeoTIFF), validate structure (4K.8.12-v1), and evaluate readiness policy (4K.8.14-v1).

**INPUTS**:
Raw DEM raster (GeoTIFF) or GEE GLO-30 tile.

**PRECONDITIONS**:
Active Research Session with captured AOI.

**USER ACTIONS**:
1. Click [ACQUIRE DEM].
2. Select GEE GLO-30 or upload local GeoTIFF.
3. Review validation statistics.
4. If requiresResearcherReview, click [ACKNOWLEDGE & PROCEED].

**PROCESSING**:
DemValidationService computes footprint coverage %, valid cell %, NoData %. DemReadinessPolicyService evaluates readiness status.

**OUTPUTS**:
Governed inputDem raster, DemReadinessAssessment, and DemReadinessAcknowledgementDialog log.

**INTERPRETATION**:
Ensures DEM is structurally valid prior to running HydroAI or terrain services.

**LIMITATIONS**:
Acknowledgement is a workflow decision, NOT objective scientific validation. Zero elevation fabrication or NoData filling occurs.

**PROVENANCE**:
validationRuleVersion (4K.8.12-v1) and readinessPolicyVersion (4K.8.14-v1) recorded in AnalyticalStep.

**EXPORT / NEXT STEP**:
Proceed to Terrain Analysis or HydroAI pipeline execution.

---

## WORKFLOW 4: HYDROAI 2D HYDRODYNAMIC SIMULATION EXECUTION
**Module**: `HydroAI Hydrodynamics` | **Status**: `SOFTWARE CONTRACTS & ADAPTER COMPLETE / NATIVE BINARY PENDING`

**PURPOSE**:
Execute 2D hydrodynamic flood simulation using solver-neutral contracts and HecRasSolverAdapter.

**INPUTS**:
Governed inputDem, precipitation forcing (HazardTimeSeries), roughness raster, and 1D channel geometry.

**PRECONDITIONS**:
Governed DEM acquired and validated.

**USER ACTIONS**:
1. Configure HydrodynamicModelDomain.
2. Click [RUN HYDROAI SIMULATION].
3. Monitor execution status.

**PROCESSING**:
HecRasInputTranslator generates .prj, .g01, .u01, .p01 files. HecRasProcessController manages execution. HecRasOutputParser parses output rasters.

**OUTPUTS**:
HydrodynamicResult containing FloodDepthRaster (Max), VelocityVectorRaster, WSE raster, and temporal FloodState stack.

**INTERPRETATION**:
Provides physics-based 2D flood depth and flow velocity fields.

**LIMITATIONS**:
Simulation completion (SimulationState.completed) indicates software completion ONLY. scientificStatus remains provisionalSoftwareOnly.

**PROVENANCE**:
AnalyticalStep chains simulationId, solverName, planFile, and DEM readiness metadata.

**EXPORT / NEXT STEP**:
Proceed to SAR 2D Inundation Validation or Exposure Intersection.

---

## WORKFLOW 5: SENTINEL-1 SAR 2D INUNDATION VALIDATION & CSI EVALUATION
**Module**: `SAR Validation` | **Status**: `SOFTWARE ENGINE COMPLETE / EMPIRICAL EXPERIMENTS PENDING`

**PURPOSE**:
Perform 2D spatial validation comparing HydroAI flood depth against independent Sentinel-1 SAR observed flood mask.

**INPUTS**:
Completed HydrodynamicResult, SarInundationRecord, and explicit depthThresholdMeters (e.g. 0.50m).

**PRECONDITIONS**:
HydrodynamicResult and SAR reference raster share Common Validation Grid.

**USER ACTIONS**:
1. Open SAR Validation panel.
2. Select SAR dataset and supply wetting threshold (depthThresholdMeters).
3. Click [RUN SAR VALIDATION].

**PROCESSING**:
SarInundationValidationEngine verifies grid compatibility, derives model extent mask, and computes confusion matrix (TP, FP, FN, TN) and CSI = TP / (TP + FP + FN).

**OUTPUTS**:
InundationValidationRecord, 4-class categorical map overlay (TP: Green, FP: Orange, FN: Red), and HydroaiValidationPanel metrics.

**INTERPRETATION**:
Quantifies spatial extent agreement between modeled flood and satellite observation.

**LIMITATIONS**:
SAR flood extent is an independent reference, NOT absolute ground truth. CSI calculation does NOT constitute automatic scientific validation or operational promotion.

**PROVENANCE**:
Validation parameters, grid status, and confusion matrix counts recorded in AnalyticalStep.

**EXPORT / NEXT STEP**:
Inspect HydroaiValidationPanel metrics and export validation report.

---

## WORKFLOW 6: ENVIRONMENTAL HEALTH & DISEASE SPATIAL INTELLIGENCE ANALYSIS
**Module**: `Environmental Health` | **Status**: `IMPLEMENTED & SOFTWARE-VERIFIED (EH.1-R1)`

**PURPOSE**:
Analyze spatial geographic associations between aggregated disease incidence rates and environmental exposure variables.

**INPUTS**:
HealthOutcomeDataset (privacy-safe aggregated district/block cases) and EnvironmentalExposureLayer (e.g. Arsenic Groundwater ppm).

**PRECONDITIONS**:
Active Research Session with minimum 3 valid observation pairs.

**USER ACTIONS**:
1. Open Environmental Health panel.
2. Select Health Outcome Dataset and Exposure Layer.
3. Click [RUN SPATIAL ASSOCIATION ANALYSIS].
4. Click [LOAD EXPOSURE OVERLAY TO MAP].

**PROCESSING**:
EnvironmentalHealthService calculates Pearson correlation r and Student t-statistic p-value over n usable observation pairs.

**OUTPUTS**:
HealthSpatialAnalysisResult, Exploratory Exposure-Health Overlay raster, and EnvironmentalHealthPanel metrics.

**INTERPRETATION**:
Identifies spatial geographic associations ONLY.

**LIMITATIONS**:
Spatial association identified. Further epidemiological investigation is required. Statistical association does NOT establish causation. Zero patient PII exposed.

**PROVENANCE**:
analysisId, pearsonCorrelationR, sampleCountN, pValue, and non-causality disclaimer recorded in AnalyticalStep.

**EXPORT / NEXT STEP**:
Export overlay raster or compile epidemiological research briefing.

---

