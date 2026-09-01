/// Supported methods for classifying numerical raster data into thematic classes.
enum ClassificationMethod {
  manual,
  equalInterval,
  quantile,
  naturalBreaks,
  standardDeviation,
}

/// Represents a single thematic class range with an associated color and label.
class ClassBreak {
  /// The inclusive lower bound of the class.
  final double minValue;

  /// The exclusive upper bound of the class (standard GIS convention), 
  /// though usually treated as inclusive for the final class in a series.
  final double maxValue;

  final String label;
  final String colorHex;

  const ClassBreak({
    required this.minValue,
    required this.maxValue,
    required this.label,
    required this.colorHex,
  });

  /// Deterministically checks if a value falls within this class.
  bool contains(double value, {bool isLast = false}) {
    if (isLast) {
      return value >= minValue && value <= maxValue;
    }
    return value >= minValue && value < maxValue;
  }
}

/// A provider-neutral collection of ordered class breaks.
class ClassificationScheme {
  final ClassificationMethod method;
  final List<ClassBreak> breaks;

  const ClassificationScheme({
    required this.method,
    required this.breaks,
  });

  /// Validates that classes are ordered correctly and do not have invalid overlaps.
  void validate() {
    if (breaks.isEmpty) return;
    
    for (int i = 0; i < breaks.length; i++) {
      if (breaks[i].minValue >= breaks[i].maxValue) {
        throw ArgumentError('Class break at index $i has an invalid range: [${breaks[i].minValue}, ${breaks[i].maxValue}]');
      }
      
      if (i < breaks.length - 1) {
        if (breaks[i].maxValue > breaks[i + 1].minValue) {
          throw ArgumentError('Overlapping class ranges detected between index $i and ${i + 1}');
        }
      }
    }
  }

  ClassificationScheme copyWith({
    ClassificationMethod? method,
    List<ClassBreak>? breaks,
  }) {
    return ClassificationScheme(
      method: method ?? this.method,
      breaks: breaks ?? List<ClassBreak>.from(this.breaks),
    );
  }
}
