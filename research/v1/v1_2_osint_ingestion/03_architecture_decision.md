# V1.2 ARCHITECTURAL DECISIONS

- **RAW VS NORMALIZED SEPARATION**: Unedited acquired text (`OsintRawObservation`) is preserved separately from extracted NLP features (`OsintNormalizedPayload`).
- **NO SECOND EVIDENCE MODEL**: OSINT data is converted into P2 `EvidenceObject` records.
- **NO DIRECT EVENT MUTATION**: OSINT reports enter Evidence $\rightarrow$ Interpretation $\rightarrow$ EventHypothesis pipeline.
