import 'package:flutter/material.dart';
import 'package:riskpulse/domain/user/user_profile.dart';

class ProfileService extends ChangeNotifier {
  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService() => _instance;
  ProfileService._internal();

  UserProfile _profile = UserProfile(
    name: 'Himachal Citizen',
    email: 'user@riskpulse.hp.gov.in',
    watchedDistricts: ['Mandi', 'Kinnaur'],
    category: UserCategory.generalPublic,
    role: AccountRole.user,
    verificationStatus: VerificationStatus.notRequired,
    subscriptionPlan: SubscriptionPlan.communityFree,
  );

  UserProfile get profile => _profile;

  void updateName(String name) {
    _profile = _profile.copyWith(name: name);
    notifyListeners();
  }

  void updateCategory(UserCategory category) {
    // Reset verification status and plan if category changes
    // (Logic for automatic plan/verification matching can go here later)
    _profile = _profile.copyWith(
      category: category,
      verificationStatus: category == UserCategory.generalPublic
          ? VerificationStatus.notRequired
          : VerificationStatus.pending,
    );
    notifyListeners();
  }

  void addDistrict(String district) {
    if (!_profile.watchedDistricts.contains(district)) {
      final updated = List<String>.from(_profile.watchedDistricts)..add(district);
      _profile = _profile.copyWith(watchedDistricts: updated);
      notifyListeners();
    }
  }

  void removeDistrict(String district) {
    final updated = List<String>.from(_profile.watchedDistricts)..remove(district);
    _profile = _profile.copyWith(watchedDistricts: updated);
    notifyListeners();
  }
}
