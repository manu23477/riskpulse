# RISKPULSE READ-ONLY FORENSIC AUDIT REPORT
## RESEARCH GIS WATERSHED BOUNDARY & DRAINAGE NETWORK VISIBILITY PATHWAY AUDIT

**Document ID**: `RISKPULSE_WATERSHED_DRAINAGE_VISIBILITY_FORENSIC_AUDIT_REPORT`  
**Workstream**: Read-Only Forensic Trace of Watershed Boundary & Drainage Network Layer Controls  
**Date**: September 25, 2026  
**Authoritative Repository**: `C:\Users\HP\StudioProjects\riskpulse`  
**Branch**: `main`  
**Pushed HEAD Commit**: `aa2b9371a8272c60caf52ab29aa2d8bab7b768d9` (`fix(research-gis): control drainage topology visibility`)  
**Audit Mode**: READ-ONLY FORENSIC AUDIT (0 code changes, 0 file edits, 0 resets/stashes, 0 commits, 0 pushes executed)

---

## 1. EXECUTIVE SUMMARY & FORENSIC CONCLUSION

A read-only forensic state trace of `ResearchGisScreen` (`lib/screens/research_gis/research_gis_screen.dart`), `ResearchWorkspaceProvider` (`lib/data/providers/research_workspace_provider.dart`), and `ResearchLayerPanel` (`lib/screens/research_gis/widgets/layer_manager.dart`) has established the exact root causes for the two live layer-control issues:

```
FORENSIC AUDIT CONCLUSION:
THE DRAINAGE NETWORK AND WATERSHED BOUNDARY ISSUES ARE TWO SEPARATE DEFECTS IN ResearchGisScreen.

DEFECT A (Drainage Network):
State Query Mismatch — ResearchGisScreen queries layer visibility from session.layers (stale)
instead of workspace.activeComposition.layers (updated by toggleLayerVisibility).

DEFECT B (Watershed Boundary):
Missing Vector Renderer — ResearchGisScreen FlutterMap.children completely lacks a PolygonLayer
or PolylineLayer to render the active watershed boundary polygon on the map canvas.
```

---

## 2. SECTION 1 — DRAINAGE NETWORK VISIBILITY RUNTIME PATHWAY

```
1. User clicks Drainage Network checkbox in ResearchLayerPanel
   └── Calls workspace.toggleLayerVisibility(layer.id)

2. ResearchWorkspaceProvider.toggleLayerVisibility(layerId)
   └── Updates activeComposition.layers (workspace.activeComposition.layers)
   └── DOES NOT update session.layers! (session.layers remains at initial state)

3. ResearchGisScreen rebuilds via Provider notifyListeners()
   └── Line 219 reads: session = workspace.currentSession
   └── Line 220 queries: session.layers.where((l) => l.name == 'Drainage Network' ...).firstOrNull
   └── Reads session.layers where layer.isVisible is STILL TRUE!

4. FlutterMap children in ResearchGisScreen evaluate:
   └── if (session?.drainageNetwork != null && isDrainageVisible) PolylineLayer(...)
   └── if (session?.drainageNetwork != null && isDrainageVisible) MarkerLayer(...)
   └── Evaluates isDrainageVisible == true!

5. BREAK POINT:
   └── ResearchLayerPanel displays [ ] Drainage Network (UNCHECKED) from activeComposition.layers.
   └── Map STILL RENDERS blue polylines, green headwaters, and orange confluences from session.layers!
```

---

## 3. SECTION 2 — WATERSHED BOUNDARY VISIBILITY RUNTIME PATHWAY

```
1. ResearchWorkflowOrchestrator creates watershedLayer
   └── GisLayer(id: 'derived-watershedBoundary...', name: 'Watershed Boundary', isVisible: true)
   └── Stored in session.layers and composition.layers.

2. ResearchLayerPanel displays Watershed Boundary item
   └── Rendered as toggleable _layerItem with a Checkbox.
   └── Checking/unchecking calls workspace.toggleLayerVisibility(layer.id)
   └── Updates composition.layers.

3. ResearchGisScreen rebuilds via Provider notifyListeners()
   └── FlutterMap.children contains:
       - TileLayer (OpenStreetMap)
       - PolylineLayer (_buildDrainagePolylines)
       - MarkerLayer (_buildNodeMarkers, Pour Point, Identify)
   └── COMPLETELY MISSES a PolygonLayer or PolylineLayer for Watershed Boundary!

4. BREAK POINT:
   └── Checking Watershed Boundary checkbox does NOT render a boundary line because NO vector renderer exists in ResearchGisScreen for session.activeWatershed!
   └── Unchecking Watershed Boundary checkbox changes no map pixels for the same reason.
```

---

## 4. SECTION 3 — EXACT LAYER IDS & INSTANCES AUDIT

| Layer Name | GisLayer ID Format | Collection Stored In | Layer Panel Status | Renderer Read Target | Renderer Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Drainage Network** | `derived-drainageNetwork-${ts}` | `session.layers` & `composition.layers` | Active Checkbox | Read `session.layers` (Stale) | **State Query Mismatch** |
| **Watershed Boundary** | `derived-watershedBoundary-${ts}` | `session.layers` & `composition.layers` | Active Checkbox | **Not Read in `FlutterMap`** | **Missing Vector Renderer** |

---

## 5. SECTION 4 — COMPARISON OF DEFECTS

- **Defect A (Drainage Network)**: State query bug — `ResearchGisScreen` queries `session.layers` instead of `workspace.activeComposition.layers`.
- **Defect B (Watershed Boundary)**: Missing UI rendering layer — `FlutterMap.children` in `ResearchGisScreen` lacks a `PolygonLayer` or `PolylineLayer` to draw the boundary polygon of `session.activeWatershed`.

