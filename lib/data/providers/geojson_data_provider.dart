import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:riskpulse/domain/exposure/exposure.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/hazard/hazard.dart';
import 'package:riskpulse/domain/vulnerability/vulnerability.dart';
import 'gis_data_provider.dart';

class GeoJsonDataProvider implements GisDataProvider {
  final String assetPath;

  GeoJsonDataProvider({required this.assetPath});

  Future<List<Hazard>> getHazardsFromAsset() async {
    final String geoJson = await rootBundle.loadString(assetPath);
    final Map<String, dynamic> data = jsonDecode(geoJson) as Map<String, dynamic>;
    final List<dynamic> features = data['features'] as List<dynamic>? ?? [];

    return features.map<Hazard>((feature) {
      final Map<String, dynamic> item = feature as Map<String, dynamic>;
      final Map<String, dynamic> properties = item['properties'] as Map<String, dynamic>? ?? {};
      final Map<String, dynamic> geometry = item['geometry'] as Map<String, dynamic>? ?? {};
      final dynamic geometryCoordinates = geometry['coordinates'];

      final GeoLocation location = _extractRepresentativeLocation(
        geometry['type']?.toString() ?? 'Point',
        geometryCoordinates,
        properties,
      );

      return Hazard(
        id: properties['id']?.toString() ?? properties['objectid']?.toString() ?? 'geojson-${DateTime.now().millisecondsSinceEpoch}',
        name: properties['name']?.toString() ?? properties['slide_name']?.toString() ?? properties['eventName']?.toString() ?? 'Unknown Hazard',
        category: properties['category']?.toString() ?? 'General',
        intensity: _toDouble(properties['intensity'] ?? 50.0),
        unit: properties['unit']?.toString() ?? 'score',
        active: _isActive(properties['active'] ?? properties['activity']),
        location: location,
        state: properties['state']?.toString(),
        district: properties['district']?.toString(),
        tehsil: properties['tehsil']?.toString(),
        village: properties['village']?.toString(),
        locationName: properties['locationName']?.toString() ?? properties['location']?.toString(),
        date: properties['date']?.toString() ?? properties['history']?.toString(),
        time: properties['time']?.toString(),
        year: _toIntOrNull(properties['year']),
        magnitude: _toDoubleOrNull(properties['magnitude']),
        magnitudeType: properties['magnitudeType']?.toString() ?? properties['magnitude_type']?.toString(),
        depth: _toDoubleOrNull(properties['depth']),
        epicentralLocation: properties['epicentralLocation']?.toString() ?? properties['epicentre']?.toString(),
        triggering: properties['triggering']?.toString(),
        casualties: properties['casualties']?.toString() ?? properties['people_impact']?.toString(),
        missing: properties['missing']?.toString(),
        injured: properties['injured']?.toString(),
        housesAffected: properties['housesAffected']?.toString() ?? properties['houses_affected']?.toString(),
        infrastructureImpact: properties['infrastructure_impact']?.toString() ?? properties['infrastructureAffected']?.toString(),
        roadDamage: properties['roadDamage']?.toString() ?? properties['road_damage']?.toString(),
        bridgeDamage: properties['bridgeDamage']?.toString() ?? properties['bridge_damage']?.toString(),
        livestockImpact: properties['livestock_impact']?.toString(),
        economicLoss: properties['economicLoss']?.toString() ?? properties['economic_loss']?.toString(),
        environmentalImpact: properties['environmentalImpact']?.toString() ?? properties['environmental_impact']?.toString(),
        response: properties['response']?.toString(),
        geology: properties['geology']?.toString(),
        movementType: properties['movement_t']?.toString() ?? properties['movement_type']?.toString(),
        movementRate: properties['movement_r']?.toString() ?? properties['movement_rate']?.toString(),
        geoScientificCause: properties['geoscientific_cause']?.toString() ?? properties['geoScientificCause']?.toString(),
        remarks: properties['remarks']?.toString(),
        history: properties['history']?.toString(),
        lengthMeters: _toDoubleOrNull(properties['length_m'] ?? properties['lengthMeters']),
        widthMeters: _toDoubleOrNull(properties['width_m'] ?? properties['widthMeters']),
        depthMeters: _toDoubleOrNull(properties['depth_m'] ?? properties['depthMeters']),
        areaSquareMeters: _toDoubleOrNull(properties['area_m2'] ?? properties['areaSquareMeters']),
        volumeCubicMeters: _toDoubleOrNull(properties['volumeCubicMeters']),
        runoutDistanceMeters: _toDoubleOrNull(properties['runoutDistanceMeters']),
        verificationStatus: _parseVerificationStatus(properties['verification_status'] ?? properties['verificationStatus']),
        source: properties['source']?.toString() ?? 'GSI',
        sourceUrl: properties['source_url']?.toString() ?? properties['sourceUrl']?.toString(),
        sourceType: properties['sourceType']?.toString(),
        explanationQuick: properties['explanation_quick']?.toString() ?? properties['explanationQuick']?.toString(),
        explanationDetailed: properties['explanation_detailed']?.toString() ?? properties['explanationDetailed']?.toString(),
        lastUpdated: _parseDateTime(properties['last_updated'] ?? properties['lastUpdated']),
        isAiGenerated: properties['is_ai_generated'] == true || properties['isAiGenerated'] == true,
        isPrediction: properties['is_prediction'] == true || properties['isPrediction'] == true,
        locationIsApproximate: properties['location_is_approximate'] == true || properties['locationIsApproximate'] == true,
        locationAccuracy: properties['locationAccuracy']?.toString() ?? properties['location_accuracy']?.toString(),
        historicalEvent: properties['historicalEvent'] == true || properties['historical_event'] == true,
        sourceProperties: properties,
        geometry: geometry,
      );
    }).toList();
  }

