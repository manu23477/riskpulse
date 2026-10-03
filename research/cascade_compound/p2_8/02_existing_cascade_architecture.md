# P2.8 EXISTING CASCADE ARCHITECTURE

P2.8 builds directly on GREEN baselines P1.1..P2.7.
`CascadeService` delegates directional topology registration to P2.3 `EventGraphService` and downstream state recomputation to P2.7 `PropagationService`.

$$\text{Root Hazard (Depth 0)} \xrightarrow{\text{triggers}} \text{Secondary Event (Depth 1)} \xrightarrow{\text{resultsIn}} \text{Infrastructure Consequence (Depth 2)} \xrightarrow{\text{resultsIn}} \text{Service Disruption (Depth 3)}$$
