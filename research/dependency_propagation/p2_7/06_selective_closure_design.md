# P2.7 SELECTIVE CLOSURE DESIGN

Selective closure is event-scoped, version-aware, and dependency-guided.
Instead of blind global graph traversal, `analyzeImpact()` traverses ONLY directed `DEPENDS_ON` and `EVENT_LOCAL` edges, terminating at terminal derived states (`DynamicRiskState`). Unrelated event branches are explicitly filtered into `unaffectedNodeIds`.
