# RISKPULSE PATENT WINDOW 1: ONE-PAGE BRIEF FOR PATENT COUNSEL

**Document Identifier**: `PW1_PATENT_COUNSEL_ONE_PAGE_BRIEF`  
**Target Audience**: Patent Attorney / IP Professional (Read Time: ~3–5 Minutes)  
**Date**: September 30, 2026  

---

### A. WHAT RISKPULSE MECHANISM IS BEING PRESENTED
A computer-implemented selective evidence propagation engine for dynamic disaster intelligence graphs. Mutating OSINT evidence items triggers selective recomputation across a 6-layer graph connecting raw evidence to spatial, administrative, and risk states, while maintaining cross-event isolation, retaining contradictory evidence, and preserving bitemporal state version history.

---

### B. WHAT WAS EXPERIMENTALLY DEMONSTRATED
- **Recomputation Reduction**: Evaluated only 3.2 nodes per mutation versus 35 nodes for full rebuilds (**89.62% to 99.91% recomputation reduction**).
- **Exact Equivalence**: Achieved **100% exact state equivalence** ($M45 = 1.0$, $S01 = 1.0$) against full graph rebuilds.
- **Cross-Event Isolation**: Maintained **100% cross-event isolation** ($S02 = 1.0$, 0 false propagations) across scale graphs with 2 to 50 events sharing administrative units.
- **Stream Throughput**: Sustained **1000 mutations/sec** continuous throughput with $0.85\text{ ms}$ latency and 0 queue backlog.
- **Ablation Minimality**: 7 of 10 component removals caused correctness failures ($B02 = 0.70$).

---

### C. C07 BOUNDARY (SHARED ADMINISTRATIVE/RISK DAG PROPAGATION)
Mutating Event A's evidence recomputes $A \rightarrow Spatial A \rightarrow Admin X \rightarrow Risk X$ while preserving Event B hypothesis, Spatial B, and B's historical versions **100% unpoisoned and unaffected**.

---

### D. C08 BOUNDARY (BITEMPORAL LATE-EVIDENCE STATE REVISION)
Late report $E_4$ arriving at 11:00 for an event at 09:55 ($t_{\text{arrival}} > t_{\text{event}}$) creates revised current state version $V_5$ while preserving historical versions $V_1..V_4$ reconstructable and immutable.

---

### E. WHAT PRIOR ART ALREADY COVERS (KNOWN-DISCLOSED LAYER)
Generic software DAG invalidation (`US7441230B2`), selective recomputation (`EP3622411B1`), bitemporal stream processing (`US20200379978A1`), and versioned provenance graphs (`CN117235153B`) are **broadly disclosed and MUST NOT be claimed as standalone inventions**.

---

### F. WHAT COMPLETE RELATIONSHIPS WERE NOT LOCATED
No single located reference in the searched corpus disclosed either the complete **C07 combination** or the complete **C08 combination**. Both exist as multi-reference mosaics across separate prior-art publications.

---

### G. MAIN TECHNICAL QUESTION FOR COUNSEL
*Does the selective propagation across multi-layer spatial administrative risk crosswalks with cross-event isolation provide sufficient technical character to satisfy patent eligibility requirements under USPTO Alice guidelines, EPO Article 52(2)/(3), and Indian Patent Act Section 3(k)?*

---

### H. MAIN LEGAL QUESTIONS FOR COUNSEL
1. Should Combinations C07 and C08 be filed as a single application with multiple independent claims or as separate divisional applications?
2. Does the multi-reference mosaic (`REF-01` + `REF-09` + `REF-04`) create a strong 35 U.S.C. § 103 obviousness challenge, and how can the claims be structured to overcome it?
3. Is immediate filing of a U.S. Provisional Patent Application recommended prior to further research publication?

---

### I. EVIDENCE PACKAGE LOCATION
Full evidence dossier, feature matrices, test suites, and manifests are located at:  
`research/patent_window_1/PROFESSIONAL_REVIEW/`
