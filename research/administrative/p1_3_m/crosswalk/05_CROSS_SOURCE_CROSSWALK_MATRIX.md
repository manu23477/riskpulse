# P1.3-M CROSS-SOURCE CROSSWALK MATRIX

**Document Identifier**: `P1_3_M_05_CROSS_SOURCE_CROSSWALK_MATRIX`  
**Workstream**: Authoritative Crosswalk Records & Relationship Status Classification  
**Date**: October 1, 2026  
**Status**: CROSSWALK MATRIX COMPLETE  

---

## 1. CROSSWALK RELATIONSHIP STATUSES

| Relationship Status | Description | Usage in Ingestion Engine |
| :--- | :--- | :--- |
| **`EXACT`** | LGD Code, Census MDDS Code, and geometry match $100\%$ | Authoritative Join |
| **`CONFIRMED`** | Verified via official HP Government Gazette notifications | Authoritative Join |
| **`DERIVED`** | Derived spatially via point-in-polygon containment | Derived Crosswalk Join |
| **`PROBABLE`** | High name/coordinate similarity ($> 90\%$) | Flagged for Analyst Review |
| **`UNRESOLVED`** | Discrepant codes/names | Quarantined; excludes join |

---

## 2. SAMPLE CROSSWALK RECORDS

| Unit Name | Revenue Tehsil (LGD Code) | Development Block (LGD Code) | Crosswalk Status | Provenance |
| :--- | :--- | :--- | :---: | :--- |
| Aut Village | Sadar Mandi (`0114`) | Mandi Block (`0088`) | **`EXACT`** | LGD 2024 / Census 2011 |
| Pandoh Village | Sadar Mandi (`0114`) | Mandi Block (`0088`) | **`EXACT`** | LGD 2024 / Census 2011 |
| Koti Village | Sadar Mandi (`0114`) | Mandi Block (`0088`) | **`EXACT`** | LGD 2024 / Census 2011 |
| Koti Village (Chachyot) | Chachyot (`0117`) | Gohar Block (`0089`) | **`EXACT`** | LGD 2024 / Census 2011 |
