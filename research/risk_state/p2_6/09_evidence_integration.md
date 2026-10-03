# P2.6 EVIDENCE INTEGRATION

- **Evidence Lineage**: `supportingEvidenceIds` and `contradictingEvidenceIds` link back to P2.0-A `EvidenceObject` records.
- **Contradiction Traceability**: Contradictory evidence (P2.1 `NegativeEvidence`) is preserved in `contradictingEvidenceIds` without automatically decreasing confidence or cancelling the risk state.
