# V1.4 ARCHITECTURAL DECISIONS

- **ENVIRONMENTAL OBSERVATION vs HYDRO MODELING**: V1.4 measures environmental forcing ($\text{Precipitation}, \text{River Stage}$). V1.5 models hydrological response.
- **NO SECOND EVIDENCE ARCHITECTURE**: Environmental indicators convert directly into P2 `EvidenceObject` records.
- **NO INVENTED FLOOD DISASTERS**: High rainfall or river stage rise creates an `EvidenceObject`, NOT a confirmed flood event.
