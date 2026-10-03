# P2.8 NEGATIVE EVIDENCE INTEGRATION

P2.1 `NegativeEvidence` is integrated into `CascadeService.evaluateNegativeEvidenceOnCascade()`.
Contradictory evidence (e.g. field inspection reports road is clear) reduces `confidenceScore` and marks status `withdrawn` if confidence falls below $0.40$, without deleting historical records.
