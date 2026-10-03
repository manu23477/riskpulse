# RISKPULSE PATENT WINDOW 1: STRATEGY BOUNDARY ANALYSIS

**Document Identifier**: `PW1_STRATEGY_BOUNDARY_ANALYSIS`  
**Workstream**: Patent Window 1 Evidence Fusion Strategy Boundary Analysis  
**Date**: September 30, 2026  
**Audited Evidence Base**: PW1C-1A through PW1C-6R & Professional Review Dossier  
**Expected Git HEAD Baseline**: `d6552707e0a693b04f40a2ade6a4efc5fdf9ae0a`  

---

## 1. PURPOSE

This report presents an exact strategy boundary analysis of Patent Window 1 (Evidence Fusion), isolating the minimal Common Technical Core shared between Combinations C07 and C08, evaluating single-reference versus multi-reference prior-art collisions, formulating Technical Boundaries A (Broad), B (Medium), and C (Narrow), and establishing a structured Counsel Decision Tree and One-Page Counsel Brief.

> [!IMPORTANT]
> **RESEARCH BOUNDARY MANDATE**:
> - NO new experimental campaigns or distributed scale-out experiments (PW1C-7) were started.
> - NO patentability, novelty, or inventive step conclusion is made.
> - The terms "novel", "patentable", "inventive", "patent-worthy" are strictly excluded as conclusions.
> - Classifications used: `ESTABLISHED FOR REVIEW`, `UNDETERMINED`, `NOT LEGALLY DETERMINED`, `NOT ASSESSED`.
> - NO production RiskPulse code in `lib/` was modified.

---

## 2. FROZEN EVIDENCE BASE

The complete research record from PW1C-1A through PW1C-6R and the Professional Review Dossier (`PW1_PROFESSIONAL_REVIEW_DOSSIER.md`) serves as the frozen evidence base. All dataset SHA-256 hashes, metrics ($M01..M72$, $S01..S21$, $B01..B16$), prior-art matrices, and search logs are incorporated without alteration.

---

## 3. C07 BOUNDARY ANALYSIS

### Audited C07 Relationship:
$$Event A / Event B \rightarrow Spatial A / Spatial B \rightarrow Shared Admin X \rightarrow Shared Risk X$$
When evidence affecting Event A mutates:
- **Recomputes**: $A \rightarrow Spatial A \rightarrow Admin X \rightarrow Risk X$.
- **Preserves**: Event B hypothesis, Spatial B, B's provenance, B's historical state, B's hypothesis state ($100\%$ unpoisoned).
- **Retains**: Contradictory evidence in evidence lineage without silent deletion.

### Prior-Art Breakdown:
- **Disclosed Components**: Generic software DAG invalidation (`REF-01` US7441230B2), selective recomputation (`REF-02` EP3622411B1), event-sourcing mutations (`REF-08` CN117235153B).
- **Partially Disclosed**: Multi-layer spatial administrative risk crosswalks (`REF-09` US10452652B2).
- **Single-Reference Collision**: **NO** (No single located reference discloses the complete C07 relationship in a single publication).
- **Multi-Reference Mosaic**: Disclosed across separate references (`REF-01`, `REF-08`, `REF-09`, `REF-10`).
- **Obviousness Vulnerability**: High risk if examiner combines DAG invalidation (`REF-01`) with geospatial correlation (`REF-09`).

---

## 4. C08 BOUNDARY ANALYSIS

### Audited C08 Relationship:
- Event occurs at $t_{\text{event}}$, report arrives later at $t_{\text{arrival}}$ ($t_{\text{arrival}} > t_{\text{event}}$).
- System creates revised current version $V_{k+1}$ while preserving historical versions $V_1..V_k$ reconstructable and immutable.
- Revised state propagates through spatial, administrative, and risk dependencies while preserving unrelated Event B.

### Prior-Art Breakdown:
- **Disclosed Components**: Bitemporal stream ingestion (`REF-04` US20200379978A1), versioned provenance graphs (`REF-08` CN117235153B), selective DAG invalidation (`REF-01` US7441230B2).
- **Single-Reference Collision**: **NO** (No single located reference discloses the complete C08 relationship in a single publication).
- **Multi-Reference Mosaic**: Disclosed across separate references (`REF-04`, `REF-08`, `REF-01`, `REF-C08-01`).

---

## 5. COMMON TECHNICAL CORE VS C07/C08-SPECIFIC FEATURES

### Classification:
1. **COMMON TECHNICAL CORE**:
   - Mutation-driven selective dependency closure propagation.
   - Cross-event isolation preserving unrelated event hypotheses ($100\%$ unpoisoned).
   - Versioned state history preservation ($V_1..V_k$).
2. **C07-SPECIFIC**:
   - Multi-event shared administrative unit and risk score crosswalk recomputation.
   - Non-deletion contradiction retention within evidence lineage.
3. **C08-SPECIFIC**:
   - Separation of event time ($t_{\text{event}}$) from evidence arrival time ($t_{\text{arrival}}$).
   - Bitemporal current-state revision without overwriting prior historical snapshots.
4. **SUPPORTING**:
   - Evidence object immutability, source reliability weighting, spatial/temporal uncertainty bounds.
5. **KNOWN DISCLOSED**:
   - 35 atomic features in `KNOWN_DISCLOSED_LAYER` (`F01`–`F04`, `F07`–`F19`, `F22`, `F24`–`F27`, `F30`–`F35`, `F37`–`F38`, `F45`–`F48`).

---

## 6. SINGLE-REFERENCE VS MULTI-REFERENCE PRIOR-ART TEST

