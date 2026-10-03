# RISKPULSE — USER MANUAL
### AI-Powered Disaster Risk Intelligence & Decision Support System
**Document Version**: 1.0.0-R.2 | **Release Baseline**: v1.0.0+1 | **Date**: September 2026
**Status**: IMPLEMENTED & SOFTWARE-VERIFIED (RESEARCH-READY)

---

## TABLE OF CONTENTS
1. About RiskPulse & Dual-Mode Architecture
2. Application Architecture
3. Getting Started
4. Home Dashboard
5. Operational RiskMap (168 Production Features)
6. Research GIS Studio & Cartographic Workspace
7. DEM Acquisition & Readiness Governance (4K.8.12-v1 / 4K.8.14-v1)
8. GIS Analytical Tools
9. Remote Sensing & Multispectral Indices (NDVI / NDWI)
10. Google Earth Engine (GEE) Architecture
11. OSINT Multi-Stream Intelligence & Controlled Promotion Gate
12. HydroAI 2D Hydrodynamic Modeling Architecture
13. HEC-RAS 2D Solver Adapter & Process Controller
14. Sentinel-1 SAR 2D Inundation Validation (CSI Engine)
15. Exposure Analysis Engine
16. Impact Assessment Engine (Stage 3.8-R Safeguards)
17. Decision Support Engine (3.9.5-v1) & Scenario Analysis
18. Research Priority Queue Engine (3.9.8-v1)
19. AI Assistance & Advisory Synthesis
20. Environmental Health & Disease Spatial Intelligence (EH.1-R1)
21. Provenance Continuity & Lineage Tracking (Stage 4K.8.18)
22. Research Product Registry (18 Products)
23. GeoTIFF / GeoJSON Export Infrastructure
24. Research vs Operational Mode Firewall
25. Troubleshooting & Data Governance
26. Scientific Limitations & Governance Disclaimers
27. Privacy & Aggregated Health Data Governance
28. Glossary & Terminology Guide

---

## SECTION: GETTING STARTED & APPLICATION OVERVIEW
**Topic ID**: `getting_started` | **Category**: `gettingStarted`
**Scientific Status**: IMPLEMENTED & SOFTWARE-VERIFIED

**Summary**: Overview of RiskPulse dual-mode architecture: Operational RiskMap vs Research GIS Studio.

### Dual-Mode Architecture
RiskPulse provides two distinct operational environments: Operational Mode for real-time district hazard tracking and Research GIS Studio for reproducible scientific research workflows.

### Scientific Governance Principles
RiskPulse enforces strict separation between software execution, spatial metrics, scientific validation, and operational promotion. A completed simulation or calculation does NOT constitute scientific validation.

### Step-by-Step User Workflow
1. Launch RiskPulse and navigate between Home Dashboard, Operational RiskMap, and Research GIS.
2. Use Operational Mode to view established 168 district risk features.
3. Use Research GIS Studio to configure AOI, acquire DEMs, run HydroAI, or perform SAR inundation validation.

> **SCIENTIFIC & APPLICATION LIMITATIONS**: Research GIS analyses remain in research mode and cannot mutate production operational RiskMap layers.

---

## SECTION: OPERATIONAL RISKMAP & PROTECTED BASELINE
**Topic ID**: `operational_riskmap` | **Category**: `operationalRiskMap`
**Scientific Status**: IMPLEMENTED & SOFTWARE-VERIFIED

**Summary**: User guide for Operational RiskMap, hazard point/polygon feeds, and baseline protection.

### Production Feature Set
The Operational RiskMap is backed by a protected production GeoJSON baseline containing 168 features (163 Points, 5 Polygons), including anchor feature ls-hp-mandi-kotropi-2017.

### Operational Isolation
Operational features are protected from experimental research modifications. Any promotion from Research GIS to Operational RiskMap requires passing the ControlledPromotionGate.

### Step-by-Step User Workflow
1. Open Operational RiskMap from Home Dashboard.
2. Tap on any district point or hazard polygon to view attribute cards, susceptibility scores, and historical event details.
3. Toggle map style (Normal, Satellite, Terrain, Dark).

> **SCIENTIFIC & APPLICATION LIMITATIONS**: Live weather/hazard updates depend on external service availability.

---

## SECTION: RESEARCH GIS STUDIO & CARTOGRAPHIC WORKSPACE
**Topic ID**: `research_gis_studio` | **Category**: `researchGisStudio`
**Scientific Status**: IMPLEMENTED & SOFTWARE-VERIFIED

**Summary**: Guide to managing Research Sessions, map compositions, layer ordering, and product inventories.

### Research Workspace State
Research Workspace Provider manages active Research Sessions, AOI extents, layer stacks, cartographic elements (scale bar, north arrow, coordinate grid), and product inventories.

