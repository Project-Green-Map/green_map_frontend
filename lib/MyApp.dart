import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late GoogleMapController mapController;

  final CameraPosition cambridgePosition = const CameraPosition(
    target: LatLng(52.2053, 0.1218),
    zoom: 12,
  );

  final Marker departmentMarker = const Marker(
    markerId: MarkerId('Computer Lab'),
    position: LatLng(52.21092413813225, 0.09148305961569092),
    infoWindow: InfoWindow(title: "Computer Lab, Cambridge"),
  );

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  Widget _buildGoogleMap(BuildContext context){
    return GoogleMap(
      mapType: MapType.normal,
      initialCameraPosition: cambridgePosition,
      onMapCreated: _onMapCreated,
      markers: {departmentMarker},
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Maps Sample App'),
          backgroundColor: Colors.green[700],
        ),
        body: _buildGoogleMap(context),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            mapController.animateCamera(CameraUpdate.newCameraPosition(cambridgePosition));
          },
          child: const Text('Center'),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }
}