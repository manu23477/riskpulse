# P2.2 REVISION FIELD SEMANTICS MATRIX

| Field Name | Revisable? | Revision Category | Behavior on Revision | Evidence Requirement |
| :--- | :---: | :--- | :--- | :--- |
| **`hypothesisId`** | **NO** | Immutable Identity | Preserved identically across all versions | Same event identity |
| **`hypothesisVersion`** | **YES** | Version Sequence | Incremented ($v1 \rightarrow v2$) | Validated RevisionDecision |
| **`geometry` / `spatialExtent`** | **YES** | `spatialRevision` | Updated footprint geometry | Spatial contradiction |
| **`estimatedStart` / `estimatedEnd`** | **YES** | `temporalRevision` | Updated timestamp window | Temporal contradiction |
| **`eventType` / `hazardCategory`** | **YES** | `semanticRevision` | Updated classification | Semantic contradiction |
| **`title` / `description`** | **YES** | `partialRevision` | Appends version notation | Contextual clarification |
| **`administrativeContextReference`**| **YES** | `spatialRevision` | Derived anew via P1.5 engine | Geometry update |
