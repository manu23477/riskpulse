# P2.6 DOMAIN MODEL SPECIFICATION

- **`DynamicRiskState`**: Primary immutable domain object (`riskStateId`, `eventHypothesisId`, `spatialStateId`, `administrativeStateId`, `riskStateVersion`).
- **`HazardCondition`**: Captures `hazardCategory`, `hazardSeverity`, `hazardIntensity`, `hazardStatus`.
- **`ExposureCondition`**: Captures `exposureStatus`, `exposedPopulation`, `exposedAssetCount`, `exposedUnitIds`, `exposureDatasetVersion`.
- **`VulnerabilityCondition`**: Captures `vulnerabilityStatus`, `vulnerabilityScore`, `susceptibilityClass`, `vulnerabilityDatasetVersion`.
- **`ImpactCondition`**: Captures `impactStatus`, `estimatedDamageCost`, `affectedInfrastructureSummary`.
