# V1.6 ARCHITECTURAL DECISIONS

- **STRICT SCIENTIFIC BOUNDARY**: $\text{EXPOSURE} \neq \text{IMPACT}$. Spatial intersection creates an exposure record, NOT a damage claim.
- **NO FABRICATED DAMAGE**: Damage claims require explicit `EvidenceObject` records with `isObserved = true`.
- **NO DATASET MISREPRESENTATION**: Census 2011 population data is explicitly labelled `Census 2011 Reference Population`.
