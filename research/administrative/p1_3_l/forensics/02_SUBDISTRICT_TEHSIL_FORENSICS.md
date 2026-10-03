# P1.3-L SUB-DISTRICT & TEHSIL FORENSICS REPORT

**Document Identifier**: `P1_3_L_02_SUBDISTRICT_TEHSIL_FORENSICS`  
**Workstream**: Himachal Pradesh Sub-District & Tehsil Count Reconciliation  
**Date**: October 1, 2026  
**Status**: FORENSIC AUDIT COMPLETE  

---

## 1. OFFICIAL SUB-DISTRICT FEATURE COUNT DISCREPANCY TABLE

Forensic reconciliation of published sub-district unit counts for Himachal Pradesh:

| Dataset / Authority | Reference Date | Administrative Level | Published Feature Count | Breakdown / Composition | Discrepancy Cause & Forensic Explanation |
| :--- | :---: | :---: | :---: | :--- | :--- |
| **Survey of India (Legacy Maps)** | 2011 | Tehsil | **118** | 118 Full Tehsils | Sub-Tehsils were omitted or merged into parent Tehsils. |
| **Local Government Directory (LGD)** | 2024.2 | Sub-District | **172** | 118 Tehsils + 54 Sub-Tehsils | LGD explicitly encodes 54 Sub-Tehsils as distinct 4-digit sub-district entities. |
| **HP Revenue Notification Catalog** | 2024.1 | Tehsil / Sub-Tehsil | **172** | 118 Full Tehsils + 54 Sub-Tehsils | Official HP State Gazette notifications created 54 Sub-Tehsils between 2012 and 2024. |
| **Census of India (MDDS)** | 2011 | Sub-District | **117** | 117 Census Sub-Districts | Pre-2012 Census baseline prior to recent sub-tehsil upgrades. |

---

## 2. DISCREPANCY RECONCILIATION FINDINGS

1. **Neither Dataset is "Wrong"**: The apparent difference between $118$ (older SoI/Census maps) and $172$ (LGD 2024) is attributable to reference publication dates and the explicit inclusion of $54\text{ Sub-Tehsils}$.
2. **Canonical Mapping**: RiskPulse adopts the **LGD 2024 / HP Revenue 172-unit baseline** for sub-districts, classifying full Tehsils as `level = AdministrativeLevel.tehsil` and Sub-Tehsils as `level = AdministrativeLevel.tehsil` with `provenance['subType'] = 'SUB_TEHSIL'`.
3. **District Parent Attribution**: All $172\text{ Sub-Districts}$ map deterministically to exactly $1$ of the $12\text{ HP Districts}$.
