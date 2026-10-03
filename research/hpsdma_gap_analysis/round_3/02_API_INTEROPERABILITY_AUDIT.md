# HPSDMA GAP ANALYSIS — ROUND 3: API & INTEROPERABILITY AUDIT

**Document Identifier**: `HPSDMA_R3_02_API_INTEROPERABILITY_AUDIT`  
**Workstream**: HPSDMA API, Object Flow, and Technical Integration Audit  
**Date**: September 30, 2026  
**Status**: RESEARCH ONLY — NO PRODUCTION CODE CHANGES  

---

## 1. DATA OBJECT FLOW CLASSIFICATION

HPSDMA public documentation identifies 16 distinct disaster information categories entering the ecosystem:

| Object Category | Source System | Ingestion Method | Transformation | GIS Representation | DSS / EOC Use |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **1. EWS Observations** | GLOF / Landslide Sensors | Push / Pull Feed | Threshold check | Point Layer | Alert generation |
| **2. Sensor Feeds** | CWC / Jal Shakti | API / Telemetry | Value extraction | Hydro Station Overlay | Flood monitoring |
| **3. Weather / Forecast** | IMD / Skymet | API Feed | Grid mapping | Isohyetal Overlay | Cloudburst tracking |
| **4. Flood Data** | CWC / HP PWD | Daily Reports / API | Loss aggregation | Inundation Polygon | Evacuation planning |
| **5. Landslide Data** | HP PWD / Geological Survey | Mobile GIS / Reports | Road block mapping | Hazard Point Overlay | Traffic diversion |
| **6. GLOF Data** | Sensor / Satellite | Sensor Push / Sat Feed | Lake area tracking | Glacial Lake Overlay | Downstream alert |
| **7. Base GIS Layers** | HP Survey / Survey of India | WMS / Vector Import | Projection transform | Vector Base Map | Spatial context |
| **8. Vulnerability Info** | Census / HP Social Justice | Tabular Import | Spatial join | Village/Ward Layer | Risk assessment |
| **9. Infrastructure** | HP PWD / HPSEBL | Department Ingestion | Asset mapping | Critical Asset Layer | Vulnerability mapping |
| **10. Road/River Layers** | HP PWD / Jal Shakti | Spatial Import | Topology mapping | Network Line Layer | Route planning |
| **11. Damage / Loss** | District Magistrates | Daily Reports / Coordinate | Loss sum per district | Loss Point/Polygon | Relief allocation |
| **12. Resource Info** | Fire / Police / NDRF | Web App Input | Inventory update | Resource Location Layer | Response dispatch |
| **13. Sectoral Dept Data**| Housing, Agriculture, etc. | Sectoral Submissions | Cost estimation | Sectoral Map Overlay | PDNA reporting |
| **14. Mobile / Field Data**| Field Responders | Mobile App API | Geo-tagging | Incident Point Layer | Field verification |
| **15. Real-Time Data** | Emergency Calls / App | Incident Push | Classification | Live Incident Overlay | EOC Monitoring |
| **16. Historical Disaster**| HPSDMA Archive | Database Import | Trend aggregation | Historical Hazard Map | Mitigation planning |

---

## 2. API & INTEROPERABILITY AUDIT

A rigorous audit was conducted to distinguish between API concepts planned in program documentation and production technical APIs available in public documentation:

| Audit Level | Public Audit Finding | Official Evidence Reference | Classification Status |
| :--- | :--- | :--- | :---: |
| **1. API Concept** | Explicitly documented as a program requirement ("push and pull data integration via API"). | Ready2Respond Rapid Diagnostic | **DOCUMENTED** |
| **2. Technical API Spec** | Not publicly documented in reviewed material (No OpenAPI / Swagger spec located). | Public HPSDMA Portal Audit | **UNDOCUMENTED** |
| **3. Public Endpoints** | Not publicly documented in reviewed material (No public REST endpoints located). | Public HPSDMA Portal Audit | **UNDOCUMENTED** |
| **4. Public Data Schema** | Not publicly documented in reviewed material (No JSON/XML schema published). | Public HPSDMA Portal Audit | **UNDOCUMENTED** |
| **5. Auth Model** | Not publicly documented in reviewed material (OAuth2/API key model undisclosed). | Public HPSDMA Portal Audit | **UNDOCUMENTED** |
| **6. Event Model** | Not publicly documented in reviewed material (Webhook / pub-sub model undisclosed). | Public HPSDMA Portal Audit | **UNDOCUMENTED** |
| **7. GIS Services** | Internal WMS/WFS services used for portal layers; external public feed URLs unlisted. | HPSDMA Geo-Portal | **PARTIALLY DOCUMENTED** |

---

## 3. AUDIT CONCLUSION

HPSDMA explicitly plans and requires API-driven push and pull data integration for inter-departmental stakeholder synchronization. However, specific technical API schemas, authentication keys, and REST endpoints are **not publicly documented in the reviewed material**. Therefore, RiskPulse must provide a clean, self-contained, flexible API contract that HPSDMA can consume or push to without depending on internal HPSDMA schema assumptions.
