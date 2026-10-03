import 'package:flutter/material.dart';
import 'package:riskpulse/domain/watershed/watershed_boundary_type.dart';

/// Flutter UI Layer Control Widget for Watershed Atlas overlays in RiskPulse Research GIS.
class WatershedLayerControlWidget extends StatelessWidget {
  final bool showReferenceWatersheds;
  final bool showDerivedCatchments;
  final int referenceCount;
  final int derivedCount;
  final ValueChanged<bool> onToggleReference;
  final ValueChanged<bool> onToggleDerived;

  const WatershedLayerControlWidget({
    super.key,
    required this.showReferenceWatersheds,
    required this.showDerivedCatchments,
    required this.referenceCount,
    required this.derivedCount,
    required this.onToggleReference,
    required this.onToggleDerived,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.water, color: Colors.blue, size: 20),
                SizedBox(width: 8),
                Text(
                  'Watershed Atlas Layers',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
            const Divider(),
            CheckboxListTile(
              dense: true,
              value: showReferenceWatersheds,
              onChanged: (val) => onToggleReference(val ?? false),
              secondary: const Icon(Icons.shield, color: Colors.indigo, size: 18),
              title: Text(WatershedBoundaryType.reference.displayName),
              subtitle: Text('$referenceCount registered units'),
            ),
            CheckboxListTile(
              dense: true,
              value: showDerivedCatchments,
              onChanged: (val) => onToggleDerived(val ?? false),
              secondary: const Icon(Icons.analytics, color: Colors.teal, size: 18),
              title: Text(WatershedBoundaryType.derived.displayName),
              subtitle: Text('$derivedCount derived catchments'),
            ),
          ],
        ),
      ),
    );
  }
}
