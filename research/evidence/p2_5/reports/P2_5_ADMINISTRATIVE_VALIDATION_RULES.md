# P2.5 ADMINISTRATIVE VALIDATION RULES

1. **Rule 1 (Identity Non-Emptiness)**: `administrativeStateId`, `spatialStateId`, and `eventHypothesisId` must be non-empty strings.
2. **Rule 2 (Internal ID Validity)**: Every `AdministrativeStateUnitRecord` must contain a valid non-empty `internalId` (e.g. `HP-06`).
3. **Rule 3 (Intersection Ratio Bounds)**: `intersectionRatio` must fall within $[0.0, 1.0]$.
4. **Rule 4 (No Fake Area for Points)**: Point attributions shall NOT invent false intersection areas or ratios.
