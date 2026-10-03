# P2 IDENTITY AND VERSIONING AUDIT

- **Identity Stability**: Every domain object uses a stable primary string ID (`hypothesisId`, `spatialStateId`, `administrativeStateId`, `riskStateId`).
- **Version Isolation**: Updating state creates a new version v2 with `previousStateId = v1.id`, keeping v1 $100\%$ queryable.
