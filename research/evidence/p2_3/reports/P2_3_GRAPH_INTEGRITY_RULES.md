# P2.3 GRAPH INTEGRITY RULES

1. **Rule 1 (Node Existence)**: All edge source and target node IDs must exist in `EventGraphRepository`.
2. **Rule 2 (Duplicate Edge Prevention)**: No two edges with identical `(sourceNodeId, relationshipType, targetNodeId)` shall coexist.
3. **Rule 3 (Self-Dependency Restriction)**: No node shall contain a `DEPENDS_ON` edge pointing to itself.
4. **Rule 4 (Cycle Detection)**: Dependency graphs shall be validated for cyclic dependencies (`H1 -> H2 -> H1`).
