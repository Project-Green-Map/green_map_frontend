import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';

import './models/car.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _distanceUnits = 'km';
  bool _drivingEnabled = true,
      _walkingEnabled = true,
      _publicTransportEnabled = true,
      _cyclingEnabled = true,
      _busEnabled = true,
      _tramEnabled = true,
      _trainEnabled = true,
      _undergroundEnabled = true,
      _shipEnabled = true;

  String _selectedCar = "Default (small)";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: SafeArea(
          child: ListView(
        children: [
          SettingsGroup(
            title: 'Common',
            children: <Widget>[
              buildDistanceUnits(),
            ],
          ),
          SettingsGroup(
            title: 'Transport',
            children: <Widget>[
              buildWalking(),
              buildCycling(),
              buildDriving(),
              buildPublicTransport()
            ],
          )
        ],
      )),
    );
  }

  Widget buildDriving() {
    return SwitchSettingsTile(
        leading: Icon(Icons.directions_car_outlined),
        settingKey: 'key-driving5',
        defaultValue: _drivingEnabled,
        title: 'Driving',
        onChange: (_) => {_drivingEnabled = !_drivingEnabled},
        childrenIfEnabled: <Widget>[
          // TODO: selected car needs to be updated
          ListTile(
              title: Text('Selected Vehicle'),
              subtitle: Text(_selectedCar),
              onTap: () =>
                  Navigator.push(context, MaterialPageRoute(builder: (context) => CarSettings()))),
        ]);
  }

  Widget buildDistanceUnits() => SimpleDropDownSettingsTile(
        title: 'Distance units',
        settingKey: 'key-distance',
        selected: _distanceUnits,
        values: ['miles', 'km'],
        onChange: (value) => {_distanceUnits = value},
      );

  Widget buildWalking() => SwitchSettingsTile(
      title: 'Walking',
      leading: Icon(Icons.add),
      defaultValue: _walkingEnabled,
      settingKey: 'key-walking3',
      onChange: (_) => {_walkingEnabled = !_walkingEnabled});

  Widget buildCycling() => SwitchSettingsTile(
        title: 'Cycling',
        leading: Icon(Icons.directions_bike),
        defaultValue: _cyclingEnabled,
        settingKey: 'key-cycling3',
        onChange: (_) => {_cyclingEnabled = !_cyclingEnabled},
      );

  Widget buildPublicTransport() => SwitchSettingsTile(
        title: 'Public Transport',
        leading: Icon(Icons.directions_bus),
        defaultValue: _publicTransportEnabled,
        settingKey: 'key-public-transport3',
        onChange: (_) => {_publicTransportEnabled = !_publicTransportEnabled},
        childrenIfEnabled: [
          SwitchSettingsTile(
              title: 'Bus',
              leading: Icon(Icons.directions_bus),
              settingKey: 'key-public-transport-bus2',
              defaultValue: _busEnabled,
              onChange: (_) => _busEnabled = !_busEnabled),
          SwitchSettingsTile(
            title: 'Train',
            leading: Icon(Icons.directions_train),
            settingKey: 'key-public-transport-train2',
            defaultValue: _trainEnabled,
            onChange: (_) => _trainEnabled = !_trainEnabled,
          ),
          SwitchSettingsTile(
            title: 'Tram',
            leading: Icon(Icons.directions_train_rounded),
            settingKey: 'key-public-transport-tram2',
            defaultValue: _tramEnabled,
            onChange: (_) => _tramEnabled = !_tramEnabled,
          ),
          SwitchSettingsTile(
            title: 'Undergound',
            leading: Icon(Icons.directions_subway),
            settingKey: 'key-public-transport-undergound2',
            defaultValue: _undergroundEnabled,
            onChange: (_) => _undergroundEnabled = !_undergroundEnabled,
          ),
          SwitchSettingsTile(
            title: 'Ship',
            leading: Icon(Icons.directions_boat),
            settingKey: 'key-public-transport-ship2',
            defaultValue: _shipEnabled,
            onChange: (_) => _shipEnabled = !_shipEnabled,
          )
        ],
      );
}

class CarSettings extends StatefulWidget {
  @override
  _CarSettingsState createState() => _CarSettingsState();
}

class _CarSettingsState extends State<CarSettings> {
  // TODO: add shared preferences for cars
  String _selectedCar = "Default (small)";
  late Future<void> _singleReadJson;

  bool editMode = false;

  @override
  void initState() {
    super.initState();
    _singleReadJson = _readJson();
  }

  Future<void> _readJson() async {
    String data = await DefaultAssetBundle.of(context).loadString("lib/assets/data/data2.json");
    List<dynamic> listJson = jsonDecode(data)['cars'];
    _cars = listJson.map((element) => Car.fromJson(element)).toList();
  }

