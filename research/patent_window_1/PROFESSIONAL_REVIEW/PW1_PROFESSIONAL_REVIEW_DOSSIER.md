# RISKPULSE PATENT WINDOW 1: PROFESSIONAL PATENT REVIEW DOSSIER

**Document Identifier**: `PW1_PROFESSIONAL_REVIEW_DOSSIER`  
**Workstream**: Patent Window 1 Evidence Fusion Technical & Prior-Art Review Package  
**Date**: September 30, 2026  
**Audited Workstream Milestones**: PW1C-1A through PW1C-6R  
**Visible Dataset Version**: `PW1C1-DATA-v1.0` (SHA-256 Validated & Frozen)  
**Hidden Ground Truth Version**: `PW1C1-GT-v1.0` (SHA-256 Validated & Frozen)  
**Expected Git HEAD Baseline**: `d6552707e0a693b04f40a2ade6a4efc5fdf9ae0a`  

---

## SECTION 1 — EXECUTIVE TECHNICAL SUMMARY

This dossier consolidates the complete experimental and prior-art research record for **Patent Window 1 (Evidence Fusion)** across workstreams PW1C-1A through PW1C-6R. It has been prepared specifically for review by a qualified patent attorney or patent professional.

### Key Summary Statements:
1. **Experimental Scope**: Patent Window 1 investigated multi-layer evidence fusion, bitemporal stream ingestion, and selective dependency propagation across a 6-layer directed acyclic graph (DAG) structure linking OSINT evidence to spatial, administrative, and risk states.
2. **Experimental Observations**: Under continuous mutation streams up to 1000 mutations/sec (`PW1C-5`), severe adversarial graph stress (`PW1C-5S`), and 10 component ablations (`PW1C-6`), selective dependency propagation maintained **100% full-rebuild state equivalence** ($M45 = 1.0$), **100% cross-event isolation** ($S02 = 1.0$), **100% historical state immutability** ($S08 = 1.0$), and an **89.62% to 99.91% recomputation reduction** over full graph rebuilds.
3. **Prior-Art Research Findings**: Targeted prior-art searches across USPTO, EPO, WIPO, and CNIPA databases (`PW1C-4`, `PW1C-5R`, `PW1C-6R`) established that generic software dependency graph invalidation (`US7441230B2`), selective recomputation (`EP3622411B1`), event-sourcing mutation tracking (`CN117235153B`), and bitemporal stream ingestion (`US20200379978A1`) are **broadly disclosed in existing prior art and do NOT constitute standalone patent distinctions**.
4. **Targeted Combination Status**: No single located reference in the searched corpus disclosed either the complete **C07 combination** (mutation + selective DAG closure + contradiction retention + shared administrative/risk crosswalk + cross-event isolation) or the complete **C08 combination** (late evidence + event-time vs arrival-time separation + historical state preservation + current state revision + shared spatial/admin/risk propagation + cross-event isolation). Both combinations remain **partially disclosed across separate references as multi-reference mosaics**.
5. **Legal Disclaimer**: This dossier presents factual experimental behavior and documented prior-art search findings. It does NOT constitute a legal determination of novelty, inventive step, patentability, validity, or freedom-to-operate.

---

## SECTION 2 — TECHNICAL PROBLEM

Conventional disaster intelligence systems face a fundamental trade-off when processing dynamic, multi-source OSINT evidence streams:
- **Global Rebuild Fragility**: Recomputing the entire spatial risk model whenever a single evidence item arrives or mutates introduces extreme computational latency and destroys historical state immutability.
- **Naïve Invalidation Poisoning**: Invertedly, invalidating global downstream cache states without tracing exact dependency closures can cause false cross-event state contamination when independent disaster events contribute to shared administrative boundaries or risk regions.

### Experimental Problem Statement:
*How can an evidence fusion system selectively propagate evidence updates and late-arriving reports through a multi-layer spatial/administrative/risk dependency graph, achieving exact state equivalence with a full graph rebuild while isolating unrelated event branches, preserving historical state versions, and retaining contradictory evidence?*

---

## SECTION 3 — RISKPULSE TECHNICAL MODEL

