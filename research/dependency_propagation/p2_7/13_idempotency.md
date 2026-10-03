# P2.7 IDEMPOTENCY

Executing `executePropagation()` multiple times with an identical plan and trigger returns the existing successful `PropagationResult` snapshot without creating uncontrolled duplicate state versions.
