import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/watershed/watershed_boundary_type.dart';
import 'package:riskpulse/domain/watershed/watershed_unit.dart';
import 'package:riskpulse/screens/research_gis/widgets/watershed_detail_sheet.dart';
import 'package:riskpulse/screens/research_gis/widgets/watershed_layer_control_widget.dart';

void main() {
  group('WA.5 Watershed Atlas UI Overlay Widget Tests', () {
    testWidgets('1. WatershedLayerControlWidget renders layer toggles and triggers callbacks', (WidgetTester tester) async {
      bool refToggled = false;
      bool derivedToggled = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(splashFactory: InkRipple.splashFactory),
          home: Scaffold(
            body: WatershedLayerControlWidget(
              showReferenceWatersheds: true,
              showDerivedCatchments: false,
              referenceCount: 2,
              derivedCount: 1,
              onToggleReference: (val) => refToggled = val,
              onToggleDerived: (val) => derivedToggled = val,
            ),
          ),
        ),
      );

      expect(find.text('Watershed Atlas Layers'), findsOneWidget);
      expect(find.text('Reference / Official Watershed'), findsOneWidget);
      expect(find.text('RiskPulse Derived Catchment'), findsOneWidget);
      expect(find.text('2 registered units'), findsOneWidget);
      expect(find.text('1 derived catchments'), findsOneWidget);

      // Tap checkboxes
      await tester.tap(find.text('Reference / Official Watershed'));
      expect(refToggled, isFalse);

      await tester.tap(find.text('RiskPulse Derived Catchment'));
      expect(derivedToggled, isTrue);
    });

    testWidgets('2. WatershedDetailSheet renders Reference Watershed details and code', (WidgetTester tester) async {
      final refUnit = WatershedUnit(
        internalId: 'wa-slusi-1B1A2a',
        sourceId: '1B1A2a',
        name: 'Kotropi Micro-Watershed',
        classificationSystemId: 'slusi_2012',
        classificationVersion: '2012.1',
        level: 'Micro-Watershed',
        code: '1B1A2a',
        boundaryType: WatershedBoundaryType.reference,
        areaKm2: 6.2,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(splashFactory: InkRipple.splashFactory),
          home: Scaffold(
            body: WatershedDetailSheet(unit: refUnit),
          ),
        ),
      );

      expect(find.text('Kotropi Micro-Watershed'), findsOneWidget);
      expect(find.text('REFERENCE'), findsOneWidget);
      expect(find.text('1B1A2a'), findsOneWidget);
      expect(find.text('slusi_2012'), findsOneWidget);
      expect(find.text('6.20 km²'), findsOneWidget);
    });

    testWidgets('3. WatershedDetailSheet enforces Official Code Protection on Derived Catchment', (WidgetTester tester) async {
      final derivedUnit = WatershedUnit(
        internalId: 'wa-derived-rp-kotropi-001',
        name: 'Mandi GLO-30 Derived Catchment',
        classificationSystemId: 'riskpulse_derived_hydro2',
        classificationVersion: 'HYDRO-2.0',
        level: 'Derived Catchment',
        code: null, // Official code is NULL!
        boundaryType: WatershedBoundaryType.derived,
        areaKm2: 6.24,
        pourPointLocation: const GeoLocation(latitude: 31.0900, longitude: 77.1600),
        provenance: const {
          'sourceDem': 'COPERNICUS/DEM/GLO30',
          'streamThresholdCells': 100.0,
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(splashFactory: InkRipple.splashFactory),
          home: Scaffold(
            body: WatershedDetailSheet(unit: derivedUnit),
          ),
        ),
      );

      expect(find.text('Mandi GLO-30 Derived Catchment'), findsOneWidget);
      expect(find.text('DERIVED'), findsOneWidget);
      // Official code protection text displayed!
      expect(find.text('Official Code: Not Assigned (Derived Catchment)'), findsOneWidget);
      expect(find.text('sourceDem: COPERNICUS/DEM/GLO30'), findsOneWidget);
      expect(find.text('streamThresholdCells: 100.0'), findsOneWidget);
    });
  });
}
