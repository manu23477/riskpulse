# HPSDMA GAP ANALYSIS — ROUND 5: REAL-WORLD DATASET REGISTER

**Document Identifier**: `HPSDMA_R5_01_DATASET_REGISTER`  
**Workstream**: Real-World Disaster Dataset Register & Provenance Metadata  
**Date**: October 1, 2026  
**Status**: RESEARCH / EXPERIMENTAL VALIDATION ONLY — NO PRODUCTION IMPLEMENTATION  

---

## 1. REAL-WORLD DATASET INVENTORY (RW-01 THROUGH RW-07)

| Dataset ID | Source Authority | Document Title / Subject | Status Label | Format | Spatial Reference / CRS | Temporal Resolution | Source URL / Publisher |
| :---: | :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| **`RW-01`** | HPSDMA / Revenue Dept | Himachal Pradesh Daily Loss & Damage Incident Reports | **`[OFFICIAL]`** | CSV / GeoJSON | District/Block Polygons (EPSG:4326) | Daily ($t_{\text{report}}$) | `https://hpsdma.hp.gov.in/loss_reports` |
| **`RW-02`** | Central Water Commission (CWC) | Himachal Pradesh River Basin Telemetry & Gauge Readings | **`[PUBLIC DATA]`** | CSV / REST API | Station Points (EPSG:4326) | Hourly ($t_{\text{observed}}$) | `https://cwc.gov.in/telemetry/hp` |
| **`RW-03`** | India Meteorological Dept (IMD) | Gridded Daily Rainfall & Automatic Weather Stations | **`[PUBLIC DATA]`** | NetCDF / CSV | $0.25^\circ \times 0.25^\circ$ Grid (EPSG:4326) | Hourly / Daily | `https://mausam.imd.gov.in/data` |
| **`RW-04`** | ISRO Bhuvan / Copernicus | Glacial Lake Inundation & Landslide Water Change Mask | **`[PUBLIC DATA]`** | GeoTIFF / KML | WGS84 Universal Transverse Mercator (EPSG:32643) | Per-pass ($t_{\text{pass}}$) | `https://bhuvan.nrsc.gov.in/disaster` |
| **`RW-05`** | Survey of India / HP Revenue | Official HP Revenue District & Tehsil/Block Boundaries | **`[OFFICIAL]`** | Shapefile / GeoJSON | WGS84 Geographic (EPSG:4326) | Annual Version | `https://hp.gov.in/gis/boundaries` |
| **`RW-06`** | HP Public Works Dept (PWD) | Critical Road & Bridge Assets (NH-21 / NH-05 Corridors) | **`[PUBLIC DATA]`** | GeoJSON / Line | Vector Line Corridors | Quarterly Update | `https://hppwd.hp.gov.in/assets` |
| **`RW-07`** | Representative Public OSINT | Social Media Emergency Alerts & Field Photo Logs | **`[PUBLICLY REPRESENTATIVE]`** | JSON / Text | Text Place Names / Geo-tags | Real-Time Stream | `https://riskpulse.io/research/osint` |

---

## 2. PROVENANCE & LICENSE COMPLIANCE

All 7 datasets were accessed between August 2026 and September 2026 from official public portals under open government data licenses or public research access terms. Original raw files are preserved unaltered in `datasets/raw/` with SHA-256 checksums recorded in `03_RAW_DATA_MANIFEST.md`.
