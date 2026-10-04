# V1.1 ARCHITECTURAL DECISIONS

- **NO Simple Confidence Averaging**: Prohibits `mean(confidence)` or `confidence * count`. Uses rule-based analytical fusion.
- **NO Probability Claims**: Confidence score is marked `UNCALIBRATED_RULE_BASED` and strictly distinguished from statistical probability.
- **NO Graph Duplication**: Reuses P2.3 `EventGraphService` for registering corroboration and contradiction edges.
