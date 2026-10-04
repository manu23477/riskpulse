# V1.5 ARCHITECTURAL DECISIONS

- **PHYSICS-BASED PIPELINE**: Loss (SCS-CN) $\rightarrow$ Transform (SCS Unit Hydrograph) $\rightarrow$ Routing (Muskingum).
- **SEPARATION OF CALIBRATION & VALIDATION**: Calibration parameter sets are strictly distinguished from independent validation evaluations.
- **NO BLACK BOX**: Every hydrograph result is linked to explicit parameter sets, DEM versions, and V1.4 rainfall input IDs.