The experimental model defines six core conceptual objects:
1. **`EvidenceObject`**: Raw, immutable report containing extraction payload, source reliability, and timestamps ($t_{\text{event}}$ vs $t_{\text{arrival}}$).
2. **`InterpretationObject`**: Semantic interpretation of hazard type, intensity, and spatial extent derived from an `EvidenceObject`.
3. **`EventHypothesis`**: Aggregated cluster hypothesis representing a distinct disaster occurrence.
4. **`SpatialEventObject`**: Derived spatial geometry projected from an `EventHypothesis`.
5. **`EventStateHistory`**: Immutable version history of candidate states ($V_1..V_k$).
6. **`EvidenceLineageGraph`**: Directed acyclic graph recording complete evidence-to-state provenance.

### Core Separation Principles:
- Evidence $\neq$ Event
- Interpretation $\neq$ Evidence
- EventHypothesis $\neq$ Evidence
- SpatialEventObject is derived from EventHypothesis
- GIS Overlay is a projection of the derived state

---

## SECTION 4 — SIX-LAYER DEPENDENCY MODEL

The experimental dependency engine (`AdvancedDependencyGraphEngine`) constructs a 6-layer directed graph:
```
Layer 1: EvidenceNode (Immutable raw reports)
   ↓ (interprets)
Layer 2: InterpretationNode (Semantic interpretations & hazard hints)
   ↓ (aggregates)
Layer 3: EventHypothesisNode (Clustered event occurrence hypotheses)
   ↓ (projects_spatial)
Layer 4: SpatialStateNode (Geospatial geometry & spatial uncertainties)
   ↓ (crosswalks_admin)
Layer 5: AdministrativeStateNode (Shared district/block administrative units)
   ↓ (evaluates_risk)
Layer 6: RiskStateNode (Shared composite risk score assessments)
```

---

## SECTION 5 — C07 TECHNICAL BOUNDARY

### Target Combination C07:
```
             Event A ──────→ Spatial A ──────→ Administrative X ──────→ Risk X
             Event B ──────→ Spatial B ──────↗
```
When evidence affecting Event A mutates:
- **Selective Propagation**: Only $A \rightarrow Spatial A \rightarrow Admin X \rightarrow Risk X$ is recomputed.
- **Cross-Event Isolation**: Event B, Spatial B, B's provenance, B's historical state, and B's hypothesis state remain **100% unpoisoned and unaffected** ($S02 = 1.0$).
- **Contradiction Retention**: Contradictory evidence is retained in evidence lineage without silent deletion ($S05 = 1.0$).
- **Prior-Art Status**: **`PARTIAL MULTI-REFERENCE COVERAGE ONLY`** (Disclosed as a mosaic across `US7441230B2`, `CN117235153B`, `US10452652B2`, and `US9870396B2`).

---

## SECTION 6 — C08 TECHNICAL BOUNDARY

### Target Combination C08:
- Event occurs at $t_{\text{event}}$, report arrives later at $t_{\text{arrival}}$ ($t_{\text{arrival}} > t_{\text{event}}$).
- Late report changes Event A's candidate location or attribution.
- **Bitemporal Versioning**: Historical versions $V_1..V_k$ remain reconstructable and immutable ($S14 = 1.0$). Revised current version $V_{k+1}$ is created with $t_{\text{arrival}}$ timestamp.
- **Selective Downstream Propagation**: Revised current state propagates through spatial, administrative, and risk dependencies while keeping Event B 100% unaffected ($S13 = 1.0$).
- **Prior-Art Status**: **`PARTIAL MULTI-REFERENCE COVERAGE ONLY`** (Disclosed as a mosaic across `US20200379978A1`, `CN117235153B`, `US7441230B2`, and `US11200215B2`).

---

## SECTION 7 — EXPERIMENTAL EVIDENCE SUMMARY

| Milestone ID | Key Experimental Metric / Value | Technical Meaning |
| :---: | :--- | :--- |
| **PW1C-2B** | $M28 = 90.51\%$ | Selective propagation recomputation reduction over full rebuilds |
| **PW1C-3** | $M31 = 1.0$, $M32 = 1.0$, $M45 = 1.0$ | 100% historical reconstruction accuracy, 100% immutability, 100% full-rebuild equivalence across 7-generation mutation chains |
| **PW1C-5** | L0–L6 (1..1000 mut/sec), Queue = 0 | Sustained 1000 mut/sec stream throughput with $0.85\text{ ms}$ latency and $90.86\%$ recomputation reduction |
| **PW1C-5S** | $S01 = 1.0$, $S02 = 1.0$, $S18 = 0$, $S19 = 0$ | 100% cross-event isolation, 0 false propagations, 0 missed propagations under adversarial stress across 2..50 scale events |
| **PW1C-6** | $B01 = 1.0$, $B02 = 0.70$, $B15 = 1.0$ | Minimality preservation, 7/10 ablations trigger correctness failures, 100% survival across 14 counterexamples |

