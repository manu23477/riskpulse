# P2.4 SPATIAL SEMANTICS MATRIX

| Category | Field Name | Representation | Semantic Purpose |
| :--- | :--- | :--- | :--- |
| **Location** | `location` | `GeoLocation` (Lat/Lon) | Event origin or reference centroid point |
| **Extent** | `geometry` / `spatialExtent` | GeoJSON Polygon/MultiPolygon | Affected physical footprint or hazard zone |
| **Uncertainty** | `uncertaintyRadiusMeters` | Numeric ($\pm \text{meters}$) | Spatial location uncertainty radius |
| **CRS** | `crs` | String (`EPSG:4326`) | Coordinate Reference System specification |
| **Basis** | `spatialBasis` | Enum (`observed`, `derived`, `remoteSensing`) | Provenance derivation origin |
