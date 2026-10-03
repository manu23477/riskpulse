# P2.4 SPATIAL VERSIONING RULES

1. **Rule 1 (Immutability)**: No `SpatialState` record shall be updated in place. Every spatial update creates a new `SpatialState` version with `spatialStateVersion = previousVersion + 1`.
2. **Rule 2 (Lineage Linkage)**: `SpatialState` v2 must specify `previousSpatialStateId` pointing to v1.
3. **Rule 3 (Historical Queryability)**: `getSpatialStateAsOf(timestamp)` shall reconstruct the active spatial state as of any historical point in time.
4. **Rule 4 (P1.5 Bridge)**: Spatial state updates trigger administrative re-attribution via P1.5 without mutating prior administrative context snapshots.
