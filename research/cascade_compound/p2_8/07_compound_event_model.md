# P2.8 COMPOUND EVENT MODEL

Implemented `CompoundEventCondition` (`lib/domain/evidence/compound_event_condition.dart`) capturing:
- `compoundEventId`: Unique identifier.
- `rootEventIds`: List of participating event IDs.
- `hazardCategories`: Interacting hazard types (e.g. `['landslide', 'flood']`).
- `combinedSeverity`: `HIGH`, `CRITICAL`, `MODERATE`.
