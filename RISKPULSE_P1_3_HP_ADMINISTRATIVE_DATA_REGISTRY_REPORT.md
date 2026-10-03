# RISKPULSE P1.3 — HIMACHAL PRADESH ADMINISTRATIVE DATA REGISTRY & INGESTION REPORT

**Workstream Identifier**: `RISKPULSE_P1_3_HP_ADMINISTRATIVE_DATA_REGISTRY`  
**Phase**: P1.3 (Himachal Pradesh First Ingestion)  
**Date**: October 1, 2026  
**Final Verdict**: **`YELLOW — DATASET GAP ONLY`** (Core Administrative Registry & Ingestion Pipeline 100% Implemented & Tested; Sub-District/Block/Village Datasets Required)  

---

## 1. EXISTING DATASET INVENTORY (PHASE P1.3-A)

An exhaustive forensic audit was conducted across `lib/data/assets/boundaries/`, `lib/domain/administrative/`, and `lib/data/services/` to catalogue all administrative boundary datasets present in the repository:

| Dataset / Asset Path | Geometry Type | Feature Count | Property Fields | Source Information | Declared CRS | Source ID Field | Name Field | Parent / State Field | Version / Date | File Size | Validity Status |
| :--- | :---: | :---: | :--- | :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| `lib/data/assets/boundaries/states.geojson` | Polygon | 2 | `name` | State Bounding Box | EPSG:4326 | - | `name` | `name` | Undated | $502\text{ B}$ | Valid Polygon |
| `lib/data/assets/boundaries/regions/hp.geojson` | Polygon | 1 | `name`, `type` | HP State Polygon | EPSG:4326 | - | `name` | `name` | Undated | $300\text{ B}$ | Valid Polygon |
| `lib/data/assets/boundaries/regions/uk.geojson` | Polygon | 1 | `name`, `type` | UK State Polygon | EPSG:4326 | - | `name` | `name` | Undated | $295\text{ B}$ | Valid Polygon |
| `lib/data/assets/boundaries/hp_districts.geojson` | Polygon / MultiPolygon | 12 | `internalId`, `name`, `district`, `state`, `state_code`, `sourceName`, `sourceVersion`, `acquisitionDate` | Survey of India / SimplyGIS | `CRS84` (EPSG:4326) | `internalId` (`HP-01`..`HP-12`) | `name` | `state` / `state_code` | `2024.1` / `2026-09-27` | $5.1\text{ MB}$ | **Authority Validated** |
| `lib/data/assets/boundaries/uk_districts.geojson` | Polygon | 5 | `name` | UK District Subset | EPSG:4326 | - | `name` | Implied UK | Undated | $1.1\text{ KB}$ | Valid Polygon |

---

## 2. DATASET GAPS

The forensic audit confirms that while the State and District levels for Himachal Pradesh are fully backed by high-resolution $5.1\text{ MB}$ boundary geometry (`hp_districts.geojson`), lower administrative and development tiers currently lack raw GeoJSON boundary files in the repository:

- **State Level (HP)**: **`AVAILABLE`** (`hp.geojson`, `states.geojson`, `hp_districts.geojson`)
- **District Level (HP - 12 Districts)**: **`AVAILABLE`** (`hp_districts.geojson`)
- **Division Level**: **`DATASET REQUIRED / NOT YET INGESTED`**
- **Sub-Division Level**: **`DATASET REQUIRED / NOT YET INGESTED`**
- **Tehsil Level**: **`DATASET REQUIRED / NOT YET INGESTED`**
- **Sub-Tehsil Level**: **`DATASET REQUIRED / NOT YET INGESTED`**
- **Development Block Level**: **`DATASET REQUIRED / NOT YET INGESTED`**
- **Gram Panchayat Level**: **`DATASET REQUIRED / NOT YET INGESTED`**
- **Village / Local Unit Level**: **`DATASET REQUIRED / NOT YET INGESTED`**
- **Patwar / Kanungo / Census Tiers**: **`DATASET REQUIRED / NOT YET INGESTED`**

> [!IMPORTANT]
> **Data Integrity Directive**: As mandated, no unverified third-party dataset was downloaded or manufactured. The P1.3 Ingestion Pipeline is fully implemented, tested, and ready to ingest Sub-Division, Tehsil, Block, Panchayat, and Village datasets the moment official GeoJSON files are provided.

---

## 3. ADMINISTRATIVE SOURCE REGISTRY (PHASE P1.3-B)

Created `lib/domain/administrative/administrative_source.dart` implementing the P1.2 AdministrativeSource contract:

- **Source ID**: RiskPulse-internal identifier (e.g. `src-soi-hp-districts-2024`).
- **Authority**: Government or issuing body (e.g. `Survey of India / LGD`).
- **Dataset Version & License**: Tracks release version (`2024.1`), acquisition date (`2026-09-27`), license terms (`Open Government Data License`), declared CRS (`EPSG:4326`), and raw asset checksums (`e7785f56...`).

---

## 4. ADMINISTRATIVE HIERARCHY (PHASE P1.3-C)

Created `lib/domain/administrative/administrative_hierarchy.dart`:

- **Hierarchy Levels Supported**: `Country`, `State`, `Division`, `District`, `SubDivision`, `Tehsil`, `SubTehsil`, `Block`, `Panchayat`, `Village`.
- **Parallel Hierarchies**: Supports parallel Revenue (State $\rightarrow$ Division $\rightarrow$ District $\rightarrow$ Tehsil) and Development (District $\rightarrow$ Block $\rightarrow$ Panchayat) structures using explicit edge types (`revenue`, `development`, `administrative`).
- **Disambiguation Safeguard**: Blocks do NOT automatically become children of Tehsils merely because both belong to the same district.
- **Graph Invariants**: Enforces DAG properties with cycle detection (`has_cycle = false`) and level compatibility checks.

