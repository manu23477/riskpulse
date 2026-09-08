import 'package:flutter/foundation.dart';

/// Immutable definition of a single spectral band in a remote sensing product.
@immutable
class RemoteSensingBand {
  final String bandId;
  final String displayName;
  final double? wavelengthNm;
  final double nominalResolutionMeters;
  final String units;
  final double scaleFactor;
  final double offset;
  final String? description;

  const RemoteSensingBand({
    required this.bandId,
    required this.displayName,
    this.wavelengthNm,
    required this.nominalResolutionMeters,
    this.units = 'reflectance',
    this.scaleFactor = 0.0001,
    this.offset = 0.0,
    this.description,
  });

  /// Pre-defined standard Sentinel-2 Level-2A bands.
  static const RemoteSensingBand sentinel2B2 = RemoteSensingBand(
    bandId: 'B2',
    displayName: 'Blue',
    wavelengthNm: 490.0,
    nominalResolutionMeters: 10.0,
    description: 'Blue (490 nm)',
  );

  static const RemoteSensingBand sentinel2B3 = RemoteSensingBand(
    bandId: 'B3',
    displayName: 'Green',
    wavelengthNm: 560.0,
    nominalResolutionMeters: 10.0,
    description: 'Green (560 nm)',
  );

  static const RemoteSensingBand sentinel2B4 = RemoteSensingBand(
    bandId: 'B4',
    displayName: 'Red',
    wavelengthNm: 665.0,
    nominalResolutionMeters: 10.0,
    description: 'Red (665 nm)',
  );

  static const RemoteSensingBand sentinel2B8 = RemoteSensingBand(
    bandId: 'B8',
    displayName: 'NIR',
    wavelengthNm: 842.0,
    nominalResolutionMeters: 10.0,
    description: 'Near Infrared (842 nm)',
  );

  static const RemoteSensingBand sentinel2B11 = RemoteSensingBand(
    bandId: 'B11',
    displayName: 'SWIR-1',
    wavelengthNm: 1610.0,
    nominalResolutionMeters: 20.0,
    description: 'Shortwave Infrared 1 (1610 nm)',
  );

  static const RemoteSensingBand sentinel2B12 = RemoteSensingBand(
    bandId: 'B12',
    displayName: 'SWIR-2',
    wavelengthNm: 2190.0,
    nominalResolutionMeters: 20.0,
    description: 'Shortwave Infrared 2 (2190 nm)',
  );

  /// Map of pre-defined Sentinel-2 bands by band ID.
  static const Map<String, RemoteSensingBand> sentinel2Bands = {
    'B2': sentinel2B2,
    'B3': sentinel2B3,
    'B4': sentinel2B4,
    'B8': sentinel2B8,
    'B11': sentinel2B11,
    'B12': sentinel2B12,
  };
}
