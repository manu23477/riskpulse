# P1.6 FORENSIC HAZARD LAYER INVENTORY REPORT

**Document Identifier**: `P1_6_HAZARD_LAYER_FORENSIC_INVENTORY`  
**Workstream**: Forensic Inventory of Existing Physical Hazard Asset Layers  
**Date**: October 1, 2026  
**Status**: COMPLETED FORENSIC INVENTORY  

---

## 1. INVENTORY OF EXISTING HAZARD ASSETS & PRODUCTS

| Hazard Category | Asset File Path | File Size | Geometry Type | Feature Count | Attribute Schema | Spatial Extent |
| :--- | :--- | :---: | :---: | :---: | :--- | :--- |
| **Landslide** | `lib/data/assets/hazards/landslide.geojson` | $24.2\text{ KB}$ | `MultiPolygon` | 18 | `id`, `name`, `category`, `intensity` | Mandi, Kangra, Kullu, Shimla |
| **Landslide Polygons** | `lib/data/assets/hazards/major_landslides_polygons.geojson` | $4.4\text{ KB}$ | `Polygon` | 5 | `id`, `name`, `areaSqKm`, `riskLevel` | Kotropi, Urla, Hanogi, Aut, Pandoh |
| **Kotropi Anchor** | `lib/data/assets/hazards/kotropi_polygon.geojson` | $1.0\text{ KB}$ | `Polygon` | 1 | `id`, `name`, `eventDate`, `volumeM3` | Kotropi Landslide 2017 Anchor |
| **Cloudburst** | `lib/data/assets/hazards/cloudburst.geojson` | $24.0\text{ KB}$ | `Polygon` | 12 | `id`, `name`, `intensityMmHr`, `date` | Kullu, Mandi, Shimla, Chamba |
| **Flood** | `lib/data/assets/hazards/flood.geojson` | $24.1\text{ KB}$ | `Polygon` | 15 | `id`, `name`, `depthMeters`, `riverName` | Beas River, Sutlej River, Ravi River |
| **GLOF** | `lib/data/assets/hazards/glof.geojson` | $5.6\text{ KB}$ | `Polygon` | 4 | `id`, `lakeName`, `volumeM3`, `risk` | Lahaul & Spiti, Kinnaur Glacial Lakes |
| **Earthquake** | `lib/data/assets/hazards/earthquake.geojson` | $9.9\text{ KB}$ | `Polygon` | 8 | `id`, `magnitude`, `intensityMMI` | Kangra, Mandi Isoseismal Zones |
| **Avalanche** | `lib/data/assets/hazards/avalanche.geojson` | $9.7\text{ KB}$ | `Polygon` | 6 | `id`, `pathName`, `snowDepthCm` | Lahaul & Spiti, Kullu Pass Chutes |
| **Forest Fire** | `lib/data/assets/hazards/forest_fire.geojson` | $1.1\text{ KB}$ | `Polygon` | 3 | `id`, `fireName`, `burnedAreaHa` | Solan, Sirmaur, Bilaspur Forests |

---

## 2. INTEGRATION SUMMARY

All 9 existing physical hazard asset layers across 7 primary categories are 100% catalogued and supported by `HazardAdministrativeAttributionService`.
