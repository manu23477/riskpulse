# RiskPulse: An Integrated Research Software Architecture for Multi-Hazard Evidence Governance, Remote Sensing, and Decision Support in Mountainous Terrain

**Author**: Kuldeep Singh
**Affiliation**: Faculty, Department of Interdisciplinary Studies, Himachal Pradesh University, Shimla, Himachal Pradesh, India
**Corresponding Email**: kuldeepsinghiihs@gmail.com | **Phone**: +91 7018431329

---

## ABSTRACT
We present RiskPulse, a software-verified research software architecture designed for multi-hazard disaster risk intelligence, evidence provenance tracking, and decision support in Himachal Pradesh, India. RiskPulse integrates local DEM terrain processing, Sentinel-2 spectral indices, multi-stream OSINT fusion, solver-neutral hydrodynamic adapters, and evidentiary briefing synthesis into a unified, traceable research environment. Crucially, RiskPulse enforces strict research-to-operational separation via a Controlled Promotion Gate. Within the audited software scope (348/348 tests passed GREEN, 0 Flutter analyzer errors), deterministic computational pathways and software contracts are fully verified. We document the uncalibrated global reference status of the Caine landslide threshold (I = 14.82 * D^-0.39) and Rational flood model (C=0.65), explicitly distinguishing software verification from empirical scientific validation.

**KEYWORDS**: Geomatics; Natural Hazards; Remote Sensing; Disaster Risk Intelligence; Evidence Provenance; Himachal Pradesh.

---

## 1. INTRODUCTION & RESEARCH GAP
Disaster risk management in high-relief mountain catchments requires synthesizing disparate hydrometeorological observations, satellite remote sensing, and crowd-sourced incident reports. In high-relief regions such as the Indian Himalayas, data fragmentation and unverified model parameters often compromise operational warnings. RiskPulse addresses this architectural challenge by coupling multi-source evidence acquisition with deterministic calculation engines, explicit provenance tracking, and a Controlled Promotion Gate.

## 2. MATERIALS AND SYSTEM ARCHITECTURE
### 2.1 Copernicus GLO-30 DEM Processing & Hydrological Conditioning
Processing incorporates local 30m GeoTIFF rasters in EPSG:4326. D8 flow direction, Planchon-Darboux depression filling, Strahler/Shreve stream ordering, and watershed delineation operate deterministically in memory.

### 2.2 Sentinel-2 Multispectral Processing
Bands B2, B3, B4, and B8 (10m spatial resolution) apply ESA L2A reflectance scaling (0.0001) to compute NDVI and NDWI with zero-denominator safeguards.

### 2.3 OSINT Multi-Stream Evidence Fusion
Multi-stream incident reports apply spatial proximity (<100m) and Jaccard text similarity (>0.80) for evidence corroboration.

### 2.4 HydroAI Solver-Neutral Adapter
HydroAI couples terrain grids and hydrograph inputs to 2D hydrodynamic solvers. In the absence of native RasUnsteady64.exe, the engine executes via a software-verified simulated fallback mode (simulatedMock).

## 3. ANALYTICAL HAZARD MODELS & DECISION SUPPORT
### 3.1 Caine Landslide Threshold Model
Global power-law relationship I = 14.82 * D^-0.39 (alpha = 14.82, beta = -0.39) is preserved as an uncalibrated global reference profile. Current project-defined calibration-readiness target is n_caine_target >= 10 complete event pairs.

### 3.2 Rational Method Peak Discharge Model
Peak runoff Q = (C * i * A) / 3.6 applies an uncalibrated default runoff coefficient C = 0.65. Current project-defined hydrograph-readiness target is n_hydro_target >= 5 continuous 15-minute event hydrographs.

### 3.3 SAR 2D Inundation Validation Framework
Dual-polarization Sentinel-1 GRD backscatter thresholding (-14dB) and spatial confusion matrix calculation are software-verified; real SAR validation rasters (n_sar = 0) remain uningested.

### 3.4 Relative Priority Decision Support Index
Analytical briefing synthesis computes a relative priority rank (0.0 ... 1.0) based on weighted evidence inputs. The priority index represents relative analytical priority, NOT an event occurrence probability.

## 4. SOFTWARE VERIFICATION & EVIDENCE RESULTS
All computational pathways passed 348/348 automated unit and integration tests. Five exploratory landslide events (Kotropi, Nigulsari, Batseri, Boh, Summer Hill) demonstrate a descriptive mean observed-to-reference ratio of 1.340 against the global Caine curve.

## 5. SCIENTIFIC LIMITATIONS & FUTURE VALIDATION ROADMAP
Model parameters remain uncalibrated for regional terrain. Empirical hold-out validation datasets (n_val = 0, n_hydro = 0, n_sar = 0) remain incomplete. Native HEC-RAS execution and live GEE tile streaming remain unverified. Sample-size targets (n_caine_target >= 10, n_hydro_target >= 5, n_val_target >= 5) are project-defined workflow readiness targets, NOT universal scientific minimums.

## 6. DISCUSSION, ETHICS & CONCLUSIONS
RiskPulse establishes a software-verified research software framework with transparent limitation disclosure and strict research-to-operational isolation enforced by a Controlled Promotion Gate.