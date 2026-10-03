# P2.3 KNOWLEDGE DEPENDENCY SEMANTICS

| Dependency Category | Source Node | Target Node | Topology Meaning | Propagation Instruction? |
| :--- | :--- | :--- | :--- | :---: |
| **`EVENT_LOCAL`** | `InterpretationObject` | `EventHypothesis` | Hypothesis semantics derive from interpretation | **NO** (P2.3 Topology Only) |
| **`VERSION_LOCAL`** | `EventHypothesis` v2 | `EventHypothesis` v1 | Version v2 supersedes version v1 | **NO** (P2.3 Topology Only) |
| **`CROSS_EVENT`** | `EventHypothesis` H1 | `EventHypothesis` H2 | Knowledge state of H1 depends on H2 | **NO** (P2.3 Topology Only) |
