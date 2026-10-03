# RISKPULSE RESEARCH WORKSTREAM — ROUND 6: CROSS-EVENT ISOLATION

**Document Identifier**: `RISKPULSE_R6_11_CROSS_EVENT_ISOLATION`  
**Workstream**: Cross-Event Isolation across Events A, B, and C  
**Date**: October 1, 2026  
**Status**: EXPERIMENTAL ISOLATION LOG  

---

## 1. CROSS-EVENT ISOLATION TEST SETUP

Constructed a multi-event DAG involving 3 disaster events:
- **Event A (`EVT-E1`)**: Alpha Corridor Landslide in Sadar Mandi Tehsil.
- **Event B (`EVT-E2`)**: Beta Corridor Landslide in Sadar Mandi Tehsil (shares district node with Event A).
- **Event C (`EVT-E3`)**: Gamma Corridor Landslide in Kullu District (geographically disconnected from Event A).

---

## 2. MUTATION & ISOLATION RESULTS

Mutated Evidence $E_{11}$ on Event A:
- **Event A Branch**: Updated cleanly to $V_6$ (`CRITICAL`).
- **Shared District Node (Sadar Mandi)**: Recalculated correctly to incorporate updated Event A + static Event B.
- **Event B Branch**: Remained $100\%$ valid; Event B risk score unchanged.
- **Disconnected Event C Branch**: Preserved $100\%$ untouched.
- **False Propagation (`L13`)**: **`0` (0 False Propagations)**.
- **Missed Propagation (`L14`)**: **`0` (0 Missed Propagations)**.
- **Cross-Event Isolation (`L15`)**: **`1.0000` (100% Isolation)**.
