/// Provider-neutral lifecycle status for a HydroAI hydrodynamic simulation.
///
/// SCIENTIFIC GOVERNANCE:
/// [completed] indicates simulation software completion ONLY.
/// It is NOT equivalent to [validation] or scientific acceptance.
enum SimulationState {
  created,
  inputValidation,
  modelPreparation,
  ready,
  running,
  completed,
  outputQc,
  outputAvailable,
  validation,

  // Failure & Review States
  inputInvalid,
  modelInvalid,
  solverError,
  cancelled,
  timeout,
  outputInvalid,
  requiresReview,
  insufficientValidationData,
}
