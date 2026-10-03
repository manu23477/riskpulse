# HPSDMA GAP ANALYSIS — ROUND 5: DUPLICATE & CONTRADICTION ANALYSIS

**Document Identifier**: `HPSDMA_R5_09_DUPLICATE_CONTRADICTION_ANALYSIS`  
**Workstream**: Naturally Occurring Duplicates & Real-World Contradiction Analysis  
**Date**: October 1, 2026  
**Status**: RESEARCH / EXPERIMENTAL VALIDATION ONLY  

---

## 1. NATURALLY OCCURRING DUPLICATES IN REAL DATASETS

| Dataset | Duplicate Occurrence | Real-World Cause | Pipeline Processing | Duplicate Action |
| :--- | :--- | :--- | :--- | :--- |
| **RW-01** | Identical incident logged twice | Resubmission by district office | Payload hash match | Merged cleanly |
| **RW-02** | Telemetry reading repeated | Sensor retry transmission | Station + time + value match | Deduplicated |
| **RW-06** | Road blockage reported twice | PWD and Police department logs | Separate sources, same road | Linked as corroboration |
| **RW-07** | Social media report retweeted | Amplification repost | Text hash match | Weight uninflated |

---

## 2. NATURALLY OCCURRING CONTRADICTIONS

In `RW-01` and `RW-07`, two reports contradicted each other regarding NH-21 highway status at Aut Bridge (Report A: "Road completely blocked by landslide"; Report B: "One-lane traffic opened").
- **Non-Arbitrary Handling**: Report A was NOT deleted ($M06 = 1.0$). Both reports were retained in evidence lineage. Current state version $V_{k+1}$ was updated to `PARTIALLY_OPEN` with `has_conflict = true` ($M06 = 1.0$).
