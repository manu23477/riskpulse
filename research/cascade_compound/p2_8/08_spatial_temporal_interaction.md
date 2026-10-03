# P2.8 SPATIAL & TEMPORAL INTERACTION SEMANTICS

- **Spatial Interaction**: Preserved via `spatialBasis` (e.g. `UPSTREAM_CATCHMENT_INTERSECTION`).
- **Temporal Interaction**: Preserved via `temporalBasis` (e.g. `TEMPORAL_SEQUENCE_WITHIN_2_HOURS`).
- **Causality Requirement**: Spatial overlap and temporal sequence alone establish `spatiallyInteracts` or `temporallyPrecedes`, NOT `triggers`.
