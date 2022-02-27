import 'package:flutter/material.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class Car {
  String brand, model, size;
  Car(this.brand, this.model, this.size);
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
  List<Car> _cars = [];
  Map<int, String> _carMAp = {0: 'Volvo X', 1: 'Toyota Y', 2: 'BMW xyz'};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('Settings')),
        body: SafeArea(
          child: ListView(
            padding: EdgeInsets.all(24),
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
          ),
        ));
  }

  Widget buildDistanceUnits() => SimpleDropDownSettingsTile(
        title: 'Distance units',
        settingKey: 'key-distance',
        selected: _distanceUnits,
        values: ['miles', 'km'],
        onChange: (value) => {_distanceUnits = value},
      );

  Widget buildDriving() => SwitchSettingsTile(
          leading: Icon(Icons.directions_car_outlined),
          settingKey: 'key-driving4',
          defaultValue: _drivingEnabled,
          title: 'Driving',
          onChange: (_) => {_drivingEnabled = !_drivingEnabled},
          childrenIfEnabled: <Widget>[
            RadioSettingsTile(
              title: 'Selected vehicle',
              settingKey: 'key-car2',
              values: _carMAp,
              selected: 0,
              subtitle: '',
            ),
            ModalSettingsTile(
              title: 'Add a new car',
              leading: Icon(Icons.add_rounded),
              children: <Widget>[
                SimpleDropDownSettingsTile(
                  title: 'Brand',
                  settingKey: 'key-car-brand2',
                  values: ['Volvo', 'Toyota', 'BMW', 'Cadillac', 'Chevrolet'],
                  selected: 'BMW',
                ),
                SimpleDropDownSettingsTile(
                    title: 'Model',
                    settingKey: 'key-car-model2',
                    selected: 'X',
                    values: ['X', 'Y', 'Z'])
              ],
            )
          ]);

  Widget buildWalking() => SwitchSettingsTile(
      title: 'Walking',
      leading: Icon(Icons.directions_walk),
      defaultValue: _walkingEnabled,
      settingKey: 'key-walking3',
      onChange: (_) => {print(_walkingEnabled), _walkingEnabled = !_walkingEnabled});

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

  //Widget navigateToCars(BuildContext context) => SafeArea(child: child)
}
