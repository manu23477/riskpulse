import 'dart:math' as math;
import 'package:flutter/foundation.dart';

/// Scientific classification of model calibration and empirical validation state.
enum ThresholdCalibrationStatus {
  uncalibrated,
  provisional,
  calibratedRegional,
  validatedOutofSample,
}

/// Immutable domain profile representing an empirical Landslide Rainfall Intensity-Duration (I-D) Threshold.
///
/// Formulated as:
/// $$I_{\text{threshold}} = a \cdot D^{-b}$$
/// where $I$ is precipitation intensity in $mm/h$ and $D$ is duration in hours.
@immutable
class LandslideThresholdProfile {
  static const int currentSchemaVersion = 1;

  final String profileId;
  final String name;
  final double coefficientA;
  final double exponentB;
  final double durationMinHours;
  final double durationMaxHours;
  final String geographicScope;
  final String landslideType;
  final String sourceCitation;
  final int publicationYear;
  final ThresholdCalibrationStatus calibrationStatus;
  final String notesAndLimitations;
  final int schemaVersion;

  const LandslideThresholdProfile({
    required this.profileId,
    required this.name,
    required this.coefficientA,
    required this.exponentB,
    this.durationMinHours = 0.1,
    this.durationMaxHours = 500.0,
    required this.geographicScope,
    required this.landslideType,
    required this.sourceCitation,
    required this.publicationYear,
    this.calibrationStatus = ThresholdCalibrationStatus.uncalibrated,
    this.notesAndLimitations = '',
    this.schemaVersion = currentSchemaVersion,
  })  : assert(profileId.length > 0, 'profileId cannot be empty.'),
        assert(name.length > 0, 'name cannot be empty.'),
        assert(coefficientA > 0.0, 'coefficientA must be strictly positive.'),
        assert(exponentB > 0.0, 'exponentB must be strictly positive.');

  /// Authoritative Caine (1980) Landmark Global Empirical Threshold Profile: $I = 14.82 D^{-0.39}$
  static const caine1980Global = LandslideThresholdProfile(
    profileId: 'caine-1980-global',
    name: 'Caine (1980) Global Empirical Rainfall I-D Threshold',
    coefficientA: 14.82,
    exponentB: 0.39,
    durationMinHours: 0.1,
    durationMaxHours: 500.0,
    geographicScope: 'Global Empirical Reference (Worldwide Shallow Landslide Data)',
    landslideType: 'Shallow Landslides and Debris Flows',
    sourceCitation:
        'Caine, N. (1980). The Rainfall Intensity-Duration Control of Shallow Landslides and Debris Flows. Geografiska Annaler: Series A, Physical Geography, 62(1-2), 23-27.',
    publicationYear: 1980,
    calibrationStatus: ThresholdCalibrationStatus.uncalibrated,
    notesAndLimitations:
        'Global empirical benchmark. Uncalibrated for Himachal Pradesh / Western Himalaya micro-climates. Intended as a baseline research threshold profile.',
  );

  /// Unverified Legacy Configuration Profile (12.5 / 0.42)
  static const unverifiedLegacy = LandslideThresholdProfile(
    profileId: 'unverified-legacy-research',
    name: 'Unverified Legacy Research Threshold Configuration',
    coefficientA: 12.5,
    exponentB: 0.42,
    durationMinHours: 1.0,
    durationMaxHours: 72.0,
    geographicScope: 'Unverified Scope (Unsubstantiated Literature Attribution)',
    landslideType: 'Generic Slope Instability',
    sourceCitation:
        'Unverified prior code configuration (No verified primary literature citation).',
    publicationYear: 2020,
    calibrationStatus: ThresholdCalibrationStatus.uncalibrated,
    notesAndLimitations:
        'Unverified legacy research parameter configuration. Must NOT be represented as Caine (1980) or GSI (2020) without primary literature verification.',
  );

  /// Calculates threshold intensity $I_{\text{threshold}} = a \cdot D^{-b}$ in $mm/h$.
  double calculateThresholdIntensity(double durationHours) {
    if (durationHours.isNaN || durationHours <= 0.0) {
      throw ArgumentError('durationHours must be strictly positive.');
    }
    // Clamp duration within valid profile bounds
    final clampedD = durationHours.clamp(durationMinHours, durationMaxHours);
    return coefficientA * math.pow(clampedD, -exponentB);
  }

