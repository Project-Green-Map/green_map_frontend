import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SingleSetting extends ChangeNotifier {
  String _distanceUnits = 'miles';
  late SharedPreferences _pref;

  _initPrefs() async {
    _pref = await SharedPreferences.getInstance();
  }

  _loadPrefs() async {
    await _initPrefs();
    _distanceUnits = _pref.getString('distanceUnit') ?? 'miles';
    notifyListeners();
  }

  _savePrefs() async {
    await _initPrefs();
    _pref.setString("distanceUnit", _distanceUnits);
  }

  SingleSetting() {
    _loadPrefs();
  }

  String get distanceUnit => _distanceUnits;

  updateDistanceUnit(String value) {
    _distanceUnits = value;
    _savePrefs();
    notifyListeners();
  }
}
