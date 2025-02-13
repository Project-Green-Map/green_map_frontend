import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:map/help.dart';
import 'package:map/services/settings_prefs.dart';

import './models/car.dart';

class SettingsPage extends StatefulWidget {
  final Function? onClose;
  const SettingsPage({Key? key, this.onClose}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _distanceUnits = 'km';
  bool _drivingEnabled = true,
      _walkingEnabled = true,
      _publicTransportEnabled = true,
      _cyclingEnabled = true;
  /*bool _busEnabled = true,
      _tramEnabled = true,
      _trainEnabled = true,
      _undergroundEnabled = true,
      _shipEnabled = true;
  */
  //SettingsPrefs parentSettingsPrefs = SettingsPrefs();

  //late Future<void> currentVehicleFutureObtained;

  /*Future<void> getVehicleFuture() async {
    await SettingsPrefs.onStart();
  }*/

  @override
  void initState() {
    super.initState();
    //currentVehicleFutureObtained = getVehicleFuture();
  }

  @override
  void deactivate() {
    if (widget.onClose != null) widget.onClose?.call();
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
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
            ),
            SettingsGroup(title: "Other", children: [
              ListTile(
                title: const Text("Help"),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const Help()),
                  );
                },
              ),
            ]),
            const SizedBox(height: 200),
          ],
        ),
      ),
    );
  }

  Widget buildDriving() {
    return SwitchSettingsTile(
      leading: const Icon(Icons.directions_car_outlined),
      settingKey: 'key-driving',
      defaultValue: _drivingEnabled,
      title: 'Driving',
      onChange: (_) => {_drivingEnabled = !_drivingEnabled},
      childrenIfEnabled: <Widget>[
        ListTile(
          title: const Text(
            'Select Vehicle',
            textAlign: TextAlign.center,
          ),
          subtitle: Text(
            SettingsPrefs.currentCarInUse.toString(),
            textAlign: TextAlign.center,
          ),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CarSettings(),
            ),
          ).then((_) => setState(() {})),
        ),
      ],
    );
  }

  Widget buildDistanceUnits() => SimpleDropDownSettingsTile(
        title: 'Distance units',
        settingKey: 'key-distance',
        selected: _distanceUnits,
        values: const ['miles', 'km'],
        onChange: (value) => {_distanceUnits = value},
      );

  Widget buildWalking() => SwitchSettingsTile(
        title: 'Walking',
        leading: const Icon(Icons.directions_walk),
        defaultValue: _walkingEnabled,
        settingKey: 'key-walking',
        onChange: (value) {
          _walkingEnabled = !_walkingEnabled;
        },
      );

  Widget buildCycling() => SwitchSettingsTile(
        title: 'Cycling',
        leading: const Icon(Icons.directions_bike),
        defaultValue: _cyclingEnabled,
        settingKey: 'key-cycling',
        onChange: (_) => {_cyclingEnabled = !_cyclingEnabled},
      );

  Widget buildPublicTransport() => SwitchSettingsTile(
        title: 'Public Transport',
        leading: const Icon(Icons.directions_bus),
        defaultValue: _publicTransportEnabled,
        settingKey: 'key-public-transport',
        onChange: (_) => {_publicTransportEnabled = !_publicTransportEnabled},
        /*childrenIfEnabled: [
          SwitchSettingsTile(
            title: 'Bus',
            leading: const Icon(Icons.directions_bus),
            settingKey: 'key-public-transport-bus',
            defaultValue: _busEnabled,
            onChange: (_) => _busEnabled = !_busEnabled,
            enabled: false,
          ),
          SwitchSettingsTile(
            title: 'Train',
            leading: const Icon(Icons.directions_train),
            settingKey: 'key-public-transport-train',
            defaultValue: _trainEnabled,
            onChange: (_) => _trainEnabled = !_trainEnabled,
            enabled: false,
          ),
          SwitchSettingsTile(
            title: 'Tram',
            leading: const Icon(Icons.directions_train_rounded),
            settingKey: 'key-public-transport-tram',
            defaultValue: _tramEnabled,
            onChange: (_) => _tramEnabled = !_tramEnabled,
            enabled: false,
          ),
          SwitchSettingsTile(
            title: 'Underground',
            leading: const Icon(Icons.directions_subway),
            settingKey: 'key-public-transport-underground',
            defaultValue: _undergroundEnabled,
            onChange: (_) => _undergroundEnabled = !_undergroundEnabled,
            enabled: false,
          ),
          SwitchSettingsTile(
            title: 'Ship',
            leading: const Icon(Icons.directions_boat),
            settingKey: 'key-public-transport-ship',
            defaultValue: _shipEnabled,
            onChange: (_) => _shipEnabled = !_shipEnabled,
            enabled: false,
          )
        ],*/
      );
}

class CarSettings extends StatefulWidget {
  const CarSettings({Key? key}) : super(key: key);

  @override
  _CarSettingsState createState() => _CarSettingsState();
}

class _CarSettingsState extends State<CarSettings> {
  late Future<void> _areFuturesInitialised;
  //SettingsPrefs settingsPrefs = SettingsPrefs();

  List<Car> _cars = [];

  @override
  void deactivate() {
    super.deactivate();
  }

  @override
  void initState() {
    super.initState();
    _areFuturesInitialised = initFutures();
  }

  Future<void> initFutures() async {
    await _readJson();
    //await SettingsPrefs.onStart(); // ensures the following lines use the right values
  }

