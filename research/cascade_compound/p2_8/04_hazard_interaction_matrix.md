# P2.8 HAZARD INTERACTION MATRIX

| Primary Hazard | Secondary Hazard | Interaction Type | Spatial Relationship | Temporal Relationship | Causal Basis Required |
| :--- | :--- | :--- | :--- | :--- | :---: |
| **Cloudburst** | Flash Flood | `triggers` | Co-located catchment | Immediate ($<1\text{ hr}$) | Gauge / Remote Sensing |
| **Heavy Rainfall** | Landslide | `triggers` | Slope area | Short ($<12\text{ hrs}$) | Geotechnical / Rainfall |
| **Landslide** | River Damming / GLOF | `resultsIn` | River channel intersection | Delayed ($1\text{--}24\text{ hrs}$) | Satellite / Field Report |
| **Landslide** | Road Blockage | `resultsIn` | Highway alignment | Immediate | Field / OSINT Report |
| **Earthquake** | Landslide | `triggers` | Seismic fault buffer | Immediate ($<1\text{ hr}$) | Seismograph / Remote Sensing |
| **Forest Fire** | Slope Instability | `amplifies` | Burn scar footprint | Long-term ($>1\text{ month}$) | Sentinel-2 Burn Scar |
