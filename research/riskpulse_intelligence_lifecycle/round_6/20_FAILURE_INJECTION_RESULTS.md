# RISKPULSE RESEARCH WORKSTREAM — ROUND 6: FAILURE INJECTION RESULTS

**Document Identifier**: `RISKPULSE_R6_20_FAILURE_INJECTION_RESULTS`  
**Workstream**: 20 Adversarial Failure Injection Tests & Results  
**Date**: October 1, 2026  
**Status**: EXPERIMENTAL FAILURE INJECTION LOG  

---

## 1. EVALUATION OF 20 ADVERSARIAL FAILURE INJECTION CASES

| Injection Case ID | Adversarial Test Input | Expected Pipeline Handling | Actual Pipeline Handling | Pass/Fail | State Effect | History Effect | Provenance Effect |
| :---: | :--- | :--- | :--- | :---: | :--- | :--- | :--- |
| **FI-01** | Missing evidence source ID | Quarantine ($E001$) | Quarantined cleanly | **PASS** | Halted | History intact | Logged |
| **FI-02** | Duplicate report payload | Deduplicate ($E008$) | Merged with original ID | **PASS** | Deduplicated | History intact | Lineage linked |
| **FI-03** | Contradictory report payload | Accept with conflict ($E009$)| Non-deletion conflict flag| **PASS** | Conflict marked | History intact | Dual lineage |
| **FI-04** | Malformed geometry payload | Warning ($E003$) | Geometry fallback | **PASS** | Point assigned | History intact | Logged |
| **FI-05** | Late observation ($> 24\text{h}$) | Bitemporal version ($E013$)| $V_7$ current revision | **PASS** | $V_7$ current | $V_1..V_6$ intact | Dual timestamps |
| **FI-06** | Source report withdrawal | Source withdrawal link ($E13$)| Weight set to $0$ | **PASS** | Hypothesis revised| History intact | Withdrawal logged |
| **FI-07** | Ambiguous place name | Candidate list ($E010$) | Candidate list emitted | **PASS** | Unresolved flag | History intact | Candidates logged|
| **FI-08** | Boundary redistricting | Re-crosswalk ($E016$) | $V_6$ attributed to $V_2$ | **PASS** | $V_6$ attributed | $V_3$ keeps $V_1$ | Boundary logged |
| **FI-09** | Dynamic edge redirection | Topology update ($E017$) | Edges redirected cleanly | **PASS** | Edges updated | History intact | Shift logged |
| **FI-10** | Source feed outage | Stale freeze | Last valid $V_k$ emitted | **PASS** | $V_k$ emitted | History intact | Offline logged |
| **FI-11** | Invalid state transition | Transition rejection | Blocked cleanly | **PASS** | Transition blocked| History intact | Rejection logged|
| **FI-12** | Cyclic dependency | Cycle detection | `CYCLE_DETECTED` flag | **PASS** | Graph protected | History intact | Cycle logged |
| **FI-13** | Orphan evidence | Intermediate state | Intermediate evidence node | **PASS** | Valid intermediate | History intact | Lineage kept |
| **FI-14** | Orphan event hypothesis | Intermediate state | Intermediate event node | **PASS** | Valid intermediate | History intact | Lineage kept |
| **FI-15** | Orphan risk state | Intermediate state | Intermediate risk node | **PASS** | Valid intermediate | History intact | Lineage kept |
| **FI-16** | Out-of-order arrival stream | Replay convergence | $100\%$ state convergence | **PASS** | Converged | History intact | Lineage kept |
| **FI-17** | Negative clearing report | Score reduction | Score reduced smoothly | **PASS** | Score = `0.65` | History intact | Lineage kept |
| **FI-18** | Event merge operation | Merged hypothesis | `EVT-C` created | **PASS** | Merged | Pre-merge intact | Lineage linked |
| **FI-19** | Event split operation | Split hypotheses | `EVT-E` & `EVT-F` created | **PASS** | Split | Pre-split intact | Lineage linked |
| **FI-20** | Direct state mutation attempt| Mutation rejection | Blocked; immutability kept| **PASS** | Blocked | 0 Corruption | Lineage kept |

---

## 2. ADVERSARIAL PASS RATE

- **Failure Injection Pass Rate**: **`20 / 20` (100% Passed)**.