### Layer Management & Symbology
Reuses GisLayer, RasterStyle, and VectorStyle to support continuous color ramps, classified schemes, opacity, and z-index reordering.

### Step-by-Step User Workflow
1. Click [NEW RESEARCH SESSION] and draw or capture Study Area / AOI extent.
2. Acquire DEM or load multispectral satellite products.
3. Run analytical pipelines and inspect layers in Layer Manager.

> **SCIENTIFIC & APPLICATION LIMITATIONS**: All research layers remain in memory/local session storage.

---

## SECTION: DEM ACQUISITION, VALIDATION & READINESS GOVERNANCE
**Topic ID**: `dem_acquisition` | **Category**: `demAndTerrain`
**Scientific Status**: IMPLEMENTED & SOFTWARE-VERIFIED

**Summary**: Complete guide to DEM structural validation (4K.8.12-v1), readiness policy (4K.8.14-v1), and acknowledgement.

### DemValidationService (4K.8.12-v1)
Evaluates raster dimensions, spatial extent coverage, valid cell %, and NoData cell % against the AOI. No synthetic elevation or silent NoData filling is permitted.

### DemReadinessPolicyService (4K.8.14-v1)
Classifies DEM into readiness states (readyForAnalysis, requiresResearcherReview, rejected, notEstablished). Partial footprint coverage (< 98%) or internal NoData cells require explicit researcher acknowledgement via DemReadinessAcknowledgementDialog.

### Step-by-Step User Workflow
1. In Research GIS, click [ACQUIRE DEM] and select GEE GLO-30 or Local GeoTIFF.
2. Review calculated valid cell %, NoData %, and coverage statistics.
3. If readiness status is requiresResearcherReview, click [ACKNOWLEDGE & PROCEED]. Note: Acknowledgement is a workflow decision, NOT scientific validation.

> **SCIENTIFIC & APPLICATION LIMITATIONS**: Raw DEM rasters outside AOI or with zero valid cells are rejected.

---

## SECTION: REMOTE SENSING (NDVI / NDWI) & GEE INTEGRATION
**Topic ID**: `remote_sensing_gee` | **Category**: `remoteSensingGee`
**Scientific Status**: SOFTWARE READY / LIVE GEE PENDING CREDENTIALS

**Summary**: Guide to Sentinel-2 multispectral index calculations and Earth Engine provider architecture.

### Multispectral Index Engine
Computes NDVI (Normalized Difference Vegetation Index) and NDWI (Normalized Difference Water Index) from Sentinel-2 bands (NIR, Red, Green). Runs independently without DEM blocking.

### Google Earth Engine Provider
GeeClient and GeeDataProvider manage GLO-30 DEM and Copernicus Sentinel-2 tile requests. Operates behind secure credential boundaries.

### Step-by-Step User Workflow
1. In Research GIS Remote Sensing tab, select Sentinel-2 product.
2. Calculate NDVI or NDWI raster.
3. Inspect continuous index color ramps in Layer Manager.

> **SCIENTIFIC & APPLICATION LIMITATIONS**: Live satellite streaming requires authenticated GEE service account credentials.

---

## SECTION: OSINT INTELLIGENCE & CONTROLLED PROMOTION GATE
**Topic ID**: `osint_intelligence` | **Category**: `osintIntelligence`
**Scientific Status**: IMPLEMENTED & SOFTWARE-VERIFIED

**Summary**: Multi-stream intelligence fusion, corroboration, and operational promotion firewall.

### Evidence Fusion Pipeline
MultiStreamFusionEngine syndicates and corroborates news, social, and remote sensing event signals. ControlledPromotionGate prevents raw unverified OSINT from directly mutating operational RiskMap or forcing hydraulic models.

### Step-by-Step User Workflow
1. Open OSINT Workspace from navigation.
2. Inspect cluster syndication, confidence scores, and source lineage.
3. Authorized reviewers can run promotion verification before operational promotion.

> **SCIENTIFIC & APPLICATION LIMITATIONS**: Raw OSINT remains intelligence evidence, not physical ground truth.

---

## SECTION: HYDROAI 2D HYDRODYNAMICS & HEC-RAS ADAPTER
**Topic ID**: `hydroai_hecras` | **Category**: `hydroAiAndHecRas`
**Scientific Status**: SOFTWARE CONTRACTS & ADAPTER COMPLETE / NATIVE BINARY PENDING

**Summary**: Physics-based 2D hydrodynamic modeling, solver-neutral contracts, and HEC-RAS 2D adapter foundation.

### Solver-Neutral HydroAI Architecture
Contains 20 domain contracts (SimulationConfig, HydrodynamicModelDomain, FloodplainModel, ChannelModel, RoughnessRaster, BoundaryCondition, FloodDepthRaster, VelocityVectorRaster, FloodState, HydrodynamicResult) decoupled from specific solvers.

