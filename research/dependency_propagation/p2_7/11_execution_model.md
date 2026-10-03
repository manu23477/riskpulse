# P2.7 EXECUTION MODEL

`PropagationService.executePropagation()` iterates over the topological `executionOrder`, invoking state creation methods (`createNextVersion()`) on P2.4 `SpatialStateService`, P2.5 `AdministrativeStateService`, and P2.6 `DynamicRiskStateService`.
