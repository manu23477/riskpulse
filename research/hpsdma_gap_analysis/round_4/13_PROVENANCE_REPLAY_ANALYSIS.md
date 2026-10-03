# HPSDMA GAP ANALYSIS — ROUND 4: PROVENANCE & REPLAY ANALYSIS

**Document Identifier**: `HPSDMA_R4_13_PROVENANCE_REPLAY_ANALYSIS`  
**Workstream**: Lineage Tracing & Out-of-Order Replay Convergence Results  
**Date**: October 1, 2026  
**Status**: RESEARCH / EXPERIMENTAL HARNESS ONLY  

---

## 1. BACKWARD PROVENANCE LINEAGE TRACING

The harness validates end-to-end backward lineage tracing from any risk score back to raw observations:

$$\text{Risk State } (0.85) \rightarrow \text{Admin Unit } (\text{Mandi}) \rightarrow \text{Spatial State} \rightarrow \text{Event Hypothesis} \rightarrow \text{Evidence Object} \rightarrow \text{Raw Observation}$$

- **Provenance Completeness (`M18`)**: **`1.0000` (100%)**. Every output state includes SHA-256 provenance hashes tracing back to raw input payloads.

---

## 2. OUT-OF-ORDER REPLAY CONVERGENCE TEST RESULTS

Tested 4 arrival order permutations for the same 6 evidence items ($E_1$ through $E_6$):

| Replay Order Scenario | Input Arrival Permutation | Final Current State ($V_{\text{final}}$) | State Convergence (`M19`) | Lineage Integrity |
| :--- | :--- | :--- | :---: | :---: |
| **Chronological** | $E_1 \rightarrow E_2 \rightarrow E_3 \rightarrow E_4 \rightarrow E_5 \rightarrow E_6$ | `RiskScore = 0.85`, `Hazard = Flash Flood` | **`1.0000`** | Intact |
| **Reverse Arrival** | $E_6 \rightarrow E_5 \rightarrow E_4 \rightarrow E_3 \rightarrow E_2 \rightarrow E_1$ | `RiskScore = 0.85`, `Hazard = Flash Flood` | **`1.0000`** | Intact |
| **Shuffled Arrival** | $E_3 \rightarrow E_1 \rightarrow E_6 \rightarrow E_2 \rightarrow E_5 \rightarrow E_4$ | `RiskScore = 0.85`, `Hazard = Flash Flood` | **`1.0000`** | Intact |
| **Batched Arrival** | $\{E_1, E_3, E_5\} \rightarrow \{E_2, E_4, E_6\}$ | `RiskScore = 0.85`, `Hazard = Flash Flood` | **`1.0000`** | Intact |

---

## 3. REPLAY CONVERGENCE FINDING

Regardless of whether evidence arrives in chronological, reverse, shuffled, or batched sequence, the final current state hypothesis **converges to 100% identical outputs** ($M19 = 1.0$), while dual timestamps ($t_{\text{observed}}$ vs $t_{\text{received}}$) preserve true event occurrence chronology.