---

## 5. IDENTITY STRATEGY & NAME NORMALIZATION (PHASE P1.3-F & P1.3-G)

- **Deterministic Internal ID Engine** (`lib/data/services/administrative/administrative_identity_engine.dart`):
  - Internal IDs are RiskPulse-managed strings independent of display names or feature ordering.
  - Legacy district aliases (`HP-01` through `HP-12`) are preserved for 100% backward compatibility.
  - Sub-district units generate deterministic IDs via FNV-1a 32-bit hashing: `$PREFIX-$HASH` (e.g., `HP-TEH-0a1b2c3d`, `HP-BLK-e4f5a6b7`).
- **Name Normalization Engine** (`lib/data/services/administrative/administrative_name_normalizer.dart`):
  - Handles case, whitespace, ampersand, and punctuation normalization (`"Lahaul & Spiti"` $\rightarrow$ `"lahaul and spiti"`).
  - Used for search and thematic matching only; names are NOT used as primary identity keys.

---

## 6. GEOMETRY & HIERARCHY VALIDATION (PHASE P1.3-H & P1.3-I)

- **Geometry Validator** (`lib/data/services/administrative/administrative_geometry_validator.dart`):
  - Validates `Polygon` and `MultiPolygon` structures, coordinate ranges ($[-90, 90]$ lat, $[-180, 180]$ lon), and CRS metadata.
  - **No Silent Repairs**: Never silently simplifies, smoothes, snaps, reprojects, or alters coordinates.
- **Hierarchy Validator** (`lib/data/services/administrative/administrative_hierarchy_validator.dart`):
  - Detects orphan units, missing parents, duplicate internal IDs, duplicate source IDs within source scope, level incompatibilities, and directed cycles.

---

## 7. REPOSITORY ARCHITECTURE & INGESTION PIPELINE (PHASE P1.3-D & P1.3-E)

- **Repository Contract & Local Implementation** (`lib/data/repositories/administrative_repository.dart`):
  - Interface-driven `AdministrativeRepository` and `LocalAdministrativeRepository` in-memory store.
  - Operations: `getById()`, `getBySourceId()`, `getByLevel()`, `getChildren()`, `getParent()`, `getAncestors()`, `getDescendants()`, `searchByName()`, `findContainingPoint()`, `findIntersectingGeometry()`, `getDatasetVersion()`.
- **Ingestion Service** (`lib/data/services/administrative/administrative_ingestion_service.dart`):
  - Orchestrates: `AdministrativeSource` $\rightarrow$ Raw GeoJSON $\rightarrow$ Parser $\rightarrow$ `AdministrativeUnit` $\rightarrow$ Identity Validation $\rightarrow$ Hierarchy Validation $\rightarrow$ Geometry Validation $\rightarrow$ Provenance $\rightarrow$ Repository.
  - Registered `hp_districts.geojson` as source `src-soi-hp-districts-2024`, preserving all 12 HP district units.

---

## 8. TEST SUITE & REGRESSION VERIFICATION (PHASE P1.3-L)

### Newly Added Dedicated P1.3 Test Suites:
1. `test/administrative_source_test.dart`: **4 / 4 Passed GREEN**
2. `test/administrative_hierarchy_test.dart`: **3 / 3 Passed GREEN**
3. `test/administrative_repository_test.dart`: **5 / 5 Passed GREEN**
4. `test/administrative_ingestion_test.dart`: **2 / 2 Passed GREEN**
5. `test/administrative_validation_test.dart`: **4 / 4 Passed GREEN**

### Regression Gate Results across Existing Suites:
1. **Existing Administrative Unit Tests (`test/administrative_unit_test.dart`)**: **7 / 7 Passed GREEN**
2. **Existing Thematic Mapping Tests (`test/administrative_thematic_mapping_test.dart`)**: **49 / 49 Passed GREEN**
3. **Existing Thematic Import Tests (`test/administrative_thematic_import_test.dart`)**: **43 / 43 Passed GREEN**
4. **Existing Layer Visibility Tests (`test/administrative_layer_visibility_test.dart`)**: **4 / 4 Passed GREEN**
5. **Existing Watershed Crosswalk Tests (`test/administrative_watershed_crosswalk_test.dart`)**: **7 / 7 Passed GREEN**
6. **HYDRO-2 Scientific & Reference Pipeline**: **100% Unmodified & Passing GREEN**
7. **Operational RiskMap & Kotropi Baseline**: **100% Unmodified & Passing GREEN**
8. **Flutter Analyzer**: **`0 Errors`, `0 Warnings`**

---

## 9. KNOWN DATA GAPS & RECOMMENDED NEXT STEP

### Known Data Gaps:
Official HP Sub-Division, Tehsil, Sub-Tehsil, Block, Gram Panchayat, and Village GeoJSON boundary datasets are currently missing from the local repository asset directory.

### Exact Next Recommended Step:
Aquire official Survey of India / LGD GeoJSON boundary files for Himachal Pradesh Tehsils and Blocks, and run them through `AdministrativeIngestionService.ingestGeoJsonStream()` to populate the second and third tiers of the Himachal Pradesh Administrative Registry.

---

## 10. FINAL VERDICT

```
FINAL VERDICT:
YELLOW — DATASET GAP ONLY

(The P1.3 Administrative Data Registry architecture, domain models, hierarchy graph, deterministic identity engine, name normalizer, geometry validator, hierarchy validator, repository interface, and ingestion pipeline are 100% complete, fully tested, and passing GREEN. Status is YELLOW solely due to missing sub-district GeoJSON asset files.)
```
