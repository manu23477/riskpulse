# P2.7 PROPAGATION PLAN SPECIFICATION

Implemented `PropagationPlan` (`lib/domain/evidence/propagation_plan.dart`) capturing:
- `planId`: Unique plan ID.
- `trigger`: Originating `PropagationTrigger`.
- `subgraph`: Calculated `AffectedSubgraph`.
- `executionOrder`: Topologically sorted list of node IDs to recompute.
- `isExecutable`: Readiness flag.
