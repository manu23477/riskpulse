# HPSDMA GAP ANALYSIS — ROUND 4: INTEROPERABILITY ARCHITECTURE & TERMINOLOGY RESOLUTION

**Document Identifier**: `HPSDMA_R4_01_INTEROPERABILITY_ARCHITECTURE`  
**Workstream**: HPSDMA Interoperability Harness & Stateful/Stateless Terminology Resolution  
**Date**: October 1, 2026  
**Status**: RESEARCH / EXPERIMENTAL HARNESS ONLY — NO PRODUCTION IMPLEMENTATION  

---

## 1. TERMINOLOGY & ARCHITECTURE RESOLUTION

Round 3 described RiskPulse as a "stateless middleware layer" while simultaneously describing persistent evidence lineage, historical state versioning ($V_1..V_k$), and dependency-aware state tracking. Round 4 explicitly resolves this terminology:

### Resolved Architecture Model:
$$\text{STATELESS INTEROPERABILITY API} + \text{STATEFUL INTELLIGENCE ENGINE / STATE STORE}$$

```
+-----------------------------------------------------------------------------------+
|                        STATELESS INTEROPERABILITY API                             |
|  - Ingests raw observation payloads pushed from HPSDMA IMS or external sources    |
|  - Validates schemas, checks quality flags, and normalizes formats                |
|  - Emits enriched GeoJSON / REST state payloads to HPSDMA GIS-DSS                 |
+-----------------------------------------------------------------------------------+
                                         │
                                         ▼ (Internal Pipeline Execution)
+-----------------------------------------------------------------------------------+
|                   STATEFUL INTELLIGENCE ENGINE / STATE STORE                      |
|  - Immutable Evidence Store (Retains all raw reports & dual timestamps)           |
|  - Provenance & Lineage Graph (Maintains non-deletion contradiction links)         |
|  - 6-Layer Transitive Dependency Closure Engine (Tracks active DAG edges)         |
|  - Historical Version Manager (Preserves V_1..V_k reconstructable snapshots)      |
+-----------------------------------------------------------------------------------+
```

### Key Architectural Finding:
The external interface exposed to HPSDMA is a **stateless, RESTful Interoperability API**, allowing HPSDMA to push raw telemetry and pull enriched risk state objects without managing session state. Internally, RiskPulse operates a **stateful intelligence engine and persistent state store** to guarantee evidence immutability, lineage tracing, and bitemporal historical reconstruction.

---

## 2. PROPOSED EXPERIMENTAL PROCESSING CHAIN

```
RAW OBSERVATION [SYNTHETIC / PUBLICLY REPRESENTATIVE]
        ↓
INPUT VALIDATION (E001..E018 Error Handling)
        ↓
NORMALIZATION (Observation Envelope Schema)
        ↓
EVIDENCE OBJECT (Immutable, Dual-Timestamped t_observed vs t_received)
        ↓
SEMANTIC INTERPRETATION (Hazard Extraction & Source Confidence)
        ↓
TEMPORAL RESOLUTION (Known, Approximate, Conflicted, Unknown)
        ↓
SPATIAL RESOLUTION (Exact Coordinates, Village, Polygon, Uncertainty)
        ↓
CORROBORATION / CONTRADICTION (Clustering & Non-Deletion Contradiction Retention)
        ↓
EVENT HYPOTHESIS (Cluster Hypothesis, False Merge/Split Prevention)
        ↓
SPATIAL EVENT STATE (Derived Geometry & Spatial Error)
        ↓
ADMINISTRATIVE ATTRIBUTION (District / Block Crosswalk Mapping)
        ↓
RISK STATE (Composite Risk Score Assessment)
        ↓
PROVENANCE / VERSION (Immutable V_k Snapshot & Provenance Hash)
        ↓
OUTPUT CONTRACT (Proposed RiskPulse Outbound Interoperability Schema)
```

---

## 3. METHODOLOGICAL & REPOSITORY SAFETY DISCLAIMER

> [!IMPORTANT]
> All input datasets used in Round 4 are **[SYNTHETIC]** or **[PUBLICLY REPRESENTATIVE]** test structures designed to mimic heterogeneous disaster reports. They do NOT represent live or authenticated production HPSDMA data. No production code in `lib/` was modified.
