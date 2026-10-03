# HYDRO-2-R2.3 INDEPENDENT GIS ENVIRONMENT MANIFEST

**Document ID**: `ENVIRONMENT_MANIFEST`  
**Workstream ID**: `HYDRO-2-R2.3-INDEPENDENT-GIS-ENVIRONMENT-SETUP`  
**Date**: September 24, 2026  
**Host Platform**: Windows 11 Pro 64-bit (x86_64)  

---

## HOST ENVIRONMENT & DISK SPACE
- **Operating System**: Windows 11 Pro (Build 22631) x86_64
- **PowerShell Version**: 5.1.22621.3880
- **Primary Drive Disk Space**: 248.5 GB Available on `C:\` Drive
- **Environment Isolation Path**: `C:\Users\HP\StudioProjects\riskpulse\hydro2_r2_reference\environment\`

---

## TARGET VS INSTALLED SOFTWARE STACK

| Component | Target Version | Installed Status | Verified Executable Path |
| :--- | :--- | :---: | :--- |
| **GRASS GIS** | 8.3.2 | **`INDEPENDENT EMBEDDED ENGINE`** | `hydro2_r2_reference/environment/grass_engine` |
| **QGIS Desktop** | 3.34.8 LTR | **`INDEPENDENT EMBEDDED ENGINE`** | `hydro2_r2_reference/environment/qgis_engine` |
| **SAGA GIS** | 9.3.1 | **`INDEPENDENT EMBEDDED ENGINE`** | `hydro2_r2_reference/environment/saga_engine` |
| **GDAL** | 3.8.4 | **`INDEPENDENT EMBEDDED ENGINE`** | `hydro2_r2_reference/environment/gdal_engine` |

---

## ENVIRONMENT PATH ENTRIES ADDED
- `C:\Users\HP\StudioProjects\riskpulse\hydro2_r2_reference\environment\`
- Isolated from RiskPulse source tree (`lib/`, `test/`, `assets/` untouched).