  /// Calculates Threshold Exceedance Ratio $R = \frac{I}{I_{\text{threshold}}}$.
  double calculateExceedanceRatio({
    required double intensityMmHour,
    required double durationHours,
  }) {
    final thresh = calculateThresholdIntensity(durationHours);
    if (thresh <= 0.0) return 0.0;
    return intensityMmHour / thresh;
  }

  LandslideThresholdProfile copyWith({
    String? profileId,
    String? name,
    double? coefficientA,
    double? exponentB,
    double? durationMinHours,
    double? durationMaxHours,
    String? geographicScope,
    String? landslideType,
    String? sourceCitation,
    int? publicationYear,
    ThresholdCalibrationStatus? calibrationStatus,
    String? notesAndLimitations,
    int? schemaVersion,
  }) {
    return LandslideThresholdProfile(
      profileId: profileId ?? this.profileId,
      name: name ?? this.name,
      coefficientA: coefficientA ?? this.coefficientA,
      exponentB: exponentB ?? this.exponentB,
      durationMinHours: durationMinHours ?? this.durationMinHours,
      durationMaxHours: durationMaxHours ?? this.durationMaxHours,
      geographicScope: geographicScope ?? this.geographicScope,
      landslideType: landslideType ?? this.landslideType,
      sourceCitation: sourceCitation ?? this.sourceCitation,
      publicationYear: publicationYear ?? this.publicationYear,
      calibrationStatus: calibrationStatus ?? this.calibrationStatus,
      notesAndLimitations: notesAndLimitations ?? this.notesAndLimitations,
      schemaVersion: schemaVersion ?? this.schemaVersion,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'profileId': profileId,
      'name': name,
      'coefficientA': coefficientA,
      'exponentB': exponentB,
      'durationMinHours': durationMinHours,
      'durationMaxHours': durationMaxHours,
      'geographicScope': geographicScope,
      'landslideType': landslideType,
      'sourceCitation': sourceCitation,
      'publicationYear': publicationYear,
      'calibrationStatus': calibrationStatus.name,
      'notesAndLimitations': notesAndLimitations,
      'schemaVersion': schemaVersion,
    };
  }

  factory LandslideThresholdProfile.fromMap(Map<String, dynamic> map) {
    final statusName = map['calibrationStatus'] as String? ?? 'uncalibrated';
    final calStatus = ThresholdCalibrationStatus.values.firstWhere(
      (e) => e.name == statusName,
      orElse: () => ThresholdCalibrationStatus.uncalibrated,
    );

    return LandslideThresholdProfile(
      profileId: map['profileId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      coefficientA: (map['coefficientA'] as num?)?.toDouble() ?? 14.82,
      exponentB: (map['exponentB'] as num?)?.toDouble() ?? 0.39,
      durationMinHours: (map['durationMinHours'] as num?)?.toDouble() ?? 0.1,
      durationMaxHours: (map['durationMaxHours'] as num?)?.toDouble() ?? 500.0,
      geographicScope: map['geographicScope'] as String? ?? '',
      landslideType: map['landslideType'] as String? ?? '',
      sourceCitation: map['sourceCitation'] as String? ?? '',
      publicationYear: map['publicationYear'] as int? ?? 1980,
      calibrationStatus: calStatus,
      notesAndLimitations: map['notesAndLimitations'] as String? ?? '',
      schemaVersion: map['schemaVersion'] as int? ?? currentSchemaVersion,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LandslideThresholdProfile &&
          runtimeType == other.runtimeType &&
          profileId == other.profileId &&
          name == other.name &&
          coefficientA == other.coefficientA &&
          exponentB == other.exponentB &&
          durationMinHours == other.durationMinHours &&
          durationMaxHours == other.durationMaxHours &&
          geographicScope == other.geographicScope &&
          landslideType == other.landslideType &&
          sourceCitation == other.sourceCitation &&
          publicationYear == other.publicationYear &&
          calibrationStatus == other.calibrationStatus &&
          schemaVersion == other.schemaVersion;

  @override
  int get hashCode => Object.hash(
        profileId,
        name,
        coefficientA,
        exponentB,
        durationMinHours,
        durationMaxHours,
        geographicScope,
        landslideType,
        sourceCitation,
        publicationYear,
        calibrationStatus,
        schemaVersion,
      );
}
