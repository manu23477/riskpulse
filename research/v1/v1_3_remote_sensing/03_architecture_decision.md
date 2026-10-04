# V1.3 ARCHITECTURAL DECISIONS

- **NO GRAPH OR FUSION DUPLICATION**: Reuses P2.3 `EventGraphService` and V1.1 `EvidenceFusionService`.
- **NO IMMEDIATE EVENT CONFIRMATION**: Remote sensing anomalies create `EvidenceObject` records, feeding downstream `InterpretationObject` $\rightarrow$ `EventHypothesis` pipeline.
- **SERVER-SIDE GEE PROXY**: GEE API keys and tokens remain strictly server-side.
