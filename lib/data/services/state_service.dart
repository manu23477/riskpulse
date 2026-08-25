import 'package:flutter/material.dart';

enum HimalayanState { himachal, uttarakhand }

class StateService extends ChangeNotifier {
  static final StateService _instance = StateService._internal();
  factory StateService() => _instance;
  StateService._internal();

  HimalayanState _selectedState = HimalayanState.himachal;

  HimalayanState get selectedState => _selectedState;

  String get stateName {
    switch (_selectedState) {
      case HimalayanState.himachal: return 'Himachal Pradesh';
      case HimalayanState.uttarakhand: return 'Uttarakhand';
    }
  }

  void setState(HimalayanState newState) {
    if (_selectedState != newState) {
      _selectedState = newState;
      notifyListeners();
    }
  }
}