---

## SECTION 8 — ABLATION FINDINGS

Ablation testing (`PW1C-6`) demonstrated that 7 of 10 component removals produce correctness failures:
1. **Shared Administrative State Removal**: Crosswalk aggregation fails.
2. **Shared Risk State Removal**: Composite risk evaluation fails.
3. **Cross-Event Isolation Removal**: False propagation poisons unrelated Event B.
4. **Contradiction Retention Removal**: Contradictory evidence lost/deleted.
5. **Historical State Removal**: Historical reconstruction fails.
6. **Late-Arrival Distinction Removal**: Out-of-order streams corrupt history.
7. **Topology Mutation Removal**: Edge-changing mutations fail.

---

## SECTION 9 — ADVERSARIAL / FALSIFICATION RESULTS

Across all 14 adversarial counterexamples (`PW1C-6`), continuous high-frequency stream mutation tests (`PW1C-5`), and scale stress graphs up to 1000 events (`PW1C-5S`), zero false propagations ($S19 = 0$) and zero missed propagations ($S20 = 0$) occurred.

---

## SECTION 10 — PRIOR-ART LANDSCAPE

### Primary Audited Patent Families:
- **`US7441230B2` (`REF-01`)**: *Method of utilizing product proxies with a dependency graph* (Microsoft, 2003). Discloses build proxy DAG invalidation.
- **`EP3622411B1` (`REF-02`)**: *Incremental graph computations for querying large graphs* (SAP SE, 2018). Discloses graph query recomputation.
- **`US20200379978A1` (`REF-04`)**: *System and method of processing late arriving and out of order data* (Google, 2019). Discloses watermark-based bitemporal stream processing.
- **`CN117235153B` (`REF-08`)**: *ProV-DM model-based compliance data evidence-storing and tracing* (Zhejiang Univ, 2023). Discloses versioned provenance graphs.
- **`US10452652B2` (`REF-09`)**: *Geospatial event extraction and correlation graph* (BAE Systems, 2016). Discloses geospatial event correlation graphs.
- **`US9870396B2` (`REF-10`)**: *Multi-source evidence fusion and contradiction resolution* (Raytheon, 2014). Discloses multi-source contradiction resolution.
- **`US10891340B2` (`REF-C07-01`)**: *System and method for creating dependency graphs for build systems* (IBM, 2018; corrected title).
- **`US11200215B2` (`REF-C08-01`)**: *Incremental dependency resolution in database query execution* (Microsoft, 2019; corrected title).

---

## SECTION 11 — ALREADY-DISCLOSED TECHNICAL LAYER

The following 35 atomic features in `KNOWN_DISCLOSED_LAYER` are broadly disclosed in prior art and **MUST NOT be treated as standalone patent distinctions**:
- `F01`–`F04` (Separation principles), `F07`–`F19` (DAG invalidation, versioning, late arrival), `F22` (Shared branch propagation), `F24`–`F27` (Recomputation reduction, closure accuracy), `F30`–`F35` (Provenance, cross-event isolation), `F37`–`F38` (Stream mutation), `F45`–`F48` (Stream selective recomputation).

---

## SECTION 12 — COMBINATION-DEPENDENT BOUNDARY

The following 13 features represent combination-dependent relationships requiring legal evaluation:
- `F05`, `F06` (Spatial/admin/risk linkages)
- `F20`, `F21` (Shared downstream admin/risk dependencies)
- `F23` (Full-rebuild equivalence verification)
- `F28`, `F29` (False/missed propagation detection)
- `F36`, `F39`, `F40` (Admin/risk state downstream mutation updates)
- `F41` (Cross-event selective propagation under shared state)
- `F42`, `F43` (Late evidence propagating through shared administrative/risk states)

