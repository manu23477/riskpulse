# P2.3 EDGE TYPE SEMANTICS MATRIX

| Edge Code | Edge Category | Source Node Type | Target Node Type | Direction |
| :--- | :--- | :--- | :--- | :---: |
| **`SUPPORTS`** | `semantic` | `EvidenceObject` / `InterpretationObject` | `EventHypothesis` | Directed |
| **`CONTRADICTS`** | `semantic` | `EvidenceObject` / `InterpretationObject` | `EventHypothesis` | Directed |
| **`SUPERSEDES`** | `lineage` | `EventHypothesis` v2 | `EventHypothesis` v1 | Directed |
| **`DEPENDS_ON`** | `dependency` | `EventHypothesis` H1 | `EventHypothesis` H2 | Directed |
| **`RELATED_TO`** | `informational` | Any Node | Any Node | Directed |