  List<Car> _cars = [];
  List<Car> _userCars = [
    Car.fromSize("small"),
    Car.fromSize("medium"),
    Car.fromSize("large"),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Car settings'),
          // TODO: add the possibility to delete in edit mode
          actions: <Widget>[
            IconButton(
                onPressed: () => setState(() {
                      editMode = !editMode;
                    }),
                icon: Icon(Icons.edit))
          ],
        ),
        body: FutureBuilder<void>(
            future: _singleReadJson,
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              //inspect(_cars);
              if (snapshot.connectionState == ConnectionState.done) {
                return SafeArea(
                    child: ListView(children: [
                  SimpleRadioSettingsTile(
                    title: 'Selected car',
                    settingKey: 'key-car190',
                    values: _userCars.map((Car c) => c.toString()).toList(),
                    selected: _userCars.first.toString(),
                  ),
                  /*Column(
                      children: _userCars
                          .map((c) => RadioListTile<String>(
                                title: Text(c.toString()),
                                value: c.toString(),
                                groupValue: _selectedCar,
                                onChanged: (String? value) {
                                  setState(() {
                                    _selectedCar = value!;
                                    print("should change to " + _selectedCar);
                                  });
                                },
                              ))
                          .toList()),*/
                  ListTile(
                    leading: const Icon(Icons.add),
                    trailing: const Icon(
                      Icons.add,
                      color: Colors.white,
                    ),
                    title: const Text(
                      'Add car...',
                      textAlign: TextAlign.center,
                    ),
                    onTap: () => showDialog(
                        context: context,
                        builder: (context) => NewCarSettings(
                              cars: _cars,
                              addNewCar: (Car newCar) {
                                setState(() {
                                  _userCars.add(newCar);
                                  _userCars = _userCars.toList();
                                });
                                inspect(_userCars);
                              },
                            )),
                  ),
                ]));
              } else
                return Center(child: CircularProgressIndicator());
            }));
  }
}

class NewCarSettings extends StatefulWidget {
  List<Car> cars;
  final ValueSetter<Car> addNewCar;

  NewCarSettings({Key? key, required this.cars, required this.addNewCar}) : super(key: key);

  @override
  _NewCarSettingsState createState() => _NewCarSettingsState(cars);
}

class _NewCarSettingsState extends State<NewCarSettings> {
  List<Car> _cars;
  String? _selectedCarBrand = null;
  String? _selectedCarModel = null;
  String? _selectedCarFuel = null;
  String? _brandEnable;
  String? _modelEnable;

  _NewCarSettingsState(this._cars);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add new car'),
      content: Column(children: <Widget>[
        DropdownButtonFormField(
            dropdownColor: Colors.blueAccent,
            //value: _selectedCarBrand,
            onChanged: (String? newValue) {
              setState(() {
                _selectedCarBrand = newValue;
                _brandEnable = null;
                _modelEnable = null;
              });
            },
            items: _cars
                .map((Car car) => car.brand)
                .toSet()
                .toList()
                .map((String car) => DropdownMenuItem(child: Text(car), value: car))
                .toList()),
        DropdownButtonFormField(
          value: _brandEnable,
          onChanged: (String? newValue) {
            setState(() {
              _selectedCarModel = newValue;
              _brandEnable = newValue;
              _modelEnable = null;
            });
          },
          dropdownColor: Colors.blueAccent,
          items: _cars
              .where((car) => car.brand == _selectedCarBrand)
              .map((car) => car.model)
              .toSet()
              .toList()
              .map((String car) => DropdownMenuItem(child: Text(car), value: car))
              .toList(),
        ),
        DropdownButtonFormField(
            value: _modelEnable,
            onChanged: (String? newValue) {
              setState(() {
                _selectedCarFuel = newValue;
                _modelEnable = newValue;
              });
            },
            dropdownColor: Colors.blueAccent,
            items: _cars
                .where((car) => car.brand == _selectedCarBrand && car.model == _selectedCarModel)
                .map((car) => car.fuel)
                .toSet()
                .toList()
                .map((String car) => DropdownMenuItem(child: Text(car), value: car))
                .toList()),
      ]),
      actions: [
        ElevatedButton(
            onPressed: () {
              if (_selectedCarBrand != null &&
                  _selectedCarModel != null &&
                  _selectedCarFuel != null) {
                inspect(Car(_selectedCarBrand!, _selectedCarModel!, _selectedCarFuel!));
                widget.addNewCar(Car(_selectedCarBrand!, _selectedCarModel!, _selectedCarFuel!));
              } else
                null;
              Navigator.pop(context);
            },
            child: Text("Add"))
      ],
    );
  }
}
