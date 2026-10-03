# P2.7 DEPENDENCY MATRIX

| Source Object | Target Object | Dependency Class | Propagation Behavior |
| :--- | :--- | :--- | :--- |
| **`EvidenceObject`** | `InterpretationObject` | `EVENT_LOCAL` | Recomputes interpretation upon source correction |
| **`InterpretationObject`** | `EventHypothesis` | `EVENT_LOCAL` | Recomputes hypothesis fusion upon interpretation update |
| **`EventHypothesis`** | `SpatialState` | `EVENT_LOCAL` | Derives new spatial state version when footprint changes |
| **`SpatialState`** | `AdministrativeState` | `EVENT_LOCAL` | Derives new administrative state version when geometry changes |
| **`AdministrativeState`** | `DynamicRiskState` | `EVENT_LOCAL` | Derives new risk state version when exposure changes |
| **`EventHypothesis` $H_1$** | `EventHypothesis` $H_2$ | `CROSS_EVENT` | Propagates ONLY if explicit `CROSS_EVENT` dependency edge exists |
