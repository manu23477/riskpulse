import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/osint/osint_source.dart';
import 'package:riskpulse/domain/osint/osint_evidence.dart';
import 'package:riskpulse/domain/osint/osint_event_type.dart';
import 'package:riskpulse/domain/osint/osint_spatial_reference.dart';
import 'package:riskpulse/domain/osint/multi_stream_fusion_result.dart';
import 'package:riskpulse/domain/osint/promotion_candidate.dart';
import 'package:riskpulse/domain/osint/promotion_result.dart';
import 'package:riskpulse/data/services/osint/controlled_promotion_gate.dart';
import 'package:riskpulse/screens/osint_workspace/osint_research_workspace_screen.dart';
import 'package:riskpulse/screens/osint_workspace/widgets/intelligence_overview_card.dart';
import 'package:riskpulse/screens/osint_workspace/widgets/evidence_list_item.dart';
import 'package:riskpulse/screens/osint_workspace/widgets/fusion_result_card.dart';
import 'package:riskpulse/screens/osint_workspace/widgets/human_review_dialog.dart';

void main() {
  final now = DateTime.utc(2026, 9, 7, 12, 0, 0);

  group('Stage 2.8 OSINT Research UI & Intelligence Workspace Tests', () {
    testWidgets('1. IntelligenceOverviewCard renders title, value, and subtitle', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: IntelligenceOverviewCard(
              title: 'Retrieved Evidence',
              value: '12',
              icon: Icons.feed,
              color: Colors.blueAccent,
              subtitle: 'Raw OSINT records',
            ),
          ),
        ),
      );

      expect(find.text('RETRIEVED EVIDENCE'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('Raw OSINT records'), findsOneWidget);
    });

    testWidgets('2. EvidenceListItem renders title, publisher, and expands on tap for provenance', (tester) async {
      final ev = OSINTEvidence(
        evidenceId: 'e-101',
        sourceId: 'src-1',
        contentFingerprint: 'a1b2c3d4e5f67890sha256hash',
        title: 'Landslide Blocks Highway',
        extractedText: 'Heavy landslide near Mandi town on NH-21.',
        canonicalUrl: 'https://ndtv.com/news/101',
        publishedAt: now,
        retrievedAt: now,
        spatialRef: const OSINTSpatialReference.named(placeName: 'Mandi', district: 'Mandi', state: 'HP'),
      );

      final source = const OSINTSource(
        sourceId: 'src-1',
        sourceType: OSINTSourceType.newsMedia,
        publisherName: 'NDTV India',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EvidenceListItem(
              evidence: ev,
              source: source,
            ),
          ),
        ),
      );

      expect(find.text('Landslide Blocks Highway'), findsOneWidget);
      expect(find.text('Publisher: NDTV India'), findsOneWidget);

      // Expand card to view provenance details
      await tester.tap(find.byType(EvidenceListItem));
      await tester.pumpAndSettle();

      expect(find.text('URL: https://ndtv.com/news/101'), findsOneWidget);
      expect(find.text('SHA-256 Fingerprint: a1b2c3d4e5f67890sha256hash'), findsOneWidget);
    });

    testWidgets('3. FusionResultCard renders three-stream convergence badge and rationale', (tester) async {
      final fusion = MultiStreamFusionResult(
        fusionId: 'fusion-1',
        contributingEvidenceIds: const ['e1', 'g1', 'r1'],
        contributingStreamTypes: const [
          EvidenceStreamType.osint,
          EvidenceStreamType.gis,
          EvidenceStreamType.remoteSensing,
        ],
        convergenceType: FusionConvergenceType.threeStreamConvergence,
        spatialAgreementScore: 0.85,
        temporalAgreementScore: 0.90,
        hasCrossStreamConflict: false,
        fusionConfidence: 0.82,
        rationale: const ['Three-stream convergence confirmed across OSINT, GIS, and Remote Sensing.'],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FusionResultCard(fusion: fusion),
          ),
        ),
      );

      expect(find.text('THREE-STREAM CONVERGENCE'), findsOneWidget);
      expect(find.text('Provisional Confidence: 82.0%'), findsOneWidget);
      expect(find.textContaining('Three-stream convergence confirmed'), findsOneWidget);
    });

    testWidgets('4. HumanReviewDialog enforces reviewer ID, rationale, and invokes ControlledPromotionGate', (tester) async {
      final candidate = PromotionCandidate(
        candidateId: 'cand-1',
        fusionResultId: 'fusion-1',
        eventType: OSINTEventType.landslide,
        title: 'Mandi Landslide Candidate',
        description: 'Landslide on NH-21.',
        spatialRef: const OSINTSpatialReference.exact(location: GeoLocation(latitude: 31.2, longitude: 77.0)),
        fusionConfidence: 0.85,
        hasCrossStreamConflict: false,
        createdTimestamp: now,
      );

      final gate = ControlledPromotionGate();
      PromotionResult? capturedResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HumanReviewDialog(
              candidate: candidate,
              promotionGate: gate,
              onPromotionComplete: (res) => capturedResult = res,
            ),
          ),
        ),
      );

      expect(find.textContaining('Mandi Landslide Candidate'), findsOneWidget);

      // Enter review rationale
      await tester.enterText(
        find.byWidgetPredicate((w) => w is TextField && w.decoration?.labelText?.contains('Rationale') == true),
        'Verified satellite change and ground report.',
      );

      // Submit review decision
      await tester.tap(find.text('Execute Review Decision'));
      await tester.pumpAndSettle();

      expect(capturedResult, isNotNull);
      expect(capturedResult!.isSuccess, isTrue);
      expect(capturedResult!.promotedHazard, isNotNull);
      expect(capturedResult!.promotedHazard!.name, equals('Mandi Landslide Candidate'));
    });

    testWidgets('5. OSINTResearchWorkspaceScreen renders workspace tab navigation cleanly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OSINTResearchWorkspaceScreen(),
        ),
      );

      expect(find.text('OSINT Intelligence Workspace'), findsOneWidget);
      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('Evidence Explorer'), findsOneWidget);
      expect(find.text('Multi-Stream Fusion'), findsOneWidget);
      expect(find.text('Promotion Gate'), findsOneWidget);

      // Tap Evidence Explorer tab
      await tester.tap(find.text('Evidence Explorer'));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget); // Search bar
    });
  });
}
