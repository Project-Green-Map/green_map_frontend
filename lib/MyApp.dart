import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart'; //only use for Position objects. add functionality via geolocator_service.dart
import 'package:map/models/place_search.dart';
import 'package:map/secrets.dart';
import 'package:map/services/places_service.dart';

import 'dart:math' show cos, sqrt, asin, min;

import './services/geolocator_service.dart';
import './services/geocoding_service.dart';

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Green Map',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MapView(),
    );
  }
}

class MapView extends StatefulWidget {
  const MapView({Key? key}) : super(key: key);

  @override
  _MapViewState createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  late GoogleMapController mapController;

  late Position _currentPosition;
  String _currentAddress = '';

  String _startAddress = '';
  String _destinationAddress = '';

  final CameraPosition cambridgePosition = const CameraPosition(
    target: LatLng(52.2053, 0.1218),
    zoom: 12,
  );

  final startAddressController = TextEditingController();
  final destinationAddressController = TextEditingController();

  final startAddressFocusNode = FocusNode();
  final destinationAddressFocusNode = FocusNode();

  final _geolocatorService = GeolocatorService();
  final _geocodingService = GeocodingService();
  final _placesService = PlacesService();

  List<PlaceSearch> searchResults = [];

  Set<Marker> markers = {};

  late PolylinePoints polylinePoints;
  Map<PolylineId, Polyline> polylines = {};
  List<LatLng> polylineCoordinates = [];

