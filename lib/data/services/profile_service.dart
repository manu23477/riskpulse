import 'package:flutter/material.dart';
import '../models/user_profile.dart';

class ProfileService extends ChangeNotifier {
  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService() => _instance;
  ProfileService._internal();

  UserProfile _profile = UserProfile(
    name: 'Himachal Citizen',
    email: 'user@riskpulse.hp.gov.in',
    watchedDistricts: ['Mandi', 'Kinnaur'],
  );

  UserProfile get profile => _profile;

  void updateName(String name) {
    _profile = _profile.copyWith(name: name);
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
