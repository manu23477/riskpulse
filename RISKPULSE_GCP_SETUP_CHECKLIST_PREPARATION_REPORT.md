# RISKPULSE GCP SETUP CHECKLIST PREPARATION REPORT

**Document ID**: `RISKPULSE_GCP_SETUP_CHECKLIST_PREPARATION_REPORT`  
**Date**: September 21, 2026  
**Workstream**: RiskPulse GCP Infrastructure Setup Checklist Preparation  
**Mode**: **READ-ONLY / NO CODE CHANGES / NO CREDENTIALS / NO DEPLOYMENTS / NO COMMITS / NO PUSHES**  
**Git HEAD**: `0b67a685aeb7926f123cf642df11bb14c8e968bd`  
**Branch**: `main`  
**Master Test Suite**: **348 / 348 Passed GREEN** (100% Pass Rate across 41 test files)  
**Flutter Analyzer**: **0 Errors, 0 Warnings** on core application code  

---

## 1. READ-ONLY MANDATE & AUDIT DECLARATION
This document is a factual, step-by-step infrastructure preparation checklist and specification report.
- **ZERO** code changes executed.
- **ZERO** credentials, API keys, or private keyfiles created or downloaded.
- **ZERO** cloud resources deployed.
- **ZERO** Git commits or pushes executed.
- **ZERO** changes to the operational RiskMap dataset (168 features intact, Kotropi 2017 anchor preserved).

---

## 2. FACTUAL GCP CONTEXT & OBSERVED STATE
The Project Owner's (Manu) Google Cloud Console was physically inspected. The active project inventory consists of:
1. `Manu Academy` (`manu-academy`)
2. `My First Project` (`promising-env-463513-g0`)
3. `My First Project` (`steel-minutia-386704`)

**CRITICAL FINDING**: There is currently **NO** project named `riskpulse-ee-project` in Manu's GCP Console. References to `riskpulse-ee-project` in client source code are unverified string literals. A dedicated Google Cloud project must be created before live GEE integration can proceed.

---

## 3. STEP-BY-STEP GCP INFRASTRUCTURE SETUP CHECKLIST

### Step 1: Dedicated RiskPulse Google Cloud Project
- **Proposed Project Name**: `RiskPulse Earth Engine`
- **Proposed Project ID**: `riskpulse-ee-project`
- **ID Availability Verification**: During project creation in GCP Console, check if `riskpulse-ee-project` is globally available. If unavailable, use `riskpulse-ee-prod` or `riskpulse-earth-engine`.
- **Architectural Justification for Isolation**: A separate GCP project isolates Earth Engine quota, billing, IAM service accounts, and API access from personal/academic projects (`manu-academy`).

### Step 2: Billing Account Association
- **Requirement**: Google Earth Engine REST API requires an active GCP Billing Account associated with the project to manage compute quotas (EECUs).
- **Required Action**: Verify or link a GCP Billing Account to the newly created RiskPulse project in GCP Console (`Navigation Menu -> Billing`).
- **Cost Protection**: Set budget alerts ($0 threshold / free tier alert) in GCP Billing.

