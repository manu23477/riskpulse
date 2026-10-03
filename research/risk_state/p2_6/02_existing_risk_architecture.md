# P2.6 EXISTING RISK ARCHITECTURE ANALYSIS

P2.6 builds directly on GREEN baselines P1.1..P1.6 and P2.0-A..P2.5.
The RiskPulse intelligence pipeline now forms a complete, versioned 6-stage chain:

$$\text{EvidenceObject} \rightarrow \text{InterpretationObject} \rightarrow \text{EventHypothesis} \rightarrow \text{SpatialState} \rightarrow \text{AdministrativeState} \rightarrow \text{DynamicRiskState}$$

`DynamicRiskState` preserves lineage to `spatialStateId` and `administrativeStateId` with exact version numbers (`spatialStateVersion`, `administrativeStateVersion`).