  Widget _textField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required double width,
    required Icon prefixIcon,
    Widget? suffixIcon,
    required Function(String) onChanged,
  }) {
    return SizedBox(
      width: width * 0.8,
      child: TextField(
        onChanged: onChanged,
        controller: controller,
        focusNode: focusNode,
        decoration: InputDecoration(
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(
            borderRadius: const BorderRadius.all(
              Radius.circular(10.0),
            ),
            borderSide: BorderSide(
              color: Colors.grey.shade400,
              width: 2,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: const BorderRadius.all(
              Radius.circular(10.0),
            ),
            borderSide: BorderSide(
              color: Colors.blue.shade300,
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.all(15),
          hintText: hint,
        ),
      ),
    );
  }

  @override
  void initState() {
    // called as soon as the app launches
    super.initState();
    print("initState() called");
  }

  void startupLogic() async {
    //called when the map is finished loading
    await updateCurrentLocation();
    moveCameraToCurrentLocation();
  }

  //in an effort to save API requests, only call when necessary
  updateCurrentLocation() async {
    await _geolocatorService.getCurrentLocation().then((position) async {
      setState(() {
        _currentPosition = position;
        print('CURRENT POS: $_currentPosition');
      });
      await _updateCurrentAddress();
    });
  }

  //do not call. use the above function
  _updateCurrentAddress() async {
    await _geocodingService.getCurrentPlacemark(_currentPosition).then((place) {
      setState(() {
        if (place != null) {
          // _currentAddress =
          //     "${place.name}, ${place.locality}, ${place.postalCode}, ${place.country}";
          ////Done: This doesn't work for street names, e.g. "17, , CB2 3NE, UK". Could we see which ones are non-null and use those?

          bool isFirst = true;
          List<String?> list = [place.name, place.locality, place.postalCode, place.country];
          for(int i = 0; i < 4; i ++){
            if(list.elementAt(i)?.isNotEmpty ?? false){
              _currentAddress += "${list.elementAt(i)}";
            }
            if(isFirst){
              isFirst = false;
            }
            else{
              _currentAddress += ", ";
            }
          }

          print("Current address: $_currentAddress");
          startAddressController.text = _currentAddress;
          _startAddress = _currentAddress;
        }
      });
    });
  }

  void moveCameraToCurrentLocation() async {
    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(_currentPosition.latitude, _currentPosition.longitude),
          zoom: 18.0,
        ),
      ),
    );
  }

  // Create the polylines for showing the route between two places
  _createPolylines(
    double startLatitude,
    double startLongitude,
    double destinationLatitude,
    double destinationLongitude,
  ) async {
    polylinePoints = PolylinePoints();
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      Secrets.API_KEY,
      PointLatLng(startLatitude, startLongitude),
      PointLatLng(destinationLatitude, destinationLongitude),
      travelMode: TravelMode.transit,
    );

    if (result.points.isNotEmpty) {
      result.points.forEach((PointLatLng point) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      });
    }

    PolylineId id = PolylineId('poly');
    Polyline polyline = Polyline(
      polylineId: id,
      color: Colors.red,
      points: polylineCoordinates,
      width: 3,
    );
    polylines[id] = polyline;
  }

  searchPlaces(String searchTerm) async {
    searchResults = await _placesService.getAutocomplete(searchTerm);
  }

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Stack(
        children: <Widget>[
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: cambridgePosition,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            // It's not working on my emulator.
            onMapCreated: (GoogleMapController controller) {
              mapController = controller;
              startupLogic(); // This logic ensures the map always loads before trying to move the camera, which itself has a currentPosition
            },
            polylines: Set<Polyline>.of(polylines.values),
          ),

          //suggestions box background (only show if there is a search):
          if (searchResults != null &&
              (startAddressController.text != '' ||
                  destinationAddressController.text != '') &&
              searchResults.length > 0)
            Container(
              height: height / 1.3,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                backgroundBlendMode: BlendMode.darken,
              ),
            ),

          //search area
          SafeArea(
              child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 10.0),
              //column below is for (1) container for search bars and (2) container for prediction results
              child: Column(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.white70,
                      borderRadius: BorderRadius.all(
                        Radius.circular(20.0),
                      ),
                    ),
                    width: width * 0.9,
                    child: Padding(
                        padding: const EdgeInsets.only(top: 10.0, bottom: 10.0),
                        //column below is for the two search bars
                        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              const Text(
                                'Places', //TODO: im not convinced we need this, it uses up a lot of real estate
                                style: TextStyle(fontSize: 20.0),
                              ),
                              const SizedBox(height: 10),
                              _textField(
                                  label: 'Start',
                                  hint: 'Choose starting point',
                                  prefixIcon: const Icon(Icons.looks_one),
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.my_location),
                                    onPressed: () {
                                      startAddressController.text =
                                          _currentAddress;
                                      _startAddress = _currentAddress;
                                    },
                                  ),
                                  controller: startAddressController,
                                  focusNode: startAddressFocusNode,
                                  width: width,
                                  onChanged: (String value) {
                                    //// DONE: should probably call locationCallback something else, it does more than just deal with location
                                    setState(() {
                                      _startAddress = value;
                                      ////DONE: should we be doing the above every time the user presses a new key?
                                      searchPlaces(value);
                                    });
                                  }),
                              const SizedBox(height: 10),
                              _textField(
                                  label: 'Destination',
                                  hint: 'Choose destination',
                                  prefixIcon: Icon(Icons.looks_two),
                                  controller: destinationAddressController,
                                  focusNode: destinationAddressFocusNode,
                                  width: width,
                                  onChanged: (String value) {
                                    setState(() {
                                      _destinationAddress = value;
                                      searchPlaces(value);
                                    });
                                  }),
                            ])),
                  ),

                  //adds spacing between the search bars and results
                  SizedBox(height: 10),

                  //suggestions list (only show if there is a search):
                  if (searchResults != null &&
                      (startAddressController.text != '' ||
                          destinationAddressController.text != '') &&
                      searchResults.length > 0)
                    ListView.builder(
                      shrinkWrap: true,
                      itemBuilder: ((context, index) {
                        return Card(
                            elevation: 3,
                            margin: EdgeInsets.symmetric(
                                vertical: 2, horizontal: 10),
                            color: Colors.black.withOpacity(0.7),
                            child: ListTile(
                              title: Text(searchResults[index].description,
                                  style: TextStyle(color: Colors.white)),
                            ));
                      }),
                      itemCount: min(3, searchResults.length),
                      //TODO: do we need more than 3?
                    ),
                ],
              ),
            ),
          )),

          //centre button
          SafeArea(
              child: Align(
                  alignment: FractionalOffset.bottomCenter,
                  child: Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: FloatingActionButton(
                        onPressed: () {
                          mapController.animateCamera(
                              CameraUpdate.newCameraPosition(CameraPosition(
                            target: LatLng(
                              _currentPosition.latitude,
                              _currentPosition.longitude,
                            ),
                            zoom: 12.0,
                          )));
                        },
                        child: const Text(
                            'Center'), //TODO: centre (UK) or center (US)? (or shall we just use an icon :P)
                      ))))
        ],
      ),
    );
  }
}

//TODO: check how much money the Places API is getting through ;)
