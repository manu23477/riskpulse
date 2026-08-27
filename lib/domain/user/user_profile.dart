class UserProfile {
  final String name;
  final String email;
  final List<String> watchedDistricts;

  UserProfile({
    required this.name,
    required this.email,
    required this.watchedDistricts,
  });

  UserProfile copyWith({
    String? name,
    String? email,
    List<String>? watchedDistricts,
  }) {
    return UserProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      watchedDistricts: watchedDistricts ?? this.watchedDistricts,
    );
  }
}
