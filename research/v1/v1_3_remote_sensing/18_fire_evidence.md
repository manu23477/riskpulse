# V1.3 FOREST FIRE PHYSICAL EVIDENCE WORKFLOW

1. Retrieve Sentinel-2 optical imagery.
2. Compute pre vs post Normalized Burn Ratio ($\text{NBR} = (B8 - B12) / (B8 + B12)$).
3. Generate `EvidenceObject` ("Burn-related surface change detected").
