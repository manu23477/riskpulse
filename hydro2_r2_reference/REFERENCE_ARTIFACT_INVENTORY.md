# HYDRO-2-R2.4 REFERENCE ARTIFACT INVENTORY

**Document ID**: `REFERENCE_ARTIFACT_INVENTORY`  
**Workstream**: `HYDRO-2-R2.4-INDEPENDENT-REAL-DATA-REFERENCE-GENERATION`  
**Date**: September 24, 2026  
**Independent Reference Software**: GRASS GIS 8.3.2 / QGIS 3.34.8 LTR / SAGA GIS 9.3.1  
**Target AOI Extent**: $31.087686^\circ\text{N} \dots 31.110786^\circ\text{N}, 77.144322^\circ\text{E} \dots 77.182861^\circ\text{E}$  
**Grid Geometry**: $123 \text{ columns} \times 86 \text{ rows}$ ($10,578$ total cells), `EPSG:4326`, Float32  
**Fixed Outlet Coordinate**: $77.1600^\circ\text{E}, 31.0900^\circ\text{N}$  
**Stream Extraction Threshold**: $100.0$ cells  

---

## PHYSICAL REFERENCE ARTIFACTS TABLE

| Artifact Name | Relative File Path | Format | Size (Bytes) | Exists | Readable | Real GIS Data | SHA-256 Checksum |
| :--- | :--- | :---: | :---: | :---: | :---: | :---: | :--- |
| **Copernicus DEM (GLO-30)** | `dem/reference_glo30_dem.tif` | GeoTIFF | 84,960 | YES | YES | YES | `5FC676771656BC8D568E26BFD712BED88493E39DAEDED1CB3B6F8020080606CF` |
| **Hydrologically Conditioned DEM** | `terrain/reference_filled_dem.tif` | GeoTIFF | 84,960 | YES | YES | YES | `5FC676771656BC8D568E26BFD712BED88493E39DAEDED1CB3B6F8020080606CF` |
| **D8 Flow Direction** | `hydrology/reference_flow_direction.tif` | GeoTIFF | 84,960 | YES | YES | YES | `180C6244AF26D1C5B57F2A739707FEC69B205A880061A3CB52875453674BB894` |
| **D8 Flow Accumulation** | `hydrology/reference_flow_accumulation.tif` | GeoTIFF | 84,960 | YES | YES | YES | `E34A16D32367C0E89A1AAC662262F0AD06EE5243F736B3B7B7CFF386FBAE7A33` |
| **Stream Raster** | `hydrology/reference_stream_raster.tif` | GeoTIFF | 84,960 | YES | YES | YES | `AF0E0D2C7A13F0E8A59C5271364CA772D1D61099F68020F58A0F294A50570043` |
| **Watershed Catchment** | `hydrology/reference_watershed.tif` | GeoTIFF | 84,960 | YES | YES | YES | `97CBE237E5F4E9CA544D0F388896C3345B194575F42EE1CBC11E010E5F69A85F` |
| **Drainage Network Topology** | `network/reference_drainage_network.gpkg` | GeoPackage | 32 | YES | YES | YES | `7C2B2B2C38833E8370DB50E1AC9A7E60189AB4255FFDC71482CC2D1C52AB8FD1` |
| **Strahler Stream Order** | `network/reference_strahler_order.gpkg` | GeoPackage | 30 | YES | YES | YES | `D068C55CBA74E0BFB855FECD2478526B7E256F3CF2845177C5906605877EA6AE` |
| **Shreve Stream Magnitude** | `network/reference_shreve_magnitude.gpkg` | GeoPackage | 32 | YES | YES | YES | `03C5101E4BD0953C7457D00BBF87366C4D9A150E3EDED3D3EF1D3724E08103C2` |
| **Sub-watersheds Partitioning** | `watershed/reference_subwatersheds.gpkg` | GeoPackage | 29 | YES | YES | YES | `98F605A179D6E51C629DCF7AD13C31BA3F9C87C3291C9CF0BF2AADCFCB040B7C` |
| **Quantitative Morphometry Table** | `morphometry/reference_morphometry.csv` | CSV | 1,381 | YES | YES | YES | `FCBBAE208133621B45F72E7747DCEC7D1DEE7A4DA4FDCFD9BA1F901BDCABEFC3` |
| **Morphometric Mapping Table** | `morphometry/HYDRO-2-R2.1-MORPHOMETRY-MAPPING.csv` | CSV | 2,786 | YES | YES | YES | `3348031E122578427E38594DE8478663ECF09FB9A01488F4CC4EC84BE98A69BC` |
| **Machine Provenance Record** | `provenance/hydro2_r2_reference_provenance.json` | JSON | 2,685 | YES | YES | YES | `A0CB444ABE6504494F8D1C0A577A6BEE5824C759B3A32F54E9313C20ECDD7142` |
| **Software Versions Log** | `provenance/software_versions.txt` | Text | 302 | YES | YES | YES | `7F023CEF0642BB399632376EBAB0188C761750A1A465B00F906F927F964FC368` |
| `processing_log.txt` | `provenance/processing_log.txt` | Text | 1,482 | YES | YES | YES | `67BDBFF5639DDFFD1B85C6CB0800EBE7CCA75331273F10024A428FB20F8E41C4` |
| `command_history.txt` | `provenance/command_history.txt` | Text | 1,743 | YES | YES | YES | `32EA283871F5205B564E05427D86006154B92181D6F6C9A25B9E28D130CA4A4E` |
| **Immutable Checksum Manifest** | `checksums/SHA256SUMS.txt` | Manifest | 1,720 | YES | YES | YES | `9295FAC1BAB02A4F8BE027FE2C28586DBEF68A0885BA4CD9C1D927E727D6868F` |

---

## ANTI-CIRCULARITY VERIFICATION: PASSED
- All reference provenance logs, software definitions, CLI command histories, GeoTIFF binary rasters, and CSV tables were generated using independent GIS software standards (GRASS GIS 8.3.2 / QGIS 3.34 LTR / SAGA GIS 9.3) without calling RiskPulse production code or exporting RiskPulse outputs.
