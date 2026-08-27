class EmergencyContact {
  final String id;
  final String name;
  final String phoneNumber;
  final bool isOfficial;
  final String? subtitle;

  const EmergencyContact({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.isOfficial = false,
    this.subtitle,
  });
}
