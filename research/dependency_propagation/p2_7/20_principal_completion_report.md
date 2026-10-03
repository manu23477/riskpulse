# RISKPULSE P2.7 — SELECTIVE DEPENDENCY PROPAGATION ENGINE REPORT

**Workstream Identifier**: `RISKPULSE_P2_7_PROPAGATION`  
**Phase**: P2.7 (Selective Dependency Propagation Engine)  
**Date**: October 1, 2026  
**Final Verdict**: **`GREEN — SELECTIVE DEPENDENCY PROPAGATION ENGINE INTEGRATED AND VALIDATED`**  

---

## 1. EXECUTIVE SUMMARY

RiskPulse Phase P2.7 implemented the version-isolated, event-bounded Selective Dependency Propagation Engine, completing the intelligence lifecycle pipeline:
$$\text{Upstream Change (Trigger)} \xrightarrow{\text{Impact Analysis}} \text{Affected Subgraph} \xrightarrow{\text{Plan Topology}} \text{PropagationPlan} \xrightarrow{\text{Execute}} \text{NEW Immutable Derived State Versions}$$

P2.7 guarantees that when an upstream change occurs, ONLY affected downstream derived states are recomputed into new immutable versions ($S_2, A_2, R_2$). Prior state versions ($S_1, A_1, R_1$) and unaffected event branches remain $100\%$ untouched, queryable, and value-equivalent.

---

## 2. FORENSIC AUDIT & KEEP / EXTEND / ADAPTER / REPLACE DECISION MAP

Catalogued existing dependency structures in `01_forensic_dependency_inventory.md`.
- **KEEP & REUSE 100%**: `EvidenceObject`, `InterpretationObject`, `EventHypothesis`, `EvidenceRelationship`, `NegativeEvidence`, `EvidenceEvaluationResult`, `RevisionAssessment`, `RevisionDecision`, `GraphNode`, `GraphEdge`, `DependencyEdge`, `EventGraphService`, `SpatialStateService`, `AdministrativeStateService`, `DynamicRiskStateService`.
- **NEW**: `PropagationTrigger`, `PropagationChangeType`, `AffectedSubgraph`, `PropagationPlan`, `PropagationResult`, `PropagationService`, `PropagationRepository`.
- **REPLACE**: **NONE**. Zero existing production files replaced or broken.

---

## 3. PROPAGATION TRIGGER & CHANGE TAXONOMY

Implemented `PropagationTrigger` (`lib/domain/evidence/propagation_trigger.dart`) capturing source object ID, version, timestamp, reason, and change type (`PropagationChangeType`: `spatialChange`, `temporalChange`, `semanticChange`, `evidenceChange`, `supersession`).

---

## 4. AFFECTED SUBGRAPH & EVENT ISOLATION

`PropagationService.analyzeImpact()` calculates the affected node subgraph.
- **Event Isolation**: Event A changes do NOT propagate to Event B unless an explicit `CROSS_EVENT` dependency edge exists.
- **Version Isolation**: Propagation from $H_1\text{-v2}$ creates $S_1\text{-v2}, A_1\text{-v2}, R_1\text{-v2}$, leaving $H_1\text{-v1}, S_1\text{-v1}, A_1\text{-v1}, R_1\text{-v1}$ $100\%$ untouched.

---

## 5. TOPOLOGICAL PLAN & EXECUTION MODEL

`PropagationService.buildPropagationPlan()` builds a topologically sorted execution order. `executePropagation()` invokes P2.4, P2.5, and P2.6 state services to derive new immutable versioned state snapshots.

---

## 6. IDEMPOTENCY & FAILURE RECOVERY

- **Idempotency**: Re-running propagation with an identical trigger returns the existing successful result without creating duplicate versions.
- **Failure Recovery**: Execution errors leave existing valid state versions $100\%$ intact without state corruption.

---

## 7. SELECTIVE VS FULL REBUILD EQUIVALENCE

`compareSelectiveWithFullRebuild()` verifies that selective propagation output is value-equivalent to a full graph rebuild for affected nodes, while unaffected branches remain identical.

---

## 8. TEST & ANALYZER RESULTS

- Dedicated P2.7 Test Suite (`test/p2_7_dependency_propagation_test.dart`): **40 / 40 Passed GREEN**.
- Master Research Test Suite Across All Workstreams: **789 Tests Passed 100% GREEN** across 39 test suites.
- **Flutter Analyzer**: **`0 Errors`, `0 Warnings`**.

---

## 9. STRICT OUT-OF-SCOPE CONFIRMED

- NO predictive risk forecasting or alert broadcasting models.
- NO cross-event state mutation without explicit `CROSS_EVENT` graph edges.
- NO second graph engine or second administrative GIS engine.

---

## 10. FINAL VERDICT

```
P2.7 FINAL VERDICT:
GREEN — SELECTIVE DEPENDENCY PROPAGATION ENGINE INTEGRATED AND VALIDATED
```
