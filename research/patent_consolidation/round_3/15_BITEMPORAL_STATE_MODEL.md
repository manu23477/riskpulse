# PATENT CONSOLIDATION — ROUND 3: BITEMPORAL STATE MODEL

**Document Identifier**: `CONSOLIDATED_R3_15_BITEMPORAL_STATE_MODEL`  
**Workstream**: Dual-Time Bitemporal State Model ($t_{\text{event}}$ vs $t_{\text{arrival}}$)  
**Date**: October 1, 2026  
**Status**: RESEARCH TECHNICAL SPECIFICATION  

---

## 1. DUAL-TIME BITEMPORAL SPECIFICATION

The bitemporal model explicitly separates two orthogonal time axes for every state version:
1. **Event Time ($t_{\text{event}}$ / $t_{\text{observed}}$)**: The time the physical disaster event occurred in the real world.
2. **Arrival Time ($t_{\text{arrival}}$ / $t_{\text{received}}$)**: The system transaction time the observation arrived and was ingested.

```
State Version V_k:
  - valid_from_event_time: 2026-08-15T08:15:00Z
  - valid_from_system_time: 2026-08-15T14:30:00Z (Late report arrival at 14:30Z)
```

This prevents late-arriving evidence from rewriting past knowledge while enabling exact point-in-time "As-Of" historical state queries ($L04 = 1.0, L16 = 1.0$).
