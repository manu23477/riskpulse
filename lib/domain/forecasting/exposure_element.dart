import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/gis/data_source_record.dart';
import 'package:riskpulse/domain/gis/analytical_step.dart';
import 'package:riskpulse/domain/forecasting/forecast_horizon.dart';

/// Categories of exposed elements, assets, or populations.
enum ExposureCategory {
  population,
  settlements,
  buildings,
  roads,
  bridges,
  railways,
  hospitals,
  schools,
  powerInfrastructure,
  waterInfrastructure,
  communicationInfrastructure,
  agriculturalLand,
  criticalFacilities,
  other,
}

/// Immutable provider-neutral domain contract representing an exposed asset, facility, or population element.
@immutable
class ExposureElement {
  static const int currentSchemaVersion = 1;

  final String elementId;
  final ExposureCategory category;
  final String name;
  final GeoLocation location;
  final MapExtent? spatialExtent;
  final double quantity;
  final String unit;
  final String spatialResolution;
  final ForecastHorizon? temporalValidity;
  final DataSourceRecord? dataSource;
  final double? uncertainty;
  final String qualityState;
  final List<AnalyticalStep> provenanceSteps;
  final Map<String, dynamic> metadata;
  final int schemaVersion;

  ExposureElement({
    required this.elementId,
    required this.category,
    required this.name,
    required this.location,
    this.spatialExtent,
    required this.quantity,
    required this.unit,
    this.spatialResolution = 'point',
    this.temporalValidity,
    this.dataSource,
    this.uncertainty,
    this.qualityState = 'observed',
    this.provenanceSteps = const [],
    this.metadata = const {},
    this.schemaVersion = currentSchemaVersion,
  }) {
    if (elementId.trim().isEmpty) {
      throw ArgumentError('elementId cannot be empty.');
    }
    if (name.trim().isEmpty) {
      throw ArgumentError('name cannot be empty.');
    }
    if (unit.trim().isEmpty) {
      throw ArgumentError('unit cannot be empty.');
    }
    if (quantity.isNaN || quantity < 0.0) {
      throw ArgumentError('quantity cannot be negative or NaN.');
    }
    if (uncertainty != null && (uncertainty!.isNaN || uncertainty! < 0.0)) {
      throw ArgumentError('uncertainty cannot be negative or NaN.');
    }
    if (schemaVersion <= 0) {
      throw ArgumentError('schemaVersion must be positive.');
    }
  }

  ExposureElement copyWith({
    String? elementId,
    ExposureCategory? category,
    String? name,
    GeoLocation? location,
    MapExtent? spatialExtent,
    bool clearSpatialExtent = false,
    double? quantity,
    String? unit,
    String? spatialResolution,
    ForecastHorizon? temporalValidity,
    bool clearTemporalValidity = false,
    DataSourceRecord? dataSource,
    bool clearDataSource = false,
    double? uncertainty,
    bool clearUncertainty = false,
    String? qualityState,
    List<AnalyticalStep>? provenanceSteps,
    Map<String, dynamic>? metadata,
    int? schemaVersion,
  }) {
    return ExposureElement(
      elementId: elementId ?? this.elementId,
      category: category ?? this.category,
      name: name ?? this.name,
      location: location ?? this.location,
      spatialExtent:
          clearSpatialExtent ? null : (spatialExtent ?? this.spatialExtent),
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      spatialResolution: spatialResolution ?? this.spatialResolution,
      temporalValidity: clearTemporalValidity
          ? null
          : (temporalValidity ?? this.temporalValidity),
      dataSource: clearDataSource ? null : (dataSource ?? this.dataSource),
      uncertainty: clearUncertainty ? null : (uncertainty ?? this.uncertainty),
      qualityState: qualityState ?? this.qualityState,
      provenanceSteps: provenanceSteps ?? this.provenanceSteps,
      metadata: metadata ?? this.metadata,
      schemaVersion: schemaVersion ?? this.schemaVersion,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'elementId': elementId,
      'category': category.name,
      'name': name,
      'latitude': location.latitude,
      'longitude': location.longitude,
      'quantity': quantity,
      'unit': unit,
      'spatialResolution': spatialResolution,
      'qualityState': qualityState,
      'uncertainty': uncertainty,
      'schemaVersion': schemaVersion,
      'metadata': metadata,
    };
  }

  factory ExposureElement.fromMap(Map<String, dynamic> map) {
    final catName = map['category'] as String? ?? 'other';
    final cat = ExposureCategory.values.firstWhere(
      (e) => e.name == catName,
      orElse: () => ExposureCategory.other,
    );

    return ExposureElement(
      elementId: map['elementId'] as String? ?? '',
      category: cat,
      name: map['name'] as String? ?? '',
      location: GeoLocation(
        latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
        longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      ),
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      unit: map['unit'] as String? ?? '',
      spatialResolution: map['spatialResolution'] as String? ?? 'point',
      qualityState: map['qualityState'] as String? ?? 'observed',
      uncertainty: (map['uncertainty'] as num?)?.toDouble(),
      schemaVersion: map['schemaVersion'] as int? ?? currentSchemaVersion,
      metadata: (map['metadata'] as Map<String, dynamic>?) ?? const {},
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExposureElement &&
          runtimeType == other.runtimeType &&
          elementId == other.elementId &&
          category == other.category &&
          name == other.name &&
          location == other.location &&
          quantity == other.quantity &&
          unit == other.unit &&
          spatialResolution == other.spatialResolution &&
          qualityState == other.qualityState &&
          schemaVersion == other.schemaVersion;

  @override
  int get hashCode => Object.hash(
        elementId,
        category,
        name,
        location,
        quantity,
        unit,
        spatialResolution,
        qualityState,
        schemaVersion,
      );
}
