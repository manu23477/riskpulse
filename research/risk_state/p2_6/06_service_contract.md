# P2.6 SERVICE CONTRACT SPECIFICATION

- **`DynamicRiskStateService`**:
  - `deriveFromPipeline()`: Assembles structured conditions into an immutable `DynamicRiskState`.
  - `validateRiskState()`: Validates ID non-emptiness, confidence score bounds ($[0.0, 1.0]$), and risk score bounds ($[0.0, 1.0]$).
  - `createNextVersion()`: Creates a new immutable `DynamicRiskState` version (v2).
  - `compareRiskStates()`: Computes detailed condition diffs.
  - `getRiskStateAsOf()`: Reconstructs historical risk state.
