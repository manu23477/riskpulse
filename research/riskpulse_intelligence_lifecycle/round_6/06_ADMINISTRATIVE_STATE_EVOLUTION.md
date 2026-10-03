# RISKPULSE RESEARCH WORKSTREAM — ROUND 6: ADMINISTRATIVE STATE EVOLUTION

**Document Identifier**: `RISKPULSE_R6_06_ADMINISTRATIVE_STATE_EVOLUTION`  
**Workstream**: Tehsil/District Attribution & Boundary Dataset Versioning (V1 vs V2)  
**Date**: October 1, 2026  
**Status**: EXPERIMENTAL ADMINISTRATIVE CROSSWALK LOG  

---

## 1. ADMINISTRATIVE CROSSWALK ATTRIBUTION

Spatial geometries are crosswalked to official HP administrative units:
- **District**: Mandi (`HP-MND`)
- **Block / Tehsil**: Sadar Mandi (`HP-MND-SAD`)
- **Panchayat**: Aut Panchayat (`HP-MND-AUT`)

---

## 2. BOUNDARY DATASET VERSIONING TEST

Tested historical attribution under two administrative boundary dataset versions:
- **`Boundary Dataset V1` (2025 Revenue Boundary)**: Attributes event $100\%$ to Sadar Mandi Tehsil.
- **`Boundary Dataset V2` (2026 Redistricted Boundary)**: Attributes event $70\%$ to Sadar Mandi Tehsil and $30\%$ to newly formed Nagwain Tehsil.

> [!IMPORTANT]
> **Historical Integrity Safeguard**: Historical state $V_3$ generated under Boundary Dataset V1 remains permanently tied to Boundary V1. Introducing Boundary V2 in state $V_6$ does NOT rewrite historical attribution records in $V_3$ ($L10 = 1.0$).