  Future<void> _readJson() async {
    String data =
        await DefaultAssetBundle.of(context).loadString("lib/assets/data/frontend_data.json");
    List<dynamic> listJson = jsonDecode(data)['cars'];
    _cars = listJson.map((element) => Car.fromJson(element)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
        future: _areFuturesInitialised,
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Scaffold(
                appBar: AppBar(
                  title: const Text('Car settings'),
                  actions: [
                    IconButton(
                      onPressed: SettingsPrefs.userCars.isEmpty
                          ? null
                          : () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      DeleteCar(onFinish: () => setState(() {})))),
                      icon: const Icon(Icons.edit),
                    ),
                  ],
                ),
                body: SafeArea(
                  child: ListView(
                    children: [
                      Column(
                          children: (SettingsPrefs.userCars + SettingsPrefs.defaultCarList)
                              .map((Car c) => RadioListTile<Car>(
                                  title: Text(c.toString()),
                                  value: c,
                                  groupValue: SettingsPrefs.currentCarInUse,
                                  onChanged: (Car? newCar) {
                                    SettingsPrefs.setCurrentCar = newCar!;
                                    setState(() {});
                                  }))
                              .toList()),
                      ListTile(
                        leading: const Icon(Icons.add),
                        trailing: const Icon(
                          Icons.add,
                          color: Colors.white,
                        ),
                        title: const Text(
                          'Add car',
                          textAlign: TextAlign.center,
                        ),
                        onTap: () => showDialog(
                          context: context,
                          builder: (context) => NewCarSettings(
                            cars: _cars,
                            onFinish: () => setState(() {}),
                          ),
                        ),
                      ),
                    ],
                  ),
                ));
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        });
  }
}

class NewCarSettings extends StatefulWidget {
  final List<Car> cars;
  final VoidCallback onFinish;

  const NewCarSettings({Key? key, required this.cars, required this.onFinish}) : super(key: key);

  @override
  _NewCarSettingsState createState() => _NewCarSettingsState();
}

class _NewCarSettingsState extends State<NewCarSettings> {
  String? _selectedCarBrand;
  String? _selectedCarModel;
  String? _selectedCarFuel;
  String? _brandEnable;
  String? _modelEnable;

  _NewCarSettingsState();

  // @override
  // void deactivate() {
  //   widget.onFinish.call();
  //   super.deactivate();
  // }

  @override
  Widget build(BuildContext context) {
    Size _size = MediaQuery.of(context).size;

    return AlertDialog(
      title: const Text('Add new car'),
      insetPadding: EdgeInsets.symmetric(
        horizontal: _size.width * 0.2,
        vertical: _size.height * 0.23,
      ),
      content: Column(children: <Widget>[
        DropdownButtonFormField(
          //dropdownColor: Colors.white,
          hint: const Text("Brand"),
          //value: _selectedCarBrand,
          onChanged: (String? newValue) {
            setState(() {
              _selectedCarBrand = newValue;
              _brandEnable = null;
              _modelEnable = null;
            });
          },
          items: widget.cars
              .map((Car car) => car.brand)
              .toSet()
              .toList()
              .map((String car) => DropdownMenuItem(child: Text(car), value: car))
              .toList(),
        ),
        DropdownButtonFormField(
          hint: const Text("Model"),
          value: _brandEnable,
          onChanged: (String? newValue) {
            setState(() {
              _selectedCarModel = newValue;
              _brandEnable = newValue;
              _modelEnable = null;
            });
          },
          //
          //dropdownColor: Colors.blueAccent,
          items: widget.cars
              .where((car) => car.brand == _selectedCarBrand)
              .map((car) => car.model)
              .toSet()
              .toList()
              .map((String car) => DropdownMenuItem(child: Text(car), value: car))
              .toList(),
        ),
        DropdownButtonFormField(
          hint: const Text("Fuel"),
          value: _modelEnable,
          onChanged: (String? newValue) {
            setState(() {
              _selectedCarFuel = newValue;
              _modelEnable = newValue;
            });
          },
          //dropdownColor: Colors.blueAccent,
          items: widget.cars
              .where((car) => car.brand == _selectedCarBrand && car.model == _selectedCarModel)
              .map((car) => car.fuel)
              .toSet()
              .toList()
              .map((String car) => DropdownMenuItem(child: Text(car), value: car))
              .toList(),
        ),
      ]),
      actions: [
        ElevatedButton(
          onPressed: () {
            if (_selectedCarBrand != null &&
                _selectedCarModel != null &&
                _selectedCarFuel != null) {
              Car newCar = Car(_selectedCarBrand!, _selectedCarModel!, _selectedCarFuel!);
              SettingsPrefs.addCar = newCar;
              SettingsPrefs.setCurrentCar = newCar;
            }
            widget.onFinish();
            Navigator.pop(context);
          },
          child: const Text("Add"),
        )
      ],
    );
  }
}

class DeleteCar extends StatelessWidget {
  DeleteCar({Key? key, required this.onFinish}) : super(key: key);
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('Delete car')),
        body: SafeArea(
            child: ListView.separated(
          shrinkWrap: true,
          // default cars can't be deleted
          itemCount: SettingsPrefs.userCars.length,
          itemBuilder: (BuildContext context, int index) {
            return ListTile(
                trailing: IconButton(
                    icon: Icon(Icons.delete),
                    color: Colors.red,
                    onPressed: () {
                      SettingsPrefs.deleteCar = SettingsPrefs.userCars[index];
                      onFinish();
                      Navigator.pop(context);
                    }),
                title: Text(SettingsPrefs.userCars[index].toString()));
          },
          separatorBuilder: (BuildContext context, int index) => const Divider(),
        )));
  }
}
