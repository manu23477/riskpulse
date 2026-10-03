# P2.5 TEMPORAL BOUNDARY RULES

1. **Rule 1 (Temporal Validation)**: Event timestamps are matched against administrative boundary `boundaryValidFrom` and `boundaryValidTo` ranges.
2. **Rule 2 (Historical Warning Gate)**: When requested historical boundary datasets are un-ingested, the engine emits `HISTORICAL_BOUNDARY_DATA_UNAVAILABLE` warning while keeping the attribution valid under current boundaries.
3. **Rule 3 (Census Reference Geography)**: Census 2011 MDDS village geography is explicitly tagged with `administrativeDatasetVersion: 'Census 2011 MDDS'` to prevent false representation as current 2026 administrative truth.
