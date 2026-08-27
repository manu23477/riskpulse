import 'package:riskpulse/domain/location/geo_location.dart';

enum VerificationStatus { verified, partiallyVerified, approximate, unverified }

class Hazard {
  final String id;
  final String name;
  final String category; // Hazard type: Landslide, Earthquake, etc.
  final double intensity;
  final String unit;
  final bool active;
  final GeoLocation location;

  // Geographic hierarchy
  final String? state;
  final String? district;
  final String? tehsil;
  final String? village;
  final String? locationName;

  // Temporal information
  final String? date;
  final String? time;
  final int? year;

  // Seismological/Hydrological specifics
  final double? magnitude;
  final String? magnitudeType;
  final double? depth; // Depth in km for EQ
  final String? epicentralLocation;
  final String? triggering;

  // Impact and Damage
  final String? casualties;
  final String? missing;
  final String? injured;
  final String? housesAffected;
  final String? infrastructureImpact;
  final String? roadDamage;
  final String? bridgeDamage;
  final String? livestockImpact;
  final String? economicLoss;
  final String? environmentalImpact;
  final String? response;

  // Scientific/Geological Details
  final String? geology;
  final String? movementType;
  final String? movementRate;
  final String? geoScientificCause;
  final String? remarks;
  final String? history;

  // Physical Dimensions
  final double? lengthMeters;
  final double? widthMeters;
  final double? depthMeters;
  final double? areaSquareMeters;
  final double? volumeCubicMeters;
  final double? runoutDistanceMeters;

  // Authenticity & Transparency fields
  final VerificationStatus verificationStatus;
  final String? source;
  final String? sourceUrl;
  final String? sourceType;
  final String? explanationQuick;
  final String? explanationDetailed;
  final DateTime? lastUpdated;
  final bool isAiGenerated;
  final bool isPrediction;
  final bool locationIsApproximate;
  final String? locationAccuracy;

  // Metadata
  final bool? historicalEvent;
  final Map<String, dynamic> sourceProperties;
  final Map<String, dynamic>? geometry;

  const Hazard({
    required this.id,
    required this.name,
    required this.category,
    required this.intensity,
    required this.unit,
    required this.active,
    required this.location,
    this.state,
    this.district,
    this.tehsil,
    this.village,
    this.locationName,
    this.date,
    this.time,
    this.year,
    this.magnitude,
    this.magnitudeType,
    this.depth,
    this.epicentralLocation,
    this.triggering,
    this.casualties,
    this.missing,
    this.injured,
    this.housesAffected,
    this.infrastructureImpact,
    this.roadDamage,
    this.bridgeDamage,
    this.livestockImpact,
    this.economicLoss,
    this.environmentalImpact,
    this.response,
    this.geology,
    this.movementType,
    this.movementRate,
    this.geoScientificCause,
    this.remarks,
    this.history,
    this.lengthMeters,
    this.widthMeters,
    this.depthMeters,
    this.areaSquareMeters,
    this.volumeCubicMeters,
    this.runoutDistanceMeters,
    this.verificationStatus = VerificationStatus.unverified,
    this.source,
    this.sourceUrl,
    this.sourceType,
    this.explanationQuick,
    this.explanationDetailed,
    this.lastUpdated,
    this.isAiGenerated = false,
    this.isPrediction = false,
    this.locationIsApproximate = false,
    this.locationAccuracy,
    this.historicalEvent,
    this.sourceProperties = const {},
    this.geometry,
  });
}
