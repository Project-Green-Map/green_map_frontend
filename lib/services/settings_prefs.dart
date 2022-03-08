import 'dart:convert';

import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:map/models/car.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPrefs {
  late SharedPreferences _prefs;
  late List<Car> userCars;
  late String currentCarInUse;

  final Car _defaultCar = Car.fromSize('medium');
  final List<Car> _defaultCarList = [
    Car.fromSize('small'),
    Car.fromSize('medium'),
    Car.fromSize('large'),
  ];

  List<Car> get getAllCars => userCars + _defaultCarList;

  /*SettingsPrefs() {
    _onStart(); // moved this call to inside settings.dart to force the values being set before use
  }*/

  Future<void> onStart() async {
    _prefs = await SharedPreferences.getInstance();

    bool prefsExist = _prefs.getBool('settingsPrefExists') ?? false;

    if (prefsExist) {
      //load locally stored preferences
      userCars = (_prefs.getStringList('userCars') ?? [])
          .map((String car) => Car.fromJson(jsonDecode(car)))
          .toList();
      currentCarInUse = _prefs.getString('currentCarInUse') ?? _defaultCar.toString();
    } else {
      //first run, so generate local settings
      _prefs.setStringList('userCars', []);
      _prefs.setString('currentCarInUse', _defaultCar.toString());
      _prefs.setBool('settingsPrefExists', true);

      userCars = [];
      currentCarInUse = _defaultCar.toString();
    }
  }

  void reupdate() {
    userCars = (_prefs.getStringList('userCars') ?? [])
        .map((String car) => Car.fromJson(jsonDecode(car)))
        .toList();
    currentCarInUse = _prefs.getString('currentCarInUse') ?? _defaultCar.toString();
  }

  void addCar(Car car) {
    userCars.insert(0, car);
    _prefs.setStringList('userCars', userCars.map((e) => jsonEncode(e.toJson())).toList());
  }

  void deleteCar(Car car) {
    if (car.toString() == currentCarInUse) {
      setCurrentCar(_defaultCar.toString());
    }
    userCars.remove(car);
    _prefs.setStringList('userCars', userCars.map((e) => jsonEncode(e.toJson())).toList());
  }

  void setCurrentCar(String carStr) {
    currentCarInUse = carStr;
    _prefs.setString('currentCarInUse', carStr);
  }

  List<TravelMode> getTravelModes() {
    List<TravelMode> list = [];
    if (_prefs.getBool('key-walking') ?? true) list.add(TravelMode.walking);
    if (_prefs.getBool('key-cycling') ?? true) list.add(TravelMode.bicycling);
    if (_prefs.getBool('key-driving') ?? true) list.add(TravelMode.driving);
    if (_prefs.getBool('key-public-transport') ?? true) list.add(TravelMode.transit);
    return list;
  }

  String getDistanceUnit() {
    return _prefs.getString('key-distance') ?? 'km';
  }
}
