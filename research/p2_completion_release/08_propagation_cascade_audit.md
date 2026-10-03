# P2 PROPAGATION AND CASCADE AUDIT

- **Selective Dependency Propagation**: P2.7 `PropagationService` recomputes ONLY affected derived states into new immutable versions ($S_2, A_2, R_2$) without mutating prior versions or unaffected event branches.
- **Cascade Intelligence**: P2.8 `CascadeService` manages multi-depth causal chains ($E_0 \rightarrow E_1 \rightarrow I_2 \rightarrow S_3$) without creating a second graph or propagation engine.
