# V1.0 KEEP / EXTEND / ADAPTER / REPLACE / NOT IMPLEMENTED MATRIX

| Component | Current State | P2 Contract | Classification | Gap / Action |
| :--- | :--- | :--- | :---: | :--- |
| **`Hazard`** | Operational UI Model | P2 `EventHypothesis` | **`ADAPTER`** | Connected via `RiskObjectAdapter` |
| **`RiskResearchSession`** | Intelligence Context | P2 Cross-View Bridge | **`KEEP`** | Reference authoritative states |
| **`ResearchAnalysisResult`** | Research Output | P2 Evidence / Interpretation | **`KEEP`** | Converts results to Evidence |
| **`EventGraphService`** | Topology Gateway | P2 Graph Topology | **`KEEP`** | Reused 100% |
| **`PropagationService`** | Propagation Gateway | P2 Selective Propagation | **`KEEP`** | Reused 100% |
| **`CascadeService`** | Causal Chain Gateway | P2 Cascade / Compound | **`KEEP`** | Reused 100% |
| **`ResearchWorkspaceProvider`** | UI Provider | P2 Session Handoff | **`EXTEND`** | Connected to `RiskResearchSession` |
| **Predictive AI Agent** | Future V1.1 Feature | Non-existent in V1.0 | **`NOT IMPLEMENTED`** | Tracked for V1.1 |
