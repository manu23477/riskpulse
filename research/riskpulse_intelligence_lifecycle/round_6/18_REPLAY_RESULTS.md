# RISKPULSE RESEARCH WORKSTREAM — ROUND 6: REPLAY RESULTS

**Document Identifier**: `RISKPULSE_R6_18_REPLAY_RESULTS`  
**Workstream**: Out-of-Order Replay Convergence Test Results  
**Date**: October 1, 2026  
**Status**: EXPERIMENTAL REPLAY CONVERGENCE LOG  

---

## 1. OUT-OF-ORDER REPLAY CONVERGENCE RESULTS

Processed the complete 15-evidence stream ($E_1$ through $E_{15}$) across 4 sequence permutations:

| Replay Order Sequence | Sequence Description | Final Current Risk State ($V_{\text{final}}$) | State Convergence (`L05`) | Lineage Integrity |
| :--- | :--- | :--- | :---: | :---: |
| **Chronological Sequence** | Order by $t_{\text{observed}}$ asc | `CompositeScore = 0.92`, `Level = CRITICAL` | **`1.0000`** | Intact |
| **Reverse Ingestion Sequence**| Order by $t_{\text{received}}$ desc | `CompositeScore = 0.92`, `Level = CRITICAL` | **`1.0000`** | Intact |
| **Shuffled Ingestion Sequence**| Randomly shuffled stream | `CompositeScore = 0.92`, `Level = CRITICAL` | **`1.0000`** | Intact |
| **Batched Source Sequence** | Grouped by source class | `CompositeScore = 0.92`, `Level = CRITICAL` | **`1.0000`** | Intact |

Final state outputs **converged to 100% identical risk state objects** regardless of feed arrival order ($L05 = 1.0$).
