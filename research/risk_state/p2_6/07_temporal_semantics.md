# P2.6 TEMPORAL SEMANTICS

- **`observedAt`**: Timestamp when underlying evidence was observed in the real world.
- **`calculatedAt`**: Timestamp when `DynamicRiskState` was evaluated by RiskPulse.
- **`effectiveFrom` / `effectiveTo`**: Temporal validity window during which the risk state condition applies.
- **Historical Reconstruction**: `getRiskStateAsOf(timestamp)` reconstructs active risk state as of any point in history.
