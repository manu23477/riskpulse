import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/location/geo_location.dart';

/// Precision levels for OSINT spatial references without creating false precision.
enum OSINTSpatialPrecision {
  exactPoint,
  approximatePoint,
  namedPlace,
  administrativeArea,
  linearFeature,
  unknown,
}

/// Immutable spatial reference for OSINT evidence, claims, and candidate events.
///
/// Prevents false precision by preserving location uncertainty and inference status.
@immutable
class OSINTSpatialReference {
  final OSINTSpatialPrecision spatialPrecision;
  final GeoLocation? location;
  final double? accuracyMeters;
  final double? uncertaintyRadiusKm;
  final String? placeName;
  final String? district;
  final String? state;
  final String? adminLevel;
  final String? routeName;
  final GeoLocation? startLocation;
  final GeoLocation? endLocation;
  final bool isGeocodedInferred;

  const OSINTSpatialReference({
    this.spatialPrecision = OSINTSpatialPrecision.unknown,
    this.location,
    this.accuracyMeters,
    this.uncertaintyRadiusKm,
    this.placeName,
    this.district,
    this.state,
    this.adminLevel,
    this.routeName,
    this.startLocation,
    this.endLocation,
    this.isGeocodedInferred = false,
  });

  const OSINTSpatialReference.exact({
    required GeoLocation location,
    double? accuracyMeters,
    bool isGeocodedInferred = false,
  }) : this(
         spatialPrecision: OSINTSpatialPrecision.exactPoint,
         location: location,
         accuracyMeters: accuracyMeters,
         isGeocodedInferred: isGeocodedInferred,
       );

  const OSINTSpatialReference.approximate({
    required GeoLocation location,
    required double uncertaintyRadiusKm,
    String? placeName,
    bool isGeocodedInferred = true,
  }) : this(
         spatialPrecision: OSINTSpatialPrecision.approximatePoint,
         location: location,
         uncertaintyRadiusKm: uncertaintyRadiusKm,
         placeName: placeName,
         isGeocodedInferred: isGeocodedInferred,
       );

  const OSINTSpatialReference.named({
    required String placeName,
    String? district,
    String? state,
    GeoLocation? location,
    bool isGeocodedInferred = false,
  }) : this(
         spatialPrecision: OSINTSpatialPrecision.namedPlace,
         placeName: placeName,
         district: district,
         state: state,
         location: location,
         isGeocodedInferred: isGeocodedInferred,
       );

  const OSINTSpatialReference.unknown()
    : this(spatialPrecision: OSINTSpatialPrecision.unknown);

  bool get isValid {
    if (accuracyMeters != null && accuracyMeters! < 0.0) return false;
    if (uncertaintyRadiusKm != null && uncertaintyRadiusKm! < 0.0) return false;
    return true;
  }

  OSINTSpatialReference copyWith({
    OSINTSpatialPrecision? spatialPrecision,
    GeoLocation? location,
    bool clearLocation = false,
    double? accuracyMeters,
    bool clearAccuracyMeters = false,
    double? uncertaintyRadiusKm,
    bool clearUncertaintyRadiusKm = false,
    String? placeName,
    bool clearPlaceName = false,
    String? district,
    String? state,
    String? adminLevel,
    String? routeName,
    GeoLocation? startLocation,
    GeoLocation? endLocation,
    bool? isGeocodedInferred,
  }) {
    return OSINTSpatialReference(
      spatialPrecision: spatialPrecision ?? this.spatialPrecision,
      location: clearLocation ? null : (location ?? this.location),
      accuracyMeters: clearAccuracyMeters
          ? null
          : (accuracyMeters ?? this.accuracyMeters),
      uncertaintyRadiusKm: clearUncertaintyRadiusKm
          ? null
          : (uncertaintyRadiusKm ?? this.uncertaintyRadiusKm),
      placeName: clearPlaceName ? null : (placeName ?? this.placeName),
      district: district ?? this.district,
      state: state ?? this.state,
      adminLevel: adminLevel ?? this.adminLevel,
      routeName: routeName ?? this.routeName,
      startLocation: startLocation ?? this.startLocation,
      endLocation: endLocation ?? this.endLocation,
      isGeocodedInferred: isGeocodedInferred ?? this.isGeocodedInferred,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'spatialPrecision': spatialPrecision.name,
      'latitude': location?.latitude,
      'longitude': location?.longitude,
      'accuracyMeters': accuracyMeters,
      'uncertaintyRadiusKm': uncertaintyRadiusKm,
      'placeName': placeName,
      'district': district,
      'state': state,
      'adminLevel': adminLevel,
      'routeName': routeName,
      'startLatitude': startLocation?.latitude,
      'startLongitude': startLocation?.longitude,
      'endLatitude': endLocation?.latitude,
      'endLongitude': endLocation?.longitude,
      'isGeocodedInferred': isGeocodedInferred,
    };
  }

  factory OSINTSpatialReference.fromMap(Map<String, dynamic> map) {
    GeoLocation? loc;
    final lat = (map['latitude'] as num?)?.toDouble();
    final lon = (map['longitude'] as num?)?.toDouble();
    if (lat != null && lon != null) {
      loc = GeoLocation(latitude: lat, longitude: lon);
    }

    GeoLocation? startLoc;
    final sLat = (map['startLatitude'] as num?)?.toDouble();
    final sLon = (map['startLongitude'] as num?)?.toDouble();
    if (sLat != null && sLon != null) {
      startLoc = GeoLocation(latitude: sLat, longitude: sLon);
    }

    GeoLocation? endLoc;
    final eLat = (map['endLatitude'] as num?)?.toDouble();
    final eLon = (map['endLongitude'] as num?)?.toDouble();
    if (eLat != null && eLon != null) {
      endLoc = GeoLocation(latitude: eLat, longitude: eLon);
    }

    return OSINTSpatialReference(
      spatialPrecision: OSINTSpatialPrecision.values.firstWhere(
        (e) => e.name == map['spatialPrecision'],
        orElse: () => OSINTSpatialPrecision.unknown,
      ),
      location: loc,
      accuracyMeters: (map['accuracyMeters'] as num?)?.toDouble(),
      uncertaintyRadiusKm: (map['uncertaintyRadiusKm'] as num?)?.toDouble(),
      placeName: map['placeName'] as String?,
      district: map['district'] as String?,
      state: map['state'] as String?,
      adminLevel: map['adminLevel'] as String?,
      routeName: map['routeName'] as String?,
      startLocation: startLoc,
      endLocation: endLoc,
      isGeocodedInferred: map['isGeocodedInferred'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OSINTSpatialReference &&
          runtimeType == other.runtimeType &&
          spatialPrecision == other.spatialPrecision &&
          location == other.location &&
          placeName == other.placeName &&
          district == other.district &&
          state == other.state &&
          isGeocodedInferred == other.isGeocodedInferred;

  @override
  int get hashCode => Object.hash(
    spatialPrecision,
    location,
    placeName,
    district,
    state,
    isGeocodedInferred,
  );
}
