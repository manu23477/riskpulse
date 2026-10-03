# P2.9 END-TO-END LIFECYCLE REPLAY

Tested canonical Kotropi Landslide end-to-end replay:
1. **Kotropi Risk Map Selection**: Selected `HYP-KOTROPI-2017`.
2. **Session Creation**: Created `RiskResearchSession` (`mode = RISK_CENTRIC`).
3. **Research GIS Analysis**: Executed NDVI / SAR Inundation change analysis.
4. **Analysis Result**: Generated `ResearchAnalysisResult`.
5. **Lifecycle Feedback**: Created `EvidenceObject` $\rightarrow$ `InterpretationObject` $\rightarrow$ `EventHypothesis` v2 $\rightarrow$ `SpatialState` v2 $\rightarrow$ `AdministrativeState` v2 $\rightarrow$ `DynamicRiskState` v2.
6. **Lineage Verification**: Kotropi v1 preserved $100\%$ intact. Kotropi v2 linked via `supersedesHypothesisId`.
