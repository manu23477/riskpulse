import 'spatial_concepts.dart';

class GisRegion {
  final String id;
  final String name;
  final String country;
  final String adminLevel;
  final MapExtent? extent;

  const GisRegion({
    required this.id,
    required this.name,
    this.country = 'India',
    this.adminLevel = 'State',
    this.extent,
  });

  static const himachalPradesh = GisRegion(
    id: 'in-hp',
    name: 'Himachal Pradesh',
  );

  static const uttarakhand = GisRegion(
    id: 'in-uk',
    name: 'Uttarakhand',
  );
}
