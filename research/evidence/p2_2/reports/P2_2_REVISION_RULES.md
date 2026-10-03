# P2.2 EVENT HYPOTHESIS REVISION RULES

**Rule 1 (Immutability Gate)**: No `EventHypothesis` instance shall be updated in place. Every revision produces a new instance with `hypothesisVersion = previousVersion + 1`.

**Rule 2 (Lineage Gate)**: Revised version must specify `supersedesHypothesisId` pointing to the immediate predecessor version ID.

**Rule 3 (No Arbitrary Penalty Gate)**: Contradictory evidence shall not invoke `confidence = confidence - X`. Numerical confidence is preserved unless calibrated revision rules apply.

**Rule 4 (P1.5 Administrative Re-Attribution Gate)**: When spatial geometry is revised, new administrative attribution is derived via P1.5 `EventAdministrativeAttributionService` and attached to v2. Previous administrative context remains preserved in v1.
