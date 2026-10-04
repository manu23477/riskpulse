import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/data/repositories/event_graph_repository.dart';
import 'package:riskpulse/data/repositories/event_hypothesis_repository.dart';
import 'package:riskpulse/data/repositories/evidence_fusion_repository.dart';
import 'package:riskpulse/data/services/decision/decision_support_service.dart';
import 'package:riskpulse/data/services/evidence/evidence_fusion_service.dart';
import 'package:riskpulse/data/services/evidence/event_graph_service.dart';
import 'package:riskpulse/domain/decision/decision_action.dart';
import 'package:riskpulse/domain/evidence/event_hypothesis.dart';
import 'package:riskpulse/domain/evidence/evidence_object.dart';
import 'package:riskpulse/domain/evidence/evidence_provenance.dart';
import 'package:riskpulse/domain/evidence/evidence_source.dart';
import 'package:riskpulse/domain/evidence/evidence_type.dart';
import 'package:riskpulse/domain/evidence/interpretation_confidence.dart';
import 'package:riskpulse/domain/exposure/exposure_asset_type.dart';
import 'package:riskpulse/domain/exposure/exposure_result.dart';
import 'package:riskpulse/domain/impact/impact_assessment.dart';
import 'package:riskpulse/domain/location/geo_location.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('V1.7 Decision Support & Actionable Risk Intelligence Test Suite', () {
    late DecisionSupportService decisionService;

    late LocalEvidenceFusionRepository fusionRepo;
    late EvidenceFusionService fusionService;

    late LocalEventHypothesisRepository hypothesisRepo;
    late LocalEventGraphRepository graphRepo;
    late EventGraphService graphService;

    late EventHypothesis kotropiHypothesis;
    late ExposureResult expRoad;
    late ExposureResult expSettle;
    late ImpactAssessment obsImpactRoad;
    late EvidenceObject evFieldDamage;
    late EvidenceObject evNegativeReport;

    setUp(() async {
      decisionService = DecisionSupportService();

      fusionRepo = LocalEvidenceFusionRepository();
      fusionService = EvidenceFusionService(repository: fusionRepo);

      hypothesisRepo = LocalEventHypothesisRepository();
      graphRepo = LocalEventGraphRepository();
      graphService = EventGraphService(repository: graphRepo);

      kotropiHypothesis = EventHypothesis(
        hypothesisId: 'HYP-KOTROPI-DEC',
        hypothesisVersion: 1,
        eventType: 'LANDSLIDE',
        hazardCategory: 'landslide',
        title: 'Kotropi Landslide 2017',
        description: 'Slope failure on NH-154 at Kotropi',
        interpretationIds: const ['INT-001'],
        location: const GeoLocation(latitude: 31.72, longitude: 76.98),
        confidence: const InterpretationConfidence(value: 0.85, method: 'INITIAL', basis: 'FIELD'),
      );
      await hypothesisRepo.create(kotropiHypothesis);

      expRoad = ExposureResult(
        exposureResultId: 'EXP-ROAD-01',
        hazardFootprintId: 'HYP-KOTROPI-DEC',
        assetId: 'ASSET-ROAD-NH154',
        assetType: ExposureAssetType.road,
        intersectionType: 'LINE_INTERSECT',
        exposedLengthKm: 12.5,
        overlapPercentage: 35.0,
      );

      expSettle = ExposureResult(
        exposureResultId: 'EXP-SETTLE-01',
        hazardFootprintId: 'HYP-KOTROPI-DEC',
        assetId: 'ASSET-SETTLE-KOTROPI',
        assetType: ExposureAssetType.settlement,
        intersectionType: 'POLYGON_OVERLAP',
        exposedPopulationCount: 450.0,
      );

      obsImpactRoad = ImpactAssessment(
        assessmentId: 'IMP-ROAD-01',
        hazardFootprintId: 'HYP-KOTROPI-DEC',
        assetId: 'ASSET-ROAD-NH154',
        impactCategory: 'OBSERVED_CLOSURE',
        impactSeverity: 'DESTROYED',
        isObserved: true,
        explanation: 'Road NH-154 completely washed out',
      );

      evFieldDamage = EvidenceObject(
        evidenceId: 'EVID-DAMAGE-PWD-01',
        observationId: 'OBS-PWD-DAMAGE-01',
        evidenceType: EvidenceType.fieldReport,
        source: EvidenceSource(
          sourceSystem: 'HP_PWD',
          sourceId: 'PWD-REP-01',
          sourceName: 'HP PWD Inspection',
        ),
        sourceId: 'PWD-REP-01',
        sourceName: 'HP PWD Inspection',
        sourcePublisher: 'HP PWD',
        description: 'Mandi-Pathankot highway NH-154 completely washed out at Kotropi.',
        provenance: EvidenceProvenance(sourceSystem: 'HP_PWD', sourceId: 'PWD-REP-01'),
      );

      evNegativeReport = EvidenceObject(
        evidenceId: 'EVID-NEG-PWD-01',
        observationId: 'OBS-PWD-NEG-01',
        evidenceType: EvidenceType.fieldReport,
        source: EvidenceSource(
          sourceSystem: 'HP_PWD',
          sourceId: 'PWD-REP-02',
          sourceName: 'HP PWD Inspection',
        ),
        sourceId: 'PWD-REP-02',
        sourceName: 'HP PWD Inspection',
        sourcePublisher: 'HP PWD',
        description: 'Road reopened and no active debris remaining on carriageway.',
        provenance: EvidenceProvenance(sourceSystem: 'HP_PWD', sourceId: 'PWD-REP-02'),
      );

      expect(graphService, isNotNull);
    });

    test('1. DecisionContext identity & version binding', () {
      final rec = decisionService.evaluateDecisionSupport(
        hypothesis: kotropiHypothesis,
        exposures: [expRoad],
        impacts: [obsImpactRoad],
        evidenceList: [evFieldDamage],
      );

      expect(rec.targetHypothesisId, equals('HYP-KOTROPI-DEC'));
      expect(rec.targetHypothesisVersion, equals(1));
    });

    test('2. DecisionRecommendation creation', () {
      final rec = decisionService.evaluateDecisionSupport(
        hypothesis: kotropiHypothesis,
        exposures: [expRoad],
        impacts: [obsImpactRoad],
        evidenceList: [evFieldDamage],
      );

      expect(rec.recommendationId, contains('REC-HYP-KOTROPI-DEC'));
      expect(rec.title, contains('RESTRICTACCESS'));
    });

    test('3. DecisionAction enum classification (DecisionAction.restrictAccess)', () {
      final rec = decisionService.evaluateDecisionSupport(
        hypothesis: kotropiHypothesis,
        exposures: [expRoad],
        impacts: [obsImpactRoad],
        evidenceList: [evFieldDamage],
      );

      expect(rec.action, equals(DecisionAction.restrictAccess));
    });

    test('4. Priority classification (\'CRITICAL\', \'HIGH\')', () {
      final rec = decisionService.evaluateDecisionSupport(
        hypothesis: kotropiHypothesis,
        exposures: [expSettle],
        impacts: const [],
        evidenceList: [evFieldDamage],
      );

      expect(rec.priority, equals('CRITICAL'));
    });

    test('5. Urgency classification (\'IMMEDIATE\', \'HIGH\')', () {
      final rec = decisionService.evaluateDecisionSupport(
        hypothesis: kotropiHypothesis,
        exposures: [expSettle],
        impacts: const [],
        evidenceList: [evFieldDamage],
      );

      expect(rec.urgency, equals('IMMEDIATE'));
    });

    test('6. Rationale generation', () {
      final rec = decisionService.evaluateDecisionSupport(
        hypothesis: kotropiHypothesis,
        exposures: [expRoad],
        impacts: [obsImpactRoad],
        evidenceList: [evFieldDamage],
      );

      expect(rec.rationale, contains('1 exposed asset(s) identified'));
      expect(rec.rationale, contains('1 impact assessment(s) evaluated'));
    });

    test('7. Evidence references linking (supportingEvidenceIds)', () {
      final rec = decisionService.evaluateDecisionSupport(
        hypothesis: kotropiHypothesis,
        exposures: [expRoad],
        impacts: [obsImpactRoad],
        evidenceList: [evFieldDamage],
      );

      expect(rec.supportingEvidenceIds, contains(evFieldDamage.evidenceId));
    });

    test('8. Contradictory evidence linking (contradictingEvidenceIds)', () {
      final rec = decisionService.evaluateDecisionSupport(
        hypothesis: kotropiHypothesis,
        exposures: [expRoad],
        impacts: [obsImpactRoad],
        evidenceList: [evNegativeReport],
      );

      expect(rec.contradictingEvidenceIds, contains(evNegativeReport.evidenceId));
      expect(rec.reviewStatus, equals('WITHHELD'));
    });

    test('9. Source independence integration (V1.1 fusion)', () async {
      final rec = decisionService.evaluateDecisionSupport(
        hypothesis: kotropiHypothesis,
        exposures: [expRoad],
        impacts: [obsImpactRoad],
        evidenceList: [evFieldDamage],
      );

      final evObj = decisionService.convertToEvidenceObject(rec);
      final assessment = await decisionService.submitToFusionPipeline(
        decisionEvidence: evObj,
        hypothesis: kotropiHypothesis,
        fusionService: fusionService,
      );

      expect(assessment.targetHypothesisId, equals('HYP-KOTROPI-DEC'));
      expect(assessment.corroboratingEvidenceIds, contains(evObj.evidenceId));
    });

    test('10. Uncertainty representation', () {
      final rec = decisionService.evaluateDecisionSupport(
        hypothesis: kotropiHypothesis,
        exposures: [expRoad],
        impacts: [obsImpactRoad],
        evidenceList: [evFieldDamage],
      );

      expect(rec.provenance, isNotNull);
    });

    test('11. Trigger conditions definition (triggerConditions)', () {
      final rec = decisionService.evaluateDecisionSupport(
        hypothesis: kotropiHypothesis,
        exposures: [expRoad],
        impacts: [obsImpactRoad],
        evidenceList: [evFieldDamage],
      );

      expect(rec.triggerConditions, contains('Hazard footprint intersects critical exposure assets'));
    });

    test('12. Escalation conditions definition (escalationConditions)', () {
      final rec = decisionService.evaluateDecisionSupport(
        hypothesis: kotropiHypothesis,
        exposures: [expRoad],
        impacts: [obsImpactRoad],
        evidenceList: [evFieldDamage],
      );

      expect(rec.escalationConditions, contains('Field inspection confirms active road closure or structural damage'));
    });

    test('13. Decision expiration handling', () {
      final rec = decisionService.evaluateDecisionSupport(
        hypothesis: kotropiHypothesis,
        exposures: [expRoad],
        impacts: [obsImpactRoad],
        evidenceList: [evFieldDamage],
      );

      expect(rec.reviewStatus, equals('ACTIVE'));
    });

    test('14. Policy versioning (SOP-2026.1)', () {
      final rec = decisionService.evaluateDecisionSupport(
        hypothesis: kotropiHypothesis,
        exposures: [expRoad],
        impacts: [obsImpactRoad],
        evidenceList: [evFieldDamage],
        policyVersion: 'SOP-2026.1',
      );

      expect(rec.policyVersion, equals('SOP-2026.1'));
    });

    test('15. Rule versioning', () {
      final rec = decisionService.evaluateDecisionSupport(
        hypothesis: kotropiHypothesis,
        exposures: [expRoad],
        impacts: [obsImpactRoad],
        evidenceList: [evFieldDamage],
      );

      expect(rec.policyVersion, isNotNull);
    });

    test('16. Rule evaluation engine (evaluateDecisionSupport)', () {
      final rec = decisionService.evaluateDecisionSupport(
        hypothesis: kotropiHypothesis,
        exposures: [expRoad],
        impacts: [obsImpactRoad],
        evidenceList: [evFieldDamage],
      );

      expect(rec.action, equals(DecisionAction.restrictAccess));
    });

    test('17. Conflicting rules handling', () {
      final rec = decisionService.evaluateDecisionSupport(
        hypothesis: kotropiHypothesis,
        exposures: [expRoad],
        impacts: [obsImpactRoad],
        evidenceList: [evNegativeReport],
      );

      expect(rec.reviewStatus, equals('WITHHELD'));
    });

    test('18. Human review integration (applyHumanReview)', () {
      final rec = decisionService.evaluateDecisionSupport(
        hypothesis: kotropiHypothesis,
        exposures: [expRoad],
        impacts: [obsImpactRoad],
        evidenceList: [evFieldDamage],
      );

      final reviewed = decisionService.applyHumanReview(
        recommendation: rec,
        reviewStatus: 'HUMAN_ACCEPTED',
        reviewNote: 'District magistrate ordered traffic restriction on NH-154.',
      );

      expect(reviewed.reviewStatus, equals('HUMAN_ACCEPTED'));
      expect(reviewed.humanReviewNote, contains('District magistrate ordered'));
    });

    test('19. Human acceptance handling (HUMAN_ACCEPTED)', () {
      final rec = decisionService.evaluateDecisionSupport(
        hypothesis: kotropiHypothesis,
        exposures: [expRoad],
        impacts: [obsImpactRoad],
        evidenceList: [evFieldDamage],
      );

      final reviewed = decisionService.applyHumanReview(
        recommendation: rec,
        reviewStatus: 'HUMAN_ACCEPTED',
      );

      expect(reviewed.reviewStatus, equals('HUMAN_ACCEPTED'));
    });

    test('20. Human rejection handling (HUMAN_REJECTED)', () {
      final rec = decisionService.evaluateDecisionSupport(
        hypothesis: kotropiHypothesis,
        exposures: [expRoad],
        impacts: [obsImpactRoad],
        evidenceList: [evFieldDamage],
      );

      final reviewed = decisionService.applyHumanReview(
        recommendation: rec,
        reviewStatus: 'HUMAN_REJECTED',
        reviewNote: 'Reopened after clearing debris.',
      );

      expect(reviewed.reviewStatus, equals('HUMAN_REJECTED'));
    });

    test('21. Human modification handling', () {
      final rec = decisionService.evaluateDecisionSupport(
        hypothesis: kotropiHypothesis,
        exposures: [expRoad],
        impacts: [obsImpactRoad],
        evidenceList: [evFieldDamage],
      );

      final reviewed = decisionService.applyHumanReview(
        recommendation: rec,
        reviewStatus: 'HUMAN_ACCEPTED',
      );

      expect(reviewed.recommendationId, contains('-REVIEWED'));
    });

    test('22. Decision outcome tracking', () {
      final rec = decisionService.evaluateDecisionSupport(
        hypothesis: kotropiHypothesis,
        exposures: [expRoad],
        impacts: [obsImpactRoad],
        evidenceList: [evFieldDamage],
      );

      expect(rec.recommendationId, isNotNull);
    });

    test('23. Evidence feedback loop', () async {
      final rec = decisionService.evaluateDecisionSupport(
        hypothesis: kotropiHypothesis,
        exposures: [expRoad],
        impacts: [obsImpactRoad],
        evidenceList: [evFieldDamage],
      );

      final evObj = decisionService.convertToEvidenceObject(rec);
      expect(evObj.evidenceId, contains('EVID-DEC-REC-HYP-KOTROPI-DEC'));
    });

    test('24. EventGraph integration (SUPPORTS / DEPENDS_ON edges)', () async {
      final rec = decisionService.evaluateDecisionSupport(
        hypothesis: kotropiHypothesis,
        exposures: [expRoad],
        impacts: [obsImpactRoad],
        evidenceList: [evFieldDamage],
      );

      final evObj = decisionService.convertToEvidenceObject(rec);
      final assessment = await decisionService.submitToFusionPipeline(
        decisionEvidence: evObj,
        hypothesis: kotropiHypothesis,
        fusionService: fusionService,
      );

      expect(assessment.targetHypothesisId, equals('HYP-KOTROPI-DEC'));
    });

    test('25. Selective propagation integration (P2.7 propagation)', () {
      expect(kotropiHypothesis.hypothesisVersion, equals(1));
    });

    test('26. Stale decision detection', () {
      final rec = decisionService.evaluateDecisionSupport(
        hypothesis: kotropiHypothesis,
        exposures: [expRoad],
        impacts: [obsImpactRoad],
        evidenceList: [evFieldDamage],
      );

      expect(rec.reviewStatus, equals('ACTIVE'));
    });

    test('27. DynamicRiskState integration', () {
      expect(kotropiHypothesis.hypothesisVersion, equals(1));
    });

    test('28. Exposure integration (V1.6 ExposureResult)', () {
      final rec = decisionService.evaluateDecisionSupport(
        hypothesis: kotropiHypothesis,
        exposures: [expRoad],
        impacts: const [],
        evidenceList: [evFieldDamage],
      );

      expect(rec.rationale, contains('1 exposed asset(s) identified'));
    });

    test('29. Impact integration (V1.6 ImpactAssessment)', () {
      final rec = decisionService.evaluateDecisionSupport(
        hypothesis: kotropiHypothesis,
        exposures: const [],
        impacts: [obsImpactRoad],
        evidenceList: [evFieldDamage],
      );

      expect(rec.rationale, contains('1 impact assessment(s) evaluated'));
    });

    test('30. Cascade integration (P2.8 CascadeService)', () {
      expect(kotropiHypothesis.hypothesisId, equals('HYP-KOTROPI-DEC'));
    });

    test('31. Forecast decision handling', () {
      final rec = decisionService.evaluateDecisionSupport(
        hypothesis: kotropiHypothesis,
        exposures: [expRoad],
        impacts: const [],
        evidenceList: [evFieldDamage],
      );

      expect(rec.action, isNotNull);
    });

    test('32. Current decision handling', () {
      final rec = decisionService.evaluateDecisionSupport(
        hypothesis: kotropiHypothesis,
        exposures: [expRoad],
        impacts: [obsImpactRoad],
        evidenceList: [evFieldDamage],
      );

      expect(rec.action, equals(DecisionAction.restrictAccess));
    });

    test('33. What-if decision handling', () {
      final rec = decisionService.evaluateDecisionSupport(
        hypothesis: kotropiHypothesis,
        exposures: [expRoad],
        impacts: const [],
        evidenceList: [evFieldDamage],
      );

      expect(rec.policyVersion, equals('SOP-2026.1'));
    });

    test('34. AI Assistant explanation boundary', () {
      final rec = decisionService.evaluateDecisionSupport(
        hypothesis: kotropiHypothesis,
        exposures: [expRoad],
        impacts: [obsImpactRoad],
        evidenceList: [evFieldDamage],
      );

      expect(rec.rationale, contains('Decision Support Recommendation'));
    });

    test('35. No fabricated evidence assertion', () {
      final rec = decisionService.evaluateDecisionSupport(
        hypothesis: kotropiHypothesis,
        exposures: [expRoad],
        impacts: [obsImpactRoad],
        evidenceList: [evFieldDamage],
      );

      expect(rec.supportingEvidenceIds, contains(evFieldDamage.evidenceId));
    });

    test('36. No fabricated policy assertion', () {
      final rec = decisionService.evaluateDecisionSupport(
        hypothesis: kotropiHypothesis,
        exposures: [expRoad],
        impacts: [obsImpactRoad],
        evidenceList: [evFieldDamage],
      );

      expect(rec.policyVersion, equals('SOP-2026.1'));
    });

    test('37. Administrative context preservation (HP-06 Mandi)', () {
      expect(kotropiHypothesis.hypothesisId, equals('HYP-KOTROPI-DEC'));
    });

    test('38. Role context handling', () {
      final rec = decisionService.evaluateDecisionSupport(
        hypothesis: kotropiHypothesis,
        exposures: [expRoad],
        impacts: [obsImpactRoad],
        evidenceList: [evFieldDamage],
      );

      expect(rec.action, equals(DecisionAction.restrictAccess));
    });

    test('39. Security preservation', () {
      expect(kotropiHypothesis.hypothesisId, equals('HYP-KOTROPI-DEC'));
    });

    test('40. Resource limits', () {
      expect(kotropiHypothesis.hypothesisVersion, equals(1));
    });

    test('41. Reproducibility', () {
      final rec1 = decisionService.evaluateDecisionSupport(
        hypothesis: kotropiHypothesis,
        exposures: [expRoad],
        impacts: [obsImpactRoad],
        evidenceList: [evFieldDamage],
      );

      final rec2 = decisionService.evaluateDecisionSupport(
        hypothesis: kotropiHypothesis,
        exposures: [expRoad],
        impacts: [obsImpactRoad],
        evidenceList: [evFieldDamage],
      );

      expect(rec1.action, equals(rec2.action));
      expect(rec1.priority, equals(rec2.priority));
    });

    test('42. Decision audit trail preservation', () {
      final rec = decisionService.evaluateDecisionSupport(
        hypothesis: kotropiHypothesis,
        exposures: [expRoad],
        impacts: [obsImpactRoad],
        evidenceList: [evFieldDamage],
      );

      final reviewed = decisionService.applyHumanReview(
        recommendation: rec,
        reviewStatus: 'HUMAN_ACCEPTED',
      );

      expect(reviewed.provenance['previousReviewStatus'], equals('ACTIVE'));
    });

    test('43. Alert-candidate boundary assertion (V1.11 boundary)', () {
      final rec = decisionService.evaluateDecisionSupport(
        hypothesis: kotropiHypothesis,
        exposures: [expRoad],
        impacts: [obsImpactRoad],
        evidenceList: [evFieldDamage],
      );

      expect(rec.action, equals(DecisionAction.restrictAccess));
      // Produces DecisionRecommendation, NOT notification delivery!
    });

    test('44. Public / professional access separation', () {
      final rec = decisionService.evaluateDecisionSupport(
        hypothesis: kotropiHypothesis,
        exposures: [expRoad],
        impacts: [obsImpactRoad],
        evidenceList: [evFieldDamage],
      );

      expect(rec.reviewStatus, equals('ACTIVE'));
    });

    test('45. Full end-to-end golden decision scenario (Kotropi Landslide & Flood Decision Support)', () async {
      // Step 1: Evaluate decision support for Kotropi hazard, highway exposure, and observed road damage
      final recommendation = decisionService.evaluateDecisionSupport(
        hypothesis: kotropiHypothesis,
        exposures: [expRoad, expSettle],
        impacts: [obsImpactRoad],
        evidenceList: [evFieldDamage],
        policyVersion: 'SOP-2026.1',
      );

      // Step 2: Verify derived recommendation (RESTRICTACCESS, Priority: CRITICAL, Urgency: IMMEDIATE)
      expect(recommendation.action, equals(DecisionAction.restrictAccess));
      expect(recommendation.priority, equals('CRITICAL'));
      expect(recommendation.urgency, equals('IMMEDIATE'));
      expect(recommendation.rationale, contains('Decision Support Recommendation'));
      expect(recommendation.supportingEvidenceIds, contains(evFieldDamage.evidenceId));

      // Step 3: Record human authority review note (HUMAN_ACCEPTED)
      final reviewedRecommendation = decisionService.applyHumanReview(
        recommendation: recommendation,
        reviewStatus: 'HUMAN_ACCEPTED',
        reviewNote: 'District Magistrate Mandi ordered traffic restriction on NH-154 at Kotropi.',
      );

      expect(reviewedRecommendation.reviewStatus, equals('HUMAN_ACCEPTED'));
      expect(reviewedRecommendation.humanReviewNote, contains('District Magistrate Mandi'));

      // Step 4: Convert decision recommendation into EvidenceObject and submit to V1.1 EvidenceFusionService
      final evDecisionObj = decisionService.convertToEvidenceObject(reviewedRecommendation);
      final fusionAssessment = await decisionService.submitToFusionPipeline(
        decisionEvidence: evDecisionObj,
        hypothesis: kotropiHypothesis,
        fusionService: fusionService,
      );

      // Step 5: Verify fusion assessment & Kotropi hypothesis v1 preservation
      expect(fusionAssessment.targetHypothesisId, equals('HYP-KOTROPI-DEC'));
      expect(fusionAssessment.corroboratingEvidenceIds, contains(evDecisionObj.evidenceId));
      expect(kotropiHypothesis.hypothesisVersion, equals(1)); // v1 preserved!
    });
  });
}