---

## SECTION 13 — C07/C08 COLLISION ANALYSIS

### Summary Collision Matrix:
- **C07 Single-Reference Coverage**: **PARTIAL COVERAGE ONLY**
- **C07 Multi-Reference Coverage**: **DISCLOSED AS MOSAIC**
- **C08 Single-Reference Coverage**: **PARTIAL COVERAGE ONLY**
- **C08 Multi-Reference Coverage**: **DISCLOSED AS MOSAIC**

---

## SECTION 14 — TECHNICAL BOUNDARY STATEMENTS

### Broad Formulation:
*A method for selective evidence propagation in disaster intelligence graphs, comprising: maintaining an explicit directed graph connecting evidence nodes to spatial, administrative, and risk nodes; invalidating only the affected dependency closure upon evidence mutation; and preserving unaffected event hypotheses and historical version records.*

### Medium-Granularity Formulation:
*An evidence fusion system comprising: a multi-layer dependency graph connecting evidence interpretations to event hypotheses and shared downstream administrative risk nodes; an active propagation engine executing mutation-driven selective invalidation; and a bitemporal state history manager separating event occurrence time from evidence arrival time.*

### Narrow Mechanism Formulation:
*A selective recomputation mechanism for multi-event disaster graphs, wherein mutating evidence for a first event recomputes its derived spatial state and updates shared administrative and risk nodes while preserving the hypothesis, spatial state, and provenance of a second independent event contributing to the same administrative node.*

---

## SECTION 15 — CLAIM-BUILDING BLOCKS

1. Immutable evidence object with source reliability and dual timestamps ($t_{\text{event}}$, $t_{\text{arrival}}$).
2. Separation of interpretation objects from raw evidence and candidate event hypotheses.
3. 6-layer directed dependency graph linking evidence to shared administrative units and risk scores.
4. Mutation-driven transitive dependency closure calculation.
5. Selective downstream node invalidation and recomputation.
6. Cross-event isolation under shared administrative/risk node attributions.
7. Non-deletion contradiction retention within evidence lineage graphs.
8. Bitemporal state versioning creating revised current states without overwriting historical versions.

---

## SECTION 16 — LIMITATIONS

1. Experiments used synthetic/controlled research datasets (`PW1C1-DATA-v1.0`).
2. Production RiskPulse (`lib/`) was not modified during PW1 research.
3. Tested stream frequency maximum was 1000 mutations/sec ($0.85\text{ ms}$ latency).
4. The 2500 mut/sec figure was an estimated theoretical degradation point, not a measured threshold.
5. Prior-art searches were thorough but do not constitute an exhaustive worldwide freedom-to-operate search.
6. Legal patentability, novelty, inventive step, and infringement were not legally determined.

---

## SECTION 17 — QUESTIONS FOR PATENT COUNSEL

See `PW1_COUNSEL_QUESTIONS.md` for the full list of 15 structured legal questions.

---

## SECTION 18 — REPRODUCIBILITY AND AUDIT TRAIL

- **Git HEAD Baseline**: `d6552707e0a693b04f40a2ade6a4efc5fdf9ae0a`
- **Dataset Hashes**:
  - `visible/evidence_objects.json`: `e7785f567660afad4c0dd33111282698db106501571b2bb679005a7cfd0133e1`
  - `ground_truth/ground_truth_cases.json`: `d3c4688ae0ae3314e7082b2360ce2042e11b4a9b3666c8f5dd15043c1d83be93`
- **Master Test Suite Status**: **114 Tests Passed 100% GREEN** across 11 test suites.
- **Flutter Analyzer**: **0 Errors, 0 Warnings**.

---

## SECTION 19 — FINAL RESEARCH POSITION

*Patent Window 1 has established an experimentally supported technical boundary and a documented prior-art boundary for professional review. The research indicates that generic component mechanisms are broadly represented in the located prior art, while the complete C07 and C08 combinations were not located in a single reference within the searched material. The experiments demonstrate the behavior of the proposed mechanism under the tested conditions. These findings do not constitute a legal determination of novelty, inventive step, patentability, validity, or freedom to operate.*

---

NO PRODUCTION RISKPULSE CODE MODIFIED.
NO PATENTABILITY OR NOVELTY CONCLUSION MADE.