### Single-Reference Test Results:
- **Does one located reference disclose complete C07?** **NO**
- **Does one located reference disclose complete C08?** **NO**

Both boundaries exist as **multi-reference mosaics** across separate prior-art publications.

---

## 7. MULTI-REFERENCE / OBVIOUSNESS PREPARATION FOR COUNSEL

| Reference Combination | Combined Technical Teaching | Potential Motivation to Combine | Counsel Evaluation Needed |
| :--- | :--- | :--- | :--- |
| `REF-01` (Microsoft) + `REF-09` (BAE Systems) | Software DAG invalidation applied to geospatial event graphs | Extending general software build invalidation to GIS layers | Does applying standard DAG invalidation to GIS crosswalks involve an inventive step? |
| `REF-04` (Google) + `REF-08` (Zhejiang) + `REF-01` | Bitemporal stream ingestion with versioned graphs and DAG invalidation | Processing out-of-order data in versioned graph databases | Is the combination of bitemporal stream processing and DAG versioning obvious to a person skilled in the art? |

---

## 8. TECHNICAL CONTRIBUTION / CHARACTER ANALYSIS

From an engineering perspective, the system exhibits the following technical properties:
- **INPUT**: Mutable OSINT evidence reports with source reliability and dual timestamps ($t_{\text{event}}$, $t_{\text{arrival}}$).
- **PROCESS**: Dependency-aware selective state propagation calculating exact transitive closure.
- **DATA STRUCTURE**: 6-layer directed acyclic graph linking evidence to shared administrative risk nodes.
- **OUTPUT**: Updated spatial, administrative, and risk states.
- **TECHNICAL CONTROL**: Unaffected event branches remain 100% unpoisoned ($S02 = 1.0$).
- **TEMPORAL INTEGRITY**: Historical version records remain 100% immutable ($S08 = 1.0$, $S14 = 1.0$).
- **PERFORMANCE OBSERVATION**: **89.62% to 99.91% recomputation reduction** over full graph rebuilds ($S21$).
- **STATE EQUIVALENCE**: **100% exact state equivalence** ($S01 = 1.0$, $S17 = 1.0$) against full graph rebuilds.

*Note: Whether these engineering properties satisfy technical character requirements under Indian Patent Law (Section 3(k)), EPO Guidelines (G-II, 3.6), or USPTO Alice guidelines requires professional counsel evaluation.*

---

## 9. THREE-TIERED TECHNICAL BOUNDARY FORMULATIONS

### Technical Boundary A (Broad):
*A method for selective evidence propagation in disaster intelligence graphs, comprising: maintaining a directed graph connecting evidence nodes to spatial, administrative, and risk nodes; invalidating only the affected dependency closure upon evidence mutation; and preserving unaffected event hypotheses and historical version records.*

### Technical Boundary B (Medium):
*An evidence fusion system comprising: a multi-layer dependency graph connecting evidence interpretations to event hypotheses and shared downstream administrative risk nodes; an active propagation engine executing mutation-driven selective invalidation; and a bitemporal state history manager separating event occurrence time from evidence arrival time.*

### Technical Boundary C (Narrow):
*A selective recomputation mechanism for multi-event disaster graphs, wherein mutating evidence for a first event recomputes its derived spatial state and updates shared administrative and risk nodes while preserving the hypothesis, spatial state, and provenance of a second independent event contributing to the same administrative node.*

---

## 10. ABLATION CROSS-CHECK

Mapping core features against ablation evidence (`PW1C-6`):
- **Shared Admin / Risk Nodes**: Required for correctness (`ABL-01`, `ABL-02` failed).
- **Cross-Event Isolation**: Required for correctness (`ABL-03` failed with false propagation).
- **Contradiction Retention**: Required for correctness (`ABL-04` failed with evidence loss).
- **Historical State Versioning**: Required for correctness (`ABL-05` failed).
- **Late Arrival Distinction**: Required for correctness (`ABL-06` failed with history corruption).
- **Topology Mutation**: Required for correctness (`ABL-07` failed).

7 of 10 component ablations produced correctness failures, establishing that these features are **experimentally necessary for system correctness**.

---

## 11. COUNSEL DECISION TREE SUMMARY

See `PW1_COUNSEL_DECISION_TREE.md` for the complete decision tree diagram and legal review flows.

---

## 12. UNRESOLVED LEGAL QUESTIONS FOR COUNSEL

1. Should C07 and C08 be filed as a single application with multiple independent claims or as separate applications?
2. Does the technical performance reduction (89.62%–99.91%) provide persuasive technical character under EPO/USPTO guidelines?
3. What specific claim framing strategy best protects against 35 U.S.C. § 101 / Section 3(k) abstract idea rejections?

---

## 13. FINAL NEUTRAL RESEARCH POSITION

*PW1 has experimentally established a reproducible technical mechanism under the tested conditions. The generic underlying components are substantially represented in prior art. The searched corpus did not identify a single reference containing the complete tested C07 relationship or the complete tested C08 relationship. However, multiple prior-art references disclose individual components, and inventive-step/obviousness analysis may consider combinations of prior art.*

```
TECHNICAL BOUNDARY: ESTABLISHED FOR REVIEW
PATENTABILITY: UNDETERMINED
NOVELTY: NOT LEGALLY DETERMINED
INVENTIVE STEP: NOT LEGALLY DETERMINED
FREEDOM TO OPERATE: NOT ASSESSED
```

---

NO PRODUCTION RISKPULSE CODE MODIFIED.
NO PATENTABILITY OR NOVELTY CONCLUSION MADE.
