# P1.3-L CROSS-SOURCE ADMINISTRATIVE CROSSWALK

**Document Identifier**: `P1_3_L_05_CROSS_SOURCE_CROSSWALK`  
**Workstream**: Cross-Source Authority Mapping (Survey of India vs LGD vs HP State Revenue)  
**Date**: October 1, 2026  
**Status**: CROSSWALK AUDIT COMPLETE  

---

## 1. CROSS-SOURCE SUB-DISTRICT & DISTRICT CROSSWALK TABLE (SAMPLE RECONCILIATION)

| RiskPulse Internal ID | District Name | LGD District Code | Survey of India Tehsil Name | LGD Sub-District Code | HP State Revenue Status | Cross-Source Match Result |
| :---: | :--- | :---: | :--- | :---: | :--- | :---: |
| `HP-01` | Bilaspur | `0208` | Sadar Bilaspur | `0102` | Full Tehsil | **`EXACT_MATCH`** |
| `HP-01` | Bilaspur | `0208` | Ghumarwin | `0101` | Full Tehsil | **`EXACT_MATCH`** |
| `HP-01` | Bilaspur | `0208` | Jhandutta | `0103` | Full Tehsil | **`EXACT_MATCH`** |
| `HP-01` | Bilaspur | `0208` | Shri Naina Devi Ji | `0104` | Sub-Tehsil (Upgraded 2021)| **`LGD_EXTENDED_MATCH`** |
| `HP-06` | Mandi | `0214` | Sadar Mandi | `0114` | Full Tehsil | **`EXACT_MATCH`** |
| `HP-06` | Mandi | `0214` | Aut | `0115` | Sub-Tehsil (Created 2018) | **`LGD_EXTENDED_MATCH`** |
| `HP-06` | Mandi | `0214` | Bali Chowki | `0116` | Sub-Tehsil | **`EXACT_MATCH`** |
| `HP-06` | Mandi | `0214` | Chachyot | `0117` | Full Tehsil | **`EXACT_MATCH`** |

---

## 2. CROSSWALK MATCH CLASSIFICATION

- **`EXACT_MATCH`**: Identical naming, LGD code, and Survey of India boundary geometry.
- **`LGD_EXTENDED_MATCH`**: Sub-Tehsil created or upgraded in recent HP Revenue notifications ($2012-2024$), recorded in LGD 2024.2 database.
- **`NAME_ONLY_MATCH`**: Name matches but LGD code is missing or unverified.
