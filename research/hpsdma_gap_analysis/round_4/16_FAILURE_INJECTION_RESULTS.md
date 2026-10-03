# HPSDMA GAP ANALYSIS — ROUND 4: FAILURE INJECTION RESULTS

**Document Identifier**: `HPSDMA_R4_16_FAILURE_INJECTION_RESULTS`  
**Workstream**: 20 Adversarial Failure Injection Tests & Results  
**Date**: October 1, 2026  
**Status**: RESEARCH / EXPERIMENTAL HARNESS ONLY  

---

## 1. EVALUATION OF 20 ADVERSARIAL FAILURE INJECTION CASES

| Injection Case ID | Adversarial Test Input | Expected Harness Handling | Actual Harness Handling | Pass/Fail | State Effect | Historical Effect | Provenance Effect |
| :---: | :--- | :--- | :--- | :---: | :--- | :--- | :--- |
| **FI-01** | Null source ID | Quarantine ($E001$) | Quarantined cleanly | **PASS** | Halted | History intact | Logged |
| **FI-02** | Null timestamp | Warning ($E002$) | Fallback to $t_{\text{received}}$ | **PASS** | $t_{\text{received}}$ logged | History intact | Logged |
| **FI-03** | Invalid timestamp `"bad-date"` | Warning ($E002$) | Fallback to $t_{\text{received}}$ | **PASS** | $t_{\text{received}}$ logged | History intact | Logged |
| **FI-04** | Lat $> 90^\circ$ (`95.0`) | Reject ($E003$) | Rejected immediately | **PASS** | Halted | History intact | Logged |
| **FI-05** | Duplicate report payload | Deduplicate ($E008$) | Merged with original ID | **PASS** | Deduplicated | History intact | Lineage linked |
| **FI-06** | Duplicate sensor feed | Deduplicate ($E008$) | Transmission filtered | **PASS** | Timestamp updated | History intact | Lineage linked |
| **FI-07** | Reposted OSINT tweet | Link repost | Linked; weight uninflated| **PASS** | Uninflated | History intact | Lineage linked |
| **FI-08** | Contradictory govt reports | Accept with conflict ($E009$)| Non-deletion conflict flag| **PASS** | Conflict marked | History intact | Dual lineage |
| **FI-09** | Satellite contradicts report | Accept with conflict ($E009$)| Marked for EOC review | **PASS** | Flagged | History intact | Dual lineage |
| **FI-10** | Ambiguous village name | Candidate list ($E010$) | Candidate list emitted | **PASS** | Unresolved flag | History intact | Candidates logged|
| **FI-11** | District boundary ambiguity | Dual crosswalk | Proportional attribution | **PASS** | Dual attributed | History intact | Ratios logged |
| **FI-12** | Late observation ($> 24\text{h}$) | Bitemporal version ($E013$)| $V_{k+1}$ current revision | **PASS** | $V_{k+1}$ current | $V_1..V_k$ intact | Dual timestamps |
| **FI-13** | Stale telemetry ($> 7\text{d}$) | Quality flag ($E012$) | `STALE_DATA` flag appended | **PASS** | Weight reduced | History intact | Flag logged |
| **FI-14** | Missing measurement value | Warning ($E006$) | Measurement omitted | **PASS** | Value null | History intact | Raw retained |
| **FI-15** | Unknown unit `"cubits"` | Warning ($E007$) | Raw unit retained + flag | **PASS** | Flagged | History intact | Raw retained |
| **FI-16** | Schema version 1 legacy | Version adapter ($E014$) | Up-converted to Envelope | **PASS** | Envelope emitted | History intact | Schema logged |
| **FI-17** | Missing admin polygon map | Unmapped fallback ($E011$)| `"Unmapped_Border_Zone"` | **PASS** | Fallback assigned | History intact | Geometry kept |
| **FI-18** | Spatial topology shift | Topology update ($E017$) | Edges redirected cleanly | **PASS** | Edges updated | History intact | Shift logged |
| **FI-19** | Shared downstream mutation | Selective closure | Recomputed shared nodes | **PASS** | Admin X updated | Event B intact | Lineage linked |
| **FI-20** | Source feed offline | Stale freeze | Last valid $V_k$ emitted | **PASS** | $V_k$ emitted | History intact | Offline logged |

---

## 2. ADVERSARIAL PASS RATE

- **Failure Injection Pass Rate**: **`20 / 20` (100% Passed)**.
- **Zero Unhandled Exceptions**: All 20 adversarial failure injection cases were handled cleanly by explicit error quarantine, fallback, or non-deletion lineage rules.
