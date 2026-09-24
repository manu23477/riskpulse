import 'package:flutter/foundation.dart';

/// Immutable domain contract representing Sentinel-2 multispectral band definitions.
///
/// SCIENTIFIC & SPECTRAL GOVERNANCE:
/// 1. Maps Sentinel-2 bands B2 (Blue), B3 (Green), B4 (Red), and B8 (NIR).
/// 2. Enforces non-negative physical surface reflectance scaling (0.0001 default for Sentinel-2 SR).
/// 3. Confirms spatial resolution (10m for B2, B3, B4, B8) and central wavelength (um).
@immutable
class MultispectralBandContract {
  final String bandId;
  final String name;
  final double centralWavelengthUm;
  final double spatialResolutionMeters;
  final double scaleFactor;
  final String units;

  const MultispectralBandContract({
    required this.bandId,
    required this.name,
    required this.centralWavelengthUm,
    required this.spatialResolutionMeters,
    this.scaleFactor = 0.0001,
    this.units = 'surface_reflectance',
  })  : assert(bandId.length > 0, 'bandId cannot be empty.'),
        assert(scaleFactor > 0.0, 'scaleFactor must be strictly positive.');

  /// Sentinel-2 Band 2 (Blue): 490 nm, 10m resolution
  static const b2Blue = MultispectralBandContract(
    bandId: 'B2',
    name: 'Blue',
    centralWavelengthUm: 0.490,
    spatialResolutionMeters: 10.0,
  );

  /// Sentinel-2 Band 3 (Green): 560 nm, 10m resolution
  static const b3Green = MultispectralBandContract(
    bandId: 'B3',
    name: 'Green',
    centralWavelengthUm: 0.560,
    spatialResolutionMeters: 10.0,
  );

  /// Sentinel-2 Band 4 (Red): 665 nm, 10m resolution
  static const b4Red = MultispectralBandContract(
    bandId: 'B4',
    name: 'Red',
    centralWavelengthUm: 0.665,
    spatialResolutionMeters: 10.0,
  );

  /// Sentinel-2 Band 8 (NIR): 842 nm, 10m resolution
  static const b8Nir = MultispectralBandContract(
    bandId: 'B8',
    name: 'NIR (Near Infrared)',
    centralWavelengthUm: 0.842,
    spatialResolutionMeters: 10.0,
  );
}