### HecRasSolverAdapter & Process Controller
Translates SimulationConfig into HEC-RAS 2D project file structures (.prj, .g01, .u01, .p01). Handles background process control, status polling, and GeoTIFF/HDF5 parsing.

### Step-by-Step User Workflow
1. In Research GIS, configure Hydrodynamic Model Domain with governed DEM and precipitation forcing.
2. Execute HydroAI simulation via HecRasSolverAdapter.
3. View output Flood Depth (Max), Peak Velocity, and Water Surface Elevation rasters.

> **SCIENTIFIC & APPLICATION LIMITATIONS**: Native binary execution requires a local Windows installation with RasUnsteady64.exe. Uninstalled machines fall back cleanly to simulated mock execution.

---

## SECTION: SENTINEL-1 SAR 2D INUNDATION VALIDATION & CSI ENGINE
**Topic ID**: `sar_inundation_validation` | **Category**: `sarInundationValidation`
**Scientific Status**: SOFTWARE ENGINE COMPLETE / EMPIRICAL EXPERIMENTS PENDING

**Summary**: Spatial validation framework comparing HydroAI flood depth rasters against Sentinel-1 SAR observations.

### Common Validation Grid Governance
SarInundationValidationEngine enforces explicit grid compatibility (CRS, dimensions, cell size, origin/bounds). Incompatible grids display SPATIAL INCOMPATIBILITY: EXPLICIT HARMONISATION REQUIRED.

### Critical Success Index (CSI)
Calculates spatial confusion matrix cell counts (TP, FP, FN, TN) and metrics: CSI = TP / (TP + FP + FN), POD, FAR, F1, IoU, BIAS, ACC. CSI is an evaluation metric and NOT automatic scientific validation or operational approval.

### Step-by-Step User Workflow
1. In Research GIS, select completed HydrodynamicResult and Sentinel-1 SAR reference record.
2. Supply explicit researcher wetting threshold (depthThresholdMeters, e.g. 0.50m).
3. Run SAR validation and inspect 4-class categorical map overlay (TP: Green, FP: Orange, FN: Red) and HydroaiValidationPanel metrics.

> **SCIENTIFIC & APPLICATION LIMITATIONS**: SAR flood extent is an independent reference, not absolute ground truth.

---

## SECTION: ENVIRONMENTAL HEALTH & DISEASE SPATIAL INTELLIGENCE
**Topic ID**: `environmental_health` | **Category**: `environmentalHealth`
**Scientific Status**: IMPLEMENTED & SOFTWARE-VERIFIED

**Summary**: Guide to spatial research into disease patterns and environmental exposure variables (EH.1-R1 governance).

### Privacy-Safe Aggregated Health Outcomes
Supports 9 health categories (respiratory, cardiovascular, vector-borne, water-borne, renal, neurological, congenital, oncological, other) aggregated at district, block, or grid-cell spatial units. Zero patient PII is exposed.

### EH.1-R1 Statistical Governance & Non-Causality
EnvironmentalHealthService computes Pearson correlation r and Student t-statistic p-value. NO hardcoded p = 0.05 default exists. Derived rasters are explicitly classified as EXPLORATORY EXPOSURE-HEALTH OVERLAY.

### Epidemiological Non-Causality Rule
The UI and domain models explicitly state: "Spatial association identified. Further epidemiological investigation is required. Statistical association does NOT establish causation."

### Step-by-Step User Workflow
1. In Research GIS, open Environmental Health panel.
2. Select Health Outcome Dataset and Environmental Exposure Layer (e.g. Arsenic Groundwater Concentration).
3. Run Spatial Association Analysis to calculate Pearson r and load Exploratory Overlay to map.

> **SCIENTIFIC & APPLICATION LIMITATIONS**: Spatial correlation indicates geographic association ONLY. It does NOT establish clinical diagnosis or medical causation.

---

## SECTION: EXPOSURE & IMPACT ASSESSMENT ENGINES
**Topic ID**: `exposure_and_impact` | **Category**: `exposureAndImpact`
**Scientific Status**: IMPLEMENTED & SOFTWARE-VERIFIED

**Summary**: Asset spatial intersection, population exposure, and physical vulnerability/impact estimation.

### HazardExposureIntersectionEngine
Intersects flood depth rasters, landslide susceptibility zones, and earthquake intensity with building, population, and road infrastructure layers.

### ImpactAssessmentEngine
Calculates physical vulnerability and estimated potential damage while enforcing Stage 3.8-R safeguards (vulnerabilityProfile == null -> impactScore = null).

### Step-by-Step User Workflow
1. Select active hazard or HydroAI flood depth layer.
2. Run Exposure Intersection to calculate affected population and road length.
3. Apply vulnerability profile to estimate potential physical damage.

> **SCIENTIFIC & APPLICATION LIMITATIONS**: Impact estimates represent model-derived potential damage under stated assumptions, NOT observed post-disaster losses.

