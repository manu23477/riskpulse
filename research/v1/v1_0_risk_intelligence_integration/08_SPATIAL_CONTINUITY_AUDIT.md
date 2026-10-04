# V1.0 SPATIAL CONTINUITY AUDIT

- **CRS Uniformity**: All spatial geometries use `EPSG:4326` WGS84.
- **Buffer Isolation Invariant**: `studyAreaGeometry` and `bufferMeters` are kept distinct from `targetGeometry` and `SpatialState`.
