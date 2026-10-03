# P2.9 RESEARCH GIS FORENSIC AUDIT

Audited Research GIS modes:
- **Mode A (FREE_RESEARCH)**: User launches Research GIS independently to draw or import study area polygons.
- **Mode B (RISK_CENTRIC)**: Launched via Risk Map "Research This Risk". Receives `RiskResearchSession` referencing target geometry, administrative context, and time range.
- Study area buffers (e.g. 5 km buffer around Kotropi) are stored in `studyAreaGeometry` without overwriting authoritative `targetGeometry`.
