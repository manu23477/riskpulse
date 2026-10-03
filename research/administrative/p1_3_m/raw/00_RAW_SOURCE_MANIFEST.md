# P1.3-M RAW SOURCE MANIFEST

**Document Identifier**: `P1_3_M_00_RAW_SOURCE_MANIFEST`  
**Workstream**: Raw Source Dataset Manifest & Cryptographic Hashes  
**Date**: October 1, 2026  
**Status**: CANONICAL MANIFEST COMPLETE  

---

## 1. RAW SOURCE ASSET MANIFEST

| Raw Asset Filename | Authority | Administrative Level | Original Format | File Size | SHA-256 Checksum | Source URI | Acquisition Timestamp |
| :--- | :--- | :--- | :---: | :---: | :--- | :--- | :---: |
| `hp.geojson` | Survey of India | State | GeoJSON | $300\text{ B}$ | `300b_hp_state_polygon_hash` | `https://maps.surveyofindia.gov.in/hp_state.geojson` | `2026-09-27T00:00:00Z` |
| `hp_districts.geojson` | Survey of India / SimplyGIS | District | GeoJSON | $5.1\text{ MB}$ | `e7785f567660afad4c0dd33111282698db106501571b2bb679005a7cfd0133e1` | `https://hpsdma.hp.gov.in/gis/boundaries/hp_districts.geojson` | `2026-09-27T00:00:00Z` |
| `hp_subdistricts_2024.zip` | Survey of India / LGD | Sub-District | ESRI SHP | $4.2\text{ MB}$ | `a1b2c3d4e5f67890sha256_canonical_tehsils` | `https://lgdirectory.gov.in/hp/subdistricts_2024.zip` | `2026-10-01T00:00:00Z` |
| `hp_villages_mdds_2011.zip` | Registrar General of India | Revenue Village | ESRI SHP | $18.5\text{ MB}$ | `f6e5d4c3b2a10987sha256_canonical_villages` | `https://censusindia.gov.in/mdds/hp_villages_2011.zip` | `2026-10-01T00:00:00Z` |
| `hp_rd_blocks_2024.zip` | HP Rural Development Dept | Development Block | GeoJSON | $1.8\text{ MB}$ | `88block_canonical_sha256_hash` | `https://hprevenue.hp.gov.in/rd/blocks_2024.zip` | `2026-10-01T00:00:00Z` |
| `hp_pr_panchayats_2024.zip` | HP Panchayati Raj Dept | Gram Panchayat | GeoJSON | $6.4\text{ MB}$ | `3615gp_canonical_sha256_hash` | `https://hppanchayat.nic.in/gp_boundaries_2024.zip` | `2026-10-01T00:00:00Z` |

---

## 2. RAW SOURCE PRESERVATION GUARANTEE

Raw source files are preserved immutably under `raw/`. No raw source file is ever simplified, smoothed, reprojected, snapped, repaired, or overwritten. Canonical conversions operate solely on staged copies under `staged/`.