### Step 3: Google Earth Engine Onboarding & Project Registration
- **Registration Site**: [Google Earth Engine Signup / Project Registration](https://earthengine.google.com/signup/)
- **Association**: Register the dedicated GCP project ID (`riskpulse-ee-project`) for Earth Engine access.
- **Access Type**: Select non-commercial / academic research project or commercial as applicable.
- **Confirmation**: Verify that Earth Engine registration approval is granted in GCP Console.

### Step 4: Required Google Cloud APIs Enablement
Enable the following APIs in GCP Console (`APIs & Services -> Library`):
1. **Earth Engine API** (`earthengine.googleapis.com`): *Required for image:computePixels REST calls*.
2. **Cloud Resource Manager API** (`cloudresourcemanager.googleapis.com`): *Required for IAM role resolution*.
3. **Secret Manager API** (`secretmanager.googleapis.com`): *Required for secure server-side key management*.
4. **IAM Service Account API** (`iam.googleapis.com`): *Required for service identity management*.

---

## 4. SECURE AUTHENTICATION & SERVICE IDENTITY ARCHITECTURE

### Production Target Architecture:
$$\text{Flutter Web Client (Chrome)} \longrightarrow \text{RiskPulse Backend Proxy} \longrightarrow \text{Google Auth (Workload Identity)} \longrightarrow \text{Earth Engine REST API} \longrightarrow \text{GeoTIFF Bytes} \longrightarrow \text{Research GIS Studio}$$

### Security Invariants:
- **Zero Client-Side Secret Leakage**: The Flutter Web JS bundle must **NEVER** receive, store, or embed GCP service account private keys (`.json` keyfiles), long-lived tokens, or API secrets.
- **Service Identity Approach**:
  - **Preferred (Cloud Run / GKE)**: **GCP Workload Identity / Managed Service Identity**. This approach uses dynamic IAM metadata tokens and avoids creating or downloading static `.json` keyfiles.
  - **Fallback**: Server-side service account stored in server environment variables or GCP Secret Manager.
  - **Unverified Identity Warning**: The previously referenced email `riskpulse-ee-service@riskpulse-ee-project.iam.gserviceaccount.com` is strictly an unverified example and does NOT currently exist.

---

## 5. BACKEND PROXY & DOMAIN CONFIGURATION

### Backend Infrastructure Decisions Required Before Deployment:
1. **Hosting Provider**: Select backend compute platform (e.g., GCP Cloud Run, AWS ECS, DigitalOcean, or private VPS).
2. **Backend Repository**: Confirm backend source code repository location.
3. **Production Web Domain**: Specify official web origin for CORS policies (e.g., `https://app.riskpulse.org`).
4. **`api.riskpulse.org` Domain & DNS**:
   - Status remains: **`NOT VERIFIED`**
   - Configure DNS A/AAAA records for `api.riskpulse.org` pointing to the backend proxy IP.
   - Install TLS 1.3 HTTPS certificate.

### GEE Proxy Endpoint Specification (`POST /v1/gee/computePixels`):
- **Authentication**: Validates incoming RiskPulse session token (`Authorization: Bearer $sessionToken`).
- **SSRF & Allowlist Guard**: Enforces explicit parameter allowlist:
  - Allowed Project IDs: `['riskpulse-ee-project']`
  - Allowed Asset IDs: `['COPERNICUS/DEM/GLO30', 'COPERNICUS/S2_SR_HARMONIZED']`
  - Allowed Bands: `['DEM', 'B2', 'B3', 'B4', 'B8', 'B11', 'B12']`
  - Allowed Output Formats: `['GEO_TIFF']`
- **Memory & Grid Limits**: Enforces max $2500 \times 2500$ cells ($6.25 \times 10^6$ cells max).
- **Dynamic Grid Calculation**: $30\text{m}$ cell scale and affine transforms ($scaleX, scaleY, translateX, translateY$) must be calculated dynamically for each AOI bounding box and latitudinal position.
- **Response**: Streams raw GeoTIFF payload directly back to client with HTTP 200.

---

## 6. GEOTIFF SCIENTIFIC INTEGRITY & ACCEPTANCE TEST WORKFLOW

### GeoTIFF Validation Invariants:
Upon receiving GLO-30 bytes, the client `GeoTiffReader` verifies:
- TIFF Magic Bytes (`0x49492A00` or `0x4D4D002A`)
- 32-bit Floating Point (`Float32`) format
- `ModelPixelScaleTag` and `ModelTiepointTag`
- CRS: `EPSG:4326`
- NoData Tag: `GDAL_NODATA=-9999`
- **Zero Synthetic DEM Fallback**: On fetch failure, `ResearchWorkspaceProvider.inputDem` remains `null`.

### Research GIS Studio Acceptance Sequence:
```
User configures AOI
       │
       ▼
RiskPulse Web requests GLO-30 DEM
       │
       ▼
Secure Backend Proxy authenticates to Earth Engine
       │
       ▼
Earth Engine REST API returns genuine GLO-30 GeoTIFF
       │
       ▼
Client validates GeoTIFF magic bytes & EPSG:4326 grid
       │
       ▼
DEM becomes AVAILABLE in Research Products Panel
       │
       ▼
Downstream Research Products (Slope, Aspect, Hillshade, D8, Watershed, HydroAI) become testable
```

---

## 7. DOWNSTREAM MODULE SYSTEM GATE STATUSES

The following modules remain strictly **`BLOCKED`** until genuine GLO-30 DEM acquisition is validated:
- D8 Flow Direction
- Flow Accumulation
- Stream Extraction Raster
- Strahler Stream Order
- Shreve Stream Magnitude
- Drainage Network Topology
- Watershed Boundary Polygon
- Sub-watersheds
- Pour Point Outlet Snapping
- Quantitative Morphometric Indices
- HydroAI Flood Depth
- Sentinel-2 Surface Reflectance (`BLOCKED — GEE Auth unavailable`)
- Sentinel-1 SAR Validation (`BLOCKED — SAR rasters unconfigured`)
- Environmental Health Exposure Overlay (`BLOCKED — spatial layers unconfigured`)

---

## 8. CURRENT SCIENTIFIC STATUS INVARIANTS

- **Authoritative System Classification**: `SOFTWARE-VERIFIED RESEARCH SYSTEM WITH DOCUMENTED SCIENTIFIC LIMITATIONS`
- **Research Release Status**: `RESEARCH_RELEASE_READY_WITH_DOCUMENTED_LIMITATIONS`
- **Operational Promotion Status**: `OPERATIONAL_PROMOTION_NOT_ELIGIBLE`
- **Automated Master Test Suite**: **348 / 348 Passed GREEN** (100% Pass Rate across 41 test files)
- **Flutter Analyzer**: **0 Errors, 0 Warnings** on core application code
- **Operational RiskMap Baseline**: **168 operational features intact** (163 Points, 5 Polygons)
- **Protected Anchor**: `ls-hp-mandi-kotropi-2017` verified intact in `risk_map_baseline.json`
- **ControlledPromotionGate**: Active (`lib/data/services/osint/controlled_promotion_gate.dart`)

*Note: Automated unit tests passing (348/348) proves software contract compilation, NOT live GEE access or empirical scientific calibration.*

---

## 9. CONCISE INFRASTRUCTURE DECISION CHECKLIST

| Infrastructure Item | Current Status | Who Must Act | Next Verification Step |
| :--- | :---: | :---: | :--- |
| **Google Cloud Account** | **VERIFIED** | Manu | Account physically verified |
| **Dedicated RiskPulse GCP Project** | **NOT YET CREATED** | Manu | Create project `riskpulse-ee-project` in GCP Console |
| **Project ID Availability** | **NOT VERIFIED** | Manu | Check ID `riskpulse-ee-project` availability during creation |
| **GCP Billing Account** | **NOT LINKED** | Manu | Link Billing Account to `riskpulse-ee-project` |
| **Earth Engine Registration** | **NOT REGISTERED** | Manu | Register `riskpulse-ee-project` at earthengine.google.com/signup |
| **Earth Engine API Enablement** | **NOT ENABLED** | Manu | Enable `earthengine.googleapis.com` in GCP API Library |
| **Service Identity / Workload Identity** | **NOT CREATED** | Manu | Create Service Account / Workload Identity in GCP IAM |
| **Secret Management** | **NOT CONFIGURATION** | Manu | Store GCP Service Account key in server secret manager |
| **Backend Codebase & Repository** | **NOT FOUND** | Manu | Provide backend repo location or authorize backend creation |
| **Backend Hosting Provider** | **NOT VERIFIED** | Manu | Select hosting provider (e.g. GCP Cloud Run, AWS, VPS) |
| **`api.riskpulse.org` Domain** | **NOT VERIFIED** | Manu | Confirm domain ownership and configure DNS records |
| **DNS A/AAAA Records** | **NOT CONFIGURED** | Manu | Point `api.riskpulse.org` to backend proxy server IP |
| **Authentication Middleware** | **NOT IMPLEMENTED** | Backend Developer | Implement session token authentication on proxy |
| **CORS Configuration** | **NOT CONFIGURED** | Backend Developer | Restrict CORS to `https://app.riskpulse.org` & local dev origin |
| **GEE Proxy Endpoint (`/v1/gee/`)** | **NOT IMPLEMENTED** | Backend Developer | Implement `POST /v1/gee/computePixels` REST proxy route |
| **Flutter Client Integration** | **NOT CONNECTED** | Flutter Developer | Connect `GeeClient` to `geeProxyEndpoint` |
| **Physical Web Runtime Test** | **BLOCKED** | Tester / Manu | Run RiskPulse Web at `localhost:51997` |
| **GLO-30 Acceptance Test** | **BLOCKED** | Tester / Manu | Verify GLO-30 GeoTIFF received & attached to workspace |

---

## 10. DECISION STATEMENT

```
CURRENT DECISION:
GCP INFRASTRUCTURE PREPARATION REQUIRED BEFORE LIVE GEE RUNTIME VALIDATION
```

---

```
============================================================
RISKPULSE GCP SETUP CHECKLIST PREPARATION REPORT COMPLETE
REPORT FILE: RISKPULSE_GCP_SETUP_CHECKLIST_PREPARATION_REPORT.md
MODE: READ-ONLY / NO CODE CHANGES / NO CREDENTIALS / NO DEPLOYMENTS / NO COMMITS / NO PUSHES
TESTS PASSED: 348 / 348 (100% GREEN)
FLUTTER ANALYZER: 0 ERRORS, 0 WARNINGS
OPERATIONAL BASELINE: 168 FEATURES INTACT (Kotropi preserved)

STOPPING WORK NOW.
AWAITING MANU'S REVIEW AND GCP INFRASTRUCTURE CREATION IN GCP CONSOLE.
============================================================
```
