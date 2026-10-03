# PATENT CONSOLIDATION — ROUND 3: CROSS-EVENT ISOLATION

**Document Identifier**: `CONSOLIDATED_R3_14_CROSS_EVENT_ISOLATION`  
**Workstream**: Dependency-Aware Branch Isolation in Shared Downstream Graphs  
**Date**: October 1, 2026  
**Status**: RESEARCH TECHNICAL SPECIFICATION  

---

## 1. CONCRETE CROSS-EVENT ISOLATION EXAMPLE

Consider two disaster events in Sadar Mandi Tehsil:
- **Event A**: Landslide at Aut Bridge (NH-21 Corridor).
- **Event B**: Flash flood at Pandoh Dam.

Both events contribute to shared downstream node `District_Risk_Mandi`.

```
Event A (Landslide) ───► Spatial A ───┐
                                      ├───► Shared Admin / Risk Node (Mandi)
Event B (Dam Flood) ───► Spatial B ───┘
```

### Isolation Behavior upon Mutating Event A:
1. Event A branch is recomputed to $V_{k+1}$.
2. Shared node `District_Risk_Mandi` is recomputed using updated Event A + static Event B.
3. Event B branch remains **100% untouched and unpoisoned** ($L15 = 1.0$, $L13 = 0, L14 = 0$).
