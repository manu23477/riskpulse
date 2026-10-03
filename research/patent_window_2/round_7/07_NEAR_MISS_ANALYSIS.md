# PATENT WINDOW 2 — ROUND 7: NEAR-MISS ANALYSIS

**Document Identifier**: `PW2R7_07_NEAR_MISS_ANALYSIS`  
**Workstream**: In-Depth Forensic Analysis of Top Near-Miss Candidates  
**Date**: October 1, 2026  
**Status**: RESEARCH ONLY — NEAR-MISS FORENSIC ANALYSIS  

---

## 1. TOP NEAR-MISS CANDIDATE EVALUATION

### 1. Near Miss #1: `US10036650B2` (ESRI - Hazard Graph Traversal)
- **What it Discloses**: Spatial hazard mapping, graph node traversal for downstream risk overlays, and static risk score assignment.
- **Which K-Components Covered**: K02, K04, partial K08, K09.
- **Which Critical Relationships Missing**: R01 (RS Mutation Ingestion), R06/R12 (Bitemporal Versioning), R16/R10 (Dynamic Topology Mutation & Downstream Recalculation).
- **Technical Significance**: ESRI describes static or batch-recomputed hazard graphs. It lacks remote-sensing observation mutation triggers and bitemporal state history ($V_1..V_k$).

### 2. Near Miss #2: `US8548248B2` (DigitalGlobe - Satellite Feature Extraction)
- **What it Discloses**: Automated satellite imagery classification, feature extraction, and land-use polygon boundary generation.
- **Which K-Components Covered**: K01, K02.
- **Which Critical Relationships Missing**: R02/R03 (Admin Crosswalk & Risk Scoring), R10/R11 (Shared Admin/Risk DAG Recalculation), R06 (Historical Versioning).
- **Technical Significance**: DigitalGlobe focuses on raster image processing and vector boundary generation. It lacks administrative unit crosswalk propagation, composite risk scoring, and state versioning.

### 3. Near Miss #3: `US7441230B2` (Microsoft - Build Proxy Dependency Graph)
- **What it Discloses**: Dependency graph invalidation, shared node recalculation, dynamic edge redirection, and branch isolation.
- **Which K-Components Covered**: K05, K08, K09, K10.
- **Which Critical Relationships Missing**: R01 (RS Mutation), R02 (Geospatial Spatial Closure), R03 (Admin Crosswalk), R04 (Hazard Scoring).
- **Technical Significance**: Microsoft describes software compilation dependency graphs (`.c` $\rightarrow$ `.obj` $\rightarrow$ `.exe`). It lacks geospatial spatial models, administrative unit crosswalks, or remote-sensing observation semantics.

### 4. Near Miss #4: `CN120808164B` (Chengdu Univ of Tech - Geological Hazard RS Warning)
- **What it Discloses**: Satellite radar/optical landslide monitoring, terrain change detection, and early warning alert levels.
- **Which K-Components Covered**: K01, K02, K04.
- **Which Critical Relationships Missing**: R08 (Full Pipeline Propagation), R10/R11 (Shared Node Recalculation), R06 (Bitemporal History), R16 (Topology Mutation).
- **Technical Significance**: Chengdu describes sensor/satellite threshold alerts. It lacks transitive 6-layer DAG dependency closure calculations or bitemporal historical versioning ($V_1..V_k$).
