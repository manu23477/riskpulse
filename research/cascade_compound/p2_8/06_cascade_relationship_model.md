# P2.8 CASCADE RELATIONSHIP MODEL

Implemented `CascadeRelationship` (`lib/domain/evidence/cascade_relationship.dart`) capturing:
- `primaryEventId` & `secondaryEventId`: Event pointers.
- `relationshipType`: `CascadeRelationshipType`.
- `cascadeDepth`: `CascadeDepthType`.
- `confidenceScore`: $[0.0, 1.0]$.
- `evidenceIds`: Documented evidence lineage.
