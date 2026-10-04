# V1.8 PREDICTION DOMAIN MODEL SPECIFICATION

Implemented `PredictiveRiskState` (`lib/domain/prediction/predictive_risk_state.dart`) capturing:
- `predictedStateId`, `riskObjectId`, `hazardType`, `scenarioId`.
- `predictedPeakDischargeM3s`, `predictedExposedAssetsCount`, `predictedPopulationExposed`.
- `forecastValidFrom`, `forecastValidTo`, `leadTimeHours`, `confidenceScore`, `calibrationStatus`.
- `decisionAction`, `decisionPriority`, `explanation`, `provenance`.
