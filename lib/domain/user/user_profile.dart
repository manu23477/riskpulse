enum UserCategory {
  generalPublic,
  student,
  teacherEducator,
  researcherAcademic,
  ngoNonProfit,
  governmentPublicAuthority,
  professionalOrganization,
  universityInstitution
}

enum AccountRole {
  user,
  owner,
  administrator
}

enum VerificationStatus {
  notRequired,
  pending,
  verified,
  expired
}

enum SubscriptionPlan {
  communityFree,
  student,
  teacher,
  researcher,
  ngo,
  professional,
  government,
  institutional
}

class UserProfile {
  final String name;
  final String email;
  final List<String> watchedDistricts;
  final UserCategory category;
  final AccountRole role;
  final VerificationStatus verificationStatus;
  final SubscriptionPlan subscriptionPlan;

  UserProfile({
    required this.name,
    required this.email,
    required this.watchedDistricts,
    this.category = UserCategory.generalPublic,
    this.role = AccountRole.user,
    this.verificationStatus = VerificationStatus.notRequired,
    this.subscriptionPlan = SubscriptionPlan.communityFree,
  });

  UserProfile copyWith({
    String? name,
    String? email,
    List<String>? watchedDistricts,
    UserCategory? category,
    AccountRole? role,
    VerificationStatus? verificationStatus,
    SubscriptionPlan? subscriptionPlan,
  }) {
    return UserProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      watchedDistricts: watchedDistricts ?? this.watchedDistricts,
      category: category ?? this.category,
      role: role ?? this.role,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      subscriptionPlan: subscriptionPlan ?? this.subscriptionPlan,
    );
  }

  String get categoryLabel {
    switch (category) {
      case UserCategory.generalPublic: return 'General Public';
      case UserCategory.student: return 'Student';
      case UserCategory.teacherEducator: return 'Teacher / Educator';
      case UserCategory.researcherAcademic: return 'Researcher / Academic';
      case UserCategory.ngoNonProfit: return 'NGO / Non-profit';
      case UserCategory.governmentPublicAuthority: return 'Government / Public Authority';
      case UserCategory.professionalOrganization: return 'Professional / Organization';
      case UserCategory.universityInstitution: return 'University / Institution';
    }
  }
}
