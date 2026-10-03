# P2.4 SPATIAL VALIDATION RULES

1. **Rule 1 (Coordinate Bounds)**: Latitudes must fall within $[-90.0, 90.0]$ and longitudes within $[-180.0, 180.0]$.
2. **Rule 2 (CRS Integrity)**: `crs` field must be non-empty (defaults to `EPSG:4326`).
3. **Rule 3 (Geometry Structure)**: Polygon geometries must pass `AdministrativeGeometryValidator` ring closure checks.
4. **Rule 4 (No Silent Repair)**: Invalid source geometries shall fail validation with explicit error messages rather than undergoing silent coordinate mutation.
