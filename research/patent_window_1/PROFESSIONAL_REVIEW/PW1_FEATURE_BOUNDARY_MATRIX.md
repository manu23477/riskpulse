# RISKPULSE PATENT WINDOW 1: FEATURE BOUNDARY MATRIX

| Feature ID | Description | Experimental Evidence | Prior-Art Status | C07 / C08 Relevance | Research Classification | Legal Question |
| :---: | :--- | :--- | :--- | :---: | :---: | :--- |
| **F01** | Immutable evidence object | `PW1C-1A`, `PW1C-3` ($M32 = 1.0$) | Disclosed (`CN117235153B`) | Core | `DISCLOSED` | Standard data structure? |
| **F02** | Evidence/interpretation separation | `PW1C-1B`, `PW1C-2A` | Disclosed (`CN117235153B`) | Core | `DISCLOSED` | Known architecture? |
| **F03** | Interpretation/event separation | `PW1C-1B`, `PW1C-2A` | Disclosed (`US10452652B2`) | Core | `DISCLOSED` | Standard event sourcing? |
| **F04** | Event/spatial-state separation | `PW1C-2A`, `PW1C-2B` | Disclosed (`US10452652B2`) | Core | `DISCLOSED` | Standard GIS decoupling? |
| **F05** | Spatial to admin state linkage | `PW1C-3`, `PW1C-5` | Partially Disclosed | C07 / C08 | `PARTIALLY DISCLOSED` | Is crosswalk linkage patentable? |
| **F06** | Admin to risk state linkage | `PW1C-3`, `PW1C-5` | Partially Disclosed | C07 / C08 | `PARTIALLY DISCLOSED` | Is risk aggregation patentable? |
| **F07** | Explicit dependency graph | `PW1C-2B`, `PW1C-3` | Disclosed (`US7441230B2`) | Core | `DISCLOSED` | Broadly disclosed software DAG? |
| **F08** | Mutation as event | `PW1C-3`, `PW1C-5` | Disclosed (`CN117235153B`) | Core | `DISCLOSED` | Event sourcing prior art? |
| **F09** | Dependency closure identification | `PW1C-2B`, `PW1C-3` | Disclosed (`US7441230B2`) | C07 / C08 | `DISCLOSED` | Standard DAG traversal? |
| **F10** | Selective invalidation | `PW1C-2B`, `PW1C-5` | Disclosed (`US7441230B2`) | C07 / C08 | `DISCLOSED` | Standard DAG cache invalidation? |
| **F11** | Selective recomputation | `PW1C-2B` ($M28 = 90.51\%$) | Disclosed (`EP3622411B1`) | C07 / C08 | `DISCLOSED` | Incremental query processing? |
| **F12** | Unaffected branch preservation | `PW1C-3` ($M36 = 1.0$) | Disclosed (`US7441230B2`) | C07 / C08 | `DISCLOSED` | Standard graph isolation? |
| **F13** | Versioned state history | `PW1C-3` ($M31 = 1.0$) | Disclosed (`CN117235153B`) | C08 | `DISCLOSED` | Immutable append-only log? |
| **F14** | Historical reconstruction | `PW1C-3` ($M31 = 1.0$) | Disclosed (`CN117235153B`) | C08 | `DISCLOSED` | Standard temporal reconstruction? |
| **F15** | Persistent contradiction retention | `PW1C-3` ($M38 = 1.0$) | Disclosed (`US9870396B2`) | C07 / C08 | `DISCLOSED` | Non-destructive evidence fusion? |
| **F18** | Event time / arrival time separation | `PW1C-5`, `PW1C-5S` ($S15 = 1.0$) | Disclosed (`US20200379978A1`) | C08 | `DISCLOSED` | Standard bitemporal processing? |
| **F20** | Shared downstream admin dependency | `PW1C-3`, `PW1C-5S` ($S03 = 1.0$) | Partially Disclosed | C07 / C08 | `COMBINATION-DEPENDENT` | Does shared node isolation distinguish? |
| **F21** | Shared downstream risk dependency | `PW1C-3`, `PW1C-5S` ($S04 = 1.0$) | Partially Disclosed | C07 / C08 | `COMBINATION-DEPENDENT` | Does shared risk isolation distinguish? |
| **F34** | Cross-event isolation | `PW1C-3`, `PW1C-5S` ($S02 = 1.0$) | Disclosed (`US7441230B2`) | C07 / C08 | `DISCLOSED` | DAG branch isolation? |
| **F41** | Cross-event selective propagation under shared state | `PW1C-5S`, `PW1C-6` | Partially Disclosed | C07 / C08 | `COMBINATION-DEPENDENT` | Core combination distinction? |