  static VerificationStatus _parseVerificationStatus(dynamic val) {
    switch (val?.toString().toLowerCase()) {
      case 'verified': return VerificationStatus.verified;
      case 'partially_verified': return VerificationStatus.partiallyVerified;
      case 'partiallyverified': return VerificationStatus.partiallyVerified;
      case 'approximate': return VerificationStatus.approximate;
      default: return VerificationStatus.unverified;
    }
  }

  static DateTime? _parseDateTime(dynamic val) {
    if (val == null) return null;
    return DateTime.tryParse(val.toString());
  }

  static int? _toIntOrNull(dynamic val) => val == null ? null : (val is int ? val : int.tryParse(val.toString()));

  @override List<Hazard> getHazards() => [];
  @override List<Exposure> getExposure() => [];
  @override List<Vulnerability> getVulnerabilities() => [];

  static GeoLocation _extractRepresentativeLocation(String type, dynamic coords, Map<String, dynamic> props) {
    if (type == 'Point' && coords is List && coords.length >= 2) {
      return GeoLocation(longitude: _toDouble(coords[0]), latitude: _toDouble(coords[1]));
    }
    if ((type == 'Polygon' || type == 'MultiPolygon') && coords is List && coords.isNotEmpty) {
      // Very simple centroid-like: take first point of first ring
      final dynamic firstRing = type == 'Polygon' ? coords[0] : coords[0][0];
      if (firstRing is List && firstRing.isNotEmpty) {
        final dynamic firstPoint = firstRing[0];
        if (firstPoint is List && firstPoint.length >= 2) {
          return GeoLocation(longitude: _toDouble(firstPoint[0]), latitude: _toDouble(firstPoint[1]));
        }
      }
    }
    return GeoLocation(
      latitude: _toDouble(props['latitude'] ?? props['lat'] ?? 0),
      longitude: _toDouble(props['longitude'] ?? props['lon'] ?? props['lng'] ?? 0),
    );
  }

  static double _toDouble(dynamic val) => val is num ? val.toDouble() : double.tryParse(val?.toString() ?? '0') ?? 0.0;
  static double? _toDoubleOrNull(dynamic val) => val == null ? null : (val is num ? val.toDouble() : double.tryParse(val.toString()));
  static bool _isActive(dynamic val) => val?.toString().toLowerCase() == 'true' || val?.toString().toLowerCase() == 'active';
}
