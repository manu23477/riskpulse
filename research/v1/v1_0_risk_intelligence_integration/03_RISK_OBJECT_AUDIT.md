# V1.0 RISK OBJECT AUDIT

Audited operational Risk Object representations:
- **`Hazard`** (`lib/domain/hazard/hazard.dart`): Operational UI feature model (`id`, `name`, `category`, `location`, `geometry`, `district`, `tehsil`, `village`).
- **Adapter Conversion**: `RiskObjectAdapter.adaptHazardToContext()` maps `Hazard` $\rightarrow$ `EventHypothesis` (`HYP-${hazard.id}`) $\rightarrow$ `SpatialState` $\rightarrow$ `AdministrativeState` $\rightarrow$ `DynamicRiskState` $\rightarrow$ `RiskResearchSession`.
