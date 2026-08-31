/// Domain model representing quantitative geomorphological and hydrological 
/// characteristics of a watershed and its drainage network.
class MorphometricResult {
  final String watershedId;

  // Linear Morphometry
  final Map<int, int> streamCountsByOrder;
  final Map<int, double> totalStreamLengthByOrder;
  final Map<int, double> meanStreamLengthByOrder;
  final Map<int, double> bifurcationRatios;
  final double meanBifurcationRatio;

  // Areal Morphometry
  final double areaKm2;
  final double perimeterKm;
  final double drainageDensity; // km/km2
  final double streamFrequency; // streams/km2
  final double circularityRatio;
  final double elongationRatio;
  final double basinLengthKm;

  // Relief Morphometry
  final double maxElevation;
  final double minElevation;
  final double basinRelief;
  final double reliefRatio;
  final double ruggednessNumber;

  final Map<String, dynamic> metadata;

  const MorphometricResult({
    required this.watershedId,
    required this.streamCountsByOrder,
    required this.totalStreamLengthByOrder,
    required this.meanStreamLengthByOrder,
    required this.bifurcationRatios,
    required this.meanBifurcationRatio,
    required this.areaKm2,
    required this.perimeterKm,
    required this.drainageDensity,
    required this.streamFrequency,
    required this.circularityRatio,
    required this.elongationRatio,
    required this.basinLengthKm,
    required this.maxElevation,
    required this.minElevation,
    required this.basinRelief,
    required this.reliefRatio,
    required this.ruggednessNumber,
    this.metadata = const {},
  });
}
