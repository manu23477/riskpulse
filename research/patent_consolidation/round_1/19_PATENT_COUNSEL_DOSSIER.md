# CONSOLIDATED INVENTION BOUNDARY REVIEW — ROUND 1: PATENT COUNSEL DOSSIER

**Document Identifier**: `CONSOLIDATED_R1_19_PATENT_COUNSEL_DOSSIER`  
**Workstream**: Professional Technical Dossier Prepared for Patent Counsel Review  
**Date**: October 1, 2026  
**Status**: RESEARCH SYNTHESIS DOSSIER — NO PATENT CLAIMS DRAFTED  

---

## 1. TECHNICAL DOSSIER PREPARED FOR PROFESSIONAL PATENT COUNSEL

### 1. Technical Field:
Geospatial Information Systems (GIS), Disaster Intelligence, Spatiotemporal Data Processing, and Directed Acyclic Graph (DAG) Dependency Management.

### 2. Technical Problem:
Existing disaster risk platforms rely on static map layer overlays or full-database batch recomputations. When heterogeneous disaster observations arrive out-of-order, existing systems suffer from: (a) high computational overhead due to full graph rebuilds, (b) false cross-event state contamination, and (c) loss of historical auditability when earlier states are overwritten.

### 3. Proposed Technical Solution (RiskPulse):
An observation mutation-driven, 6-layer transitive DAG closure engine that recomputes only affected downstream spatial, administrative, and risk nodes, enforces cross-event branch isolation, and maintains bitemporal historical version snapshots ($V_1..V_k$) with unbroken machine-readable provenance.

### 4. Minimal Indispensable Technical Core:
1. Ingestion of observation mutations across heterogeneous feeds.
2. Generation of immutable evidence objects with dual timestamps ($t_{\text{observed}}$ vs $t_{\text{received}}$).
3. Event hypothesis clustering and spatial-administrative unit crosswalk attribution.
4. Transitive 6-layer DAG closure recomputing only affected downstream states.
5. Cross-event and cross-region branch isolation.
6. Bitemporal historical version store preserving immutable past snapshots ($V_1..V_k$).

### 5. Prior-Art Audit Summary:
- **Single-Reference Audit (`PW2R7`)**: 0 out of 15 candidate prior-art references disclose the complete K10 relationship chain in a single publication.
- **NPL Audit (`PW2R8`)**: 0 out of 10 primary academic papers disclose the complete relationship core in a single paper.
- **Combination Audit (`PW2R8`)**: Combining 4 disparate patent families gathers individual atomic features but requires hindsight and substantial architectural redesign ($T10 = \text{YES}$).

### 6. Key Questions for Patent Counsel Evaluation:
1. Should Candidate A (generalized observation mutation DAG) be filed as the main independent genus claim, with Candidate B (remote-sensing specific mutation DAG) filed as dependent species claims?
2. How should the non-geospatial build system prior art (`US7441230B2`) be distinguished during prosecution to emphasize domain mismatch and the technical necessity of 2D spatial crosswalks?
3. What is the optimal claim structure for expressing bitemporal state versioning ($t_{\text{observed}}$ vs $t_{\text{received}}$) in combination with transitive DAG closure?
