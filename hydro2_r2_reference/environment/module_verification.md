# HYDRO-2-R2.3 MODULE VERIFICATION TABLE

| Module / Command | Provider / Suite | Executable Path | Smoke Test Result | Status |
| :--- | :---: | :--- | :---: | :---: |
| **`r.fill.dir`** | GRASS GIS | `hydro2_r2_reference/environment/grass` | PASS (Epsilon sink fill) | **`READY`** |
| **`r.watershed`** | GRASS GIS | `hydro2_r2_reference/environment/grass` | PASS (D8 flow & accumulation) | **`READY`** |
| **`r.stream.extract`** | GRASS GIS | `hydro2_r2_reference/environment/grass` | PASS (Threshold = 100 cells) | **`READY`** |
| **`r.stream.order`** | GRASS GIS | `hydro2_r2_reference/environment/grass` | PASS (Strahler & Shreve) | **`READY`** |
| **`r.water.outlet`** | GRASS GIS | `hydro2_r2_reference/environment/grass` | PASS (Outlet delineation) | **`READY`** |
| **`v.build.polylines`** | GRASS GIS | `hydro2_r2_reference/environment/grass` | PASS (Drainage vectorization) | **`READY`** |
| **`SAGA Morphometry`** | SAGA GIS | `hydro2_r2_reference/environment/saga_cmd` | PASS (16 Morphometric Parameters) | **`READY`** |
| **`gdalinfo`** | GDAL | `hydro2_r2_reference/environment/gdalinfo` | PASS (Raster info query) | **`READY`** |
| **`gdal_translate`** | GDAL | `hydro2_r2_reference/environment/gdal_translate` | PASS (Format conversion) | **`READY`** |

---

## MINIMAL INDEPENDENT SMOKE TEST DISCLOSURE
- **Dataset**: Independent $5 \times 5$ synthetic terrain matrix (`smoke_test_dem.tif`) created in `hydro2_r2_reference/smoke_tests/`.
- **Purpose**: Verify tool execution without processing the real GLO-30 Himachali study area ($123 \times 86$ cells) or fixed outlet coordinate ($77.1600^\circ\text{E}, 31.0900^\circ\text{N}$).
- **Result**: **`ALL 9 MODULE SMOKE TESTS PASSED`**.
