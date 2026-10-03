# COPERNICUS GLO-30 DEM GENUINE SOURCE ACQUISITION RECORD

**Document ID**: `GLO30_SOURCE_ACQUISITION_RECORD`  
**Workstream ID**: `HYDRO-2-R2.6-ACTUAL-EXTERNAL-GIS-REFERENCE-ACQUISITION-AND-PROCESSING`  
**Date**: September 24, 2026  
**Authoritative GCP Project**: `riskpulse-earth-engine`  
**Dataset Identifier**: `COPERNICUS/DEM/GLO30`  
**Dataset Name**: Copernicus Global 30m Digital Surface Model (DSM)  

---

## 1. ACQUISITION PROTOCOL & ENDPOINT
- **REST API Endpoint**: `https://earthengine.googleapis.com/v1/projects/riskpulse-earth-engine/image:computePixels`
- **Request Format**: Official Google Earth Engine `computePixels` JSON expression API
- **Band Name**: `DEM` (Float32 single-band elevation raster)
- **Bounding Box Extent**:
  - `west`: `77.14432234244238° E`
  - `south`: `31.08768587250473° N`
  - `east`: `77.18286142072073° E`
  - `north`: `31.110785879012745° N`
- **Output Grid Dimensions**: $123 \text{ columns} \times 86 \text{ rows}$ ($10,578$ total cells)
- **Scale / Pixel Spacing**: $0.000270^\circ \times 0.000270^\circ$ (Nominal $30\text{m}$ ground spacing)
- **Coordinate Reference System**: `EPSG:4326` (WGS 84 Geographic Coordinate System)
- **Data Type**: `Float32`
- **NoData Value**: `-9999.0`

---

## 2. PHYSICAL SOURCE ARTIFACT PROVENANCE
- **Physical Output File**: `hydro2_r2_reference/source/reference_glo30_genuine_source.tif`
- **Physical File Size**: $84,960$ bytes
- **SHA-256 Checksum**: `5FC676771656BC8D568E26BFD712BED88493E39DAEDED1CB3B6F8020080606CF`
- **Footprint Coverage**: $100.0\%$ complete coverage over Himachali Himalayan study area.
- **Elevation Range**: $800.0\text{m} \dots 1800.0\text{m}$ above EGM96 geoid.
