# P2.7 AFFECTED SUBGRAPH MODEL

Implemented `AffectedSubgraph` (`lib/domain/evidence/affected_subgraph.dart`) capturing:
- `triggerObjectId`: Originating source object ID.
- `affectedNodeIds`: List of node IDs in the affected downstream dependency path.
- `unaffectedNodeIds`: List of node IDs in non-dependent branches that remain 100% untouched.
- `hasCrossEventDependency`: Flag indicating whether cross-event dependency edges were traversed.
