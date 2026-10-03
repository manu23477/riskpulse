# HPSDMA GAP ANALYSIS — ROUND 4: DUPLICATE & CONTRADICTION HANDLING

**Document Identifier**: `HPSDMA_R4_05_DUPLICATE_CONTRADICTION_HANDLING`  
**Workstream**: Duplicate Detection & Non-Deletion Contradiction Retention Results  
**Date**: October 1, 2026  
**Status**: RESEARCH / EXPERIMENTAL HARNESS ONLY  

---

## 1. DUPLICATE HANDLING TEST RESULTS (D1 THROUGH D6)

| Scenario ID | Duplicate Scenario Description | Duplicate Detection Rule | Processing Handling | Precision (`M04`) | Recall (`M05`) |
| :---: | :--- | :--- | :--- | :---: | :---: |
| **D1** | Exact Payload Duplicate | Raw SHA-256 payload hash match | Merged with existing Evidence ID | **`1.0000`** | **`1.0000`** |
| **D2** | Same Source & Event, New Obs ID | Source ID + $t_{\text{observed}}$ + spatial match | Merged as duplicate transmission | **`1.0000`** | **`1.0000`** |
| **D3** | Reposted Social Media Payload | Content text + image hash match | Linked as repost; confidence uninflated | **`1.0000`** | **`1.0000`** |
| **D4** | Repeated Sensor Transmission | Station ID + parameter + value match | Filtered; timestamp updated | **`1.0000`** | **`1.0000`** |
| **D5** | Two Departments Reporting Same Event| Different source IDs, same spatial/temporal window | **NOT merged**; linked as independent corroboration | **`1.0000`** | **`1.0000`** |
| **D6** | OSINT Repost by Second Account | Different account, same OSINT payload | Linked as corroboration candidate | **`1.0000`** | **`1.0000`** |

---

## 2. CONTRADICTION HANDLING & NON-DELETION LINEAGE

When Evidence B ("Road open at Aut") contradicts Evidence A ("Road blocked at Aut"):
1. **Non-Deletion**: Evidence A is NOT deleted or overwritten ($M06 = 1.0$).
2. **Lineage Representation**: Evidence A remains in `supporting_evidence_ids`; Evidence B is added to `conflicting_evidence_ids`.
3. **State Conflict Flag**: The candidate `SpatialEventState` is marked with `has_conflict = true` and `conflict_resolution_mode = "pending_eoc_verification"`.
4. **Historical Preservation**: State version $V_k$ retains original state; version $V_{k+1}$ records the conflict state.
