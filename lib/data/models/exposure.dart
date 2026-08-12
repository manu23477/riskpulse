class Exposure {
  final String id;
  final String name;
  final String category;
  final double value;
  final String unit;
  final double latitude;
  final double longitude;

  const Exposure({
    required this.id,
    required this.name,
    required this.category,
    required this.value,
    required this.unit,
    required this.latitude,
    required this.longitude,
  });
}