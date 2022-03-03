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

  String _selectedCar = "default";
  late Future<void> _singleReadJson;

  @override
  void initState() {
    super.initState();
    _singleReadJson = _readJson();
  }

  List<Car> _cars = [];
  Map<int, String> _carMap = {0: 'BMW 3', 1: 'Volvo X', 2: 'Toyota Yaris'};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: SafeArea(
          child: FutureBuilder<void>(
              future: _singleReadJson,
              builder: (BuildContext context, AsyncSnapshot snapshot) {
                //inspect(_cars);
                if (snapshot.connectionState == ConnectionState.done) {
                  return ListView(
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
                  );
                } else
                  return Center(child: CircularProgressIndicator());
              })),
    );
  }

  Future<void> _readJson() async {
    String data = await DefaultAssetBundle.of(context).loadString("lib/assets/data/data2.json");
    List<dynamic> listJson = jsonDecode(data)['cars'];
    _cars = listJson.map((element) => Car.fromJson(element)).toList();
  }

  Widget buildDriving() {
    return SwitchSettingsTile(
        leading: Icon(Icons.directions_car_outlined),
        settingKey: 'key-driving5',
        defaultValue: _drivingEnabled,
        title: 'Driving',
        onChange: (_) => {_drivingEnabled = !_drivingEnabled},
        childrenIfEnabled: <Widget>[
          SimpleSettingsTile(
            title: 'Selected vehicle',
            subtitle: _selectedCar,
            child: Scaffold(
                appBar: AppBar(
                  title: Text('Car settings'),
                  actions: <Widget>[IconButton(onPressed: null, icon: Icon(Icons.edit))],
                ),
                body: SafeArea(
                    child: ListView(children: [
                  RadioSettingsTile(
                    title: 'Selected car',
                    settingKey: 'key-car140',
                    values: _carMap,
                    selected: 0,
                  ),
                  ListTile(
                    title: Text('Button'),
                    onTap: () => showDialog(
                        context: context, builder: (context) => CarSettings(cars: _cars)),
                  ),
                ]))),
          )
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
  List<Car> cars;

  CarSettings({Key? key, required this.cars}) : super(key: key);

  @override
  _CarSettingsState createState() => _CarSettingsState(cars);
}

class _CarSettingsState extends State<CarSettings> {
  List<Car> _cars;
  String? _selectedCarBrand = null;
  String? _selectedCarModel = null;
  String? _selectedCarFuel = null;
  String? _brandEnable;
  String? _modelEnable;

  _CarSettingsState(this._cars);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add new car'),
      content: Column(children: [
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
                .toList())
      ]),
    );
  }
}
