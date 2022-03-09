import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:map/models/car.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPrefs {
  static late SharedPreferences _prefs;
  static late List<Car> userCars;
  static late Car currentCarInUse;

  static final Car _defaultCar = Car.fromSize('medium');
  static final List<Car> _defaultCarList = [
    Car.fromSize('small'),
    Car.fromSize('medium'),
    Car.fromSize('large'),
  ];

  factory() => SettingsPrefs._internal();
  SettingsPrefs._internal();

  static List<Car> get getAllCars =>
      (_prefs.getStringList('userCars') ?? [])
          .map((String car) => Car.fromJson(jsonDecode(car)))
          .toList() +
      _defaultCarList;

  static List<Car> get getUserCars => (_prefs.getStringList('userCars') ?? [])
      .map((String car) => Car.fromJson(jsonDecode(car)))
      .toList();
  static Car get getCurrentCarInUse => _prefs.getString('currentCarInUse') == null
      ? Car.fromJson(_prefs.getString('currentCarInUse'))
      : _defaultCar;

  /*SettingsPrefs() {
    _onStart(); // moved this call to inside settings.dart to force the values being set before use
  }*/

  static Future<void> onStart() async {
    _prefs = await SharedPreferences.getInstance();

    if (_prefs != null) {
      //load locally stored preferences
      print("load seetings....");
      userCars = (_prefs.getStringList('userCars') ?? [])
          .map((String car) => Car.fromJson(jsonDecode(car)))
          .toList();
      print(_prefs.getString('currentCarInUse'));
      currentCarInUse = Car.fromJson(jsonDecode(_prefs.getString('currentCarInUse')!));
    } else {
      print("first load...");
      //first run, so generate local settings
      _prefs.setStringList('userCars', []);
      _prefs.setString('currentCarInUse', _defaultCar.toJSON());

      userCars = [];
      currentCarInUse = _defaultCar;
    }
  }

  /*void reupdate() {
    userCars = (_prefs.getStringList('userCars') ?? [])
        .map((String car) => Car.fromJson(jsonDecode(car)))
        .toList();
    currentCarInUse = _prefs.getString('currentCarInUse') ?? _defaultCar.toString();
  }*/

  static set addCar(Car car) {
    if (!userCars.contains(car)) {
      userCars.insert(0, car);
      _prefs.setStringList('userCars', userCars.map((e) => e.toJSON()).toList());
    }
  }

  static set deleteCar(Car car) {
    if (car == currentCarInUse) {
      currentCarInUse = _defaultCar;
      _prefs.setString('currentCarInUse', _defaultCar.toJSON());
    }
    userCars.remove(car);
    _prefs.setStringList('userCars', userCars.map((e) => e.toJSON()).toList());
  }

  static set setCurrentCar(Car car) {
    currentCarInUse = car;
    _prefs.setString('currentCarInUse', car.toJSON());
  }

  static List<TravelMode> getTravelModes() {
    List<TravelMode> list = [];
    if (_prefs.getBool('key-walking') ?? true) list.add(TravelMode.walking);
    if (_prefs.getBool('key-cycling') ?? true) list.add(TravelMode.bicycling);
    if (_prefs.getBool('key-driving') ?? true) list.add(TravelMode.driving);
    if (_prefs.getBool('key-public-transport') ?? true) list.add(TravelMode.transit);
    return list;
  }

  static String getDistanceUnit() {
    return _prefs.getString('key-distance') ?? 'km';
  }
}
