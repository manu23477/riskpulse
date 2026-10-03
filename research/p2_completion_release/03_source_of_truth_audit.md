# P2 SOURCE OF TRUTH MATRIX

| Domain Concept | Authoritative Source of Truth |
| :--- | :--- |
| **Raw Observation Data** | `EvidenceObject` (`lib/domain/evidence/evidence_object.dart`) |
| **Inferred Meaning** | `InterpretationObject` (`lib/domain/evidence/interpretation_object.dart`) |
| **Candidate Event Identity** | `EventHypothesis` (`lib/domain/evidence/event_hypothesis.dart`) |
| **Graph Topology & Lineage** | `EventGraphService` (`lib/data/services/evidence/event_graph_service.dart`) |
| **Versioned Geometry Footprint** | `SpatialState` (`lib/domain/evidence/spatial_state.dart`) |
| **Administrative Overlap State** | `AdministrativeState` (`lib/domain/evidence/administrative_state.dart`) |
| **Dynamic Risk Condition** | `DynamicRiskState` (`lib/domain/evidence/dynamic_risk_state.dart`) |
| **Propagation Execution** | `PropagationService` (`lib/data/services/evidence/propagation_service.dart`) |
| **Causal Cascade Chains** | `CascadeService` (`lib/data/services/evidence/cascade_service.dart`) |
| **Cross-View Intelligence Context** | `RiskResearchSession` (`lib/domain/evidence/risk_research_session.dart`) |
