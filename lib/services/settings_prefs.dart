import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:map/models/car.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPrefs {
  late SharedPreferences _prefs;
  late List<Car> userCars;
  late String currentCarInUse; //! Car.toString() of the current car, NOT the _carToString() of it
  //sorry for the confusion, but without changing the Car.toString(), e.g. "Kia Motors XS 5" is
  //ambiguous (how to tell where brand ends / model starts?), hence the need for these two representations

  final Car _defaultCar = Car.fromSize('medium');
  final List<Car> _defaultCarList = [
    Car.fromSize('small'),
    Car.fromSize('medium'),
    Car.fromSize('large'),
  ];

  /*SettingsPrefs() {
    _onStart(); // moved this call to inside settings.dart to force the values being set before use
  }*/

  Future<void> onStart() async {
    _prefs = await SharedPreferences.getInstance();

    //_prefs.clear();

    bool prefsExist = _prefs.getBool('settingsPrefExists') ?? false;

    if (prefsExist) {
      //load locally stored preferences
      userCars =
          (_prefs.getStringList('userCars') ?? []).map((String car) => _stringToCar(car)).toList();
      currentCarInUse = _prefs.getString('currentCarInUse') ?? _defaultCar.toString();
    } else {
      //first run, so generate local settings
      _prefs.setStringList('userCars', _defaultCarList.map((e) => _carToString(e)).toList());
      _prefs.setString('currentCarInUse', _defaultCar.toString());
      _prefs.setBool('settingsPrefExists', true);
      _prefs.setInt('currentCarIndex', 1);

      userCars = _defaultCarList;
      currentCarInUse = _defaultCar.toString();
    }
  }

  //TODO: fix blue button and carbon request not updating when changing car

  void reupdate() {
    userCars =
        (_prefs.getStringList('userCars') ?? []).map((String car) => _stringToCar(car)).toList();
    currentCarInUse = _prefs.getString('currentCarInUse') ?? _defaultCar.toString();
  }

  void addCar(Car car) {
    userCars.insert(0, car);
    _prefs.setStringList('userCars', userCars.map((e) => _carToString(e)).toList());
    _prefs.setInt('currentCarIndex', _prefs.getInt('currentCarIndex') ?? 1 + 1);
  }

  void setCurrentCar(String carStr) {
    currentCarInUse = carStr;
    _prefs.setString('currentCarInUse', carStr);
  }

  Car _stringToCar(String str) {
    List<String> splits = str.split('\n');
    if (splits.first.isNotEmpty) {
      //if brand is not ""
      return Car(splits[0], splits[1], splits[2]);
    } else {
      return Car.fromSize(splits[3]);
    }
  }

  String _carToString(Car car) {
    //doesn't use Car.toString() as potentially ambiguous spacing
    return car.brand + '\n' + car.model + '\n' + car.fuel + '\n' + car.size;
  }

  List<TravelMode> getTravelModes() {
    List<TravelMode> list = [];
    if (_prefs.getBool('key-walking3') ?? true) list.add(TravelMode.walking);
    if (_prefs.getBool('key-cycling3') ?? true) list.add(TravelMode.bicycling);
    if (_prefs.getBool('key-driving5') ?? true) list.add(TravelMode.driving);
    if (_prefs.getBool('key-public-transport3') ?? true) list.add(TravelMode.transit);
    return list;
  }

  String getDistanceUnit() {
    return _prefs.getString('key-distance') ?? 'km';
  }

  Car getCurrentCar() {
    int index = _prefs.getInt('currentCarIndex') ?? 1;
    return userCars[index];
  }

  void setCurrentCarIndex(int i) {
    _prefs.setInt('currentCarIndex', i);
  }
}
