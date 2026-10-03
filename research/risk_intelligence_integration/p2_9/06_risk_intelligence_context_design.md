# P2.9 RISK INTELLIGENCE CONTEXT DESIGN

Implemented `RiskResearchSession` (`lib/domain/evidence/risk_research_session.dart`) containing:
- Session ID, risk object ID, risk object type, mode (`RISK_CENTRIC` / `FREE_RESEARCH`).
- Version pointers: `hypothesisVersion`, `spatialStateVersion`, `administrativeStateVersion`, `dynamicRiskStateVersion`.
- Spatial properties: `targetLocation`, `targetGeometry`, `studyAreaGeometry`, `bufferMeters`, `crs`.
- Temporal & Admin: `observedAt`, `effectiveFrom`, `effectiveTo`, `administrativeContext`.
- Evidence & Lineage: `evidenceIds`, `interpretationIds`, `originatingScreen`.
