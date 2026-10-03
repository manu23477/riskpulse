# P2.9 RISK MAP ↔ RESEARCH GIS CONTRACT

When user clicks a risk object on Risk Map:
$$\text{RiskMap} \xrightarrow{\text{createSessionFromRiskObject()}} \text{RiskResearchSession} \xrightarrow{\text{Open Mode B}} \text{ResearchGIS}$$
When analysis finishes in Research GIS:
$$\text{ResearchGIS} \xrightarrow{\text{saveAnalysisResult()}} \text{ResearchAnalysisResult} \xrightarrow{\text{feedBack}} \text{Evidence / Interpretation} \xrightarrow{\text{getReturnContext()}} \text{RiskMap Overlay}$$
