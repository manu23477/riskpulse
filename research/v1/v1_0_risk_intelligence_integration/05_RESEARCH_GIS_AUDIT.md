# V1.0 RESEARCH GIS FORENSIC AUDIT

Research GIS modes:
- **Mode A (FREE_RESEARCH)**: User launches Research GIS independently for exploratory GIS/RS analysis.
- **Mode B (RISK_CENTRIC)**: Launched via Risk Map selection. Receives `RiskResearchSession` referencing target geometry, administrative context, and temporal bounds. Analysis buffer (e.g. 5 km buffer around Kotropi) is kept in `studyAreaGeometry` without overwriting `targetGeometry`.
