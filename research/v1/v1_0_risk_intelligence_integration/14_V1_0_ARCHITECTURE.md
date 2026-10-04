# V1.0 EXECUTION ARCHITECTURE SPECIFICATION

```
                        [RISK MAP] ("What is happening?")
                            │
                            ▼
                    [RiskObjectAdapter]
                            │
                            ▼
              [RiskResearchSession] (Mode B)
                            │
                            ▼
                    [RESEARCH GIS] ("Why / where / how?")
                            │
                            ▼
                 [GIS / RS / GEE Analysis]
                            │
                            ▼
                 [ResearchAnalysisResult]
                            │
                            ▼
      [EvidenceObject] -> [InterpretationObject] -> [EventHypothesis v2]
                            │
                            ▼
                 [SpatialState v2 & AdminState v2]
                            │
                            ▼
                    [DynamicRiskState v2]
                            │
                            ▼
               [PropagationService & CascadeService]
                            │
                            ▼
                     [RISK MAP OVERLAY]
```
