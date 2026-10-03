# RISKPULSE PATENT WINDOW 1: C07 AND C08 BOUNDARY MATRICES

---

## 1. C07 TARGET BOUNDARY MATRIX

### Target Statement:
*A system receives evidence mutating an event hypothesis, identifies affected dependency closure through a multi-layer spatial-administrative-risk graph, selectively recomputes downstream administrative/risk nodes, and preserves independent event hypotheses, provenance, and historical states.*

| C07 Sub-Feature | Disclosed in Prior Art? | Primary Disclosing Reference | Disclosed in Single Reference? |
| :--- | :---: | :--- | :---: |
| **C07-F1**: Evidence mutation | **YES** | `CN117235153B` (`REF-08`) | **NO** |
| **C07-F2**: Selective DAG closure | **YES** | `US7441230B2` (`REF-01`) | **NO** |
| **C07-F3**: Recompute affected nodes only | **YES** | `US7441230B2` (`REF-01`) | **NO** |
| **C07-F4**: Preserve unaffected branches | **YES** | `US7441230B2` (`REF-01`) | **NO** |
| **C07-F5**: Retain contradictions | **YES** | `US9870396B2` (`REF-10`) | **NO** |
| **C07-F6**: Shared admin state | **PARTIAL** | `US10452652B2` (`REF-09`) | **NO** |
| **C07-F7**: Shared risk state | **PARTIAL** | `US10452652B2` (`REF-09`) | **NO** |
| **C07-F8**: Update shared node | **PARTIAL** | `US7441230B2` (`REF-01`) | **NO** |
| **C07-F9**: Preserve Event B hypothesis | **YES** | `US7441230B2` (`REF-01`) | **NO** |
| **C07-F10**: Preserve Event B spatial state | **YES** | `US7441230B2` (`REF-01`) | **NO** |
| **C07-F11**: Historical reconstructability | **YES** | `CN117235153B` (`REF-08`) | **NO** |

**C07 Summary Result**: **`PARTIAL MULTI-REFERENCE COVERAGE ONLY`**

---

## 2. C08 TARGET BOUNDARY MATRIX

### Target Statement:
*A system receives late evidence after event occurrence time ($t_{\text{arrival}} > t_{\text{event}}$), creates a revised current state version while preserving historical version records, and propagates revisions through spatial, administrative, and risk dependencies without altering unrelated event states.*

| C08 Sub-Feature | Disclosed in Prior Art? | Primary Disclosing Reference | Disclosed in Single Reference? |
| :--- | :---: | :--- | :---: |
| **C08-F1**: Late arriving evidence | **YES** | `US20200379978A1` (`REF-04`) | **NO** |
| **C08-F2**: $t_{\text{arrival}} > t_{\text{event}}$ distinction | **YES** | `US20200379978A1` (`REF-04`) | **NO** |
| **C08-F3**: Revise current event state | **YES** | `US20200379978A1` (`REF-04`) | **NO** |
| **C08-F4**: Retain historical prior states | **YES** | `CN117235153B` (`REF-08`) | **NO** |
| **C08-F5**: Reconstruct prior states | **YES** | `CN117235153B` (`REF-08`) | **NO** |
| **C08-F6**: Spatial propagation | **PARTIAL** | `US11200215B2` (`REF-C08-01`) | **NO** |
| **C08-F7**: Administrative propagation | **PARTIAL** | `US11200215B2` (`REF-C08-01`) | **NO** |
| **C08-F8**: Risk propagation | **PARTIAL** | `US11200215B2` (`REF-C08-01`) | **NO** |
| **C08-F9**: Update shared node cleanly | **YES** | `US7441230B2` (`REF-01`) | **NO** |
| **C08-F10**: Bitemporal invariance | **YES** | `US20200379978A1` (`REF-04`) | **NO** |

**C08 Summary Result**: **`PARTIAL MULTI-REFERENCE COVERAGE ONLY`**
