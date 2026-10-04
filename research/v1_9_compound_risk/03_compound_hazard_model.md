# V1.9 COMPOUND HAZARD MODEL SPECIFICATION

Implemented `CompoundRiskState` (`lib/domain/cascade/compound_risk_state.dart`) capturing:
- `compoundStateId`, `riskObjectId`, `componentEventHypothesisIds`.
- `interactionType` (`'CO_OCCURRENCE'`, `'TEMPORAL_ASSOCIATION'`, `'TRIGGER'`, `'AMPLIFICATION'`).
- `hasCausalMechanism` (bool), `cascadeChainIds`, `affectedServiceTypes`.
- `decisionAction`, `decisionPriority`, `confidenceScore`, `calibrationStatus`, `explanation`.
