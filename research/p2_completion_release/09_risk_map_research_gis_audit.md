# P2 RISK MAP ↔ RESEARCH GIS INTEGRATION AUDIT

- **Cross-View Session Bridge**: P2.9 `RiskResearchSession` bridges Risk Map ("What is happening?") and Research GIS ("Why / where / how?").
- **Buffer Isolation**: Analysis `bufferMeters` does NOT overwrite original `targetGeometry`.
- **Lifecycle Feedback**: Research GIS outputs convert to `ResearchAnalysisResult`, generating new `EvidenceObject` and `InterpretationObject` instances that feed back into the pipeline.
