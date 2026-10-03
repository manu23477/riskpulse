# P2.7 PROPAGATION TRIGGER MODEL

Implemented `PropagationTrigger` (`lib/domain/evidence/propagation_trigger.dart`) capturing:
- `triggerId`: Unique trigger identifier.
- `triggerType`: Category (`spatialChange`, `temporalChange`, `semanticChange`, `evidenceChange`, `supersession`).
- `sourceObjectId` & `sourceObjectType`: Originating changed node pointer.
- `sourceVersion`: Triggering source version number.
- `timestamp` & `reason`: Occurrence timestamp and audit rationale.