---

## SECTION: DECISION SUPPORT, SCENARIO ANALYSIS & PRIORITY QUEUE
**Topic ID**: `decision_support` | **Category**: `decisionSupport`
**Scientific Status**: IMPLEMENTED & SOFTWARE-VERIFIED

**Summary**: Evidentiary briefing, risk driver attribution, scenario comparison, and research priority queueing.

### DecisionSupportEngine (3.9.5-v1)
Synthesizes evidentiary briefings, risk driver attribution (rainfall vs susceptibility vs exposure), and scenario comparison without arbitrary weighting.

### ResearchPriorityQueueEngine (3.9.8-v1)
Generates prioritized research task queues sorted by risk urgency, data gaps, and validation requirements.

### Step-by-Step User Workflow
1. In Research GIS, select Decision Support tab.
2. Generate Evidentiary Briefing or compare Baseline vs 95th Percentile Extreme scenarios.
3. Inspect Research Priority Queue for recommended field validation tasks.

> **SCIENTIFIC & APPLICATION LIMITATIONS**: Decision support provides advisory research insights; human decision-makers remain authoritative.

---

## SECTION: PROVENANCE CONTINUITY & RESEARCH PRODUCT REGISTRY
**Topic ID**: `provenance_registry` | **Category**: `provenanceAndRegistry`
**Scientific Status**: IMPLEMENTED & SOFTWARE-VERIFIED

**Summary**: AnalyticalStep lineage, metadata tracking, and 18-product Research Product Registry.

### Provenance Continuity (Stage 4K.8.18)
Every AnalyticalStep in session workflow steps preserves validationRuleVersion (4K.8.12-v1), readinessPolicyVersion (4K.8.14-v1), productContext, valid cell %, NoData %, readiness status, and researcher acknowledgement.

### Research Product Registry (18 Products)
ResearchProductRegistryFactory catalogs 18 products while preserving strict distinction between sourceData != null (software availability) and scientific validation.

### Step-by-Step User Workflow
1. Open Product Registry panel in Research GIS.
2. Inspect product availability, supported export formats, and provenance step names.
3. Click on any product to view detailed analytical step parameters.

> **SCIENTIFIC & APPLICATION LIMITATIONS**: Product availability indicates data object presence in memory, NOT empirical scientific validation.

---

## SECTION: RASTER/VECTOR EXPORT & TROUBLESHOOTING GUIDE
**Topic ID**: `export_troubleshooting` | **Category**: `exportAndTroubleshooting`
**Scientific Status**: IMPLEMENTED & SOFTWARE-VERIFIED

**Summary**: GeoTIFF/GeoJSON export workflows and solutions for common GIS/data errors.

### Raster & Vector Export
RasterExportService exports GeoTIFF rasters and GeoJSON vectors complete with CRS and metadata headers.

### Troubleshooting Common Issues
1. DEM Rejected -> Ensure GeoTIFF overlaps AOI extent.
2. Spatial Incompatibility in SAR Validation -> Ensure model and SAR masks share identical CRS, resolution, and origin.
3. Native HEC-RAS Failure -> Verify RasUnsteady64.exe installation or use mock execution mode.
4. Insufficient Health Data -> Ensure HealthOutcomeDataset has >= 3 valid non-NoData observation pairs.

### Step-by-Step User Workflow
1. In Product Registry or Layer Manager, select product to export.
2. Choose GeoTIFF or GeoJSON format.
3. Click [EXPORT PRODUCT] to save file.

> **SCIENTIFIC & APPLICATION LIMITATIONS**: Exported GeoTIFFs preserve native floating-point pixel values.

---

## SECTION: GLOSSARY & SCIENTIFIC TERMINOLOGY GUIDE
**Topic ID**: `glossary` | **Category**: `glossary`
**Scientific Status**: IMPLEMENTED & SOFTWARE-VERIFIED

**Summary**: Definitive scientific terminology guide for RiskPulse GIS, Remote Sensing, and HydroAI.

### Key Scientific Definitions
• AOI: Area of Interest / Study Area Extent.
• CSI: Critical Success Index = TP / (TP + FP + FN).
• DEM: Digital Elevation Model.
• GLO-30: Copernicus 30m Global Digital Elevation Model.
• HEC-RAS: Hydrologic Engineering Center River Analysis System (2D Hydrodynamics).
• NDVI / NDWI: Normalized Difference Vegetation / Water Index.
• OSINT: Open Source Intelligence.
• Pearson r: Bivariate spatial correlation coefficient.
• SAR: Synthetic Aperture Radar (Sentinel-1).
• WSE: Water Surface Elevation (meters above datum).

> **SCIENTIFIC & APPLICATION LIMITATIONS**: Terminology follows authoritative IUGS, WMO, and Copernicus remote sensing standards.

---

