# P2.5 ADMINISTRATIVE STATE SEMANTICS MATRIX

| Field / Component | Representation | Semantic Purpose |
| :--- | :--- | :--- |
| **`internalId`** | String (`HP-06`, `HP-TEH-0114`) | Primary RiskPulse administrative unit identity |
| **`intersectionAreaSqKm`** | Double ($\text{km}^2$) | Estimated intersected area within unit |
| **`intersectionRatio`** | Double ($0.0$ to $1.0$) | Fractional overlap ratio of hazard footprint |
| **`hierarchyType`** | String (`revenue`, `development`) | Parallel administrative chain classification |
| **`administrativeDatasetVersion`** | String (`2024.1`, `Census 2011 MDDS`) | Authoritative boundary dataset version |
| **`attributionBasis`** | Enum (`pointContainment`, `polygonIntersection`) | Spatial attribution derivation origin |
