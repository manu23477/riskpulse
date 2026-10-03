# HPSDMA GAP ANALYSIS — ROUND 4: ERROR HANDLING MATRIX

**Document Identifier**: `HPSDMA_R4_09_ERROR_HANDLING_MATRIX`  
**Workstream**: E001 through E018 Error Class Matrix & Quarantine Rules  
**Date**: October 1, 2026  
**Status**: RESEARCH / EXPERIMENTAL HARNESS ONLY  

---

## 1. E001 THROUGH E018 ERROR CLASS HANDLING MATRIX

| Error Code | Error Description | Validation Action | Processing Disposition | Error Log Contents |
| :---: | :--- | :---: | :--- | :--- |
| **`E001`** | Missing source ID | QUARANTINE | Quarantined; processing halted for object | Obs ID, Error Code, Timestamp |
| **`E002`** | Invalid / unparseable timestamp | WARNING | Fallback to $t_{\text{received}}$ ingestion time | Obs ID, Error Code, Raw Timestamp |
| **`E003`** | Impossible coordinate ($> 90^\circ$ lat) | REJECT | Rejected immediately | Obs ID, Error Code, Bad Coordinates |
| **`E004`** | Missing hazard type | QUARANTINE | Quarantined pending classification | Obs ID, Error Code, Source |
| **`E005`** | Unknown hazard terminology | WARNING | Mapped to `"unclassified_hazard"` | Obs ID, Error Code, Raw Term |
| **`E006`** | Malformed numerical measurement | WARNING | Measurement omitted; payload retained | Obs ID, Error Code, Bad Value |
| **`E007`** | Unit mismatch / unknown unit | WARNING | Unit converted or flagged | Obs ID, Error Code, Raw Unit |
| **`E008`** | Duplicate observation ID | MERGE | Deduplicated against existing record | Obs ID, Error Code, Original Hash |
| **`E009`** | Conflicting evidence payloads | ACCEPT | Marked with `has_conflict = true` | Obs ID, Error Code, Conflict Link |
| **`E010`** | Ambiguous place name | ACCEPT | Emits candidate alternative list | Obs ID, Error Code, Candidates |
| **`E011`** | Missing administrative mapping | ACCEPT | Attributed to `"Unmapped_Border_Zone"`| Obs ID, Error Code, Geometry |
| **`E012`** | Stale telemetry observation ($> 7\text{ days}$) | ACCEPT | Quality flag `STALE_DATA` appended | Obs ID, Error Code, Age Hours |
| **`E013`** | Late-arriving historical observation | ACCEPT | Creates $V_{k+1}$ current revision snapshot | Obs ID, Error Code, Dual Timestamps |
| **`E014`** | Schema version mismatch | NORMALIZATION | Up-converted via schema adapter | Obs ID, Error Code, Version Ingested |
| **`E015`** | Unsupported source protocol | REJECT | Rejected with protocol alert | Obs ID, Error Code, Protocol Name |
| **`E016`** | Boundary dataset version mismatch | WARNING | Crosswalked with dataset version tag | Obs ID, Error Code, Boundary Version |
| **`E017`** | Spatial topology edge shift | ACCEPT | Triggers dynamic topology update ($T_1$) | Obs ID, Error Code, Edge Details |
| **`E018`** | Dependency closure inconsistency | QUARANTINE | Quarantined; full rebuild verified | Obs ID, Error Code, Node Trace |

---

## 2. ERROR HANDLING PRINCIPLE

The harness **never silently drops invalid data**. Every rejected or quarantined observation emits an explicit `ValidationResult` object containing error codes, timestamps, and payload references ($M01 = 1.0$).