---

## 6. SECTION 5 & 6 — CRITICAL MAP RENDERING TREE AUDIT

### Actual `FlutterMap.children` in `ResearchGisScreen`:
```
FlutterMap
 ├── TileLayer (OpenStreetMap basemap)
 ├── PolylineLayer (_buildDrainagePolylines - DrainageNetwork segments) [Condition: session.drainageNetwork != null && isDrainageVisible]
 └── MarkerLayer [Condition: session.drainageNetwork != null && isDrainageVisible]
      ├── _buildNodeMarkers (Headwaters [Green], Junctions [Orange])
      ├── Active Pour Point Marker (Red)
      ├── Snapped Pour Point Marker (Blue)
      └── Last Identify Point Marker (Orange)
```

### Unconditional or Bypassed Paths:
- **No vector Watershed Boundary layer** is mounted in `FlutterMap.children`.
- `session.activeWatershed` is used in `ResearchInfoPanel` (tabular area display) and `ResearchProductRegistryFactory` (export catalog), but has **zero vector representation on the map canvas**.

---

## 7. SECTION 7, 8, & 9 — SCIENTIFIC & OPERATIONAL SAFETY

- **Scientific Algorithms**: **100% UNTOUCHED & FROZEN**. `DrainageAnalysisService`, `WatershedAnalysisService`, `TerrainAnalysisService`, and `HydrologicalAnalysisService` algorithms were **0% modified**.
- **Operational RiskMap Baseline**: **100% INTACT**. The 168-feature GeoJSON operational dataset and Kotropi 2017 anchor feature remain untouched.
- **`HYDRO-2` Research Baseline**: **100% FROZEN & PROTECTED**.

---

## 8. SECTION 10 & 11 — MINIMAL SURGICAL CORRECTIONS REQUIRED

When authorized for implementation:

### Correction 1 — Drainage Network State Query Fix (`lib/screens/research_gis/research_gis_screen.dart`):
Query layer visibility from `workspace.activeComposition.layers` instead of `session.layers`:
```dart
final drainageLayer = (workspace.activeComposition?.layers ?? session?.layers)
    ?.where((l) => l.name == 'Drainage Network' || l.metadata['hydrology_product'] == 'drainageNetwork')
    .firstOrNull;
final bool isDrainageVisible = drainageLayer?.isVisible ?? true;
```

### Correction 2 — Watershed Boundary Vector Rendering (`lib/screens/research_gis/research_gis_screen.dart`):
1. Query `isWatershedVisible` from `workspace.activeComposition.layers`:
   ```dart
   final watershedLayer = (workspace.activeComposition?.layers ?? session?.layers)
       ?.where((l) => l.name == 'Watershed Boundary' || l.metadata['hydrology_product'] == 'watershedBoundary')
       .firstOrNull;
   final bool isWatershedVisible = watershedLayer?.isVisible ?? true;
   ```
2. Extract outer boundary ring coordinates from `session.activeWatershed.mask` or `session.activeWatershed.extent` to construct a `PolylineLayer` or `PolygonLayer` in `FlutterMap.children` when `isWatershedVisible == true`:
   ```dart
   if (session?.activeWatershed != null && isWatershedVisible)
     PolygonLayer(
       polygons: _buildWatershedPolygons(session!.activeWatershed!),
     ),
   ```

---

## 9. SECTION 12 — EXACT FILES TO BE MODIFIED (UPON AUTHORIZATION)

1. `lib/screens/research_gis/research_gis_screen.dart` (Update layer query to `workspace.activeComposition.layers` and add `PolygonLayer` for Watershed Boundary)
2. `test/drainage_topology_visibility_test.dart` (Add widget regression assertions verifying both Drainage Network and Watershed Boundary layer toggles)

---

## 10. SECTION 13 — TEST REQUIREMENTS

- Widget tests verifying:
  - Drainage Network ON $\rightarrow$ polylines + nodes visible.
  - Drainage Network OFF $\rightarrow$ polylines + nodes hidden.
  - Watershed Boundary ON $\rightarrow$ watershed boundary polygon visible.
  - Watershed Boundary OFF $\rightarrow$ watershed boundary polygon hidden.
  - Pour point and identify markers remain 100% independent.

---

## 11. SECTION 14 — FINAL AUDIT STATUS STATEMENT

```
READ-ONLY WATERSHED & DRAINAGE AUDIT COMPLETE — GREEN
(All root causes isolated; zero file modifications executed; awaiting authorization)
```

---

```
============================================================
RISKPULSE WATERSHED & DRAINAGE VISIBILITY FORENSIC AUDIT COMPLETE
STATUS: READ-ONLY WATERSHED & DRAINAGE AUDIT COMPLETE
DEFECT A (Drainage): Query activeComposition.layers instead of session.layers
DEFECT B (Watershed): Add PolygonLayer for activeWatershed in FlutterMap.children
SCIENTIFIC ALGORITHMS: 100% UNTOUCHED & FROZEN
HYDRO-2 BASELINE: 100% FROZEN & PROTECTED
OPERATIONAL BASELINE: 168 FEATURES INTACT (Kotropi preserved)
COMMITS EXECUTED: 0 | PUSHES EXECUTED: 0

STOPPING WORK NOW.
NO CODE CHANGES EXECUTED.
NO COMMITS EXECUTED.
NO PUSHES EXECUTED.
AWAITING MANU'S INSTRUCTION.
============================================================
```