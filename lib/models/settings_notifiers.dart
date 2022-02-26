import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SingleSetting extends ChangeNotifier {
  int _distanceUnits = 0;
  late SharedPreferences _pref;

  _initPrefs() async {
    _pref = await SharedPreferences.getInstance();
  }

  _loadPrefs() async {
    await _initPrefs();
    _distanceUnits = _pref.getInt('distanceUnit') ?? 0;
    notifyListeners();
  }

  _savePrefs() async {
    await _initPrefs();
    _pref.setInt("distanceUnit", _distanceUnits);
  }

  SingleSetting() {
    _loadPrefs();
  }

  int get distanceUnit => _distanceUnits;

  updateDistanceUnit(int value) {
    _distanceUnits = value;
    _savePrefs();
    notifyListeners();
  }
}
