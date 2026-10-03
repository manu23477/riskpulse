# RISKPULSE RESEARCH WORKSTREAM — ROUND 6: CONTRADICTION ANALYSIS

**Document Identifier**: `RISKPULSE_R6_09_CONTRADICTION_ANALYSIS`  
**Workstream**: 5 Contradiction Types (C1 through C5) & Conflict Lineage Tracking  
**Date**: October 1, 2026  
**Status**: EXPERIMENTAL CONTRADICTION LOG  

---

## 1. EVALUATION OF FIVE CONTRADICTION TYPES (C1 THROUGH C5)

| Type ID | Contradiction Category | Contradicting Evidence Pair | Representation Logic | Resulting State Effect |
| :---: | :--- | :--- | :--- | :--- |
| **`C1`** | Road Status Contradiction | $E_2$ ("Blocked") vs $E_9$ ("Open") | Non-deletion conflict relation | `has_conflict = true`, Score = `0.65` |
| **`C2`** | Hazard Existence Contradiction | $E_1$ ("Landslide") vs $E_{13}$ ("Withdrawn") | Source withdrawal link appended | $E_1$ weight set to $0$; $E_2$ retains state |
| **`C3`** | Location Contradiction | $E_2$ ("km 14") vs $E_6$ ("km 18") | Multi-node spatial candidate list | Two candidate spatial nodes created |
| **`C4`** | Temporal Contradiction | $E_2$ ("08:25Z") vs $E_{12}$ ("08:15Z") | Dual-timestamping ($t_{\text{observed}}$) | $08:15\text{Z}$ accepted as true occurrence |
| **`C5`** | Severity Contradiction | $E_2$ ("Minor") vs $E_8$ ("Major 500m³") | Confidence-weighted escalation | Score escalated to `0.85` |

Across all 5 contradiction types, zero evidence objects were deleted ($L06 = 1.0$).
