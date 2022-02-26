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
  int _distanceUnits = 0;
  bool _drivingEabled = true;
  List<Car> _cars = [];
  Map<int, String> _carMAp = {};

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
                children: <Widget>[],
              )
            ],
          ),
        ));
  }

  Widget buildDistanceUnits() => DropDownSettingsTile(
        title: 'Distance units',
        settingKey: 'key-distance-units',
        selected: _distanceUnits,
        values: <int, String>{0: 'miles', 1: 'km'},
        onChange: (int value) => {_distanceUnits = value},
      );

  /*Widget buildCars() => CheckboxSettingsTile(
          leading: Icon(Icons.directions_car_outlined),
          settingKey: 'key-driving',
          title: 'Cars',
          onChange: (_) => {},
          childrenIfEnabled: <Widget>[
            RadioSettingsTile(
              title: 'Cars',
              settingKey: 'key-car',
              values: _carMAp,
              selected: 0,
            ),
            ModalSettingsTile(
              title: 'Add new car',
              children: <Widget>[
                SimpleDropDownSettingsTile(
                  title: 'Brand',
                  settingKey: 'key-car-brand',
                  values: <String>['Volvo', 'Toyota', 'BMW', 'Cadillac', 'Chevrolet'],
                  selected: 'BMW',
                )
              ],
            )
          ]);*/
}
