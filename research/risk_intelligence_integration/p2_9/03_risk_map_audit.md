# P2.9 RISK MAP FORENSIC AUDIT

Audited Risk Map feature click workflow:
- Selected map feature resolves to canonical `EventHypothesis.hypothesisId`.
- `RiskIntelligenceContextService.createSessionFromRiskObject()` constructs a Mode B (`RISK_CENTRIC`) session referencing `eventHypothesisId`, `spatialStateId`, `administrativeStateId`, and `dynamicRiskStateId`.
- Target geometry, location, and administrative context are made available to Research GIS without losing identity or version lineage.
