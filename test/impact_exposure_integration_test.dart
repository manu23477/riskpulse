import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/hazard/hazard.dart';
import 'package:riskpulse/domain/forecasting/forecasting.dart';
import 'package:riskpulse/data/services/forecasting/forecasting_services.dart';

void main() {
  group('Stage 3.8 Impact-Based Forecasting & Exposure Integration', () {
    final now = DateTime.utc(2026, 9, 8, 12, 0, 0);

    final mandiLocation = const GeoLocation(latitude: 31.7081, longitude: 76.9317);
    final pandohLocation = const GeoLocation(latitude: 31.6710, longitude: 77.0420);

    final horizon = ForecastHorizon(
      validFrom: now,
      validTo: now.add(const Duration(hours: 24)),
    );

    final popElement = ExposureElement(
      elementId: 'pop-mandi-001',
      category: ExposureCategory.population,
      name: 'Mandi Town Center Population Grid',
      location: mandiLocation,
      quantity: 2500.0,
      unit: 'persons',
      spatialResolution: '1km_grid',
    );

    final roadElement = ExposureElement(
      elementId: 'road-nh21-001',
      category: ExposureCategory.roads,
      name: 'NH-21 Mandi-Pandoh Corridor',
      location: mandiLocation,
      quantity: 12000.0,
      unit: 'meters',
      spatialResolution: 'vector_segment',
    );

    final hospitalElement = ExposureElement(
      elementId: 'hosp-mandi-001',
      category: ExposureCategory.hospitals,
      name: 'Zonal Hospital Mandi',
      location: mandiLocation,
      quantity: 1.0,
      unit: 'facility',
      spatialResolution: 'point',
    );

    final exposureDataset = ExposureDatasetRecord(
      datasetId: 'mandi-exposure-atlas-2026',
      datasetName: 'Mandi District Infrastructure & Population Atlas',
      category: ExposureCategory.population,
      geographicCoverage: 'Mandi District, Himachal Pradesh',
      referenceYear: 2026,
      totalElementCount: 3,
    );

    group('1. Exposure Contracts & Dataset Metadata', () {
      test('instantiates valid ExposureElement and ExposureDatasetRecord', () {
        expect(popElement.elementId, 'pop-mandi-001');
        expect(popElement.quantity, 2500.0);
        expect(popElement.unit, 'persons');

        expect(exposureDataset.datasetId, 'mandi-exposure-atlas-2026');
        expect(exposureDataset.referenceYear, 2026);
      });

      test('rejects negative quantities or empty element IDs', () {
        expect(
          () => ExposureElement(
            elementId: '',
            category: ExposureCategory.population,
            name: 'Test',
            location: mandiLocation,
            quantity: 100.0,
            unit: 'persons',
          ),
          throwsArgumentError,
        );

        expect(
          () => ExposureElement(
            elementId: 'elem-1',
            category: ExposureCategory.population,
            name: 'Test',
            location: mandiLocation,
            quantity: -50.0, // Negative quantity -> MUST REJECT!
            unit: 'persons',
          ),
          throwsArgumentError,
        );
      });
    });

    group('2. VulnerabilityProfile Contract', () {
      test('instantiates valid VulnerabilityProfile and enforces score bounds 0..1', () {
        final profile = VulnerabilityProfile(
          profileId: 'vul-building-landslide-high',
          name: 'Mountainous Masonry Building Landslide Susceptibility',
          exposureCategory: ExposureCategory.buildings,
          hazardCategory: 'Landslide',
          vulnerabilityScore: 0.75,
          susceptibilityClass: 'High',
          sourceCitation: 'GSI Slope Vulnerability Index 2020',
        );

        expect(profile.profileId, 'vul-building-landslide-high');
        expect(profile.vulnerabilityScore, 0.75);

        expect(
          () => VulnerabilityProfile(
            profileId: 'vul-bad',
            name: 'Bad',
            exposureCategory: ExposureCategory.buildings,
            hazardCategory: 'Landslide',
            vulnerabilityScore: 1.5, // Invalid score > 1.0 -> MUST REJECT!
            sourceCitation: 'None',
          ),
          throwsArgumentError,
        );
      });
    });

    group('3. HazardExposureIntersectionEngine', () {
      const intersectionEngine = HazardExposureIntersectionEngine();

      test('intersects hazard location with exposure elements and records scale mismatch provenance', () {
        final elements = [popElement, roadElement, hospitalElement];

        final result = intersectionEngine.evaluateIntersection(
          hazardId: 'fcst-ls-mandi-1',
          hazardCategory: 'Landslide',
          hazardLocation: mandiLocation,
          exposureElements: elements,
          maxSpatialDistanceMeters: 5000.0,
          hazardSpatialResolution: '10m_raster',
        );

        expect(result.exposedElements.length, 3);
        expect(result.totalExposedQuantity, greaterThan(0.0));
        expect(result.provenanceStep.parameters['scaleMismatchNote'], isNotNull);
      });

      test('excludes elements outside spatial radius tolerance', () {
        final farElement = ExposureElement(
          elementId: 'pop-far-001',
          category: ExposureCategory.population,
          name: 'Far Population Grid',
          location: pandohLocation, // ~11km away
          quantity: 1000.0,
          unit: 'persons',
        );

        final result = intersectionEngine.evaluateIntersection(
          hazardId: 'fcst-ls-mandi-2',
          hazardCategory: 'Landslide',
          hazardLocation: mandiLocation,
          exposureElements: [farElement],
          maxSpatialDistanceMeters: 3000.0, // 3km radius -> Far element excluded
        );

        expect(result.exposedElements, isEmpty);
        expect(result.totalExposedQuantity, 0.0);
      });
    });

    group('4. ImpactAssessmentEngine & Scientific Safeguards', () {
      const impactEngine = ImpactAssessmentEngine();

      test('assesses potential impact combining Hazard + Exposure + Vulnerability', () {
        final vulProfile = VulnerabilityProfile(
          profileId: 'vul-pop-001',
          name: 'Population Slope Exposure',
          exposureCategory: ExposureCategory.population,
          hazardCategory: 'Landslide',
          vulnerabilityScore: 0.60,
          sourceCitation: 'UNDP Himalayan Risk Index 2021',
        );

        final assessment = impactEngine.assessImpact(
          assessmentId: 'impact-mandi-101',
          hazardId: 'fcst-ls-mandi-1',
          hazardCategory: 'Landslide',
          hazardSourceType: 'forecast_derived',
          hazardLocation: mandiLocation,
          horizon: horizon,
          uncertainty: ForecastUncertainty(modelConfidence: 0.70),
          exposureElements: [popElement],
          exposureDatasetId: exposureDataset.datasetId,
          vulnerabilityProfile: vulProfile,
        );

        expect(assessment.assessmentId, 'impact-mandi-101');
        expect(assessment.hazardSourceType, 'forecast_derived');
        expect(assessment.isForecastDerived, isTrue);
        expect(assessment.isObservedImpact, isFalse);
        expect(assessment.totalExposedQuantity, 2500.0);
        expect(assessment.impactSeverityLabel, isNotEmpty);
      });

      test('MANDATORY SCIENTIFIC NEGATIVE TEST: forecast-derived impact is NOT labeled as observed damage', () {
        final assessment = impactEngine.assessImpact(
          assessmentId: 'impact-mandi-neg-1',
          hazardId: 'fcst-ls-mandi-2',
          hazardCategory: 'Landslide',
          hazardSourceType: 'forecast_derived',
          hazardLocation: mandiLocation,
          horizon: horizon,
          uncertainty: ForecastUncertainty(),
          exposureElements: [roadElement],
          exposureDatasetId: exposureDataset.datasetId,
        );

        // ASSERT: Forecast-derived impact MUST NOT be labeled as observed damage
        expect(assessment.isObservedImpact, isFalse);
        expect(assessment.hazardSourceType, equals('forecast_derived'));
      });

      test('MANDATORY SCIENTIFIC NEGATIVE TEST: economic loss returns "NOT AVAILABLE" (zero fabricated property values)', () {
        final assessment = impactEngine.assessImpact(
          assessmentId: 'impact-mandi-neg-2',
          hazardId: 'fcst-ls-mandi-3',
          hazardCategory: 'Landslide',
          hazardLocation: mandiLocation,
          horizon: horizon,
          uncertainty: ForecastUncertainty(),
          exposureElements: [hospitalElement],
          exposureDatasetId: exposureDataset.datasetId,
        );

        // ASSERT: Economic loss MUST NOT be fabricated
        expect(assessment.economicImpactEstimate, equals('NOT AVAILABLE'));
      });

      test('UNKNOWN-VULNERABILITY TEST: when vulnerability is null, returns UNKNOWN severity while preserving valid exposure quantity', () {
        final assessment = impactEngine.assessImpact(
          assessmentId: 'impact-mandi-rectified-1',
          hazardId: 'fcst-ls-mandi-5',
          hazardCategory: 'Landslide',
          hazardLocation: mandiLocation,
          horizon: horizon,
          uncertainty: ForecastUncertainty(),
          exposureElements: [popElement],
          exposureDatasetId: exposureDataset.datasetId,
          vulnerabilityProfile: null, // UNKNOWN Vulnerability -> MUST NOT generate fallback score!
        );

        // ASSERT: Vulnerability is unknown and impact score is null / UNKNOWN / NOT ESTIMATED
        expect(assessment.isVulnerabilityUnknown, isTrue);
        expect(assessment.isImpactEstimated, isFalse);
        expect(assessment.estimatedImpactScore, isNull);
        expect(assessment.impactSeverityLabel, equals('UNKNOWN / NOT ESTIMATED'));
        expect(assessment.scientificStatus, equals(ScientificValidationStatus.notValidatedDataUnavailable));
        expect(assessment.metadata['vulnerabilityStatus'], equals('UNKNOWN'));
        expect(assessment.metadata['impactStatus'], equals('NOT_ESTIMATED'));

        // ASSERT: Exposure information remains 100% PRESERVED!
        expect(assessment.totalExposedQuantity, equals(2500.0));
        expect(assessment.quantityUnit, equals('persons'));
        expect(assessment.exposedElementIds, contains('pop-mandi-001'));
        expect(assessment.location, equals(mandiLocation));
      });

      test('MANDATORY GOVERNANCE TEST: impact assessment DOES NOT mutate RiskMap or create operational hazards', () {
        final assessment = impactEngine.assessImpact(
          assessmentId: 'impact-gov-1',
          hazardId: 'fcst-ls-mandi-4',
          hazardCategory: 'Landslide',
          hazardLocation: mandiLocation,
          horizon: horizon,
          uncertainty: ForecastUncertainty(),
          exposureElements: [popElement, roadElement],
          exposureDatasetId: exposureDataset.datasetId,
        );

        expect(assessment, isA<ImpactAssessment>());
        expect(assessment, isNot(isA<Hazard>()));
      });
    });
  });
}
