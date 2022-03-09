import 'dart:convert';

import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:map/models/car.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPrefs {
  static late SharedPreferences prefs;
  static late List<Car> userCars;
  static late Car currentCarInUse;

  static final Car defaultCar = Car.fromSize('medium');
  static final List<Car> defaultCarList = [
    Car.fromSize('small'),
    Car.fromSize('medium'),
    Car.fromSize('large'),
  ];

  factory SettingsPrefs() => SettingsPrefs._internal();
  SettingsPrefs._internal();

  /*SettingsPrefs() {
    _onStart(); // moved this call to inside settings.dart to force the values being set before use
  }*/

  static Future<void> onStart() async {
    prefs = await SharedPreferences.getInstance();

    bool prefsExist = prefs.getBool('settingsPrefExists') ?? false;

    if (prefsExist) {
      //load locally stored preferences
      userCars = (prefs.getStringList('userCars') ?? [])
          .map((String car) => Car.fromJson(jsonDecode(car)))
          .toList();
      currentCarInUse = Car.fromJson(jsonDecode(prefs.getString('currentCarInUse')!));
    } else {
      //first run, so generate local settings
      prefs.setStringList('userCars', []);
      prefs.setString('currentCarInUse', defaultCar.toJSON());
      prefs.setBool('settingsPrefExists', true);

      userCars = [];
      currentCarInUse = defaultCar;
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
      prefs.setStringList('userCars', userCars.map((e) => e.toJSON()).toList());
    }
  }

  static set deleteCar(Car car) {
    if (car == currentCarInUse) {
      currentCarInUse = defaultCar;
      prefs.setString('currentCarInUse', defaultCar.toJSON());
    }
    userCars.remove(car);
    prefs.setStringList('userCars', userCars.map((e) => e.toJSON()).toList());
  }

  static set setCurrentCar(Car car) {
    currentCarInUse = car;
    prefs.setString('currentCarInUse', car.toJSON());
  }

  static List<TravelMode> getTravelModes() {
    List<TravelMode> list = [];
    if (prefs.getBool('key-walking') ?? true) list.add(TravelMode.walking);
    if (prefs.getBool('key-cycling') ?? true) list.add(TravelMode.bicycling);
    if (prefs.getBool('key-driving') ?? true) list.add(TravelMode.driving);
    if (prefs.getBool('key-public-transport') ?? true) list.add(TravelMode.transit);
    return list;
  }

  static String getDistanceUnit() {
    return prefs.getString('key-distance') ?? 'km';
  }
}
